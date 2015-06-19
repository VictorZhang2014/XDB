//
//  NSString+SQL.h
//  eContact
//
//  Created by zouxu on 11/7/14.
//  izouxv@gmail.com
//  Copyright (c) 2014 zouxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XDB.h"



//BigWord is DB item
#define FUN_INLINE(RRR,NNN) +(RRR)NNN{ static RRR sql=0; if(sql) return sql; sql = [super NNN]; return sql;}

#define XDB_ENABLE          \
FUN_INLINE(NSString*, sqlInsert)          \
FUN_INLINE(NSString*, sqlDeleteByDbId)    \
FUN_INLINE(NSArray*, tableItemName)       \
FUN_INLINE(NSArray*, tableItemType)       \
+ (instancetype)New{return [self new];}



#define XDB_ATTR(TTTTTTTABLE_ATTR) \
+ (NSDictionary*)tableAttr{return TTTTTTTABLE_ATTR;}

#define XDB_INDEX(TTTTTTABLE_INDEX) \
+ (NSArray*)tableIndex{return TTTTTTABLE_INDEX;}

#define XDB_ATTR_INDEX(TTTTTTTABLE_ATTR, TTTTTTABLE_INDEX)  \
XDB_ATTR(TTTTTTTABLE_ATTR)                                  \
XDB_INDEX(TTTTTTABLE_INDEX)

#define XDB_NAME(TTTTTTTABLE_NAME ) \
+ (NSString*)tableName{ return TTTTTTTABLE_NAME; }


#define XDB_EXCLUDE_COLUME(TTTTTTTABLE_EXCLUDE) \
+ (NSArray*)tableExcludeColume{ return TTTTTTTABLE_EXCLUDE; }



//FMDB data item base
@interface XDBaseItem : NSObject
@property(atomic, readonly)UInt64 DBId;
+(instancetype)New;
@end

#pragma mark - XDBaseItem (SQL)
@interface XDBaseItem (SQL)
//没事不要继承下面这些东西
+ (NSArray*)tableIndex;
+ (NSDictionary*)tableAttr;//set table attr, such as "PRIMARY KEY", "UNIQUE NOT NULL", "DEFAULT -2", "DEFAULT NULL"
+ (NSString*)tableName;//set tableName, default tableName is ClassName
+ (NSArray*)tableExcludeColume;//重载这个排除不需要处理的数据库项，否则全部

+ (NSString*)createTableSQL;
+ (NSArray*)createIndexSqls;

//需要加入XDB_ENABLE宏里，来缓存一些runtime常量，
+ (NSString*)sqlInsert;
+ (NSString*)sqlDeleteByDbId;
+ (NSArray*)tableItemName;
+ (NSArray*)tableItemType;
@end


#pragma mark - XDBaseItem (QUERY)
@interface XDBaseItem (QUERY)
+ (int)countInDb:(XDB*)dbFD where:(NSString*)where ;
+ (NSMutableArray*)objectsInDb:(XDB*)dbFD where:(NSString*)where range:(NSRange)range;
+ (NSMutableArray*)objectsInDb:(XDB*)dbFD where:(NSString*)where;
+ (NSMutableArray*)objectsInDb:(XDB*)dbFD sql:(NSString*)sql;

//key pk int or text
+ (id) objectForKeyedSubscript:(id<NSCopying>)paramKey;
+ (void) setObject:(id)paramObject forKeyedSubscript:(id<NSCopying>)paramKey;
//index
+ (id) objectAtIndexedSubscript:(NSUInteger)paramIndex;
+ (void) setObject:(id)paramObject atIndexedSubscript:(NSUInteger)paramIndex;

@end

@interface XDBaseItem (UPDATA)
+ (BOOL)deleteInDb:(XDB*)dbFD where:(NSString*)where;
@end


