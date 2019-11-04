//
//  XLLCommandProtocol.h
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "XLLReceiverProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ProcessComplete)(AVAsset *asset, AVMutableVideoComposition * _Nullable videoComposition, AVMutableAudioMix * _Nullable audioMix);

@protocol XLLCommandProtocol <NSObject>

@property (nonatomic, readonly) id<XLLReceiverProtocol> receiver;
@property (nonatomic, readonly) id<XLLCommandProtocol> command;

@property (nonatomic, readonly) AVMutableComposition *mutableComposition;
@property (nonatomic, readonly) AVMutableVideoComposition *videoComposition;
@property (nonatomic, readonly) AVMutableAudioMix *audioMix;

- (void)execute:(AVMutableComposition *)asset videoComposition:(AVMutableVideoComposition * _Nullable)videoComposition audioMix:(AVMutableAudioMix * _Nullable)audioMix;

- (instancetype)initWithCommand:(id<XLLCommandProtocol>)command;
- (void)processWithCompleteHandle:(ProcessComplete)handler;

@end

NS_ASSUME_NONNULL_END
