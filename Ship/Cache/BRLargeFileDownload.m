//
//  BRLargeFileDownload.m
//  Ship
//
//  Created by xlL on 2020/1/6.
//  Copyright © 2020 xlL. All rights reserved.
//

#import "BRLargeFileDownload.h"

static NSString *kBRLargeFileDownloadURLKey = @"kBRLargeFileDownloadURLKey";
static NSString *kBRLargeFileDownloadRangeKey = @"kBRLargeFileDownloadRangeKey";

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
    return [self expectedContentLength];
}

- (NSString *)br_contentType {
    return [self allHeaderFields][@"Content-Type"];
}

- (BRRange)br_range {
    NSString *range = [self allHeaderFields][@"Content-Range"];
    if (range) {
        NSArray *ranges = [range componentsSeparatedByString:@"/"];
        NSArray *rangeBE = [[ranges firstObject] componentsSeparatedByString:@" "];
        NSArray *range = [rangeBE.lastObject componentsSeparatedByString:@"-"];
        return BRMakeRange([range.firstObject longLongValue], [range.lastObject longLongValue]);
    }
    
    return BRMakeRange(NSIntegerMax, NSIntegerMax);
}

@end

#pragma mark - BRLargeFileRequest

@interface BRLargeFileRequest: NSObject

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, assign) BRRange range;

@end

@implementation BRLargeFileRequest

@end


#pragma mark - BRLargeFileDownload

@interface BRLargeFileDownload () <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSArray<NSString *> *allHeaderKeys;

@property (nonatomic, strong) NSMutableData *data;

@property (nonatomic, strong) NSMutableArray<AVAssetResourceLoadingRequest *> *loadingRequests;

@property (nonatomic, strong) BRFileHandleCache *localFile;

@property (nonatomic, strong) NSMutableArray<BRLargeFileRequest *> *largeFileRequests;

@end

@implementation BRLargeFileDownload

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
        
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:request.request.URL resolvingAgainstBaseURL:NO];
        components.scheme = @"http";
        [self commonInitWithURL:[components URL]];
        
        [self initRangeWithRequest:request];
        [self initRequestWithURL:[components URL]];
    }
    return self;
}

- (void)commonInitWithURL:(NSURL *)URL {
    self.localFile = [BRFileHandleCache cacheWithURL:URL];
}

#pragma mark - public

- (void)start {
    
    BRLargeFileRequest *reqeust = self.largeFileRequests.firstObject;
    NSURL *URL = reqeust.URL;
    BRRange range = reqeust.range;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
    
    if (range.length != NSNotFound && range.length != NSNotFound) {
        NSString *rangeString = [NSString stringWithFormat:@"bytes=%lld-%lld", range.location, range.location + (range.length - 1)];
        [request setValue:rangeString forHTTPHeaderField:@"Range"];
        NSLog(@"请求开始位置: %lld", (int64_t)range.location);
        NSLog(@"请求长度: %lld", (int64_t)range.length);
        NSLog(@"请求范围: %@", rangeString);
    }
    
    NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *sharedSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    self.dataTask = [sharedSession dataTaskWithRequest:request];
    
    [self.dataTask resume];
}

#pragma mark - NSURLSession delegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(download:didReceiveResponse:)]) {
        [self.delegate download:self didReceiveResponse:httpResponse];
    }
    else if (self.delegate && [self.delegate respondsToSelector:@selector(download:didReceiveResponse:contentLength:totalLength:contentType:contentRange:)]) {
        
        int64_t contentLength = httpResponse.expectedContentLength;
        int64_t fileLength = [httpResponse br_fileTotalLength];
        NSString *contentType = [httpResponse br_contentType];
        BRRange range = [httpResponse br_range];
        
        self.localFile.totalLength = fileLength;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate download:self didReceiveResponse:httpResponse contentLength:contentLength totalLength:fileLength  contentType:contentType contentRange:range];
        });
    }
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    [self.localFile appendData:data offset:self.range.location];
    self.availableLength += data.length;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(download:didReceiveData:)]) {
            [self.delegate download:self didReceiveData:data];
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(download:didCompleteWithError:)]) {
            [self.delegate download:self didCompleteWithError:error];
        }
        
        if (error) {
            NSLog(@"请求出错:%@", error);
            return;
        }
        
        [self.localFile closeFileIfComplete];
        [self.localFile saveToKeyedUnarchiver];
        [self resumeNextRequestIfComplete];
    });
}

#pragma mark - private

- (void)resumeNextRequestIfComplete {
    BRLargeFileRequest *reqeust = self.largeFileRequests.firstObject;
    BRRange range = reqeust.range;
    if (self.availableLength >= range.length) {
        self.availableLength = 0;
        
        NSInteger requestsCount = self.largeFileRequests.count;
        if (requestsCount > 0) {
            [self.largeFileRequests removeObjectAtIndex:0];
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

- (void)initRequestWithURL:(NSURL *)URL {
    
    if (!URL) {
        NSLog(@"URL is nil, ignore URL request");
        return;
    }
    
    int64_t localFileAvailableLength = self.localFile.availableLength;
    int64_t start = self.range.location;
    int64_t end = self.range.location + self.range.length;
    
    BRRange range = BRMakeRange(0, 0);
    BRLargeFileRequest *reqeust = BRLargeFileRequest.new;
    reqeust.URL = URL;
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
        
        reqeust.range = range;
    }
    [self.largeFileRequests addObject:reqeust];
}

- (void)initRangeWithRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    int64_t location = loadingRequest.dataRequest.requestedOffset;
    int64_t length = loadingRequest.dataRequest.requestedLength;

    if ([loadingRequest.dataRequest respondsToSelector:@selector(requestsAllDataToEndOfResource)] && loadingRequest.dataRequest.requestsAllDataToEndOfResource) {
        length = self.localFile.totalLength - location;
    }
    
    if(loadingRequest.dataRequest.currentOffset > 0){
        location = loadingRequest.dataRequest.currentOffset;
    }
    
    self.range = BRMakeRange(location, length);
    self.loadingRequest = loadingRequest;
}

#pragma mark - getter

- (NSMutableArray<BRLargeFileRequest *> * )largeFileRequests {
    if (!_largeFileRequests) {
        _largeFileRequests = @[].mutableCopy;
    }
    return _largeFileRequests;
}

@end