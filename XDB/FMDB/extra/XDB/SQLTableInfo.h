//
//  SQLTableInfo.h
//  CommonX
//
//  Created by 邓斯天 on 15/7/31.
//  Copyright (c) 2015年 zouxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

#define SQLTableInfo(__name,__type)  [SQLTableInfo tableInfoWithName:__name type:__type]

typedef NS_ENUM(NSInteger, AttSqlType) {
    kAttSqlType_NA=1000,
    kAttSqlType_INTEGER=SQLITE_INTEGER,
    kAttSqlType_REAL=SQLITE_FLOAT,
    kAttSqlType_TEXT=SQLITE_TEXT,
    kAttSqlType_BLOB=SQLITE_BLOB,
    //kAttSqlType_NULL=SQLITE_NULL,
};

@interface SQLTableInfo : NSObject
@property(nonatomic, strong)NSString* name;
@property(nonatomic, assign)AttSqlType type;
@property(nonatomic, assign)int autoIncreament;
@property(nonatomic, assign)int primaryKey;

+(SQLTableInfo*) tableInfoWithName:(NSString*)name type:(AttSqlType)type;

@end
