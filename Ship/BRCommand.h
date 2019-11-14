//
//  BRCommand.h
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BRCommandProtocol.h"
#import "XLLReceiverProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BRCommand : NSObject <BRCommandProtocol>

- (instancetype)initWithReceiver:(id<XLLReceiverProtocol>)receiver;
- (instancetype)initWithVideoURL:(NSURL *)URL;

- (void)recompositionVideoWithAsset:(AVAsset *)asset;

- (void)exportMediaToURL:(NSURL *)URL completeHandle:(dispatch_block_t)complete;

@end

NS_ASSUME_NONNULL_END
