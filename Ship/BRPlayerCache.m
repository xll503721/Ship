//
//  BRPlayerCache.m
//  Ship
//
//  Created by xlL on 2019/12/9.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "BRPlayerCache.h"

static NSString *BRVideoPlayerURLScheme = @"com.long.xlL.BRKit";
static NSString *BRVideoPlayerURL = @"www.long.com";

typedef struct _BRRange {
    long long location;
    long long length;
} BRRange;

NS_INLINE BRRange BRMakeRange(long long loc, long long len) {
    BRRange r;
    r.location = loc;
    r.length = len;
    return r;
}

@interface NSHTTPURLResponse (BRPlayerCache)

@end

@implementation NSHTTPURLResponse (BRPlayerCache)

- (long long)br_fileLength {
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

#pragma mark - BRPlayerViewDownload

@interface BRPlayerViewDownload : NSObject

@end

@protocol BRPlayerViewDownloadDelegate <NSObject>

- (void)download:(BRPlayerViewDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response;
- (void)download:(BRPlayerViewDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response contentLength:(int64_t)length totalLength:(int64_t)totalLength contentType:(NSString *)type contentRange:(BRRange)range;
- (void)download:(BRPlayerViewDownload *)download didReceiveData:(NSData *)data;
- (void)download:(BRPlayerViewDownload *)download didCompleteWithError:(NSError *)error;

@end

@interface BRPlayerViewDownload () <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSArray<NSString *> *allHeaderKeys;
@property (nonatomic, weak) id<BRPlayerViewDownloadDelegate> delegagte;
@property (nonatomic, assign) NSRange range;

@property (nonatomic, strong) NSFileHandle *writeFileHandle;
@property (nonatomic, strong) NSFileHandle *readFileHandle;
@property (nonatomic, strong) NSMutableData *data;

@property (nonatomic, strong) AVAssetResourceLoadingRequest *assetResourceLoadingRequest;

@end

@implementation BRPlayerViewDownload

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *tempPath =  [document stringByAppendingPathComponent:@"temp.mp4"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
            [[NSFileManager defaultManager] createFileAtPath:tempPath contents:nil attributes:nil];
            
        }
        else {
            [[NSFileManager defaultManager] createFileAtPath:tempPath contents:nil attributes:nil];
        }
        
        self.writeFileHandle = [NSFileHandle fileHandleForWritingAtPath:tempPath];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL
{
    self = [super init];
    if (self) {
        [self commonInitWithURL:URL];
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
        
        [self commonInitWithURL:[NSURL URLWithString:@"http://www.w3school.com.cn/example/html5/mov_bbb.mp4"]];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL reqeustRange:(NSRange)range
{
    self = [super init];
    if (self) {
        
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *tempPath =  [document stringByAppendingPathComponent:@"temp.mp4"];
        self.writeFileHandle = [NSFileHandle fileHandleForWritingAtPath:tempPath];
        
        [self commonInitWithURL:URL];
        self.range = range;
    }
    return self;
}

- (NSRange)fetchRequestRangeWithRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSUInteger location = 0;
    NSUInteger length = 0;

    if ([loadingRequest.dataRequest respondsToSelector:@selector(requestsAllDataToEndOfResource)] && loadingRequest.dataRequest.requestsAllDataToEndOfResource) {
        location = (NSUInteger)loadingRequest.dataRequest.requestedOffset;
        length = NSUIntegerMax;
    }
    else {
        location = (NSUInteger)loadingRequest.dataRequest.requestedOffset;
        length = loadingRequest.dataRequest.requestedLength;
    }
    
    if(loadingRequest.dataRequest.currentOffset > 0){
        location = (NSUInteger)loadingRequest.dataRequest.currentOffset;
    }
    
    return NSMakeRange(location, length);
}

- (void)start {
    [self.dataTask resume];
}

- (void)commonInitWithURL:(NSURL *)URL {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
    if (self.range.length != NSNotFound && self.range.length != NSNotFound) {
        [request setValue:[NSString stringWithFormat:@"bytes=%ld-%ld", self.range.location, self.range.length] forHTTPHeaderField:@"Range"];
    }
    NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *sharedSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    self.dataTask = [sharedSession dataTaskWithRequest:request];
    
    self.data = [NSMutableData data];
}

- (void)startWithURL:(NSURL *)URL reqeustRange:(NSRange)range {
    self.range = range;
    [self commonInitWithURL:URL];
    [self.dataTask resume];
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
        int64_t fileLength = [httpResponse br_fileLength];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegagte download:self didReceiveResponse:httpResponse contentLength:contentLength totalLength:fileLength  contentType:contentType contentRange:BRMakeRange(numbersContentRanges.firstObject.longLongValue, numbersContentRanges.lastObject.longLongValue)];
        });
    }
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    [self.writeFileHandle seekToEndOfFile];
    [self.writeFileHandle writeData:data];
    
    [self.data appendData:data];
    
    if (self.delegagte && [self.delegagte respondsToSelector:@selector(download:didReceiveData:)]) {
        [self.delegagte download:self didReceiveData:data];
    }
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

@interface BRPlayerCache () <AVAssetResourceLoaderDelegate>

@property (nonatomic, strong) NSMutableArray<BRPlayerViewDownload *> *downloads;
@property (nonatomic, strong) NSMutableArray<AVAssetResourceLoadingRequest *> *assetResourceLoadingRequests;

@property (nonatomic, strong) AVAssetResourceLoadingRequest *loadingAssetResourceLoadingRequest;

@end

@implementation BRPlayerCache

- (instancetype)init
{
    self = [super init];
    if (self) {
        _downloads = @[].mutableCopy;
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
    NSLog(@"shouldWaitForLoadingOfRequestedResource");
    if (loadingRequest) {

        BRPlayerViewDownload *download = [[BRPlayerViewDownload alloc] initWithResourceLoadingRequest:loadingRequest];
        download.delegagte = self;
        [self.downloads addObject:download];

        [download start];
        
//        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.w3school.com.cn/example/html5/mov_bbb.mp4"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
//
//        NSRange range = [self fetchRequestRangeWithRequest:loadingRequest];
//        [request setValue:[NSString stringWithFormat:@"bytes=%ld-%ld", range.location, range.length] forHTTPHeaderField:@"Range"];
//
//        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
//        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//
//            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
//
//            CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(@"video/mp4"), NULL);
//            loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
//            loadingRequest.contentInformationRequest.contentType = CFBridgingRelease(contentType);
//            loadingRequest.contentInformationRequest.contentLength = [httpResponse br_fileLength];
//
//            [loadingRequest.dataRequest respondWithData:data];
//            [loadingRequest finishLoading];
//        }];
//
//        [task resume];
    }
    
    return YES;
}

- (NSRange)fetchRequestRangeWithRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSUInteger location = 0;
    NSUInteger length = 0;
    
    if ([loadingRequest.dataRequest respondsToSelector:@selector(requestsAllDataToEndOfResource)] && loadingRequest.dataRequest.requestsAllDataToEndOfResource) {
        location = (NSUInteger)loadingRequest.dataRequest.requestedOffset;
        length = NSUIntegerMax;
    }
    else {
        location = (NSUInteger)loadingRequest.dataRequest.requestedOffset;
        length = loadingRequest.dataRequest.requestedLength;
    }
    
    if(loadingRequest.dataRequest.currentOffset > 0){
        location = (NSUInteger)loadingRequest.dataRequest.currentOffset;
    }
    
    return NSMakeRange(location, length);
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    
}

- (void)download:(BRPlayerViewDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response contentLength:(int64_t)length totalLength:(int64_t)totalLength contentType:(NSString *)type contentRange:(BRRange)range {
    
    AVAssetResourceLoadingContentInformationRequest *contentInformationRequest = download.assetResourceLoadingRequest.contentInformationRequest;
    
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(type), NULL);
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = totalLength;
}

- (void)download:(BRPlayerViewDownload *)download didCompleteWithError:(NSError *)error {
    
//    [self.loadingAssetResourceLoadingRequest.dataRequest respondWithData:download.data];
    [download.assetResourceLoadingRequest finishLoading];
}

@end
