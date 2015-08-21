//
//  XLog.h
//  eContact
//
//  Created by zouxu on 14/6/14.
//  Copyright (c) 2014 zouxu. All rights reserved.
//


#import <Foundation/Foundation.h>

//CONF
#define XCODE_COLORS_ENABLE 0
#define LOG_LEVEL_DEF LOG_LEVEL_VERBOSE
#define LOG_ASYNC_ALL   NO
//#define LOG_WRITE_FILE  

#define LOG_FLAG_ERROR    (1 << 0)  // 0...00001
#define LOG_FLAG_WARN     (1 << 1)  // 0...00010
#define LOG_FLAG_INFO     (1 << 2)  // 0...00100
#define LOG_FLAG_DEBUG    (1 << 3)  // 0...01000
#define LOG_FLAG_VERBOSE  (1 << 4)  // 0...10000

#define LOG_LEVEL_OFF     0
#define LOG_LEVEL_ERROR   (LOG_FLAG_ERROR)                                                                      // 0...00001
#define LOG_LEVEL_WARN    (LOG_FLAG_ERROR | LOG_FLAG_WARN)                                                      // 0...00011
#define LOG_LEVEL_INFO    (LOG_FLAG_ERROR | LOG_FLAG_WARN | LOG_FLAG_INFO)                                      // 0...00111
#define LOG_LEVEL_DEBUG   (LOG_FLAG_ERROR | LOG_FLAG_WARN | LOG_FLAG_INFO | LOG_FLAG_DEBUG)                     // 0...01111
#define LOG_LEVEL_VERBOSE (LOG_FLAG_ERROR | LOG_FLAG_WARN | LOG_FLAG_INFO | LOG_FLAG_DEBUG | LOG_FLAG_VERBOSE)  // 0...11111

#define LOG_LOGFILE_ERROR   ( LOG_FLAG_ERROR | LOG_FLAG_WARN  | LOG_FLAG_INFO | LOG_FLAG_DEBUG | LOG_FLAG_VERBOSE)
#define LOG_LOGFILE_WARN    ( LOG_FLAG_WARN  | LOG_FLAG_INFO  | LOG_FLAG_DEBUG | LOG_FLAG_VERBOSE)
#define LOG_LOGFILE_INFO    ( LOG_FLAG_INFO  | LOG_FLAG_DEBUG | LOG_FLAG_VERBOSE)
#define LOG_LOGFILE_DEBUG   ( LOG_FLAG_DEBUG | LOG_FLAG_VERBOSE)
#define LOG_LOGFILE_VERBOSE ( LOG_FLAG_VERBOSE)

#define LOG_ASYNC_ERROR   LOG_ASYNC_ALL
#define LOG_ASYNC_WARN    LOG_ASYNC_ALL
#define LOG_ASYNC_INFO    LOG_ASYNC_ALL
#define LOG_ASYNC_DEBUG   LOG_ASYNC_ALL
#define LOG_ASYNC_VERBOSE LOG_ASYNC_ALL

#ifdef DEBUG
#define LOG_MACRO(isAsynchronous, lvl, flg, ctx, fnct, frmt, ...) \
[LOG log:isAsynchronous                                           \
level:lvl                                                         \
flag:flg                                                          \
context:ctx                                                       \
file:__FILE__                                                     \
function:fnct                                                     \
line:__LINE__                                                     \
format:(frmt), ##__VA_ARGS__]
#else
#define LOG_MACRO(isAsynchronous, lvl, flg, ctx, fnct, frmt, ...) {}
#endif

#define LOG_MAYBE(async, lvl, flg, ctx, fnct, frmt, ...) \
do { if(lvl & flg) LOG_MACRO(async, lvl, flg, ctx, fnct, frmt, ##__VA_ARGS__); } while(0)

#define LOG_OBJC_MAYBE(async, lvl, flg,ctx, frmt, ...) \
LOG_MAYBE(async, lvl, flg, ctx, sel_getName(_cmd), frmt, ##__VA_ARGS__)

#define LOG_C_MAYBE(async, lvl, flg, ctx,frmt, ...) \
LOG_MAYBE(async, lvl, flg, ctx, __FUNCTION__, frmt, ##__VA_ARGS__)

#define XLogError(frmt, ...)   LOG_OBJC_MAYBE(LOG_ASYNC_ERROR,   LOG_LEVEL_DEF, LOG_LOGFILE_ERROR,   0, frmt, ##__VA_ARGS__)
#define XLogWarn(frmt, ...)    LOG_OBJC_MAYBE(LOG_ASYNC_WARN,    LOG_LEVEL_DEF, LOG_LOGFILE_WARN,    0, frmt, ##__VA_ARGS__)
#define XLogInfo(frmt, ...)    LOG_OBJC_MAYBE(LOG_ASYNC_INFO,    LOG_LEVEL_DEF, LOG_LOGFILE_INFO,    0, frmt, ##__VA_ARGS__)
#define XLogDebug(frmt, ...)   LOG_OBJC_MAYBE(LOG_ASYNC_DEBUG,   LOG_LEVEL_DEF, LOG_LOGFILE_DEBUG,   0, frmt, ##__VA_ARGS__)
#define XLogVerbose(frmt, ...) LOG_OBJC_MAYBE(LOG_ASYNC_VERBOSE, LOG_LEVEL_DEF, LOG_LOGFILE_VERBOSE, 0, frmt, ##__VA_ARGS__)

#define XLogCError(frmt, ...)   LOG_C_MAYBE(LOG_ASYNC_ERROR,   LOG_LEVEL_DEF, LOG_LOGFILE_ERROR,   0, frmt, ##__VA_ARGS__)
#define XLogCWarn(frmt, ...)    LOG_C_MAYBE(LOG_ASYNC_WARN,    LOG_LEVEL_DEF, LOG_LOGFILE_WARN,    0, frmt, ##__VA_ARGS__)
#define XLogCInfo(frmt, ...)    LOG_C_MAYBE(LOG_ASYNC_INFO,    LOG_LEVEL_DEF, LOG_LOGFILE_INFO,    0, frmt, ##__VA_ARGS__)
#define XLogCDebug(frmt, ...)   LOG_C_MAYBE(LOG_ASYNC_DEBUG,   LOG_LEVEL_DEF, LOG_LOGFILE_DEBUG,   0, frmt, ##__VA_ARGS__)
#define XLogCVerbose(frmt, ...) LOG_C_MAYBE(LOG_ASYNC_VERBOSE, LOG_LEVEL_DEF, LOG_LOGFILE_VERBOSE, 0, frmt, ##__VA_ARGS__)

#define XLog(frmt, ...)         LOG_C_MAYBE(LOG_ASYNC_INFO,    LOG_LEVEL_DEF, LOG_FLAG_INFO,    0, frmt, ##__VA_ARGS__)

@interface LOG : NSObject
+ (void)log:(BOOL)synchronous
      level:(int)level
       flag:(int)flag
    context:(int)context
       file:(const char *)file
   function:(const char *)function
       line:(int)line
     format:(NSString *)format, ... ;//__attribute__ ((format (__NSString__, 9, 10)));
@end










#if 0
char *xcode_colors = getenv(XCODE_COLORS);
if (xcode_colors && (strcmp(xcode_colors, "YES") == 0))
{
    // XcodeColors is installed and enabled!
}
#endif













