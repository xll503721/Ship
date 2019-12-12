//
//  BRPlayerCache.h
//  Ship
//
//  Created by xlL on 2019/12/9.
//  Copyright © 2019 xlL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

NS_ASSUME_NONNULL_BEGIN

@interface BRPlayerCache : NSObject<AVAssetResourceLoaderDelegate>

- (NSURL *)composeFakeVideoURL;

@end

NS_ASSUME_NONNULL_END
