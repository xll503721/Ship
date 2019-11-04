//
//  ViewController.m
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "ViewController.h"
#import "xlLShip.h"
#import "xlLCommand.h"
#import "xlLStitchCommand.h"
#import "xlLImageCommand.h"
#import "xlLClipCommand.h"
#import "xlLPlayerView.h"

#import "APLCompositionDebugView.h"

@interface ViewController ()

@property (nonatomic, strong) xlLPlayerView *playerView;
@property (nonatomic, strong) APLCompositionDebugView *compositionDebugView;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    xlLShip *ship = xlLShip.new;
//    [ship stitchFrontVideoWithURL:[NSURL URLWithString:@""] videoURL:[NSURL URLWithString:@""]];
//    [ship compositeVideoWithImages:@[]];
//    [ship clipViedoWithURL:[NSURL URLWithString:@""] fromSecond:0 toSecond:0];
//    [ship executeExport];
    
    
    {
        xlLCommand *command = [[xlLCommand alloc] initWithVideoURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sample_clip1" ofType:@"m4v"]]];
        xlLStitchCommand *stitchCommand = [[xlLStitchCommand alloc] initWithCommand:command videoURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sample_clip2" ofType:@"mov"]]];
        [stitchCommand processWithCompleteHandle:^(AVAsset * _Nonnull asset, AVMutableVideoComposition * _Nullable videoComposition, AVMutableAudioMix * _Nullable audioMix) {
            
        }];
        
        self.playerView = [[xlLPlayerView alloc] initWithAsset:stitchCommand.mutableComposition videoComposition:stitchCommand.videoComposition audioMix:stitchCommand.audioMix];
        self.playerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height / 2);
        self.playerView.backgroundColor = [UIColor lightGrayColor];
        [self.view addSubview:self.playerView];

        [self.playerView play];
        
        self.compositionDebugView = APLCompositionDebugView.new;
        [self.compositionDebugView synchronizeToComposition:[stitchCommand.mutableComposition copy] videoComposition:nil audioMix:nil];
        [self.view addSubview:self.compositionDebugView];

//        [stitchCommand processWithCompleteHandle:^(AVAsset * _Nonnull asset) {
//
//            self.playerView = [[xlLPlayerView alloc] initWithAsset:asset];
//            self.playerView.frame = self.view.bounds;
//            self.playerView.backgroundColor = [UIColor redColor];
//            [self.view addSubview:self.playerView];
//
//            [self.playerView play];
//        }];
    }
    
    
    
//    {
//        xlLCommand *command = xlLCommand.new;
//        xlLImageCommand *imageCommand = [[xlLImageCommand alloc] initWithCommand:command images:@[]];
//        xlLClipCommand *clipCommand = [[xlLClipCommand alloc] initWithCommand:imageCommand fromSecond:0 toSecond:0];
//        xlLStitchCommand *stitchCommand = [[xlLStitchCommand alloc] initWithCommand:clipCommand videoURL:[NSURL URLWithString:@""]];
//        
//        [stitchCommand processWithCompleteHandle:^(AVAsset * _Nonnull asset) {
//            
//        }];
//        
//    }
    
    
//    [NSURL URLWithString:@"http://m.oss.icam.chat/12595555/eceb3c1c5581dfc6a7a669c7295a3ed2.mp4"]
//    AVURLAsset *asset1 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sample_clip1" ofType:@"m4v"]]];
//    self.playerView = [[xlLPlayerView alloc] initWithAsset:asset1];
//    self.playerView.frame = self.view.bounds;
//    self.playerView.backgroundColor = [UIColor redColor];
//    [self.view addSubview:self.playerView];
//
//    [self.playerView play];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.compositionDebugView.frame = CGRectMake(0, self.view.bounds.size.height / 2, self.view.bounds.size.width, self.view.bounds.size.height);
}


@end
