//
//  xlLImageCommand.m
//  Ship
//
//  Created by xlL on 2019/10/29.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "xlLImageCommand.h"
#import "xlLStitchCommand.h"

static NSString *kxlLImageCommandVideoName = @"imageCommandVideo";

@interface xlLImageCommand ()

@property (nonatomic, strong) NSArray<UIImage *> *images;

@end

@implementation xlLImageCommand

- (instancetype)initWithReceiver:(id<XLLReceiverProtocol>)receiver images:(NSArray<UIImage *> *)images
{
    self = [super initWithReceiver:receiver];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithCommand:(id<XLLCommandProtocol>)command images:(NSArray<UIImage *> *)images {
    self = [super initWithCommand:command];
    if (self) {
        self.images = images;
    }
    return self;
}

- (void)execute:(AVMutableComposition *)asset videoComposition:(AVMutableVideoComposition * _Nullable)videoComposition audioMix:(AVMutableAudioMix * _Nullable)audioMix {
    [super execute:asset videoComposition:videoComposition audioMix:audioMix];
    
    if (!(self.images.count > 0)) {
        return;
    }
    
    //setp1: setup AVAssetWriter to save video
    NSArray<NSString *> *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSURL *cacheURL = [NSURL URLWithString:[cachePaths.firstObject stringByAppendingPathComponent:kxlLImageCommandVideoName]];
    
    NSError *error = nil;
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:cacheURL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error) {
        return;
    }
    
    NSDictionary *videoSettings = @{
        AVVideoCodecKey: AVVideoCodecTypeH264,
        AVVideoWidthKey: [NSNumber numberWithInt:320],
        AVVideoHeightKey: [NSNumber numberWithInt:480],
    };
    
    //setp2: setup AVAssetWriterInput
    AVAssetWriterInput *assetWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    if (![assetWriter canAddInput:assetWriterInput]) {
        return;
    }
    
    [assetWriter addInput:assetWriterInput];
    [assetWriter startWriting];
    [assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB],kCVPixelBufferPixelFormatTypeKey,nil];
    
    //setp3: setup AVAssetWriterInputPixelBufferAdaptor to append PixelBuffer
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    NSInteger imageCount = self.images.count;
    __block NSInteger videoFrameCount = 0;
    
    //setp4: start to make image to video
    dispatch_queue_t queue = dispatch_queue_create("com.long.xlLImageCommand", nil);
    [assetWriterInput requestMediaDataWhenReadyOnQueue:queue usingBlock:^{
        while ([assetWriterInput isReadyForMoreMediaData]) {
            videoFrameCount++;
            if (videoFrameCount > imageCount) {
                [assetWriterInput markAsFinished];
                [assetWriter finishWritingWithCompletionHandler:^{
                    xlLStitchCommand *stitchCommand = [[xlLStitchCommand alloc] initWithVideoURL:cacheURL];
//                    [stitchCommand execute:self.mutableComposition];
                }];
                break;
            }
            
            CVPixelBufferRef pixelBufferRef = [self pixelBufferFromImage:self.images[videoFrameCount]];
            [adaptor appendPixelBuffer:pixelBufferRef withPresentationTime:CMTimeMake(videoFrameCount, 10)];
        }
    }];
}

- (CVPixelBufferRef)pixelBufferFromImage:(UIImage *)image {
    
    CGImageRef cgImage = image.CGImage;
    
    NSDictionary *options = @{
                              (NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]
                              };
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(cgImage);
    CGFloat frameHeight = CGImageGetHeight(cgImage);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0, 0, frameWidth, frameHeight), cgImage);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}



@end
