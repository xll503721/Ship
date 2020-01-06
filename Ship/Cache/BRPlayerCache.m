//
//  BRPlayerCache.m
//  Ship
//
//  Created by xlL on 2019/12/9.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "BRPlayerCache.h"

#import <CommonCrypto/CommonCrypto.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "BRLog.h"
#import "BRLargeFileDownload.h"

static NSString *BRVideoPlayerURLScheme = @"com.long.xlL.BRKit";
static NSString *BRVideoPlayerURL = @"www.long.com";


@interface NSData (BRPlayerCache)

- (NSString *)md5String;

@end

@implementation NSData (BRPlayerCache)

- (NSString *)md5String {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(self.bytes, (CC_LONG)self.length, result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end

@interface NSString (BRPlayerCache)

- (NSString *)md5String;

@end

@implementation NSString (BRPlayerCache)

- (NSString *)md5String {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] md5String];
}

@end

#pragma mark - NSHTTPURLResponse(BRPlayerCache)

@implementation NSHTTPURLResponse (BRPlayerCache)

- (long long)br_fileTotalLength {
    NSString *range = [self allHeaderFields][@"Content-Range"];
    if (range) {
        NSArray *ranges = [range componentsSeparatedByString:@"/"];
        if (ranges.count > 0) {
            NSString *lengthString = [[ranges lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            return [lengthString longLongValue];
        }
    }
    else {
        return [self expectedContentLength];
    }
    return 0;
}

@end

#pragma mark - BRPlayerCacheFile

@interface BRPlayerCacheFile : NSObject

@property (nonatomic, assign) int64_t totalLength;
@property (nonatomic, assign) int64_t availableLength;
@property (nonatomic, strong) NSString *contentType;
@property (nonatomic, strong) NSString *identify;
@property (nonatomic, assign) BOOL dowloadComplete;
@property (nonatomic, strong) NSURL *URL;

@end

@implementation BRPlayerCacheFile

- (void)checkCloseFile {
    if (self.availableLength >= self.totalLength) {
        
    }
}

#pragma mark - getter

- (BOOL)dowloadComplete {
    return self.availableLength >= self.totalLength;
}

#pragma mark - setter

- (void)setTotalLength:(int64_t)totalLength {
    if (_totalLength == 0) {
        _totalLength = totalLength;
    }
}

- (void)setContentType:(NSString *)contentType {
    if (!_contentType || [_contentType isEqualToString:@""]) {
        _contentType = contentType;
    }
}

@end

#pragma mark - BRPlayerCacheLocalFile

@interface BRPlayerCacheLocalFile : BRPlayerCacheFile

@property (nonatomic, strong) NSFileHandle *writeFileHandle;
@property (nonatomic, strong) NSFileHandle *readFileHandle;

@end

@implementation BRPlayerCacheLocalFile

- (void)dealloc
{
    [_writeFileHandle closeFile];
    [_readFileHandle closeFile];
}

- (instancetype)initWithURL:(NSURL *)URL
{
    self = [super init];
    if (self) {
        self.URL = URL;
        
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    NSString *fileNameMD5 = [self.URL.absoluteString md5String];
//    NSString *path = [BRVideoPlayerURLScheme stringByAppendingPathComponent:fileNameMD5];
    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    NSString *fullPath = [document stringByAppendingPathComponent:fileNameMD5];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:fullPath]) {
        [fileManager createFileAtPath:fullPath contents:nil attributes:nil];
    }
    
    self.writeFileHandle = [NSFileHandle fileHandleForWritingAtPath:fullPath];
}

#pragma mark - public
- (void)appendData:(NSData *)data offset:(int64_t)offset {
    if ([self checkComplete]) {
        return;
    }
    
    [self.writeFileHandle seekToFileOffset:offset];
    [self.writeFileHandle writeData:data];
    [self.writeFileHandle synchronizeFile];
    
    self.availableLength += data.length;
}

- (void)appendData:(NSData *)data {
    [self appendData:data offset:self.availableLength];
}

- (BOOL)checkComplete {
    return self.availableLength >=  self.totalLength;
}

- (void)closeFileIfComplete {
    if (![self checkComplete]) {
        return;
    }
    
    [self.writeFileHandle closeFile];
}

@end

#pragma mark - BRPlayerViewDownload

static NSString *kBRPlayerCacheWebDownloadURLKey = @"kBRPlayerCacheWebDownloadURLKey";
static NSString *kBRPlayerCacheWebDownloadRangeKey = @"kBRPlayerCacheWebDownloadRangeKey";

@interface BRPlayerCacheWebDownload : NSObject

@end

@protocol BRPlayerViewDownloadDelegate <NSObject>

@optional
- (void)download:(BRPlayerCacheWebDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response;
- (void)download:(BRPlayerCacheWebDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response contentLength:(int64_t)length totalLength:(int64_t)totalLength contentType:(NSString *)type contentRange:(BRRange)range;
- (void)download:(BRPlayerCacheWebDownload *)download didReceiveData:(NSData *)data;
- (void)download:(BRPlayerCacheWebDownload *)download didCompleteWithError:(NSError *)error;

@end

@interface BRPlayerCacheWebDownload () <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSArray<NSString *> *allHeaderKeys;
@property (nonatomic, weak) id<BRPlayerViewDownloadDelegate> delegagte;

@property (nonatomic, assign) BRRange range;
@property (nonatomic, assign) int64_t availableLength;

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) AVAssetResourceLoadingRequest *loadingRequest;
@property (nonatomic, strong) NSMutableArray<AVAssetResourceLoadingRequest *> *loadingRequests;

@property (nonatomic, strong) BRPlayerCacheLocalFile *localFile;

@property (nonatomic, strong) NSMutableArray<NSDictionary<NSString *, NSObject *> *> *requests;

@end

@implementation BRPlayerCacheWebDownload

- (instancetype)initWithURL:(NSURL *)URL
{
    self = [super init];
    if (self) {
        [self commonInitWithURL:URL];
        
        _localFile = [[BRPlayerCacheLocalFile alloc] initWithURL:URL];
    }
    return self;
}

- (instancetype)initWithResourceLoadingRequest:(AVAssetResourceLoadingRequest *)request
{
    self = [super init];
    if (self) {
        [self addResourceLoadingRequest:request];

        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:request.request.URL resolvingAgainstBaseURL:NO];
        components.scheme = @"http";

        _localFile = [[BRPlayerCacheLocalFile alloc] initWithURL:[components URL]];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL reqeustRange:(BRRange)range
{
    self = [super init];
    if (self) {
        
        _range = range;
        [self commonInitWithURL:URL];
        
        _localFile = [[BRPlayerCacheLocalFile alloc] initWithURL:URL];
    }
    return self;
}

- (void)addResourceLoadingRequest:(AVAssetResourceLoadingRequest *)request {
    [self.loadingRequests addObject:request];
    self.range = [self fetchRequestRangeWithRequest:request];
    
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:request.request.URL resolvingAgainstBaseURL:YES];
    components.scheme = @"http";
    
    [self commonInitWithURL:[components URL]];
}

- (BRRange)fetchRequestRangeWithRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    int64_t location = loadingRequest.dataRequest.requestedOffset;
    int64_t length = loadingRequest.dataRequest.requestedLength;

    if ([loadingRequest.dataRequest respondsToSelector:@selector(requestsAllDataToEndOfResource)] && loadingRequest.dataRequest.requestsAllDataToEndOfResource) {
        length = self.localFile.totalLength - location;
    }
    
    if(loadingRequest.dataRequest.currentOffset > 0){
        location = loadingRequest.dataRequest.currentOffset;
    }
    
    return BRMakeRange(location, length);
}

- (void)start {
    self.loadingRequest = self.loadingRequests.firstObject;
    
    NSDictionary<NSString *, NSObject *> *reqeust = self.requests.firstObject;
    NSURL *URL = (NSURL *)reqeust[kBRPlayerCacheWebDownloadURLKey];
    NSValue *rangeValue = (NSValue *)reqeust[kBRPlayerCacheWebDownloadRangeKey];
    BRRange range;
    [rangeValue getValue:&range];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
    
    if (range.length != NSNotFound && range.length != NSNotFound) {
        NSString *rangeString = [NSString stringWithFormat:@"bytes=%lld-%lld", range.location, range.location + (range.length - 1)];
        [request setValue:rangeString forHTTPHeaderField:@"Range"];
        BRDebugLog(@"请求开始位置: %lld", (int64_t)range.location);
        BRDebugLog(@"请求长度: %lld", (int64_t)range.length);
        BRDebugLog(@"请求范围: %@", rangeString);
    }
    
    BRDebugLog(@"请求内容: %@", self.requests);
    
    NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *sharedSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    self.dataTask = [sharedSession dataTaskWithRequest:request];
    
    [self.dataTask resume];
}

- (void)cancel {
    [self.dataTask cancel];
}

- (void)commonInitRequestWithURL:(NSURL *)URL {
    
    if (!URL) {
        BRErrorLog(@"URL is nil, ignore URL request");
        return;
    }
    
    int64_t localFileAvailableLength = self.localFile.availableLength;
    int64_t start = self.range.location;
    int64_t end = self.range.location + self.range.length;
    
    BRRange range = BRMakeRange(0, 0);
    while (start < end) {
        
        //当新的下载开始位置在已下载的之前
        if (localFileAvailableLength > start) {
            range = BRMakeRange(start, localFileAvailableLength - start);
            start = localFileAvailableLength;
        }
        else {
            range = BRMakeRange(start, end - start);
            start = end;
        }
        
        [self.requests addObject:@{
                                   kBRPlayerCacheWebDownloadURLKey: URL,
                                   kBRPlayerCacheWebDownloadRangeKey: [NSValue value:&range withObjCType:@encode(BRRange)]
                                   
                                   }];
    }
}

- (void)commonInitWithURL:(NSURL *)URL {
    [self commonInitRequestWithURL:URL];
}

- (NSString *)headerFieldWithKey:(NSString *)key allHeaderFields:(NSDictionary<NSString *, NSString *> *)headerFields {
    NSString *value = headerFields[key];
    if (![value isEqualToString:@""] && value) {
        return value;
    }
    return nil;
}

#pragma mark - NSURLSession delegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    
    if (self.delegagte && [self.delegagte respondsToSelector:@selector(download:didReceiveResponse:)]) {
        [self.delegagte download:self didReceiveResponse:httpResponse];
    }
    else if (self.delegagte && [self.delegagte respondsToSelector:@selector(download:didReceiveResponse:contentLength:totalLength:contentType:contentRange:)]) {
        
        NSDictionary<NSString *, NSString *> *allHeaderFields = httpResponse.allHeaderFields;
        NSString *contentRange = [self headerFieldWithKey:@"Content-Range" allHeaderFields:allHeaderFields];
        NSString *contentType = [self headerFieldWithKey:@"Content-Type" allHeaderFields:allHeaderFields];
        NSArray<NSString *> *contentRanges = [contentRange componentsSeparatedByString:@"/"];
        NSArray<NSString *> *numbersContentRanges = [[contentRanges.firstObject componentsSeparatedByString:@" "].lastObject componentsSeparatedByString:@"-"];
        
        int64_t contentLength = httpResponse.expectedContentLength;
        int64_t fileLength = [httpResponse br_fileTotalLength];
        self.localFile.totalLength = fileLength;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegagte download:self didReceiveResponse:httpResponse contentLength:contentLength totalLength:fileLength  contentType:contentType contentRange:BRMakeRange(numbersContentRanges.firstObject.longLongValue, numbersContentRanges.lastObject.longLongValue)];
        });
    }
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    [self.localFile appendData:data offset:self.range.location];
    self.availableLength += data.length;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegagte && [self.delegagte respondsToSelector:@selector(download:didReceiveData:)]) {
            [self.delegagte download:self didReceiveData:data];
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegagte && [self.delegagte respondsToSelector:@selector(download:didCompleteWithError:)]) {
            [self.delegagte download:self didCompleteWithError:error];
        }
        
        if (error) {
            BRErrorLog(@"请求出错:%@", error);
            return;
        }
        
        [self.localFile closeFileIfComplete];
        [self resumeNextRequestIfComplete];
    });
}

#pragma mark - private

- (void)resumeNextRequestIfComplete {
    NSDictionary<NSString *, NSObject *> *reqeust = self.requests.firstObject;
    NSValue *rangeValue = (NSValue *)reqeust[kBRPlayerCacheWebDownloadRangeKey];
    BRRange range;
    [rangeValue getValue:&range];
    if (self.availableLength >= range.length) {
        self.availableLength = 0;
        
        NSInteger requestsCount = self.requests.count;
        if (requestsCount > 0) {
            [self.requests removeObjectAtIndex:0];
            requestsCount--;
            if (requestsCount == 0) {
                if (self.loadingRequests.count > 0) {
                    [self.loadingRequests removeObjectAtIndex:0];
                }
                return;
            }
        }
        
        [self start];
    }
}

#pragma mark - getter

- (NSArray<NSString *> *)allHeaderKeys {
    return @[@"Content-Range"];
}

- (NSMutableArray<AVAssetResourceLoadingRequest *> *)loadingRequests {
    if (!_loadingRequests) {
        _loadingRequests = @[].mutableCopy;
    }
    return _loadingRequests;
}

- (NSMutableArray<NSDictionary<NSString *, NSObject *> *> *)requests {
    if (!_requests) {
        _requests = @[].mutableCopy;
    }
    return _requests;
}

@end

#pragma mark - BRPlayerCacheVideo

@interface BRPlayerCacheMediaFile: BRPlayerCacheFile<BRLargeFileDownloadDelegate>

@property (nonatomic, strong) BRLargeFileDownload *fileDownload;

@end

@implementation BRPlayerCacheMediaFile

- (void)addResourceLoadingRequest:(AVAssetResourceLoadingRequest *)request {
    self.fileDownload = [[BRLargeFileDownload alloc] initWithResourceLoadingRequest:request];
    self.fileDownload.delegate = self;
    [self.fileDownload start];
    
    self.identify = [request.request.URL.absoluteString md5String];
}

- (void)fillContentInformationRequest {
    AVAssetResourceLoadingContentInformationRequest *contentInformationRequest = self.fileDownload.loadingRequest.contentInformationRequest;
    if (self.contentType && !contentInformationRequest.contentType) {
        
        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(self.contentType), NULL);
        contentInformationRequest.byteRangeAccessSupported = YES;
        contentInformationRequest.contentType = CFBridgingRelease(contentType);
        contentInformationRequest.contentLength = self.totalLength;
    }
}

- (BOOL)isEqual:(BRPlayerCacheMediaFile *)other
{
    if (other == self) {
        return YES;
    }
    else {
        return [self.identify isEqualToString:other.identify];
    }
}

- (NSUInteger)hash
{
    return self.identify.hash ^ self.totalLength;
}

#pragma mark - public

- (BOOL)isNewFileWithURL:(NSURL *)URL {
    NSString *identify = [URL.absoluteString md5String];
    return ![self.identify isEqualToString:identify];
}

- (void)cancelWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    
}

#pragma mark - BRPlayerViewDownloadDelegate

- (void)download:(BRPlayerCacheWebDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response contentLength:(int64_t)length totalLength:(int64_t)totalLength contentType:(NSString *)type contentRange:(BRRange)range {
    
    BRDebugLog(@"文件总长度: %lld", totalLength);
    self.totalLength = totalLength;
    self.contentType = type;
    
    [self fillContentInformationRequest];
}

- (void)download:(BRPlayerCacheWebDownload *)download didReceiveData:(NSData *)data {
    BRDebugLog(@"接受到数据长度: %ld", data.length);
    BRDebugLog(@"接受到数据长度: %@", download.loadingRequest.dataRequest);
    [download.loadingRequest.dataRequest respondWithData:data];
    
    self.availableLength += data.length;
}

- (void)download:(BRPlayerCacheWebDownload *)download didCompleteWithError:(NSError *)error {
    BRDebugLog(@"下载完成，一共下载长度: %ld, 文件下载完成: %@", download.availableLength, self.dowloadComplete ? @"是" : @"否");
    
    self.dowloadComplete = (self.availableLength >= self.totalLength);
    if (download.availableLength >= download.range.length) {
        [download.loadingRequest finishLoading];
    }
}

@end

#pragma mark - BRPlayerCache

@interface BRPlayerCache () <AVAssetResourceLoaderDelegate>

@property (nonatomic, strong) NSMutableArray<BRPlayerCacheMediaFile *> *mediaFiles;
//Are dealing with mediaFile
@property (nonatomic, strong) BRPlayerCacheMediaFile *mediaFile;
@property (nonatomic, strong) NSMutableArray<AVAssetResourceLoadingRequest *> *assetResourceLoadingRequests;

@property (nonatomic, strong) AVAssetResourceLoadingRequest *loadingAssetResourceLoadingRequest;

@end

@implementation BRPlayerCache

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mediaFiles = @[].mutableCopy;
        
        _assetResourceLoadingRequests = @[].mutableCopy;
    }
    return self;
}

- (NSURL *)composeFakeVideoURL {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:BRVideoPlayerURLScheme] resolvingAgainstBaseURL:NO];
    components.scheme = BRVideoPlayerURL;
    return [components URL];
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    if (loadingRequest) {
        BRDebugLog(@"========================接受到新的请求========================");
        BOOL isNewFileURL = [self.mediaFile isNewFileWithURL:loadingRequest.request.URL];
        if (!self.mediaFile || isNewFileURL) {
            BRDebugLog(@"新下载文件");
            
            BRPlayerCacheMediaFile *mediaFile = BRPlayerCacheMediaFile.new;
            [mediaFile addResourceLoadingRequest:loadingRequest];
            [self.mediaFiles addObject:mediaFile];
            
            self.mediaFile = mediaFile;
        }
        else {
            BRDebugLog(@"接着下载文件");
            [self.mediaFile addResourceLoadingRequest:loadingRequest];
        }
    }
    
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self.mediaFile cancelWithLoadingRequest:loadingRequest];
}

@end
