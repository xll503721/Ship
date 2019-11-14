//
//  xlLWaterMarkCommand.h
//  Ship
//
//  Created by xlL on 2019/10/30.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "BRCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface BRWaterMarkCommand : BRCommand

- (instancetype)initWithCommand:(id<BRCommandProtocol>)command image:(UIImage *)image;
- (instancetype)initWithCommand:(id<BRCommandProtocol>)command string:(NSString *)string;
- (instancetype)initWithCommand:(id<BRCommandProtocol>)command waterMarkLayer:(CALayer *)layer;

@end

NS_ASSUME_NONNULL_END
