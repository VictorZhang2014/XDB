//
//  XLog.m
//  eContact
//
//  Created by zouxu on 14/6/14.
//  Copyright (c) 2014 zouxu. All rights reserved.
//

#import "LOG.h"


#define XCODE_COLORS_ESCAPE_MAC @"\033["
#define XCODE_COLORS_ESCAPE_IOS @"\xC2\xA0["

#if 0//TARGET_OS_IPHONE//pc用这个
#define XCODE_COLORS_ESCAPE  XCODE_COLORS_ESCAPE_IOS
#else
#define XCODE_COLORS_ESCAPE  XCODE_COLORS_ESCAPE_MAC
#endif


#define XCODE_COLORS_RESET_FG  XCODE_COLORS_ESCAPE @"fg;" // Clear any foreground color
#define XCODE_COLORS_RESET_BG  XCODE_COLORS_ESCAPE @"bg;" // Clear any background color
#define XCODE_COLORS_RESET     XCODE_COLORS_ESCAPE @";"   // Clear any foreground or background color


#if XCODE_COLORS_ENABLE
#define InnerLOGError(frmt, ...)   NSLog((XCODE_COLORS_ESCAPE @"fg10,10,10;"  XCODE_COLORS_ESCAPE @"bg255,33,0;"  frmt  XCODE_COLORS_RESET), ##__VA_ARGS__);
#define InnerLOGDebug(frmt, ...)   NSLog((XCODE_COLORS_ESCAPE @"fg70,30,255;" frmt XCODE_COLORS_RESET), ##__VA_ARGS__)
#define InnerLOGInfo(frmt, ...)    NSLog((XCODE_COLORS_ESCAPE @"fg63,181,255;" frmt XCODE_COLORS_RESET), ##__VA_ARGS__)
#define InnerLOGWarn(frmt, ...)    NSLog((XCODE_COLORS_ESCAPE @"fg10,10,10;"  XCODE_COLORS_ESCAPE @"bg255,131,61;"  frmt  XCODE_COLORS_RESET), ##__VA_ARGS__);
#define InnerLOGVerbose(frmt, ...) NSLog((XCODE_COLORS_ESCAPE @"fg0,0,0;" frmt XCODE_COLORS_RESET), ##__VA_ARGS__)
#else
#define InnerLOGError NSLog
#define InnerLOGDebug NSLog
#define InnerLOGInfo  NSLog
#define InnerLOGWarn  NSLog
#define InnerLOGError NSLog
#endif

static NSString* KLogDir = @"/Documents/log";


NSString *applicationName(){
    static NSString *appName;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       // appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
        appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"];//[[NSBundle mainBundle]infoDictionary]
        if (! appName)
            appName = [[NSProcessInfo processInfo] processName];
        if (! appName)
            appName = @"";
    });
    return appName;
};
NSString*getTypeStr(int flag){
    switch (flag) {
        case LOG_FLAG_ERROR:return @"ERROR";
        case LOG_FLAG_WARN:return @"WARN";
        case LOG_FLAG_INFO:return @"INFO";
        case LOG_FLAG_DEBUG:return @"DEBUG";
        case LOG_FLAG_VERBOSE:return @"VERBOSE";
    }
    return nil;
}

@interface LogInnerMsg : NSObject
@property (nonatomic, assign)BOOL asynchronous;
@property (nonatomic, assign)int level;
@property (nonatomic, assign)int flag;
@property (nonatomic, assign)int context;
@property (nonatomic, strong)NSString* file;
@property (nonatomic, strong)NSString* function;
@property (nonatomic, assign)int line;
@property (nonatomic, strong)NSString* logText;
@end
@implementation LogInnerMsg
@end
LogInnerMsg* NewLogInnerMsg(BOOL asynchronous ,int level,int flag,int context, NSString* file,
                            NSString* function,int line, NSString* logText){
    LogInnerMsg* innerMsg = [LogInnerMsg new];
    innerMsg.asynchronous = asynchronous;
    innerMsg.level=level;
    innerMsg.flag=flag;
    innerMsg.context=context;
    innerMsg.file=file;
    innerMsg.function=function;
    innerMsg.line=line;
    innerMsg.logText=logText;
    return innerMsg;
}


@implementation LOG
static NSMutableDictionary* fileHandles;
static dispatch_queue_t loggingQueue;
static dispatch_semaphore_t queueSemaphore;
+ (void)initialize{
    static dispatch_once_t XLogOnceToken;
    dispatch_once(&XLogOnceToken, ^{
        loggingQueue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT);
        queueSemaphore = dispatch_semaphore_create(0);
    });
}
+(NSString*)logFileDir{
     return [NSHomeDirectory() stringByAppendingPathComponent:KLogDir];
}
+(NSString*)logFileNameFlag:(int)flag level:(int)level{
    static NSString* appName = nil;
    static NSString* logStartTime = nil;
    if(!appName) appName = applicationName();
    if(!logStartTime){
        NSDate* data =  [NSDate date];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setDateFormat:@"yyyyMMdd_hhmmss"];
        logStartTime = [dateFormatter stringFromDate:data];
    }
    
    NSString* logFilePath = nil;
    if(level>0)
        logFilePath = [NSString stringWithFormat:@"%@_%@_%@.log",appName,logStartTime,getTypeStr(flag)];
    else
        logFilePath = [NSString stringWithFormat:@"%@_%@_%@_%d.log",appName,logStartTime,getTypeStr(flag), level];
    return logFilePath;
}
+(void)writeLogMsg:(NSString*)msgStr flag:(int)flag level:(int)level {
    //没有测试
    NSString* logDir = [self logFileDir];
    NSString* logName = [self logFileNameFlag:flag level:level];
    NSString* logFilePath = [NSString stringWithFormat:@"%@/%@", logDir, logName ];
    
    if(!fileHandles)
        fileHandles = [NSMutableDictionary new];
    NSFileHandle* logFile = fileHandles[logFilePath];
    if(!logFile){
        NSError* error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (![[NSFileManager defaultManager] fileExistsAtPath:logFilePath])
            [[NSFileManager defaultManager] createFileAtPath:logFilePath contents:nil attributes:nil];
        logFile = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
        if(!logFile)
            XLogError(@"LOG file create failed: %@", logFilePath);
        if(logFile){
            [logFile seekToEndOfFile];
            fileHandles[logFilePath] = logFile;
        }
    }
    static int exception_count = 0;
    
    NSData *logData = [msgStr dataUsingEncoding:NSUTF8StringEncoding];
    
    @try {
        [logFile writeData:logData];
    }@catch (NSException *exception){
        exception_count++;
        if (exception_count <= 10) {
            NSLog(@"DDFileLogger.logMessage: %@", exception);
            if (exception_count == 10)
                NSLog(@"DDFileLogger.logMessage: Too many exceptions -- will not log any more of them.");
        }
    }
    //    [logFile synchronizeFile];
    //    [logFile closeFile];
}

+(void)outputLogMsg:(LogInnerMsg*)msg {
    NSString* logText = [NSString stringWithFormat:@"%@:%d %@", msg.file, msg.line, msg.logText];
    if(msg.flag & LOG_FLAG_ERROR){
        InnerLOGError(@"ERRER: %@", logText);
    }else if(msg.flag & LOG_FLAG_WARN){
        InnerLOGWarn(@"WARN : %@", logText);
    }else if(msg.flag & LOG_FLAG_INFO){
        InnerLOGInfo(@"INFO : %@", logText);
    }else if(msg.flag & LOG_FLAG_DEBUG){
        InnerLOGDebug(@"DEBUG: %@", logText);
    }else if(msg.flag & LOG_FLAG_VERBOSE){
        InnerLOGInfo(@"VERBO: %@", logText);
    }
}

+(void)writeLogMsgToFile:(LogInnerMsg*)msg {
    NSString* logMsg = nil;
    if(msg.flag & LOG_FLAG_ERROR){
        logMsg = [NSString stringWithFormat:@"ERROR:%@:%d %@\n", msg.file, msg.line,msg.logText ];
    }else if(msg.flag & LOG_FLAG_WARN){
        logMsg = [NSString stringWithFormat:@"WARN :%@:%d %@\n", msg.file, msg.line,msg.logText ];
    }else if(msg.flag & LOG_FLAG_INFO){
        logMsg = [NSString stringWithFormat:@"INFO :%@:%d %@\n", msg.file, msg.line,msg.logText ];
    }else if(msg.flag & LOG_FLAG_DEBUG){
        logMsg = [NSString stringWithFormat:@"DEBUG:%@:%d %@\n", msg.file, msg.line,msg.logText ];
    }else if(msg.flag & LOG_FLAG_VERBOSE){
        logMsg = [NSString stringWithFormat:@"VERBO:%@:%d %@\n", msg.file, msg.line,msg.logText ];
    }
    //每个日志文件需要写出来
    if(msg.flag & LOG_FLAG_VERBOSE)
        [self writeLogMsg:logMsg flag:LOG_FLAG_VERBOSE level:msg.level ];
    if(msg.flag & LOG_FLAG_INFO)
        [self writeLogMsg:logMsg flag:LOG_FLAG_INFO level:msg.level ];
    if(msg.flag & LOG_FLAG_DEBUG)
        [self writeLogMsg:logMsg flag:LOG_FLAG_DEBUG level:msg.level ];
    if(msg.flag & LOG_FLAG_WARN)
        [self writeLogMsg:logMsg flag:LOG_FLAG_WARN level:msg.level ];
    if(msg.flag & LOG_FLAG_ERROR)
        [self writeLogMsg:logMsg flag:LOG_FLAG_ERROR level:msg.level ];
}

+ (void)log:(BOOL)asynchronous
      level:(int)level
       flag:(int)flag
    context:(int)context
       file:(const char *)file
   function:(const char *)function
       line:(int)line
     format:(NSString *)format, ... {
    va_list args;
    if (format) {
        va_start(args, format);
        @autoreleasepool {
        if(YES){
            NSString *msgStr = [[NSString alloc] initWithFormat:format arguments:args];
            NSString* fileStr = [NSString stringWithUTF8String:file];
            fileStr = [fileStr lastPathComponent];
            NSString* functionStr =[NSString stringWithUTF8String:function];
            LogInnerMsg* msg = NewLogInnerMsg(asynchronous, level, flag, context, fileStr, functionStr, line, msgStr);
            
            dispatch_block_t logBlock = ^{ @autoreleasepool {
                [self outputLogMsg:msg ];
#ifdef LOG_WRITE_FILE
                [self writeLogMsgToFile:msg  ];
#endif
            }};
            if (asynchronous)
                dispatch_async(loggingQueue, logBlock);
            else
                dispatch_sync(loggingQueue, logBlock);
        }}
        va_end(args);
    }
}

@end

