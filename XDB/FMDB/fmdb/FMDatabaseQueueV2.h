//
//  FMDatabaseQueueV2.h
//  GuDong
//
//  Created by Sitian Deng on 12-3-22.
//  Copyright (c) 2012年 comisys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

@class FMDatabase;
@interface FMDatabaseQueueV2 : NSObject

@property (atomic, strong) NSString *path;

@property (atomic, readonly) int openFlags;

+ (instancetype)databaseQueueWithPath:(NSString*)aPath pwd:(NSString*)pwd;

- (instancetype)initWithPath:(NSString*)aPath pwd:(NSString*)pwd;

+ (Class)databaseClass;
- (void)close;

- (FMDatabase*)databaseForWrite;
- (FMDatabase*)databaseForRead;
//- (FMDatabase *)database;
- (NSInteger) dbVersion;
- (void)queryInDatabase:(void (^)(FMDatabase *db))block;
- (void)updateDatabase:(void (^)(FMDatabase *db))block;

//事务不可以嵌套 block中不再调inTransaction，否则会出现乱序(内部已经做处理),返回值为是否rollback
- (BOOL)inTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block;
- (BOOL)inDeferredTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block;

-(sqlite_int64)lastInsertRowId;

#if SQLITE_VERSION_NUMBER >= 3007000
// NOTE: you can not nest these, since calling it will pull another database out of the pool and you'll get a deadlock.
// If you need to nest, use FMDatabase's startSavePointWithName:error: instead.
- (NSError*)inSavePoint:(void (^)(FMDatabase *db, BOOL *rollback))block;
#endif

@end
