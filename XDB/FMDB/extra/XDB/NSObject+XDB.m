//
//  NSString+SQL.m
//  eContact
//
//  Created by zouxu on 11/7/14.
//  Copyright (c) 2014 zouxu. All rights reserved.
//

#import "NSObject+XDB.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "FMDatabaseAdditions.h" 
#import "XDB.h"
#import "SQLTableInfo.h"


typedef NS_ENUM(NSInteger, AttType) {
    kAttType_char=1,
    kAttType_int,
    kAttType_short,
    kAttType_long,
    kAttType_longLong,
    kAttType_unsignedChar,
    kAttType_unsignedInt,
    kAttType_unsignedShort,
    kAttType_unsignedLong,
    kAttType_unsignedLongLong,
    kAttType_float,
    kAttType_double,
    kAttType_bool,
    
    kAttType_NSString,
    kAttType_NSData,
    
    //NA
    kAttType_NA,
    kAttType_NSNumber,
};

#pragma mark - XDBaseItem (SQL)
@implementation NSObject (XDBaseItem_SQL)
+ (NSArray*)tableIndex{
    return nil;
}
+ (NSDictionary*)tableAttr{
    return nil;
}
+ (NSString*)tableName{
    return NSStringFromClass([self class]);
}
+ (NSArray*)tableExcludeColumn{
    return nil;
}

+ (NSArray*)tableExtraColumn{
    return nil;
}

+(AttType)getType:(char)valueType{
    switch (valueType) {
        case 'c':return kAttType_char;
        case 'i':return kAttType_int;
        case 's':return kAttType_short;
        case 'l':return kAttType_long;
        case 'q':return kAttType_longLong;
        case 'C':return kAttType_unsignedChar;
        case 'I':return kAttType_unsignedInt;
        case 'S':return kAttType_unsignedShort;
        case 'L':return kAttType_unsignedLong;
        case 'Q':return kAttType_unsignedLongLong;
        case 'f':return kAttType_float;
        case 'd':return kAttType_double;
        case 'B':return kAttType_bool;
        case '#':
        case '@'://return kAttType_NSString;
        case '^'://NSInteger ptr
        default:return kAttType_NA;
    }
}
+(AttSqlType)getSqlType:(AttType)attType{
    switch (attType) {
        case kAttType_char:
        case kAttType_int:
        case kAttType_short:
        case kAttType_long:
        case kAttType_longLong:
        case kAttType_unsignedChar:
        case kAttType_unsignedInt:
        case kAttType_unsignedShort:
        case kAttType_unsignedLong:
        case kAttType_bool:
        case kAttType_unsignedLongLong:
            return kAttSqlType_INTEGER;
        case kAttType_float:
        case kAttType_double:
            return kAttSqlType_REAL;
        case kAttType_NSString:
            return kAttSqlType_TEXT;
        case kAttType_NSData:
            return kAttSqlType_BLOB;
        default:
            NSAssert(NO, @"attType NA");
            break;
    }
    NSAssert(NO, @"attType NA");
    return kAttSqlType_NA;
}


+(void)getAttsByClass:(Class)theClass array:(NSMutableArray*)infoArray{
    unsigned int outCount;
    objc_property_t* pro = class_copyPropertyList(theClass, &outCount);
    
    NSMutableDictionary*  infosDic=[NSMutableDictionary new];
    NSArray* excludeColume = [self tableExcludeColumn];
    
    for (NSUInteger i = 0; i<outCount; i++) {
        const char * nameChar =  property_getName(*(pro+i));
        const char * typeChat = property_getAttributes(*(pro+i));
        NSString* name =[NSString stringWithUTF8String:nameChar];
        NSString* type =[NSString stringWithUTF8String:typeChat];
        
        if([excludeColume containsObject:name])
            continue;
        
        if([type hasPrefix:@"T"]){
            const char funcType = [type characterAtIndex:1];
            AttType attType =  [self getType:funcType];
            
            if(attType == kAttType_NA){
                if([type hasPrefix:@"T@\"NSString\""])
                    attType =kAttType_NSString;
                else if( [type hasPrefix:@"T@\"NSData\""])
                    attType =kAttType_NSData;
                else if( [type hasPrefix:@"T@\"NSNumber\""])
                    attType =kAttType_longLong;
            }
            if(kAttType_NA != attType){
                
                AttSqlType sqlType = [self getSqlType:attType];
                
                SQLTableInfo *info = [SQLTableInfo new];
                info.type=sqlType;
                info.name=name;
                
                //  info.selGet =NSSelectorFromString(name);
                //  NSString* getFun = [NSString stringWithFormat:@"set%@%@",  [[name substringToIndex:1]uppercaseString], [name substringFromIndex:1] ];
                //  info.selSet=NSSelectorFromString(getFun);
                
                infosDic[name]=info;
                [infoArray addObject:info];
            }
        }
    }
}

+(NSMutableArray*) getAttributeInfo {
    const char *cClassName =[NSStringFromClass([self class]) UTF8String];;// [tableName UTF8String];
    id theClass = objc_lookUpClass(cClassName);
    
    NSMutableArray* classArray = [NSMutableArray new];
    NSMutableArray* infoArray = [NSMutableArray new];
    
    Class tmpClass=theClass;
    while(YES){
        if(tmpClass == [NSObject class])
            break;
        [classArray insertObject:NSStringFromClass(tmpClass) atIndex:0];
        tmpClass=class_getSuperclass(tmpClass);
    }
    
    for(NSUInteger i=0; i<classArray.count; i++){
        NSString* classStr =classArray[i];
        Class classTmp = NSClassFromString(classStr);
        [self getAttsByClass:classTmp array:infoArray];
    }
    
    //set increase tag
    NSDictionary* tableAttr = [self tableAttr];
    for(SQLTableInfo* info in infoArray){
        NSString* attr = tableAttr[ info.name];
        if([[attr uppercaseString] rangeOfString:@"AUTOINCREMENT"].length>0){
            info.autoIncreament = 1;
        }
    }
    
    //put primay key to first
    for(int i=0; i<infoArray.count; i++){
        SQLTableInfo* info = infoArray[i];
        NSString* attr = tableAttr[info.name];
        if([[attr uppercaseString] rangeOfString:@"PRIMARY"].length>0){
            info.primaryKey = 1;
            [infoArray removeObjectAtIndex:i];
            [infoArray insertObject:info atIndex:0];
            break;
        }
    }
    
    return  infoArray;
}

+(NSArray*)getSQLTableInfo {
    
    NSMutableArray* infoArray = [self getAttributeInfo];
    
    NSArray* extra = [self tableExtraColumn];
    if (extra) {
        [infoArray addObjectsFromArray:extra];
    }
    
    BOOL userSetPrimary = NO;
    //put primay key to first
    
    SQLTableInfo* info = [infoArray firstObject];
    if (info && info.primaryKey == 1) {
        userSetPrimary = YES;
    }
    
    //add dbid
    SQLTableInfo *idInfo = [SQLTableInfo new];
    idInfo.type=kAttSqlType_INTEGER;
    idInfo.name=XDBaseItemDBID;
    idInfo.autoIncreament =1;
    [infoArray insertObject:idInfo atIndex:0];
    if(!userSetPrimary){
        info.primaryKey=1;//DBId 不要去设置。
    }
    
    return  infoArray;
}

+ (NSString*)tableItemPrimaryKey{
    NSArray* infoArray = [self getSQLTableInfo];
    for(NSUInteger i=0; i<infoArray.count; i++){
        SQLTableInfo* info = infoArray[i];
        if(info.primaryKey==1){
            return info.name;
        }
    }
    return  XDBaseItemDBID;
}
+ (int)tableItemPrimaryKeyType{
    NSArray* infoArray = [self getSQLTableInfo];
    for(NSUInteger i=0; i<infoArray.count; i++){
        SQLTableInfo* info = infoArray[i];
        if(info.primaryKey==1){
            return info.type;
        }
    }
    return  kAttSqlType_NA;
}

+ (NSArray*)tableItemType{
    NSArray* infoArray = [self getSQLTableInfo];
    
    NSMutableArray* tagName = [NSMutableArray new];
    for(NSUInteger i=0; i<infoArray.count; i++){
        SQLTableInfo* info = infoArray[i];
        [tagName addObject:@(info.type)];
    }
    
    return  tagName;
}
+ (NSString*)primaryKey{
    NSArray* infoArray = [self getSQLTableInfo];
    for(SQLTableInfo* info in infoArray){
        if(info.primaryKey==1){
            return info.name;
        }
    }
    return nil;
}

+ (NSArray*)itemName;
{
    NSArray* infoArray = [self getAttributeInfo];
    
    NSMutableArray* tagName = [NSMutableArray new];
    for(NSUInteger i=0; i<infoArray.count; i++){
        SQLTableInfo* info = infoArray[i];
        [tagName addObject:info.name];
    }
    
    return  tagName;
}

+ (NSArray*)itemType;
{
    NSArray* infoArray = [self getAttributeInfo];
    
    NSMutableArray* tagName = [NSMutableArray new];
    for(NSUInteger i=0; i<infoArray.count; i++){
        SQLTableInfo* info = infoArray[i];
        [tagName addObject:@(info.type)];
    }
    
    return  tagName;
}

+(NSArray*)tableItemName{
    NSArray* infoArray = [self getSQLTableInfo];
    
    NSMutableArray* tagName = [NSMutableArray new];
    for(NSUInteger i=0; i<infoArray.count; i++){
        SQLTableInfo* info = infoArray[i];
        [tagName addObject:info.name];
    }
    
    return  tagName;
}

//@"create table spokesPerson (userUniId text PRIMARY KEY,orgId integer,loginName text, name text, photoResId text, type integer, description text, canBeSearched integer, isSubscribed integer, status integer)"];

+ (NSString*)createTableSQLWithAttrs:(NSDictionary*)attrs{
    NSArray* infoArray = [self getSQLTableInfo];
    
    NSString *tableName = [self tableName];//NSStringFromClass([self class]);
    
    NSMutableString* sql = [NSMutableString new];
    [sql appendFormat:@"CREATE TABLE %@", tableName ];
    
    [sql appendString:@"("];
    for (NSUInteger i=0; i<infoArray.count; i++) {
        SQLTableInfo *info = infoArray[i];
        //first att must be DBid
  
            NSString* colType = nil;
            switch (info.type) {
                case kAttSqlType_INTEGER:colType=@"INTEGER";break;
                case kAttSqlType_REAL:colType=@"REAL";break;
                case kAttSqlType_TEXT:colType=@"TEXT";break;
                case kAttSqlType_BLOB:colType=@"BLOB";break;
                default:
                    NSAssert(NO, @"colType NA");
                    break;
            }
            NSString* attr = attrs[info.name];
            if(attr)
                [sql appendFormat:@"%@ %@ %@", info.name, colType, attr];
            else if([info.name isEqualToString:XDBaseItemDBID]){
                if(info.primaryKey){
                    [sql appendFormat:@"%@ %@ PRIMARY KEY AUTOINCREMENT NOT NULL", info.name, colType];
                }else{
                    [sql appendFormat:@"%@ %@", info.name, colType];
                }
            }
            else
                [sql appendFormat:@"%@ %@", info.name, colType];

        if(i!=infoArray.count-1)
            [sql appendString:@","];
    }
    [sql appendString:@")"];
    
    
    return sql;
}
+ (NSString*)createTableSQL{
    NSDictionary* dir = [self tableAttr];
    return [self createTableSQLWithAttrs:dir];
}

+ (NSArray*)createIndexSqls{
    NSArray* indexCnts = [self tableIndex];
    if(!indexCnts)return nil;
    //检验属性是否合法
    NSMutableArray* array = [NSMutableArray new];
    
    NSString *tableName = [self tableName];
    for(NSString* cnt in indexCnts){
        NSMutableString* indexName = [NSMutableString new];
        for(NSUInteger i=0; i<cnt.length; i++){
            unichar CHAR = [cnt characterAtIndex:i];
            if(!((CHAR >='a'&& CHAR<='z') || (CHAR >='A'&& CHAR<='Z') ||(CHAR >='0'&& CHAR<='9') ||CHAR ==' ' ))
                continue;
            NSString* str =[cnt substringWithRange:NSMakeRange(i, 1)];
            if(CHAR ==' ')
                str = @"_";
            [indexName appendString:str];
        }
        NSMutableString* sql = [NSMutableString new];
        [sql appendFormat:@"CREATE INDEX IF NOT EXISTS %@_%@ ON %@ (%@)", tableName, indexName , tableName, cnt];
        [array addObject:sql];
    }
    return array;
}

+ (NSString*)sqlUpdataByDbId{
    // [db executeUpdate:@"UPDATE organizationTree SET path = ?  WHERE structId = ? ",path,structId];
    NSArray* infoArray = [self getAttributeInfo];//[self infoArrayExcludeAutoincrement];
    
    NSString *tableName = [self tableName];//NSStringFromClass([self class]);
    
    
    NSMutableString* innerStr = [NSMutableString new];
    for(NSUInteger i=0; i<infoArray.count;i++){
        SQLTableInfo* info =infoArray[i];
        [innerStr appendFormat:@"%@=?", info.name];
        if(i!=infoArray.count-1)
            [innerStr appendString:@","];
    }
    
    NSString* sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@=?", tableName, innerStr, [self tableItemPrimaryKey]];
    
    return sql;
}

+(NSString*)sqlDeleteByDbId{
    NSString *tableName = [self tableName];//NSStringFromClass([self class]);
    return [NSString stringWithFormat:@"delete from %@ where %@=?", tableName, [self tableItemPrimaryKey]];
}

+(NSArray*)infoArrayExcludeAutoincrement{
    NSArray* infoArray2 = [self getSQLTableInfo];
    NSMutableArray* infoArray =[NSMutableArray new];
    for(int i=0; i< infoArray2.count; i++){
        SQLTableInfo* info = infoArray2[i];
        if(info.autoIncreament)//
            continue;
        [infoArray addObject:info];
    }
    return infoArray;
}

+(NSString*)sqlReplace{
    return [self sqlInsertOrReplace:@"REPLACE INTO"];
}
+(NSString*)sqlInsert{
    return [self sqlInsertOrReplace:@"INSERT OR REPLACE INTO"];
//    return [self sqlInsertOrReplace:@"INSERT OR IGNORE INTO"];
}
+(NSString*)sqlInsertOrReplace:(NSString*)insertOrReplace{
    NSArray* infoArray = [self getAttributeInfo];//[self infoArrayExcludeAutoincrement];
    
    NSString *tableName = [self tableName];//NSStringFromClass([self class]);
    
    NSMutableString* sql = [NSMutableString new];
    
    [sql appendFormat:@"%@ %@", insertOrReplace, tableName];
    [sql appendString:@"("]; 
    for(NSUInteger i=0; i<infoArray.count;i++){
        SQLTableInfo* info =infoArray[i];
        
        [sql appendFormat:@"%@", info.name];
        if(i!=infoArray.count-1)
            [sql appendString:@","];
    }
    [sql appendString:@")"];
   // [sql appendString:@"VALUES"];
      [sql appendString:@"VALUES"];
    [sql appendString:@"("];
    for(NSUInteger i=0; i<infoArray.count;i++){
        [sql appendString:@"?"];
        if(i!=infoArray.count-1)
            [sql appendString:@","];
    }
    [sql appendString:@");"];
    
    return sql;
}

@end



#pragma mark - XDBaseItem (QUERY)
@implementation NSObject (XDBaseItem_QUERY)

+ (int)countInDb:(XDB*)dbFD where:(NSString*)where,... {
    NSString *table =[self tableName];// NSStringFromClass([self class]);
    NSString* sql =nil;
    if(where.length>0)
        sql= [NSString stringWithFormat:@"select count(*) from %@ where %@",table, where];
    else
        sql= [NSString stringWithFormat:@"select count(*) from %@",table ];
    
    return [dbFD intWithSql:sql];
}

+(NSMutableArray*)objectsInDbInner:(XDB*)dbFD sql:(NSString*)sql orVAList:(va_list)args{
    NSMutableArray* arrActivity = [[NSMutableArray alloc] initWithCapacity:10];
    [dbFD queryInDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql orVAList:args];
        while ([rs next]){
            // NSObject* item = [self New];
            NSObject* item = [self new];
            [rs kvcMagicForXDB:item];
            [arrActivity addObject:item ];
        }
        [rs close];
    }];
    return arrActivity;
}

+ (NSMutableArray*)objectsInDb:(XDB*)dbFD where:(NSString*)where range:(NSRange)range
{
    NSString *table = [self tableName];
    NSString* sql = nil;
    if(where.length>0)
        sql = [NSString stringWithFormat:@"select * from %@ where %@ LIMIT %lu OFFSET %lu",table , where, (unsigned long)range.length, (unsigned long)range.location];
    else
        sql = [NSString stringWithFormat:@"select * from %@ LIMIT %lu OFFSET %lu",table , (unsigned long)range.length, (unsigned long)range.location];
    return [self objectsInDb:dbFD sql:sql];
}

+ (NSMutableArray*)objectsInDb:(XDB*)dbFD where:(NSString*)where, ...
{
    NSString *table = [self tableName];//NSStringFromClass([self class]);
    NSString* sql = nil;
    if(where.length>0)
        sql= [NSString stringWithFormat:@"select * from %@ where %@",table, where];
    else
        sql = [NSString stringWithFormat:@"select * from %@",table ];
    va_list args;
    va_start(args, where);
    NSMutableArray* array = [self objectsInDbInner:dbFD sql:sql orVAList:args];
    va_end(args);
    return array;
}

+(NSMutableArray*)objectsInDb:(XDB*)dbFD sql:(NSString*)sql, ...
{
    va_list args;
    va_start(args, sql);
    NSMutableArray* array = [self objectsInDbInner:dbFD sql:sql orVAList:args];
    va_end(args);
    return array;
}

+(id)objectInDbInner:(XDB*)dbFD sql:(NSString*)sql orVAList:(va_list)args{
    __block id object = nil;
    [dbFD queryInDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql orVAList:args];
        if ([rs next]){
            // NSObject* item = [self New];
            object = [self new];
            [rs kvcMagicForXDB:object];
        }
        [rs close];
    }];
    return object;
}

+ (id)objectInDb:(XDB*)dbFD where:(NSString*)where, ...{
    NSString *table = [self tableName];//NSStringFromClass([self class]);
    NSString* sql = nil;
    if(where.length>0)
        sql= [NSString stringWithFormat:@"select * from %@ where %@",table, where];
    else
        sql = [NSString stringWithFormat:@"select * from %@",table];
    
    va_list args;
    va_start(args, where);
    id object = [self objectInDbInner:dbFD sql:sql orVAList:args];
    va_end(args);
    return object;
}

+ (id)objectInDb:(XDB*)dbFD sql:(NSString*)sql, ...{
    va_list args;
    va_start(args, sql);
    id object = [self objectInDbInner:dbFD sql:sql orVAList:args];
    va_end(args);
    return object;
}

+ (id)objectInDb:(XDB*)dbFD withPrimaryKeyValue:(id)value;
{
    NSString *table = [self tableName];
    NSString *primaryKey = [self primaryKey];
    NSString* sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@=%@",table,primaryKey,value];
    return [self objectInDbInner:dbFD sql:sql orVAList:nil];
}

+(id)value:(NSString*)propertyName InDb:(XDB*)dbFD where:(NSString*)where, ... {
    NSString *table = [self tableName];//NSStringFromClass([self class]);
    NSString* sql = nil;
    if(where.length>0)
        sql= [NSString stringWithFormat:@"select %@ from %@ where %@",propertyName,table, where];
    else
        sql = [NSString stringWithFormat:@"select %@ from %@",propertyName,table];
    va_list args;
    va_start(args, where);
    id value = [dbFD valueWithSql:sql valist:args];
    va_end(args);
    return value;
}


+(NSMutableArray*)values:(NSString*)propertyName InDb:(XDB*)dbFD where:(NSString*)where, ...
{
    NSString *table = [self tableName];//NSStringFromClass([self class]);
    NSString* sql = nil;
    if(where.length>0)
        sql= [NSString stringWithFormat:@"select %@ from %@ where %@",propertyName,table, where];
    else
        sql = [NSString stringWithFormat:@"select %@ from %@",propertyName,table];
    va_list args;
    va_start(args, where);
    NSMutableArray* result = [dbFD valueListWithSql:sql valist:args];
    va_end(args);
    return result;
}

@end


@implementation NSObject (XDBaseItem_UPDATA)



+ (BOOL)deleteInDb:(XDB*)dbFD where:(NSString*)where,...{
    NSString *table = [self tableName];
    NSString* sql =nil;
    if(where.length>0)
        sql= [NSString stringWithFormat:@"DELETE FROM %@ where %@",table, where];
    else
        sql= [NSString stringWithFormat:@"DELETE FROM %@",table];
    va_list args;
    va_start(args, where);
    BOOL success = [dbFD executeUpdate:sql withVAList:args];
    va_end(args);
    return success;
}
- (BOOL)updataInDb:(XDB*)dbFD{
    return [dbFD updataObject:self];
}
+ (BOOL)updataInDb:(XDB*)dbFD item:(NSObject*)item{
    return [dbFD updataObject:item];
}
+ (BOOL)updataInDb:(XDB*)dbFD items:(NSArray*)items{
    __block BOOL ok = NO;
 
    [dbFD updateDatabase:^(FMDatabase *db){
        for (int i=0; i<items.count; i++) {
            BOOL suc = [dbFD updataObject:items[i]];
            if (!suc){
                suc = NO;
                return;
            }
        }
       ok = YES;
    }];
    return ok;
}

+ (BOOL)deleteInDb:(XDB*)dbFD withPrimaryKeyValue:(id)value;
{
    __block BOOL success = NO;
    [dbFD updateDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:[self sqlDeleteByDbId],value];
    }];
    return success;
}

+(BOOL) updateInDb:(XDB *)dbFD data:(NSDictionary *)data where:(NSString *)where valist:(va_list)args
{
    NSString *table = [self tableName];
    
    NSMutableString* innerStr = [NSMutableString new];
    NSArray* keys = data.allKeys;
    for (int i=0; i<keys.count; i++) {
        NSString* key  = keys[i];
        id value = data[key];
        [innerStr appendFormat:@"%@=%@",key, value];
        if(i!=keys.count-1)
            [innerStr appendString:@","];
    }
    NSString* sql = nil;
    if(where.length>0)
        sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@", table, innerStr,where];
    else
        sql = [NSString stringWithFormat:@"UPDATE %@ SET %@", table, innerStr];
    
    return [dbFD executeUpdate:sql withVAList:args];
}

+ (BOOL)updateInDb:(XDB*)dbFD data:(NSDictionary*)data where:(NSString*)where,...
{
    va_list args;
    va_start(args, where);
    BOOL success = [self updateInDb:dbFD data:data where:where valist:args];
    va_end(args);
    return success;
}

- (BOOL)updateInDb:(XDB*)dbFD keys:(NSArray*)keys where:(NSString*)where,...
{
    NSMutableDictionary* data = [[NSMutableDictionary alloc] initWithCapacity:keys.count];
    for (id key in keys) {
        id value = [self valueForKey:key];
        if (value) {
            [data setObject:value forKey:key];
        }
    }
    va_list args;
    va_start(args, where);
    BOOL success = [[self class] updateInDb:dbFD data:data where:where valist:args];
    va_end(args);
    return success;
}

@end






@implementation NSObject (XDBaseItem)
static const char *kDbKeyTag = "kDbKeyTag";
#pragma mark Associations
- (UInt64) DBId{
    NSNumber* num = objc_getAssociatedObject(self, (void *) kDbKeyTag);
    if(num)
        return num.unsignedLongLongValue;
    return 0;
}
- (void)setDBId:(UInt64)DBId{
    objc_setAssociatedObject(self, (void *) kDbKeyTag, @(DBId), OBJC_ASSOCIATION_ASSIGN);
}
@end

































