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

#pragma mark - BRPlayerCacheMediaFile

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

- (void)download:(BRLargeFileDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response contentLength:(int64_t)length totalLength:(int64_t)totalLength contentType:(NSString *)type contentRange:(BRRange)range {
    
    BRDebugLog(@"文件总长度: %lld", totalLength);
    self.totalLength = totalLength;
    self.contentType = type;
    
    [self fillContentInformationRequest];
}

- (void)download:(BRLargeFileDownload *)download didReceiveData:(NSData *)data {
    BRDebugLog(@"接受到数据长度: %ld", data.length);
    BRDebugLog(@"接受到数据长度: %@", download.loadingRequest.dataRequest);
    
    [download.loadingRequest.dataRequest respondWithData:data];
}

- (void)download:(BRLargeFileDownload *)download didCompleteWithError:(NSError *)error {
    BRDebugLog(@"下载完成，一共下载长度: %ld, 文件下载完成: %@", download.availableLength, self.dowloadComplete ? @"是" : @"否");
    
    [download.loadingRequest finishLoading];
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
