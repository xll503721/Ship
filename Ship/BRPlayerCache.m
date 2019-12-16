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

static NSString *BRVideoPlayerURLScheme = @"com.long.xlL.BRKit";
static NSString *BRVideoPlayerURL = @"www.long.com";

typedef struct _BRRange {
    int64_t location;
    int64_t length;
} BRRange;

NS_INLINE BRRange BRMakeRange(int64_t loc, int64_t len) {
    BRRange r;
    r.location = loc;
    r.length = len;
    return r;
}

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

#pragma mark - BRPlayerCacheLocalFile

@interface BRPlayerCacheLocalFile : NSObject

@property (nonatomic, strong) NSFileHandle *writeFileHandle;
@property (nonatomic, strong) NSFileHandle *readFileHandle;

@property (nonatomic, strong) NSURL *URL;

@property (nonatomic, assign) int64_t totalLength;

@end

@implementation BRPlayerCacheLocalFile

- (instancetype)initWithURL:(NSURL *)URL
{
    self = [super init];
    if (self) {
        _URL = URL;
        
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

@end

#pragma mark - BRPlayerViewDownload

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

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) AVAssetResourceLoadingRequest *assetResourceLoadingRequest;

@property (nonatomic, strong) BRPlayerCacheLocalFile *localFile;

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
        _assetResourceLoadingRequest = request;
        _range = [self fetchRequestRangeWithRequest:request];
        
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:request.request.URL resolvingAgainstBaseURL:NO];
        components.scheme = @"http";
        
        [self commonInitWithURL:[components URL]];
        
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

- (void)reloadWithResourceLoadingRequest:(AVAssetResourceLoadingRequest *)request {
    _assetResourceLoadingRequest = request;
    _range = [self fetchRequestRangeWithRequest:request];
    
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
    
    if (length == -1) {
        
    }
    
    return BRMakeRange(location, length);
}

- (void)start {
    [self.dataTask resume];
}

- (void)cancel {
    [self.dataTask cancel];
}

- (void)commonInitWithURL:(NSURL *)URL {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
    if (self.range.length != NSNotFound && self.range.length != NSNotFound) {
        NSString *rangeString = [NSString stringWithFormat:@"bytes=%lld-%lld", (int64_t)self.range.location, (int64_t)self.range.location + (int64_t)(_range.length - 1)];
        [request setValue:rangeString forHTTPHeaderField:@"Range"];
        BRDebugLog(@"请求开始位置: %lld", (int64_t)self.range.location);
        BRDebugLog(@"请求长度: %lld", (int64_t)_range.length);
        BRDebugLog(@"请求范围: %@", rangeString);
    }
    NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *sharedSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    self.dataTask = [sharedSession dataTaskWithRequest:request];
    
    self.data = [NSMutableData data];
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
    
    [self.localFile.writeFileHandle seekToEndOfFile];
    [self.localFile.writeFileHandle writeData:data];
    [self.data appendData:data];
    
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
    });
}

#pragma mark - getter

- (NSArray<NSString *> *)allHeaderKeys {
    return @[@"Content-Range"];
}

@end

#pragma mark - BRPlayerCacheVideo

@interface BRPlayerCacheMediaFile: NSObject<BRPlayerViewDownloadDelegate>

@property (nonatomic, strong) BRPlayerCacheWebDownload *webDownload;
@property (nonatomic, assign) int64_t totalLength;
@property (nonatomic, strong) NSString *contentType;
@property (nonatomic, assign) NSInteger availableLength;
@property (nonatomic, assign) BOOL saveFull;

@property (nonatomic, strong) NSString *identify;

@end

@implementation BRPlayerCacheMediaFile

- (instancetype)initWithResourceLoadingRequest:(AVAssetResourceLoadingRequest *)request
{
    self = [super init];
    if (self) {
        [self commonInitWithResourceLoadingRequest:request];
    }
    return self;
}

- (void)commonInitWithResourceLoadingRequest:(AVAssetResourceLoadingRequest *)request {
    self.webDownload = [[BRPlayerCacheWebDownload alloc] initWithResourceLoadingRequest:request];
    self.webDownload.delegagte = self;
    [self.webDownload start];
    
    self.identify = [request.request.URL.absoluteString md5String];
}

- (void)reloadWithResourceLoadingRequest:(AVAssetResourceLoadingRequest *)request {
    [self.webDownload cancel];
    [self.webDownload reloadWithResourceLoadingRequest:request];
    [self.webDownload start];
}

- (void)fullfillContentInfo {
    AVAssetResourceLoadingContentInformationRequest *contentInformationRequest = self.webDownload.assetResourceLoadingRequest.contentInformationRequest;
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

#pragma mark - BRPlayerViewDownloadDelegate

- (void)download:(BRPlayerCacheWebDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response contentLength:(int64_t)length totalLength:(int64_t)totalLength contentType:(NSString *)type contentRange:(BRRange)range {
    
    self.totalLength = totalLength;
    self.contentType = type;
    
    [self fullfillContentInfo];
}

- (void)download:(BRPlayerCacheWebDownload *)download didReceiveData:(NSData *)data {
    BRDebugLog(@"接受到数据长度: %ld", data.length);
    [download.assetResourceLoadingRequest.dataRequest respondWithData:data];
}

- (void)download:(BRPlayerCacheWebDownload *)download didCompleteWithError:(NSError *)error {
    BRDebugLog(@"下载完成，一共下载长度: %ld", download.data.length);
    [download.assetResourceLoadingRequest finishLoading];
}

#pragma mark - setter

- (void)setTotalLength:(NSInteger)totalLength {
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
        BRPlayerCacheMediaFile *mediaFile = [[BRPlayerCacheMediaFile alloc] initWithResourceLoadingRequest:loadingRequest];
        NSInteger index = [self.mediaFiles indexOfObject:mediaFile];
        if (index == NSNotFound) {
            BRDebugLog(@"新的下载文件");
            [self.mediaFiles addObject:mediaFile];
            self.mediaFile = mediaFile;
            return YES;
        }
        
        BRDebugLog(@"接着下载文件");
        BRPlayerCacheMediaFile *requestingMediaFile = [self.mediaFiles objectAtIndex:index];
        [requestingMediaFile reloadWithResourceLoadingRequest:loadingRequest];
    }
    
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
//    BRPlayerCacheMediaFile *mediaFile = [[BRPlayerCacheMediaFile alloc] initWithResourceLoadingRequest:loadingRequest];
//    NSInteger index = [self.mediaFiles indexOfObject:mediaFile];
//    if (index != NSNotFound) {
//        [self.mediaFiles removeObjectAtIndex:index];
//    }
}

@end
