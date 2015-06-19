//
//  Util.m
//  ppChat
//
//  Created by zouxu on 18/1/14.
//  Copyright (c) 2014 zouxu. All rights reserved.
//

#import "UtilOC.h"
//#import "NSString+Util.h"

@implementation UtilOC


#pragma mark - File

+(NSString*)mkdirABS:(NSString*)file_Name dic:(NSString*)dic{
    NSError* error= nil;
    NSString *baseDir =NSHomeDirectory();
    if(dic)
        baseDir = [NSHomeDirectory() stringByAppendingPathComponent:dic];
    
    NSString* targetDir= [baseDir stringByAppendingPathComponent:file_Name];
    
    if(![file_Name hasSuffix:@"/" ]){
        targetDir= [targetDir stringByDeletingLastPathComponent];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:targetDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:targetDir withIntermediateDirectories:YES attributes:nil error:&error];
    
    NSString * filePath = [NSString stringWithFormat:@"%@/%@",baseDir, file_Name ];
    return filePath;
}

+(NSString*)mkTmpABS:(NSString*)file_Name{
    return [self mkdirABS:file_Name dic:@"tmp"];
}

+(NSString*)mkDocABS:(NSString*)file_Name{
    return [self mkdirABS:file_Name dic:@"Documents"];
}

+(BOOL)fileWrite_ReplaceABS:(NSString*)filePath data:(NSData*)data{
    @synchronized(data){
        @try
        {
            NSError *error = nil;
            if ([data writeToFile:filePath options:NSDataWritingAtomic error:&error])
                return YES;// return filePath;
            if (error.code == NSFileNoSuchFileError || error.code == NSFileWriteFileExistsError)
            {
                if ([data writeToFile:filePath options:NSDataWritingAtomic error:&error])
                    return YES;// return filePath;
            }
            NSLog(@"Error writing file at %@", filePath);
            return YES;
        }
        @catch (NSException *e)
        {
            NSLog(@"Error writing Exception file at %@", filePath);
            return NO;
        }
    }
    return NO;
}
+(BOOL)fileReadABS:(NSString*)filePath data:(NSData**)data{
    NSData* dat = [NSData dataWithContentsOfFile:filePath];
    *data = dat;
    if(dat.length>0)return YES;
    else return NO;
}
+(BOOL)fileDeleteABS:(NSString*)filePath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    if (success) {
        UIAlertView *removeSuccessFulAlert=[[UIAlertView alloc]initWithTitle:@"Congratulation:" message:@"Successfully removed" delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
        [removeSuccessFulAlert show];
        return YES;
    }
    else
    {
        NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
        return NO;
    }
}
+(BOOL)fileExistABS:(NSString*)file_Name {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:file_Name]) //如果不存在
        return NO;
    return YES;
}
+(void)getAllAction:(NSString*)path fm:(NSFileManager*)fm files:(NSMutableArray*)files{
    NSArray *contents = [fm subpathsOfDirectoryAtPath:path error:NULL];
    
    NSMutableArray *fileList = [NSMutableArray arrayWithArray:contents];
    
    while (fileList.count>0) {
        NSString *filename = fileList[fileList.count-1];
        [fileList removeLastObject];
        // NSError* error;
        [files addObject:[path stringByAppendingPathComponent:filename]];
        // BOOL suc = [fm removeItemAtPath:[path stringByAppendingPathComponent:filename] error:&error];
        //if(!suc){
        //    NSLog(@"removeFailed: %@", error);
        // }
    }
}

+( NSMutableArray*)getAllFile:(NSString*)dir{
    NSMutableArray* array = [NSMutableArray new];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [self getAllAction:dir fm:fileManager files:array];
    return array;
}

 

@end
