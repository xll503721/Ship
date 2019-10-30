//
//  xlLClipCommand.m
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "xlLClipCommand.h"

@interface xlLClipCommand ()

@end

@implementation xlLClipCommand

- (instancetype)initWithReceiver:(id<XLLReceiverProtocol>)receiver fromSecond:(NSTimeInterval)fromSecond toSecond:(NSTimeInterval)toSecond
{
    self = [super initWithReceiver:receiver];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithCommand:(id<XLLCommandProtocol>)command fromSecond:(NSTimeInterval)fromSecond toSecond:(NSTimeInterval)toSecond {
    self = [super initWithCommand:command];
    if (self) {
        
    }
    return self;
}

- (void)execute:(AVMutableComposition *)asset {
    [super execute:asset];
    
    NSLog(@"%@:%@",[self class],NSStringFromSelector(_cmd));
}

@end
