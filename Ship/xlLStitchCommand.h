//
//  XLLStitchCommand.h
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XLLCommandProtocol.h"
#import "XLLReceiverProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface xlLStitchCommand : NSObject <XLLCommandProtocol>

- (instancetype)initWithReceiver:(id<XLLReceiverProtocol>)receiver frontVideoURL:(NSURL *)fURL videoURL:(NSURL *)URL;
- (instancetype)initWithFrontVideoURL:(NSURL *)fURL videoURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
