//
//  XLLShip.m
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "xlLShip.h"
#import "XLLShipMacro.h"

@interface xlLShip () <NSCopying,NSMutableCopying>

@property (nonatomic, strong) NSMutableArray<id<XLLCommandProtocol>> *commands;

@end

@implementation xlLShip

- (instancetype)init
{
    self = [super init];
    if (self) {
        _commands = @[].mutableCopy;
        
        
    }
    return self;
}

- (instancetype)initWithVideoURL:(NSURL *)URL
{
    self = [super init];
    if (self) {
        _commands = @[].mutableCopy;
        
        xlLCommand *command = [[xlLCommand alloc] initWithVideoURL:URL];
        [_commands addObject:command];
    }
    return self;
}

//static XLLShip *defaultShip = nil;
//
//+ (instancetype)defaultShip {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        defaultShip = [[self alloc] init];
//    });
//    return defaultShip;
//}
//
//+ (id)allocWithZone:(struct _NSZone *)zone{
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        defaultShip = [super allocWithZone:zone];
//    });
//    return defaultShip;
//}
//
//- (nonnull id)copyWithZone:(nullable NSZone *)zone {
//    return defaultShip;
//}
//
//- (nonnull id)mutableCopyWithZone:(nullable NSZone *)zone {
//    return defaultShip;
//}

#pragma mark - edit

- (xlLShip *)stitchWithFrontVideoURL:(NSURL *)fURL videoURL:(NSURL *)URL {
    xlLStitchCommand *command = [[xlLStitchCommand alloc] initWithFrontVideoURL:fURL videoURL:URL];
    [self.commands addObject:command];
    return self;
}

- (xlLShip *)compositeVideoWithImages:(NSArray<UIImage * > *)images {
    
    return self;
}

- (xlLShip *)clipViedoWithURL:(NSURL *)URL fromSecond:(NSTimeInterval)fromSecond toSecond:(NSTimeInterval)toSecond {
//    xlLClipCommand *command = [[xlLClipCommand alloc] initWithVideoURL:URL fromSecond:fromSecond toSecond:toSecond];
//    [self.commands addObject:command];
    return self;
}

#pragma mark - action

- (void)executeExport {
    [self.commands enumerateObjectsUsingBlock:^(id<XLLCommandProtocol>  _Nonnull command, NSUInteger idx, BOOL * _Nonnull stop) {
        [command execute:command.mutableComposition];
    }];
    
    [self.commands.firstObject execute:nil];
}

@end
