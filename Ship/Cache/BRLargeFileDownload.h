//
//  BRLargeFileDownload.h
//  Ship
//
//  Created by xlL on 2020/1/6.
//  Copyright © 2020 xlL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BRLargeFileDownload;

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

@protocol BRLargeFileDownloadDelegate <NSObject>

@optional
- (void)download:(BRLargeFileDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response;
- (void)download:(BRLargeFileDownload *)download didReceiveResponse:(NSHTTPURLResponse *)response contentLength:(int64_t)length totalLength:(int64_t)totalLength contentType:(NSString *)type contentRange:(BRRange)range;
- (void)download:(BRLargeFileDownload *)download didReceiveData:(NSData *)data;
- (void)download:(BRLargeFileDownload *)download didCompleteWithError:(NSError *)error;

@end

@interface BRLargeFileDownload : NSObject

@property (nonatomic, weak) id<BRLargeFileDownloadDelegate> delegate;
@property (nonatomic, strong) AVAssetResourceLoadingRequest *loadingRequest;

- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)initWithResourceLoadingRequest:(AVAssetResourceLoadingRequest *)request;

- (void)start;

@end

NS_ASSUME_NONNULL_END
