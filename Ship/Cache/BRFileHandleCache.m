//
//  BRFileHandleCache.m
//  Ship
//
//  Created by xlL on 2020/1/6.
//  Copyright © 2020 xlL. All rights reserved.
//

#import "BRFileHandleCache.h"
#import <CommonCrypto/CommonCrypto.h>

static NSString *kBRFileHandleCachePath = @"BRShip";
static NSString *kBRFileHandleCacheMetadataExtension = @".data";

@interface NSData (BRFileHandleCache)

- (NSString *)md5String;

@end

@implementation NSData (BRFileHandleCache)

- (NSString *)md5String {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(self.bytes, (CC_LONG)self.length, result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end

@interface NSString (BRFileHandleCache)

- (NSString *)md5String;

@end

@implementation NSString (BRFileHandleCache)

- (NSString *)md5String {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] md5String];
}

@end

@interface BRFileHandleCache ()

@property (nonatomic, strong) NSFileHandle *writeFileHandle;
@property (nonatomic, strong) NSFileHandle *readFileHandle;

@property (nonatomic, strong) NSString *contentType;
@property (nonatomic, strong) NSString *identify;
@property (nonatomic, assign) BOOL dowloadComplete;
@property (nonatomic, strong) NSURL *URL;

@end

@implementation BRFileHandleCache

+ (instancetype)cacheWithURL:(NSURL *)URL directoryNameUnderCaches:(NSString *)directoryName {
    
    NSString *fullPath = [[BRFileHandleCache cachePath] stringByAppendingPathComponent:[BRFileHandleCache fileNameWithURL:URL]];
    id cache = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
    
    if (!cache) {
        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *fullPath = [cachesPath stringByAppendingPathComponent:kBRFileHandleCachePath];
        [BRFileHandleCache createDirectoryWithPath:fullPath];
        
        BRFileHandleCache *cache = BRFileHandleCache.new;
        cache.URL = URL;
        return cache;
    }
    return cache;
}

+ (instancetype)cacheWithURL:(NSURL *)URL {
    return [BRFileHandleCache cacheWithURL:URL directoryNameUnderCaches:kBRFileHandleCachePath];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.contentType forKey:NSStringFromSelector(@selector(contentType))];
    [coder encodeObject:self.URL forKey:NSStringFromSelector(@selector(URL))];
    [coder encodeInt64:self.totalLength forKey:NSStringFromSelector(@selector(totalLength))];
    [coder encodeInt64:self.availableLength forKey:NSStringFromSelector(@selector(availableLength))];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        if ([coder containsValueForKey:NSStringFromSelector(@selector(contentType))]) {
            self.contentType = [coder decodeObjectForKey:NSStringFromSelector(@selector(contentType))];
        }
        
        if ([coder containsValueForKey:NSStringFromSelector(@selector(URL))]) {
            self.URL = [coder decodeObjectForKey:NSStringFromSelector(@selector(URL))];
        }
        
        if ([coder containsValueForKey:NSStringFromSelector(@selector(contentType))]) {
            self.totalLength = [coder decodeInt64ForKey:NSStringFromSelector(@selector(totalLength))];
        }
        
        if ([coder containsValueForKey:NSStringFromSelector(@selector(contentType))]) {
            self.availableLength = [coder decodeInt64ForKey:NSStringFromSelector(@selector(availableLength))];
        }
    }
    return self;
}

+ (NSString *)cachePath {
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fullPath = [cachesPath stringByAppendingPathComponent:kBRFileHandleCachePath];
    return fullPath;
}

+ (BOOL)createDirectoryWithPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL succeed = YES;
    BOOL existed = [fileManager fileExistsAtPath:path];
    if (!existed) {
        NSError *error;
        if (![fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
            succeed = NO;
            NSLog(@"creat Directory Failed:%@",[error localizedDescription]);
        }
    }
    return succeed;
}

+ (NSString *)fileNameWithURL:(NSURL *)URL {
    return [NSString stringWithFormat:@"%@%@", [URL.absoluteString md5String], kBRFileHandleCacheMetadataExtension];
}

#pragma mark - public

- (BOOL)saveToKeyedUnarchiverWithPath:(NSString *)path {
    BOOL succeed = [NSKeyedArchiver archiveRootObject:self toFile:[path stringByAppendingPathComponent:[BRFileHandleCache fileNameWithURL:self.URL]]];
    return succeed;
}

- (BOOL)saveToKeyedUnarchiver {
    return [self saveToKeyedUnarchiverWithPath:[BRFileHandleCache cachePath]];
}

- (void)appendData:(NSData *)data offset:(int64_t)offset {
    
    int64_t availableLength = self.writeFileHandle.availableData.length;
    if ([self checkComplete] || offset <= availableLength) {
        return;
    }
    
    [self.writeFileHandle seekToFileOffset:offset];
    [self.writeFileHandle writeData:data];
    [self.writeFileHandle synchronizeFile];
    
    self.availableLength += data.length;
}

- (void)appendData:(NSData *)data {
    [self appendData:data offset:self.availableLength];
}

- (BOOL)checkComplete {
    return self.availableLength >=  self.totalLength;
}

- (void)closeFileIfComplete {
    if (![self checkComplete]) {
        return;
    }
    
    [self.writeFileHandle closeFile];
}

@end
