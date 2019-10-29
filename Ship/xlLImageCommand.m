//
//  xlLImageCommand.m
//  Ship
//
//  Created by xlL on 2019/10/29.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "xlLImageCommand.h"

@interface xlLImageCommand ()

@property (nonatomic, strong) NSArray<UIImage *> *images;

@end

@implementation xlLImageCommand

- (instancetype)initWithReceiver:(id<XLLReceiverProtocol>)receiver images:(NSArray<UIImage *> *)images
{
    self = [super initWithReceiver:receiver];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithImages:(NSArray<UIImage *> *)images {
    self = [super init];
    if (self) {
        self.images = images;
    }
    return self;
}

- (void)execute:(AVAsset *)asset {
    
    NSError *error = nil;
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:[NSURL URLWithString:@""] fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error) {
        return;
    }
    
    AVAssetWriterInput *assetWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:@{}];
    if (![assetWriter canAddInput:assetWriterInput]) {
        return;
    }
    
    [assetWriter addInput:assetWriterInput];
    [assetWriter startWriting];
    [assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    NSInteger imageCount = self.images.count;
    NSInteger videoFrameCount = 0;
    
    dispatch_queue_t queue = dispatch_queue_create("", nil);
    [assetWriterInput requestMediaDataWhenReadyOnQueue:queue usingBlock:^{
        while ([assetWriterInput isReadyForMoreMediaData]) {
            if (videoFrameCount > imageCount) {
                [assetWriterInput markAsFinished];
                break;
            }
            
            [assetWriterInput appendSampleBuffer:nil];
        }
    }];
    
    AVAsset *imageVideoAsset = [AVAsset assetWithURL:[NSURL URLWithString:@""]];
    
}



@end
