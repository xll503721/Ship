//
//  xlLCommand.h
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XLLCommandProtocol.h"
#import "XLLReceiverProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface xlLCommand : NSObject <XLLCommandProtocol>

- (instancetype)initWithReceiver:(id<XLLReceiverProtocol>)receiver;
- (instancetype)initWithVideoURL:(NSURL *)URL;

- (AVMutableComposition *)recompositionVideoWithAsset:(AVAsset *)asset;

@end

NS_ASSUME_NONNULL_END
