//
//  XLLStitchCommand.m
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "xlLStitchCommand.h"

@interface xlLStitchCommand ()

@property (nonatomic, strong) id<XLLReceiverProtocol> receiver;
@property (nonatomic, strong) AVAsset *asset;

@end

@implementation xlLStitchCommand

- (instancetype)initWithReceiver:(id<XLLReceiverProtocol>)receiver frontVideoURL:(NSURL *)fURL videoURL:(NSURL *)URL
{
    self = [super init];
    if (self) {
        self.receiver = receiver;
    }
    return self;
}

- (instancetype)initWithFrontVideoURL:(NSURL *)fURL videoURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        self.asset = [AVAsset assetWithURL:URL];
    }
    return self;
}

- (instancetype)initWithCommand:(id<XLLCommandProtocol>)command videoURL:(NSURL *)URL {
    self = [super initWithCommand:command];
    if (self) {
        self.asset = [AVAsset assetWithURL:URL];
    }
    return self;
}

- (void)execute:(AVMutableComposition *)asset {
    [super execute:asset];
    
    if ([asset tracksWithMediaType:AVMediaTypeVideo].count > 0 && [self.asset tracksWithMediaType:AVMediaTypeVideo].count > 0) {
        AVAssetTrack *assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        AVAssetTrack *assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        
        AVAssetTrack *addAssetVideoTrack = [self.asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        AVAssetTrack *addAssetAudioTrack = [self.asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        
        NSError *error = nil;
        AVMutableCompositionTrack *mutableVideoCompositionTrack = [asset mutableTrackCompatibleWithTrack:assetVideoTrack];
        [mutableVideoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:addAssetVideoTrack atTime:[asset duration] error:&error];
        if (error) {
            NSLog(@"");
        }
        
        AVMutableCompositionTrack *mutableAudioCompositionTrack = [asset mutableTrackCompatibleWithTrack:assetAudioTrack];
        [mutableAudioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:addAssetAudioTrack atTime:[asset duration] error:&error];
        if (error) {
            NSLog(@"");
        }
    }
}

@end
