//
//  xlLClipCommand.h
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BRCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface BRClipCommand : BRCommand

- (instancetype)initWithCommand:(id<BRCommandProtocol>)command fromSecond:(NSTimeInterval)fromSecond toSecond:(NSTimeInterval)toSecond;

@end

NS_ASSUME_NONNULL_END
