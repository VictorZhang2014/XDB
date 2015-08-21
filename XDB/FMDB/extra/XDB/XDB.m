




#import "XDB.h"
#import "FMDatabaseAdditions.h"
#import "NSObject+XDB.h"
#import "NSObject+XDB.h"
#import "FMDatabaseQueue.h"
#import "FMDatabaseQueueV2.h"
#import "LOG.h"

@interface XDB(){
}
@property (nonatomic,strong) FMDatabaseQueueV2 *dbQueue; 
@end

@implementation XDB
-(void)close{
    [self.dbQueue close];
}
+ (id)dbPath:(NSString*)aAbsPath pwd:(NSString*)pwd{
    XDB *q = [[self alloc] initWithPath:aAbsPath pwd:pwd];
    FMDBAutorelease(q);
    return q;
}
- (id)initWithPath:(NSString*)aPath pwd:(NSString*)pwd{
    self = [super init];
    if (self != nil) {
        self.dbQueue = [FMDatabaseQueueV2 databaseQueueWithPath:aPath pwd:pwd];
    }
    return self;
}
- (BOOL)Database:(FmdbTransaction)type
           query:(BOOL)query
        callback:(void (^)(FMDatabase *db, BOOL *rollback))block{
    switch (type) {
        case kTransaction_DontUse:{
            [self.dbQueue queryInDatabase:^(FMDatabase* db){
                block(db, nil);
            }];
            return YES;
        }
        case kTransaction_deferred:{
            [self.dbQueue inDeferredTransaction:block];
            break;
        }
        case kTransaction_exclusive:{
            [self.dbQueue inTransaction:block];
            break;
        }
        default:
            break;
    }
    return NO;
}

-(void) queryInDatabase:(void(^)(FMDatabase* db))block {
    [self.dbQueue queryInDatabase:block];
}

- (void)updateDatabase:(void (^)(FMDatabase *db))block;{
    [self.dbQueue updateDatabase:block];
}
-(NSString*)path{
    return self.dbQueue.path;
}
@end




#pragma mark -  XDB (UPDATA)
@implementation XDB (UPDATA)

-(void) query:(void(^)())block
{
    [self.dbQueue queryInDatabase:^(FMDatabase *db) {
        block();
    }];
}

- (BOOL)transaction:(void (^)())block
{
    void (^wrapBlock)(FMDatabase *db, BOOL *rollback) = ^(FMDatabase *db, BOOL *rollback) {
        block();
    };
    return [self.dbQueue inTransaction:wrapBlock];
}

-(BOOL)transactionBlock:(void (^)(FMDatabase *db, BOOL *rollback))blk{
    
    return [self.dbQueue inTransaction:blk];
}

-(BOOL)replaceObject:(id)item{
    __block BOOL success = NO;
    [self.dbQueue updateDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:[[item class] sqlReplace]  withDataItem:item type:XDB_Replace];
    }];
    return success;
}

-(BOOL)addObject:(id)item{
    __block BOOL success = NO;
    [self.dbQueue updateDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:[[item class] sqlInsert]  withDataItem:item type:XDB_Insert];
    }];
    return success;
}

-(BOOL)addObjects:(NSArray*)items{
    
    BOOL success = [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for(NSObject* item in items){
            Class class = [item class];
            if(![db executeUpdate:[class sqlInsert]  withDataItem:item type:XDB_Insert]) {
                *rollback=YES;
                break;
            }
        }
    }];
    return success;
}

-(BOOL)removeObject:(NSObject*)item{
    Class class = [item class];
    id value = [item valueForKey: [class tableItemPrimaryKey]];
    __block BOOL success = NO;
    [self.dbQueue updateDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:[class sqlDeleteByDbId] ,value];
    }];
    return success;
}

-(BOOL)updataObject:(NSObject*)item{
    __block BOOL success = NO;
    [self.dbQueue updateDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:[[item class] sqlUpdataByDbId]  withDataItem:item type:XDB_Updata];
    }];
    return success;
}

-(BOOL)removeObjects:(NSArray*)items{
    BOOL success = [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for(NSObject* item in items){
            Class class = [item class];
            id value = [item valueForKey: [class tableItemPrimaryKey]];
            if(![db executeUpdate:[class sqlDeleteByDbId] ,value]){
                *rollback = YES;
                break;
            }
        }
    }];
    return success;
}

- (BOOL)executeUpdate:(NSString*)sql args:(NSDictionary *)arguments {
    __block BOOL success = NO;
    [self.dbQueue updateDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:sql withParameterDictionary:arguments];
    }];
    return success;
}

-(BOOL)executeUpdate:(NSString*)sql,...
{
    va_list args;
    va_start(args, sql);
    BOOL success = [self executeUpdate:sql withVAList:args];
    va_end(args);
    return success;
//        __block BOOL ret = NO;
//    [self Database:kTransaction_DontUse
//             query:NO
//          callback:^(FMDatabase *db, BOOL *rollback){
//              ret = [db executeUpdate:sql];
//          }];
//    return ret;
}

-(BOOL) executeUpdate:(NSString *)sql withVAList:(va_list)args
{
    __block BOOL success = NO;
    [self.dbQueue updateDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:sql withVAList:args];
    }];
    return success;
}

-(BOOL)dropTable:(Class)class{
    if (![[self class]MustBeSubClassOfXDBBaseItem:class])
        return NO;
    NSString *tableName = [class tableName];
    NSString* sql = [NSString stringWithFormat:@"drop table %@", tableName];
    __block BOOL success = NO;
    [self.dbQueue updateDatabase:^(FMDatabase *db) {
        success = [self executeUpdate:sql];
    }];
    return success;
}

-(BOOL)createTable:(Class)class{
    if (![[self class]MustBeSubClassOfXDBBaseItem:class])
        return NO;
    NSString* sql =[class createTableSQL];
    __block BOOL success = NO;
    [self.dbQueue updateDatabase:^(FMDatabase *db) {
        success = [self executeUpdate:sql];
    }];
    NSLog(@"createTable: %d\n%@", success, sql);
    return success;
}

+(BOOL)MustBeSubClassOfXDBBaseItem:(Class)c{
      if ([c conformsToProtocol:@protocol(XDB_protocol)]) {
          return YES;
      }
    return NO;
//    if(![c isSubclassOfClass:[XDBaseItem class]]){
//        NSLog(@"CreateTable Error: %@ MUST be subClassOf XDBaseItem", c);
//        return NO;
//    }
    return YES;
}

-(BOOL)createIndex:(Class)class{
    if (![[self class]MustBeSubClassOfXDBBaseItem:class])
        return NO;
    NSArray* sqls = [class createIndexSqls];
    if(!sqls)return NO;
    BOOL success = [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for( NSString* sql in sqls){
            BOOL success = [self executeUpdate:sql];
            if (!success) {
                *rollback = YES;
                break;
            }
        }
    }];
    return success;
}

-(BOOL)alertTable{
    //    ALTER TABLE orders ADD FOREIGN KEY (C_Id) REFERENCES customers(C_Id);
    return YES;
}

- (int)intWithSql:(NSString*)sql valist:(va_list)args
{
    __block int count = 0;
    [self queryInDatabase:^(FMDatabase *db) {
        FMResultSet* rs = [db executeQuery:sql orVAList:args];
        if ([rs next]) {
            count = [rs intForColumnIndex:0];
        }
    }];
    return count;
}

-(int)intWithSql:(NSString*)sql,...;
{
    va_list args;
    va_start(args, sql);
    int count = [self intWithSql:sql valist:args];
    va_end(args);
    return count;
}

-(id)valueWithSql:(NSString*)sql valist:(va_list)args
{
    __block id value = nil;
    [self queryInDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql orVAList:args];
        if ([rs next]){
            value = [rs objectForColumnIndex:0];
        }
        [rs close];
    }];
    return value;
}

-(id)valueWithSql:(NSString*)sql,...
{
    va_list args;
    va_start(args, sql);
    id value = [self valueWithSql:sql valist:args];
    va_end(args);
    return value;
}

-(NSMutableArray*)valueListWithSql:(NSString*)sql valist:(va_list)args
{
    NSMutableArray* arrActivity = [[NSMutableArray alloc] initWithCapacity:10];
    [self queryInDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql orVAList:args];
        while ([rs next]){
            [arrActivity addObject:[rs objectForColumnIndex:0]];
        }
        [rs close];
    }];
    return arrActivity;
}

-(NSMutableArray*)valueListWithSql:(NSString*)sql, ...
{
    va_list args;
    va_start(args, sql);
    NSMutableArray* arrActivity = [self valueListWithSql:sql valist:args];
    va_end(args);
    return arrActivity;
}

-(NSDictionary*)valueDictionaryWithSql:(NSString*)sql valist:(va_list)args
{
    __block NSDictionary* dict = nil;
    [self queryInDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql orVAList:args];
        if ([rs next]){
            dict = [rs resultDictionary];
        }
        [rs close];
    }];
    return dict;
}

-(NSDictionary*)valueDictionaryWithSql:(NSString*)sql,...;
{
    va_list args;
    va_start(args, sql);
    __block NSDictionary* dict = [self valueDictionaryWithSql:sql valist:args];
    va_end(args);
    return dict;
}

@end










