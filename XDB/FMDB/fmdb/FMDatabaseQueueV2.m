//
//  FMDatabaseQueueV2.m
//  GuDong
//
//  Created by Sitian Deng on 12-3-22.
//  Copyright (c) 2012年 comisys. All rights reserved.
//

#import "FMDatabaseQueueV2.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "LOG.h"

@implementation FMDatabaseQueueV2
{
    NSString            *_path;
    NSString            *_pwd;
    //    dispatch_queue_t    _queue;
    
    int _specificUpdateKey;
    int _specificQueryKey;
    
    dispatch_queue_t    _update;
    dispatch_queue_t    _query;
    //    FMDatabase          *_db;
    FMDatabase          *_db_read;
    FMDatabase          *_db_write;
    //    NSOperationQueue    *_update;
    //    NSOperationQueue    *_query;
}

@synthesize path = _path;

+ (instancetype)databaseQueueWithPath:(NSString*)aPath pwd:(NSString*)pwd
{
    FMDatabaseQueueV2 *q = [[self alloc] initWithPath:aPath pwd:pwd];
    
    FMDBAutorelease(q);
    
    return q;
}

+ (Class)databaseClass {
    return [FMDatabase class];
}

- (id)initWithPath:(NSString*)aPath pwd:(NSString*)pwd
{
    
    self = [super init];
    XLogCDebug(@"init database:%@",aPath);
    if (self != nil) {
        
//        CSLog(@"%d",[FMDatabase isSQLiteThreadSafe]);
        
        sqlite3_config(SQLITE_CONFIG_MULTITHREAD);
        
        _path = FMDBReturnRetained(aPath);
        _pwd = FMDBReturnRetained(pwd);
        
        if (![self databaseForWrite] || ![self databaseForRead]) {
            return self;
        }
        
//        [_db_write executeUpdate:@"PRAGMA default_cache_size = ? ",[NSNumber numberWithInt:8000]];
//        [_db_read executeUpdate:@"PRAGMA default_cache_size = ? ",[NSNumber numberWithInt:8000]];
//        
//        [_db_write executeUpdate:@"PRAGMA read_uncommitted = ? ",[NSNumber numberWithBool:1]];
//        [_db_read executeUpdate:@"PRAGMA read_uncommitted = ? ",[NSNumber numberWithBool:1]];
//        
//        [_db_write executeUpdate:@"PRAGMA synchronous = ? ",@"NORMAL"];
//        [_db_read executeUpdate:@"PRAGMA synchronous = ? ",@"NORMAL"];
        
        

        _update = dispatch_queue_create([[NSString stringWithFormat:@"fmdb.%@.write", self] UTF8String], DISPATCH_QUEUE_SERIAL);
        _query = dispatch_queue_create([[NSString stringWithFormat:@"fmdb.%@.read", self] UTF8String], DISPATCH_QUEUE_SERIAL);
        
        
        CFStringRef specificValueUpdate = CFSTR("queueUpdate");
        dispatch_queue_set_specific(_update,
                                    &_specificUpdateKey,
                                    (void*)specificValueUpdate,
                                    (dispatch_function_t)CFRelease);
        
        CFStringRef specificValueQuery = CFSTR("queueQuery");
        dispatch_queue_set_specific(_query,
                                    &_specificQueryKey,
                                    (void*)specificValueQuery,
                                    (dispatch_function_t)CFRelease);

//        _update = [[NSOperationQueue alloc] init];
//        _update.maxConcurrentOperationCount = 1;
//        _query = [[NSOperationQueue alloc] init];
//        _query.maxConcurrentOperationCount = 1;
        

    }
    
    return self;
}

- (void)dealloc {
    
//    FMDBRelease(_db);
    FMDBRelease(_db_read);
    FMDBRelease(_db_write);
    FMDBRelease(_path);
    FMDBRelease(_pwd);
    if (_update) {
        FMDBDispatchQueueRelease(_update);
        _update = NULL;
    }
    if (_query) {
        FMDBDispatchQueueRelease(_query);
        _query = NULL;
    }
//    if (_update) {
//        [_update release];
//        _update = nil;
//    }
//    if (_query) {
//        [_query release];
//        _query = nil;
//    }
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void)close {
    FMDBRetain(self);

    dispatch_sync(_query, ^() {
        [_db_read close];
        FMDBRelease(_db_read);
        _db_read = nil;
    });
    dispatch_sync(_update, ^() {
        [_db_write close];
        FMDBRelease(_db_write);
        _db_write = nil;
    });
//    [_update addOperationWithBlock:^{
//        [_db_write close];
//        FMDBRelease(_db_write);
//        _db_write = 0x00;
//    }];
//    [_query addOperationWithBlock:^{
//        [_db_read close];
//        FMDBRelease(_db_read);
//        _db_read = 0x00;
//    }];
    
    FMDBRelease(self);
}

-(FMDatabase *) database
{
    return _db_write;
}

-(NSInteger) dbVersion
{
    __block NSInteger version = 0;
    [self queryInDatabase:^(FMDatabase * db){
        FMResultSet *rs = [_db_read executeQuery:@"PRAGMA user_version"];
        if ([rs next]) 
        {
            version = [rs intForColumnIndex:0];
        }
        [rs close];
    }];
    return version;
}

- (FMDatabase*)databaseForRead
{
    if (!_db_read) {
        _db_read = FMDBReturnRetained([FMDatabase databaseWithPath:_path]);
        
        if (![_db_read openWithFlags:SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE]) {
            NSLog(@"FMDatabaseQueue could not reopen database for path %@", _path);
            FMDBRelease(_db_read);
            _db_read  = nil;
            return nil;
        }
        //[_db_write setKey:@""];
        if(_pwd.length){
       // if([GDSettings isVersionFunctionEnable:userSettingFunctionDbKeyEnable])
            [_db_read setKey:_pwd];
        }
        
        NSString* mode = nil;
        if (SQLITE_VERSION_NUMBER >= 3007000 /*&& [[[UIDevice currentDevice] systemVersion] floatValue]>4.25*/)
        {
            mode = [_db_read stringForQuery:@"PRAGMA journal_mode = WAL"];
        }
        else
        {
            mode = [_db_read stringForQuery:@"PRAGMA journal_mode = DELETE"];
        }
        XLog(@"%@",mode);
        
        [_db_read setShouldCacheStatements:YES];
    }
    
    return _db_read;
}

- (FMDatabase*)databaseForWrite
{
    if (!_db_write) {
        _db_write = FMDBReturnRetained([FMDatabase databaseWithPath:_path]);
        
        if (![_db_write openWithFlags:SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE]) {
            NSLog(@"FMDatabaseQueue could not reopen database for path %@", _path);
            FMDBRelease(_db_write);
            _db_write  = nil;
            return nil;
        }
        //[_db_write setKey:@""];
         if (_pwd.length)//{
      //  if([GDSettings isVersionFunctionEnable:userSettingFunctionDbKeyEnable])
            [_db_write setKey:_pwd];
        
        NSString* mode = nil;
        if (SQLITE_VERSION_NUMBER >= 3007000 /*&& [[[UIDevice currentDevice] systemVersion] floatValue]>4.25*/)
        {
            mode = [_db_write stringForQuery:@"PRAGMA journal_mode = WAL"];
        }
        else
        {
            mode = [_db_write stringForQuery:@"PRAGMA journal_mode = DELETE"];
        }
        XLog(@"%@",mode);
        
        [_db_write setShouldCacheStatements:YES];
    }
    
    return _db_write;
}

- (void)queryInDatabase:(void (^)(FMDatabase *db))block {
    FMDBRetain(self);
    

    if (dispatch_get_specific(&_specificQueryKey)) {
        FMDatabase *db = [self databaseForRead];
        @autoreleasepool {
            block(db);
        }
    }
    else if (dispatch_get_specific(&_specificUpdateKey)) {
        FMDatabase *db = [self databaseForWrite];
        @autoreleasepool {
            block(db);
        }
    }
    else
    {
        dispatch_sync(_query, ^() {
            
            FMDatabase *db = [self databaseForRead];
            @autoreleasepool {
                block(db);
            }
            if ([db hasOpenResultSets]) {
                NSLog(@"Warning: there is at least one open result set around after performing [FMDatabaseQueue inDatabase:]");
                
#if defined(DEBUG) && DEBUG
                NSSet *openSetCopy = FMDBReturnAutoreleased([[db valueForKey:@"_openResultSets"] copy]);
                for (NSValue *rsInWrappedInATastyValueMeal in openSetCopy) {
                    FMResultSet *rs = (FMResultSet *)[rsInWrappedInATastyValueMeal pointerValue];
                    NSLog(@"query: '%@'", [rs query]);
                }
#endif
            }
        });
    }
    
    FMDBRelease(self);
}

- (void)updateDatabase:(void (^)(FMDatabase *db))block {
    FMDBRetain(self);
    
    if (dispatch_get_specific(&_specificUpdateKey)) {
        FMDatabase *db = [self databaseForWrite];
        @autoreleasepool {
            block(db);
        }
    }
    else
    {
        dispatch_sync(_update, ^() {
            
            FMDatabase *db = [self databaseForWrite];
            @autoreleasepool {
                block(db);
            }
            if ([db hasOpenResultSets]) {
                NSLog(@"Warning: there is at least one open result set around after performing [FMDatabaseQueue inDatabase:]");
                
#if defined(DEBUG) && DEBUG
                NSSet *openSetCopy = FMDBReturnAutoreleased([[db valueForKey:@"_openResultSets"] copy]);
                for (NSValue *rsInWrappedInATastyValueMeal in openSetCopy) {
                    FMResultSet *rs = (FMResultSet *)[rsInWrappedInATastyValueMeal pointerValue];
                    NSLog(@"query: '%@'", [rs query]);
                }
#endif
            }
        });
    }
    
    FMDBRelease(self);
}

- (BOOL)beginTransaction:(BOOL)useDeferred withBlock:(void (^)(FMDatabase *db, BOOL *rollback))block {
    __block BOOL shouldRollback = NO;
    FMDBRetain(self);
    
    void (^rollbackBlk)(FMDatabase *db, BOOL *rollback) = ^(FMDatabase *db, BOOL *rollback) {
        @try {
            block(db, rollback);
        }
        @catch (NSException *exception) {
            XLogError(@"FMDatabaseQueueV2 beginTransaction:%@",[exception reason]);
            *rollback = YES;
        }
        @finally {
            
        }
    };
    
    dispatch_block_t transactionBlock = ^{
        if (useDeferred) {
            [[self databaseForWrite] beginDeferredTransaction];
        }
        else {
            [[self databaseForWrite] beginTransaction];
        }
        @autoreleasepool {
            rollbackBlk([self databaseForWrite], &shouldRollback);
        }
        if (shouldRollback) {
            [[self databaseForWrite] rollback];
        }
        else {
            [[self databaseForWrite] commit];
        }
    };
    
    if (dispatch_get_specific(&_specificUpdateKey)) {
        if (![[self databaseForWrite] inTransaction]) {
            transactionBlock();
        }
        else
        {
           block([self databaseForWrite], &shouldRollback); 
        }
    }
    else
    {
        dispatch_sync(_update, transactionBlock);
    }

    FMDBRelease(self);
#if DEBUG
    if(shouldRollback) {
        NSLog(@"%@",[NSThread callStackSymbols]);
        [NSException raise:@"FMDatabaseQueueV2 exception" format:@"beginTransaction shouldRollback"];
    }
#endif
    return shouldRollback;
}

- (BOOL)inDeferredTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block {
    return [self beginTransaction:YES withBlock:block];
}

- (BOOL)inTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block {
    return [self beginTransaction:NO withBlock:block];
}

-(sqlite_int64)lastInsertRowId
{
    return [_db_write lastInsertRowId];
}

#if SQLITE_VERSION_NUMBER >= 3007000
- (NSError*)inSavePoint:(void (^)(FMDatabase *db, BOOL *rollback))block {
    
    static unsigned long savePointIdx = 0;
    __block NSError *err = nil;
    FMDBRetain(self);
    
    void(^saveBlock)(void) = ^{
            NSString *name = [NSString stringWithFormat:@"savePoint%ld", savePointIdx++];
            BOOL shouldRollback = NO;
            if ([[self databaseForWrite] startSavePointWithName:name error:&err]) {
                block([self databaseForWrite], &shouldRollback);
                if (shouldRollback) {
                    [[self databaseForWrite] rollbackToSavePointWithName:name error:&err];
                }
                else {
                    [[self databaseForWrite] releaseSavePointWithName:name error:&err];
                }
            }
    };
                
    if (dispatch_get_specific(&_specificUpdateKey)) {
        saveBlock();
    }
    else {
        dispatch_sync(_update,saveBlock);
    }
    
    FMDBRelease(self);
    return err;
}
#endif


@end
