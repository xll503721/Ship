//
//  ViewController.m
//  Ship
//
//  Created by xlL on 2019/10/28.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "ViewController.h"
#import "xlLShip.h"

@interface ViewController ()

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
    
    AVAsset *asset = [AVAsset assetWithURL:[NSURL URLWithString:@""]];
    
    AVAssetTrack *assetTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    
    NSError *error;
    AVAssetReader *assetReader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    AVAssetReaderTrackOutput *assetReaderTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetTrack outputSettings:@{}];
    
    [assetReader addOutput:assetReaderTrackOutput];
    [assetReader startReading];
    
    
}


@end
