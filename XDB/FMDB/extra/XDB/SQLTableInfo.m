//
//  SQLTableInfo.m
//  CommonX
//
//  Created by 邓斯天 on 15/7/31.
//  Copyright (c) 2015年 zouxu. All rights reserved.
//

#import "SQLTableInfo.h"

@implementation SQLTableInfo

+(SQLTableInfo*) tableInfoWithName:(NSString*)name type:(AttSqlType)type
{
    SQLTableInfo* info = [SQLTableInfo new];
    info.name = name;
    info.type = type;
    return info;
}

@end
