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
    
    
//    {
//        xlLCommand *command = [[xlLCommand alloc] initWithVideoURL:[NSURL URLWithString:@""]];
//        xlLStitchCommand *stitchCommand = [[xlLStitchCommand alloc] initWithVideoURL:[NSURL URLWithString:@""]];
//        [stitchCommand addInternalCommand:command];
//
//        [stitchCommand execute:stitchCommand.mutableComposition];
//    }
    
    {
        xlLCommand *command = xlLCommand.new;
        xlLImageCommand *imageCommand = [[xlLImageCommand alloc] initWithCommand:command images:@[]];
        xlLClipCommand *clipCommand = [[xlLClipCommand alloc] initWithCommand:imageCommand fromSecond:0 toSecond:0];
        xlLStitchCommand *stitchCommand = [[xlLStitchCommand alloc] initWithCommand:clipCommand videoURL:[NSURL URLWithString:@""]];
        
        [stitchCommand processWithCompleteHandle:^(AVAsset * _Nonnull asset) {
            
        }];
        
    }
    
}


@end
