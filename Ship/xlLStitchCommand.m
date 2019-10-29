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
        
    }
    return self;
}

- (void)execute:(AVAsset *)asset {
    
}

@end
