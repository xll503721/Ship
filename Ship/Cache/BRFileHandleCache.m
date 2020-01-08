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

@implementation NSString (BRFileHandleCache)

- (NSString *)md5String {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] md5String];
}

@end

@interface BRFileHandleCache ()

@property (nonatomic, strong) NSFileHandle *writeFileHandle;
@property (nonatomic, strong) NSFileHandle *readFileHandle;

@property (nonatomic, assign) int64_t readOffset;
@property (nonatomic, assign) int64_t writeOffset;

@property (nonatomic, strong) NSString *identify;
@property (nonatomic, assign) BOOL dowloadComplete;
@property (nonatomic, strong) NSURL *URL;

@end

@implementation BRFileHandleCache

#pragma mark - class method

+ (instancetype)cacheWithURL:(NSURL *)URL directoryNameUnderCaches:(NSString *)directoryName {
    
    //create directory
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fullCachesPath = [cachesPath stringByAppendingPathComponent:kBRFileHandleCachePath];
    [BRFileHandleCache createDirectoryWithPath:fullCachesPath];
    
    NSString *fullFilePath = [[BRFileHandleCache cacheWithRootDirectory:directoryName] stringByAppendingPathComponent:[BRFileHandleCache metadataFileNameWithURL:URL]];
    id cache = [NSKeyedUnarchiver unarchiveObjectWithFile:fullFilePath];
    
    if (!cache) {
        BRFileHandleCache *cache = BRFileHandleCache.new;
        cache.URL = URL;
        return cache;
    }
    return cache;
}

+ (instancetype)cacheWithURL:(NSURL *)URL {
    return [BRFileHandleCache cacheWithURL:URL directoryNameUnderCaches:kBRFileHandleCachePath];
}

+ (NSString *)cacheWithRootDirectory:(NSString *)directory {
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fullPath = [cachesPath stringByAppendingPathComponent:directory];
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
            NSLog(@"create Directory Failed:%@",[error localizedDescription]);
        }
    }
    return succeed;
}

+ (NSString *)metadataFileNameWithURL:(NSURL *)URL {
    return [NSString stringWithFormat:@"%@%@", [URL.absoluteString md5String], kBRFileHandleCacheMetadataExtension];
}

+ (NSString *)fileNameWithURL:(NSURL *)URL {
    return [URL.absoluteString md5String];
}

#pragma mark - init method

- (instancetype)initWithURL:(NSURL *)URL
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.contentType forKey:NSStringFromSelector(@selector(contentType))];
    [coder encodeObject:self.URL forKey:NSStringFromSelector(@selector(URL))];
    [coder encodeInt64:self.fileLength forKey:NSStringFromSelector(@selector(fileLength))];
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
            self.fileLength = [coder decodeInt64ForKey:NSStringFromSelector(@selector(fileLength))];
        }
        
        if ([coder containsValueForKey:NSStringFromSelector(@selector(contentType))]) {
            self.availableLength = [coder decodeInt64ForKey:NSStringFromSelector(@selector(availableLength))];
        }
        
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    NSString *path = [BRFileHandleCache cacheWithRootDirectory:kBRFileHandleCachePath];
    NSString *fullPath = [path stringByAppendingPathComponent:[BRFileHandleCache fileNameWithURL:self.URL]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:fullPath]) {
        [fileManager createFileAtPath:fullPath contents:nil attributes:nil];
    }
    
    self.writeFileHandle = [NSFileHandle fileHandleForWritingAtPath:fullPath];
    self.readFileHandle = [NSFileHandle fileHandleForReadingAtPath:fullPath];
}


#pragma mark - public

- (BOOL)saveToKeyedUnarchiverWithPath:(NSString *)path {
    BOOL succeed = [NSKeyedArchiver archiveRootObject:self toFile:[path stringByAppendingPathComponent:[BRFileHandleCache metadataFileNameWithURL:self.URL]]];
    return succeed;
}

- (BOOL)saveToKeyedUnarchiver {
    return [self saveToKeyedUnarchiverWithPath:[BRFileHandleCache cacheWithRootDirectory:kBRFileHandleCachePath]];
}

- (void)appendData:(NSData *)data offset:(int64_t)offset {
    
    if ([self completed]) {
        return;
    }
    
    [self.writeFileHandle seekToFileOffset:offset];
    [self.writeFileHandle writeData:data];
    [self.writeFileHandle synchronizeFile];

}

- (void)appendData:(NSData *)data {
    [self appendData:data offset:self.availableLength];
}

- (NSData *)readDataWithLength:(int64_t)length offset:(int64_t)offset {
    [self.readFileHandle seekToFileOffset:offset];
    NSData *data = [self.readFileHandle readDataOfLength:length];
    return data;
}

- (NSData *)readDataWithLength:(int64_t)length {
    NSData *data = [self readDataWithLength:length offset:self.readOffset];
    if (data.length > 0) {
        self.readOffset += length;
    }
    return data;
}

- (BOOL)completed {
    return (self.availableLength >= self.fileLength) && (self.fileLength != 0);
}

- (int64_t)availableLength {
    int64_t offset = self.readFileHandle.offsetInFile;
    [self.readFileHandle seekToEndOfFile];
    
    int64_t availableLength = self.readFileHandle.offsetInFile;
    [self.readFileHandle seekToFileOffset:offset];
    
    return availableLength;
}

- (void)close {
    [self.readFileHandle closeFile];
    [self.writeFileHandle closeFile];
}

- (void)clearCache {
    NSString *path = [BRFileHandleCache cacheWithRootDirectory:kBRFileHandleCachePath];
    NSString *fullFilePath = [path stringByAppendingPathComponent:[BRFileHandleCache fileNameWithURL:self.URL]];
    NSString *fullMetadataPath = [path stringByAppendingPathComponent:[BRFileHandleCache metadataFileNameWithURL:self.URL]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager removeItemAtPath:fullFilePath error:&error];
    [fileManager removeItemAtPath:fullMetadataPath error:&error];
    if (!error) {
        NSLog(@"");
    }
}

@end
