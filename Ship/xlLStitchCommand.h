//
//  XLLStitchCommand.h
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "xlLCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface xlLStitchCommand : xlLCommand

- (instancetype)initWithCommand:(id<XLLCommandProtocol>)command videoURL:(NSURL *)URL;


@end

NS_ASSUME_NONNULL_END
