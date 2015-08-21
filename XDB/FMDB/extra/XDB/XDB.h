//
//
//  Created by zouxu on 14-07-10.
//  Copyright (c) 2014年 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
@class FMDatabaseQueueV2;

typedef NS_ENUM(NSInteger, FmdbTransaction) {
    kTransaction_DontUse=1,
    kTransaction_deferred,
    kTransaction_exclusive,
};

@interface XDB : NSObject 
@property (nonatomic,readonly,strong) FMDatabaseQueueV2 *dbQueue;
+ (id)dbPath:(NSString*)aAbsPath pwd:(NSString*)pwd;
- (BOOL)Database:(FmdbTransaction)type
           query:(BOOL)query
        callback:(void (^)(FMDatabase *db, BOOL *rollback))block;
-(void)close;
- (void)queryInDatabase:(void(^)(FMDatabase* db))block;
- (void)updateDatabase:(void (^)(FMDatabase *db))block;
-(NSString*)path;
@end

@interface XDB (UPDATA)

-(void) query:(void(^)())block;

//by funcation
-(BOOL)transaction:(void (^)())block;
-(BOOL)transactionBlock:(void (^)(FMDatabase *db, BOOL *rollback))blk;

-(BOOL)addObject:(id)item;
-(BOOL)replaceObject:(id)item;
-(BOOL)addObjects:(NSArray*)items;
-(BOOL)removeObject:(NSObject*)item;
-(BOOL)removeObjects:(NSArray*)items;
-(BOOL)updataObject:(NSObject*)item;
-(BOOL)createTable:(Class)subClassOfXDBaseItem;//subClassOfXDBaseItem MUST be subclass of XDBaseItem
-(BOOL)createIndex:(Class)subClassOfXDBaseItem;
-(BOOL)dropTable:(Class)subClassOfXDBaseItem;

//by SQL
-(BOOL)executeUpdate:(NSString*)sql,...;
-(BOOL)executeUpdate:(NSString *)sql withVAList:(va_list)args;

-(BOOL)executeUpdate:(NSString*)sql args:(NSDictionary *)arguments;

-(int)intWithSql:(NSString*)sql,...;
-(int)intWithSql:(NSString*)sql valist:(va_list)args;
-(id)valueWithSql:(NSString*)sql,...;
-(id)valueWithSql:(NSString*)sql valist:(va_list)args;

-(NSMutableArray*)valueListWithSql:(NSString*)sql valist:(va_list)args;
-(NSMutableArray*)valueListWithSql:(NSString*)sql, ...;
-(NSDictionary*)valueDictionaryWithSql:(NSString*)sql,...;
@end

