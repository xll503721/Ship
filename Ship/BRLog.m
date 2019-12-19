//
//  BRLog.m
//  Ship
//
//  Created by xlL on 2019/12/9.
//  Copyright © 2019 xlL. All rights reserved.
//

#import "BRLog.h"

NSString *BRLogMessage = nil;
NSString *BRLogThreadName = nil;
static dispatch_queue_t BRLogSyncQueue;
static BRLogLevel _logLevel;

@implementation BRLog

+ (void)initialize {
    _logLevel = BRLogLevelDebug;
    BRLogSyncQueue = dispatch_queue_create("com.long.log.sync.queue.www", DISPATCH_QUEUE_SERIAL);
}

+ (void)logWithFlag:(BRLogLevel)logLevel
               file:(const char *)file
           function:(const char *)function
               line:(NSUInteger)line
             format:(NSString *)format, ... {
    if (logLevel > _logLevel || !format) return;

    va_list args;
    va_start(args, format);

    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        BRLogMessage = message;
        if (BRLogMessage.length) {
            NSString *flag;
            switch (logLevel) {
                case BRLogLevelDebug:
                    flag = @"DEBUG";
                    break;

                case BRLogLevelWarning:
                    flag = @"Waring";
                    break;

                case BRLogLevelError:
                    flag = @"Error";
                    break;

                default:
                    break;
            }

            BRLogThreadName = [[NSThread currentThread] description];
            BRLogThreadName = [BRLogThreadName componentsSeparatedByString:@">"].lastObject;
            BRLogThreadName = [BRLogThreadName componentsSeparatedByString:@","].firstObject;
            BRLogThreadName = [BRLogThreadName stringByReplacingOccurrencesOfString:@"{number = " withString:@""];
            // message = [NSString stringWithFormat:@"[%@] [Thread: %@] %@ => [%@ + %ld]", flag, threadName, message, tempString, line];
            BRLogMessage = [NSString stringWithFormat:@"[%@] [BRPlayer] %s [%@]", flag, function, BRLogMessage];
            NSLog(@"%@", BRLogMessage);
        }
    });
}

@end
