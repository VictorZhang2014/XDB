//
//  Util.h
//  ppChat
//
//  Created by zouxu on 18/1/14.
//  Copyright (c) 2014 zouxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

typedef void (^MyLocBlk)(NSString* name,  CLLocation* loc);

@interface UtilOC : NSObject
//file
+(NSString*)mkdirABS:(NSString*)file_Name dic:(NSString*)dic;
+(NSString*)mkTmpABS:(NSString*)file_Name;
+(NSString*)mkDocABS:(NSString*)file_Name;
+(BOOL)fileWrite_ReplaceABS:(NSString*)file_Name data:(NSData*)data; 
+(BOOL)fileReadABS:(NSString*)file_Name data:(NSData**)data;
+(BOOL)fileExistABS:(NSString*)file_Name;
+(BOOL)fileDeleteABS:(NSString*)file_Name;

+(NSMutableArray*)getAllFile:(NSString*)dir;

 

@end

