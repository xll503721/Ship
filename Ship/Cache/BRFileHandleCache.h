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

@property (nonatomic, assign) int64_t fileLength;
@property (nonatomic, assign) int64_t availableLength;
@property (nonatomic, strong) NSString *contentType;

/// Load BRFileHandleCache with URL, under the Caches directory
/// @param URL req URL
+ (instancetype)cacheWithURL:(NSURL *)URL;

/// Custom directory name under Caches directory
/// @param URL req URL
/// @param directoryName under Caches Directory
+ (instancetype)cacheWithURL:(NSURL *)URL directoryNameUnderCaches:(NSString *)directoryName;

/// Archiving
- (BOOL)saveToKeyedUnarchiver;

/// Append data to fileHandle, start with offset
/// @param data new data
/// @param offset start index
- (void)appendData:(NSData *)data offset:(int64_t)offset;
- (void)appendData:(NSData *)data;

- (NSData *)readDataWithLength:(int64_t)length offset:(int64_t)offset;
- (NSData *)readDataWithLength:(int64_t)length;

/// Check that the document is complete
- (BOOL)completed;
- (void)closeIfCompleted;

- (void)clearCache;

@end

NS_ASSUME_NONNULL_END
