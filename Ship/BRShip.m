//
//  XLLShip.m
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "BRShip.h"
#import "BRShipMacro.h"

@interface BRShip () <NSCopying,NSMutableCopying>

@property (nonatomic, strong) NSMutableArray<id<BRCommandProtocol>> *commands;

@end

@implementation BRShip

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
        
        BRCommand *command = [[BRCommand alloc] initWithVideoURL:URL];
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

- (BRShip *)stitchWithFrontVideoURL:(NSURL *)fURL videoURL:(NSURL *)URL {
//    xlLStitchCommand *command = [[xlLStitchCommand alloc] initWithFrontVideoURL:fURL videoURL:URL];
//    [self.commands addObject:command];
    return self;
}

- (BRShip *)compositeVideoWithImages:(NSArray<UIImage * > *)images {
    
    return self;
}

- (BRShip *)clipViedoWithURL:(NSURL *)URL fromSecond:(NSTimeInterval)fromSecond toSecond:(NSTimeInterval)toSecond {
//    xlLClipCommand *command = [[xlLClipCommand alloc] initWithVideoURL:URL fromSecond:fromSecond toSecond:toSecond];
//    [self.commands addObject:command];
    return self;
}

#pragma mark - action

- (void)executeExport {
//    [self.commands enumerateObjectsUsingBlock:^(id<BRCommandProtocol>  _Nonnull command, NSUInteger idx, BOOL * _Nonnull stop) {
//        [command execute:command.mutableComposition videoComposition:command.videoComposition audioMix:command.audioMix];
//    }];
    
    [self.commands.firstObject execute:self.commands.firstObject.mutableComposition videoComposition:nil audioMix:nil];
}

@end
