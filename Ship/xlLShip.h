//
//  XLLShip.h
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface xlLShip : NSObject

//+ (instancetype)defaultShip;

- (instancetype)initWithVideoURL:(NSURL *)URL;
- (instancetype)initWithImages:(NSArray<UIImage *> *)images;

- (xlLShip *)stitchFrontVideoWithURL:(NSURL *)fURL videoURL:(NSURL *)URL;
- (xlLShip *)compositeVideoWithImages:(NSArray<UIImage * > *)images;
- (xlLShip *)clipViedoWithURL:(NSURL *)URL fromSecond:(NSTimeInterval)fromSecond toSecond:(NSTimeInterval)toSecond;

- (void)executeExport;

@end

NS_ASSUME_NONNULL_END
