//
//  xlLWaterMarkCommand.h
//  Ship
//
//  Created by xlL on 2019/10/30.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "xlLCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface xlLWaterMarkCommand : xlLCommand

- (instancetype)initWithCommand:(id<XLLCommandProtocol>)command image:(UIImage *)image;
- (instancetype)initWithCommand:(id<XLLCommandProtocol>)command string:(NSString *)string;
- (instancetype)initWithCommand:(id<XLLCommandProtocol>)command waterMarkLayer:(CALayer *)layer;

@end

NS_ASSUME_NONNULL_END
