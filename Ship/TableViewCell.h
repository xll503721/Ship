//
//  TableViewCell.h
//  Ship
//
//  Created by xlL on 2019/11/5.
//  Copyright © 2019 xlL. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BRPlayerView;

NS_ASSUME_NONNULL_BEGIN

@interface TableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet BRPlayerView *playerView;

@end

NS_ASSUME_NONNULL_END
