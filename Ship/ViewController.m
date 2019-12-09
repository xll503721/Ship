//
//  ViewController.m
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "ViewController.h"
#import "BRShip.h"
#import "BRCommand.h"
#import "BRStitchCommand.h"
#import "BRImageCommand.h"
#import "BRClipCommand.h"
#import "BRPlayerView.h"

#import "APLCompositionDebugView.h"

#import "TableViewCell.h"

@interface ViewController ()<UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, BRPlayerViewDeleate>

@property (nonatomic, strong) BRPlayerView *playerView;
@property (nonatomic, strong) BRPlayerView *playerView2;
@property (nonatomic, strong) APLCompositionDebugView *compositionDebugView;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
//    {
//        BRCommand *command = [[BRCommand alloc] initWithVideoURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sample_clip1" ofType:@"m4v"]]];
//        xlLStitchCommand *stitchCommand = [[xlLStitchCommand alloc] initWithCommand:command videoURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sample_clip2" ofType:@"mov"]]];
//        [stitchCommand processWithCompleteHandle:^(AVAsset * _Nonnull asset, AVMutableVideoComposition * _Nullable videoComposition, AVMutableAudioMix * _Nullable audioMix) {
//
//        }];
//
//        self.playerView = [[xlLPlayerView alloc] initWithAsset:stitchCommand.mutableComposition videoComposition:stitchCommand.videoComposition audioMix:stitchCommand.audioMix];
//        self.playerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height / 2);
//        self.playerView.backgroundColor = [UIColor lightGrayColor];
//        [self.view addSubview:self.playerView];
//
//        [self.playerView play];
//
//        self.compositionDebugView = APLCompositionDebugView.new;
//        [self.compositionDebugView synchronizeToComposition:[stitchCommand.mutableComposition copy] videoComposition:nil audioMix:nil];
//        [self.view addSubview:self.compositionDebugView];
//
////        [stitchCommand processWithCompleteHandle:^(AVAsset * _Nonnull asset) {
////
////            self.playerView = [[xlLPlayerView alloc] initWithAsset:asset];
////            self.playerView.frame = self.view.bounds;
////            self.playerView.backgroundColor = [UIColor redColor];
////            [self.view addSubview:self.playerView];
////
////            [self.playerView play];
////        }];
//    }
    
//    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
//    self.scrollView.backgroundColor = [UIColor redColor];
//    self.scrollView.delegate = self;
//    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height * 2);
//    self.scrollView.pagingEnabled = YES;
//    [self.view addSubview:self.scrollView];
//    
//    self.playerView = [[xlLPlayerView alloc] initWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sample_clip1" ofType:@"m4v"]]];
//    self.playerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
//    self.playerView.backgroundColor = [UIColor yellowColor];
//    self.playerView.loopPlayCount = 10;
//    [self.scrollView addSubview:self.playerView];
//    [self.playerView autoLoadWithScrollView:self.scrollView];
//    
//    self.playerView2 = [[xlLPlayerView alloc] initWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sample_clip1" ofType:@"m4v"]]];
//    self.playerView2.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height);
//    self.playerView2.backgroundColor = [UIColor blueColor];
//    self.playerView2.loopPlayCount = 10;
//    [self.scrollView addSubview:self.playerView2];
//    [self.playerView2 autoLoadWithScrollView:self.scrollView];
    
    
//    [[self.view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.playerView = [[BRPlayerView alloc] initWithURL:[NSURL URLWithString:@"http://www.w3school.com.cn/example/html5/mov_bbb.mp4"]];
    self.playerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
//    self.playerView.enablePlayWhileDownload = YES;
    self.playerView.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:self.playerView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.compositionDebugView.frame = CGRectMake(0, self.view.bounds.size.height / 2, self.view.bounds.size.width, self.view.bounds.size.height);
    self.scrollView.frame = self.view.bounds;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableViewCell"];
//    cell.playerView.URL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sample_clip1" ofType:@"m4v"]];
    cell.playerView.delegate = self;
//    [cell.playerView scrollInRect:CGRectMake(0, 300, tableView.bounds.size.width, 300) scrollView:tableView];
//    [cell.playerView scrollInCenterBaseLineWithScrollView:tableView];
    cell.playerView.loopPlayCount = 10;
    
    return cell;
}

#pragma mark - xlLPlayerView

- (void)scrollInType:(BRScrollType)type currentIn:(BRPlayerView *)currentInPlayerView willIn:(BRPlayerView *)willInPlayerView {
    [currentInPlayerView pause];
    [willInPlayerView play];
}


@end
