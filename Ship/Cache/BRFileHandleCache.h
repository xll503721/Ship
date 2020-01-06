//
//  BRFileHandleCache.h
//  Ship
//
//  Created by xlL on 2020/1/6.
//  Copyright © 2020 xlL. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (BRFileHandleCache)

- (NSString *)md5String;

@end

@interface NSString (BRFileHandleCache)

- (NSString *)md5String;

@end

@interface BRFileHandleCache : NSObject <NSCoding>

@property (nonatomic, assign) int64_t totalLength;
@property (nonatomic, assign) int64_t availableLength;

/// load BRFileHandleCache with URL, under Caches Directory
/// @param URL req URL
+ (instancetype)cacheWithURL:(NSURL *)URL;

/// custom directoryName under Caches Directory
/// @param URL req URL
/// @param directoryName under Caches Directory
+ (instancetype)cacheWithURL:(NSURL *)URL directoryNameUnderCaches:(NSString *)directoryName;

/// archiving
- (BOOL)saveToKeyedUnarchiver;


/// append data to fileHandle, start with offset
/// @param data new data
/// @param offset start index
- (void)appendData:(NSData *)data offset:(int64_t)offset;
- (void)appendData:(NSData *)data;

- (BOOL)checkComplete;
- (void)closeFileIfComplete;

@end

NS_ASSUME_NONNULL_END
