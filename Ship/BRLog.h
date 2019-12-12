//
//  BRLog.h
//  Ship
//
//  Created by xlL on 2019/12/9.
//  Copyright © 2019 xlL. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __OBJC__

#define BR_LOG_MACRO(logFlag, frmt, ...) \
                                        [BRLog logWithFlag:logFlag\
                                                      file:__FILE__ \
                                                  function:__FUNCTION__ \
                                                      line:__LINE__ \
                                                    format:(frmt), ##__VA_ARGS__]


#define BR_LOG_MAYBE(logFlag, frmt, ...) BR_LOG_MACRO(logFlag, frmt, ##__VA_ARGS__)

#if DEBUG

/**
 * Log debug log.
 */
#define BRDebugLog(frmt, ...) BR_LOG_MAYBE(BRLogLevelDebug, frmt, ##__VA_ARGS__)

/**
 * Log debug and warning log.
 */
#define BRWarningLog(frmt, ...) BR_LOG_MAYBE(BRLogLevelWarning, frmt, ##__VA_ARGS__)

/**
 * Log debug, warning and error log.
 */
#define BRErrorLog(frmt, ...) BR_LOG_MAYBE(BRLogLevelError, frmt, ##__VA_ARGS__)

#else

#define BRDebugLog(frmt, ...)
#define BRWarningLog(frmt, ...)
#define BRErrorLog(frmt, ...)
#endif

#endif

typedef NS_ENUM(NSUInteger, BRLogLevel) {
    // no log output.
    BRLogLevelNone = 0,

    // output debug, warning and error log.
    BRLogLevelError = 1,

    // output debug and warning log.
    BRLogLevelWarning = 2,

    // output debug log.
    BRLogLevelDebug = 3,
};

@interface BRLog : NSObject

+ (void)logWithFlag:(BRLogLevel)logLevel file:(const char *)file function:(const char *)function line:(NSUInteger)line format:(NSString *)format, ...;

@end

NS_ASSUME_NONNULL_END
