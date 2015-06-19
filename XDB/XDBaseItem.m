//
//  NSString+SQL.m
//  eContact
//
//  Created by zouxu on 11/7/14.
//  izouxv@gmail.com
//  Copyright (c) 2014 zouxu. All rights reserved.
//

#import "XDBaseItem.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "sqlite3.h"
#import "FMDatabaseAdditions.h"

#define MAXTEST 100
#define TESTXDBENABLE(MAX)  static int KCurCall = 0;  KCurCall++; if(KCurCall>MAX) NSLog(@"WARNING!!!,XDB May be not enable in table: %@", tableName);


@implementation XDBaseItem
+(instancetype)New{
    return nil;
}
@end


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



typedef NS_ENUM(NSInteger, AttSqlType) {
    kAttSqlType_NA=1000,
    kAttSqlType_INTEGER=SQLITE_INTEGER,
    kAttSqlType_REAL=SQLITE_FLOAT,
    kAttSqlType_TEXT=SQLITE_TEXT,
    kAttSqlType_BLOB=SQLITE_BLOB,
    //kAttSqlType_NULL=SQLITE_NULL,
};


@interface SQLTableInfo :NSObject
@property(nonatomic, strong)NSString* name;
@property(nonatomic, assign)AttSqlType type;
@end

@implementation SQLTableInfo
@end

#pragma mark - XDBaseItem (SQL)
@implementation XDBaseItem (SQL)
+ (NSArray*)tableIndex{
    return nil;
}
+ (NSDictionary*)tableAttr{
    return nil;
}
+ (NSString*)tableName{
    return NSStringFromClass([self class]);
}
+ (NSArray*)tableExcludeColume{
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


+(void)getAttsByClass:(Class)theClass table:(NSString*)tableName array:(NSMutableArray*)infoArray{
    unsigned int outCount;
    objc_property_t* pro = class_copyPropertyList(theClass, &outCount);
    
    NSMutableDictionary*  infosDic=[NSMutableDictionary new];
    NSArray* excludeColume = [self tableExcludeColume];
   
    for (int i = 0; i<outCount; i++) {
        const char * nameChar =  property_getName(*(pro+i));
        const char * typeChat = property_getAttributes(*(pro+i));
        NSString* name =[NSString stringWithUTF8String:nameChar];
        NSString* type =[NSString stringWithUTF8String:typeChat];
        
#if 1
        if([excludeColume containsObject:name])
            continue;
#else
        //filter invaild name
        unichar mustBigChar = [name characterAtIndex:0];
        if(!(mustBigChar>='A' && mustBigChar<='Z'))
            continue;
#endif
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


+(NSArray*)getSQLTableInfo{
    NSString *tableName = [self tableName];//  [[self class]TableName];//  NSStringFromClass([self class]);
    
    const char *cClassName =[NSStringFromClass([self class]) UTF8String];;// [tableName UTF8String];
    id theClass = objc_lookUpClass(cClassName);
    
    NSMutableArray* classArray = [NSMutableArray new];
    NSMutableArray* infoArray = [NSMutableArray new];
    
    Class tmpClass=theClass;
    while(YES){
        [classArray insertObject:NSStringFromClass(tmpClass) atIndex:0];
        if(tmpClass == [XDBaseItem class])
            break;
        else
            tmpClass=class_getSuperclass(tmpClass);
    }
    
    for(int i=0; i<classArray.count; i++){
        NSString* classStr =classArray[i];
        Class classTmp = NSClassFromString(classStr);
        [self getAttsByClass:classTmp table:tableName array:infoArray];
    }
    
    return  infoArray;
}

+ (NSArray*)tableItemType{
    NSArray* infoArray = [self getSQLTableInfo];
    
    NSMutableArray* tagName = [NSMutableArray new];
    for(int i=0; i<infoArray.count; i++){
        SQLTableInfo* info = infoArray[i];
        [tagName addObject:@(info.type)];
    }
    
    NSString *tableName = [self tableName];//NSStringFromClass([self class]);
    TESTXDBENABLE(MAXTEST)
    
    return  tagName;
}
+(NSArray*)tableItemName{
    NSArray* infoArray = [self getSQLTableInfo];
    
    NSMutableArray* tagName = [NSMutableArray new];
    for(int i=0; i<infoArray.count; i++){
        SQLTableInfo* info = infoArray[i];
        [tagName addObject:info.name];
    }
    NSString *tableName = [self tableName];//NSStringFromClass([self class]);
    TESTXDBENABLE(MAXTEST)
    
    return  tagName;
}

//@"create table spokesPerson (userUniId text PRIMARY KEY,orgId integer,loginName text, name text, photoResId text, type integer, description text, canBeSearched integer, isSubscribed integer, status integer)"];

+ (NSString*)createTableSQLWithAttrs:(NSDictionary*)attrs{
    NSArray* infoArray = [self getSQLTableInfo];
    
    NSString *tableName = [self tableName];//NSStringFromClass([self class]);
    
    BOOL hasPrimaryKey = NO;
    for (NSString* attr in attrs) {
        NSString* value = attrs[attr];
        NSString* valueLow = [value lowercaseString];
        if([valueLow rangeOfString:@"primary"].length>0){
            hasPrimaryKey =YES;
            break;
        }
    }
    
    NSMutableString* sql = [NSMutableString new];
    [sql appendFormat:@"CREATE TABLE %@", tableName ];
    
    [sql appendString:@"("];
    for (int i=0; i<infoArray.count; i++) {
        SQLTableInfo *info = infoArray[i];
        //first att must be DBid
        if(i==0 && !hasPrimaryKey){
            NSAssert(info.type==kAttSqlType_INTEGER, @"DBBase first att MUST be int");
            [sql appendFormat:@"%@ INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL", info.name];
        }else{
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
            else
                [sql appendFormat:@"%@ %@", info.name, colType];
        }
        if(i!=infoArray.count-1)
            [sql appendString:@","];
    }
    [sql appendString:@")"];
    
    TESTXDBENABLE(MAXTEST)
    
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
        for(int i=0; i<cnt.length; i++){
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

+(NSString*)sqlDeleteByDbId{
    NSString *tableName = [self tableName];//NSStringFromClass([self class]);
    
       TESTXDBENABLE(MAXTEST)
    
    return [NSString stringWithFormat:@"delete from %@ where DBId=?", tableName ];
}

+(NSString*)sqlInsert{
    NSArray* infoArray = [self getSQLTableInfo];
    NSString *tableName = [self tableName];//NSStringFromClass([self class]);
    
    NSMutableString* sql = [NSMutableString new];
    
    [sql appendFormat:@"INSERT OR IGNORE INTO %@", tableName];
    [sql appendString:@"("];
    int IgnoreAutoId = 1;
    for(int i=IgnoreAutoId; i<infoArray.count;i++){
        SQLTableInfo* info =infoArray[i];
        [sql appendFormat:@"%@", info.name];
        if(i!=infoArray.count-1)
            [sql appendString:@","];
    }
    [sql appendString:@")"];
    [sql appendString:@"VALUES"];
    [sql appendString:@"("];
    for(int i=IgnoreAutoId; i<infoArray.count;i++){
        [sql appendString:@"?"];
        if(i!=infoArray.count-1)
            [sql appendString:@","];
    }
    [sql appendString:@")"];
    
       TESTXDBENABLE(MAXTEST)
    
    return sql;
}

@end



#pragma mark - XDBaseItem (QUERY)
@implementation XDBaseItem (QUERY)
+ (int)countInDb:(XDB*)dbFD where:(NSString*)where {
    NSString *table =[self tableName];// NSStringFromClass([self class]);
    NSString* sql =nil;
    if(where)
        sql= [NSString stringWithFormat:@"select count(*) from %@ where %@",table, where];
    else
        sql= [NSString stringWithFormat:@"select count(*) from %@",table ];
    
    __block int count = 0;
    [dbFD Database:kTransaction_DontUse query:YES callback:^(FMDatabase *db, BOOL *rollback){
#if 0
        FMResultSet *rs = [db executeQuery:sql];
        if ([rs next])  {
            count = [rs intForColumnIndex:0];
        }
        [rs close];
#else
        count  =  [db intForQuery:sql];
#endif
    }];
    return count;
}
+ (NSMutableArray*)objectsInDb:(XDB*)dbFD where:(NSString*)where range:(NSRange)range {
    NSString *table = [self tableName];
    NSString* sql = nil;
    if(where)
        sql = [NSString stringWithFormat:@"select * from %@ where %@ LIMIT %lud OFFSET %lud",table , where, (unsigned long)range.location, (unsigned long)range.length];
    else
        sql = [NSString stringWithFormat:@"select * from %@ LIMIT %lud OFFSET %lud",table , (unsigned long)range.location, (unsigned long)range.length];
    return [self objectsInDb:dbFD sql:sql];
}
+ (NSMutableArray*)objectsInDb:(XDB*)dbFD where:(NSString*)where{
    NSString *table = [self tableName];//NSStringFromClass([self class]);
    NSString* sql = [NSString stringWithFormat:@"select * from %@",table ];
    return [self objectsInDb:dbFD sql:sql];
}
+(NSMutableArray*)objectsInDb:(XDB*)dbFD sql:(NSString*)sql{
    NSMutableArray* arrActivity = [[NSMutableArray alloc] initWithCapacity:10];
    [dbFD Database:kTransaction_DontUse query:YES callback:^(FMDatabase *db, BOOL *rollback){
       // FMResultSet *rs = [db executeQuery:@"select * from activity where qunId =? order by CreateTime desc",groupID];
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]){
            XDBaseItem* item = [self New];
            [rs kvcMagic:item];
            [arrActivity addObject:item ];
        }
        [rs close];
    }];
    return arrActivity;
}


#pragma mark - XDBaseItem index & key
+ (id) objectForKeyedSubscript:(id<NSCopying>)paramKey{
    NSObject<NSCopying> *keyAsObject = (NSObject<NSCopying> *)paramKey;
    if ([keyAsObject isKindOfClass:[NSString class]]){
//        NSString *keyAsString = (NSString *)keyAsObject;
//        if ([keyAsString isEqualToString:kFirstNameKey] ||
//            [keyAsString isEqualToString:kLastNameKey]){
//            return [self valueForKey:keyAsString];
//        }
    }
    return nil;
}
+ (void) setObject:(id)paramObject forKeyedSubscript:(id<NSCopying>)paramKey{
    NSObject<NSCopying> *keyAsObject = (NSObject<NSCopying> *)paramKey;
    if ([keyAsObject isKindOfClass:[NSString class]]){
//        NSString *keyAsString = (NSString *)keyAsObject;
//        if ([keyAsString isEqualToString:kFirstNameKey] ||
//            [keyAsString isEqualToString:kLastNameKey]){
//            [self setValue:paramObject forKey:keyAsString];
//        }
    }
}
+ (id) objectAtIndexedSubscript:(NSUInteger)paramIndex{
    switch (paramIndex){
        case 0:{
          //  return self.firstName;
            break;
        }
        default:{
            [NSException raise:@"Invalid index" format:nil];
        }
    }
    return nil;
}
+ (void) setObject:(id)paramObject atIndexedSubscript:(NSUInteger)paramIndex{
    switch (paramIndex){
        case 0:{
          //  self.firstName = paramObject;
            break;
        }
        default:{
            [NSException raise:@"Invalid index" format:nil];
        }
    }
}
@end




@implementation XDBaseItem (UPDATA)
+ (BOOL)deleteInDb:(XDB*)dbFD where:(NSString*)where{
    NSString *table = [self tableName];
    NSString* sql =nil;
    if(where)
        sql= [NSString stringWithFormat:@"DELETE FROM %@ where %@",table, where];
    else
        sql= [NSString stringWithFormat:@"DELETE FROM %@",table ];
    
   return [dbFD executeUpdate:(NSString*)sql];
}

@end




