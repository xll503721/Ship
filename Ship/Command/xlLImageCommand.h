//
//  xlLImageCommand.h
//  Ship
//
//  Created by xlL on 2019/10/29.
//  Copyright © 2019 xlL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "xlLCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface xlLImageCommand : xlLCommand

- (instancetype)initWithCommand:(id<XLLCommandProtocol>)command images:(NSArray<UIImage *> *)images;

@end

NS_ASSUME_NONNULL_END
