//
//  NSString+SQL.h
//  eContact
//
//  Created by zouxu on 11/7/14.
//  Copyright (c) 2014 zouxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLTableInfo.h"

//MUST ENABLE XDB_ENABLE, and XDB_protocol


//BigWord is DB item
#define FUN_INLINE(RRR,NNN) +(RRR)NNN{ static RRR sql=0; if(sql) return sql; sql = [super NNN]; return sql;}

#define XDB_ENABLE          \
FUN_INLINE(NSString*, sqlInsert)          \
FUN_INLINE(NSString*, sqlReplace)          \
FUN_INLINE(NSString*, sqlDeleteByDbId)    \
FUN_INLINE(NSArray*, itemName)       \
FUN_INLINE(NSArray*, itemType)       \
FUN_INLINE(NSArray*, tableItemName)       \
FUN_INLINE(NSArray*, tableItemType)       \
FUN_INLINE(NSString*, tableItemPrimaryKey)  \
FUN_INLINE(NSString*, sqlUpdataByDbId)  \
FUN_INLINE(int, tableItemPrimaryKeyType)



#define XDB_ATTR(TTTTTTTABLE_ATTR) \
+ (NSDictionary*)tableAttr{return TTTTTTTABLE_ATTR;}

#define XDB_INDEX(TTTTTTABLE_INDEX) \
+ (NSArray*)tableIndex{return TTTTTTABLE_INDEX;}

#define XDB_ATTR_INDEX(TTTTTTTABLE_ATTR, TTTTTTABLE_INDEX)  \
XDB_ATTR(TTTTTTTABLE_ATTR)                                  \
XDB_INDEX(TTTTTTABLE_INDEX)

#define XDB_NAME(TTTTTTTABLE_NAME ) \
+ (NSString*)tableName{ return TTTTTTTABLE_NAME; }

#define XDB_EXCLUDE_COLUMN(TTTTTTTABLE_EXCLUDE) \
+ (NSArray*)tableExcludeColumn{ return TTTTTTTABLE_EXCLUDE; }

#define XDB_EXTRA_COLUMN(__extra) \
+ (NSArray*)tableExtraColumn{ return __extra;}


@class XDB;

enum{
    XDB_Insert=1,
    XDB_Replace,
    XDB_Updata,
};

@protocol XDB_protocol
//MUST enable XDB_ENABLE in your class
+ (NSString*)sqlInsert;
+ (NSString*)sqlDeleteByDbId;
+ (NSArray*)itemName;
+ (NSArray*)itemType;
+ (NSArray*)tableItemName;
+ (NSArray*)tableItemType;
+ (NSString*)tableItemPrimaryKey;
@end


#pragma mark - XDBaseItem (SQL)
@interface NSObject (XDBaseItem_SQL)
//over ride
+ (NSArray*)tableIndex;
+ (NSDictionary*)tableAttr;//set table attr, such as "PRIMARY KEY", "UNIQUE NOT NULL", "DEFAULT -2", "DEFAULT NULL"
+ (NSString*)tableName;//set tableName, default tableName is ClassName
+ (NSArray*)tableExcludeColumn;
+ (NSString*)createTableSQL;
+ (NSArray*)createIndexSqls;
+ (NSArray*)tableExtraColumn;//SQLTableInfos

//MUST enable XDB_ENABLE in your class
//Don't over ride
+ (NSString*)sqlInsert;
+ (NSString*)sqlReplace;
+ (NSString*)sqlDeleteByDbId;
+ (NSString*)sqlUpdataByDbId;
+ (NSArray*)itemName;
+ (NSArray*)itemType;
+ (NSArray*)tableItemName;
+ (NSArray*)tableItemType;
+ (NSString*)tableItemPrimaryKey;
+ (int)tableItemPrimaryKeyType;
@end


#pragma mark - XDBaseItem (QUERY)
@interface NSObject (XDBaseItem_QUERY)

+ (int)countInDb:(XDB*)dbFD where:(NSString*)where,...;

+ (NSMutableArray*)objectsInDb:(XDB*)dbFD where:(NSString*)where range:(NSRange)range;
+ (NSMutableArray*)objectsInDb:(XDB*)dbFD where:(NSString*)where, ...;
+ (NSMutableArray*)objectsInDb:(XDB*)dbFD sql:(NSString*)sql, ...;
+ (id)objectInDb:(XDB*)dbFD where:(NSString*)where, ...;
+ (id)objectInDb:(XDB*)dbFD sql:(NSString*)sql, ...;
+ (id)objectInDb:(XDB*)dbFD withPrimaryKeyValue:(id)value;
+ (BOOL)updataInDb:(XDB*)dbFD items:(NSArray*)items;
+(id)value:(NSString*)propertyName InDb:(XDB*)dbFD where:(NSString*)where, ...;
+(NSMutableArray*)values:(NSString*)propertyName InDb:(XDB*)dbFD where:(NSString*)where, ...;

@end

@interface NSObject (XDBaseItem_UPDATA)
+ (BOOL)deleteInDb:(XDB*)dbFD where:(NSString*)where,...;
+ (BOOL)deleteInDb:(XDB*)dbFD withPrimaryKeyValue:(id)value;
+ (BOOL)updateInDb:(XDB*)dbFD data:(NSDictionary*)data where:(NSString*)where,...;//where must be set
- (BOOL)updateInDb:(XDB*)dbFD keys:(NSArray*)keys where:(NSString*)where,...;
@end


#define XDBaseItemDBID @"DBId"
@interface NSObject (XDBaseItem)
@property(nonatomic, readonly)UInt64 DBId;//SQL 建表不需要设置这个属性 
@end

















