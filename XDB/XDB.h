//
//
//  Created by zouxu on 14-07-10.
//  izouxv@gmail.com
//  Copyright (c) 2014年 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

typedef NS_ENUM(NSInteger, FmdbTransaction) {
    kTransaction_DontUse=1,
    kTransaction_deferred,
    kTransaction_exclusive,
};

//不支持嵌套事务
@interface XDB : NSObject
+ (id)dbPath:(NSString*)aAbsPath pwd:(NSString*)pwd;
- (BOOL)Database:(FmdbTransaction)type
           query:(BOOL)query
        callback:(void (^)(FMDatabase *db, BOOL *rollback))block;
@end


#pragma mark -  XDB (UPDATA)
@interface XDB (UPDATA)
//by funcation
-(BOOL)TransactionBlock:(void (^)(XDB *xdb, BOOL *rollback))blk; 
-(BOOL)addObject:(XDBaseItem*)item;
-(BOOL)addObjects:(NSArray*)items;//直接调用会自动事务
-(BOOL)removeObject:(XDBaseItem*)item;
-(BOOL)removeObjects:(NSArray*)items;//直接调用会自动事务
-(BOOL)createTable:(Class)subClassOfXDBaseItem;//subClassOfXDBaseItem MUST be subclass of XDBaseItem
-(BOOL)createIndex:(Class)subClassOfXDBaseItem;
-(BOOL)dropTable:(Class)subClassOfXDBaseItem;

//by SQL
-(BOOL)executeUpdate:(NSString*)sql;
@end


