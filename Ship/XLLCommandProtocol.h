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

@protocol XLLCommandProtocol <NSObject>

@property (nonatomic, readonly) id<XLLReceiverProtocol> receiver;
@property (nonatomic, readonly) id<XLLCommandProtocol> command;

@property (nonatomic, readonly) AVAssetWriter *assetWriter;
@property (nonatomic, readonly) AVAsset *asset;

- (void)execute:(AVAsset *)asset;

@end

NS_ASSUME_NONNULL_END
