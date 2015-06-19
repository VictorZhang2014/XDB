

////////////////////////////////////////////////////////////////////
//                          _ooOoo_                               //
//                         o8888888o                              //
//                         88" . "88                              //
//                         (| ^_^ |)                              //
//                         O\  =  /O                              //
//                      ____/`---'\____                           //
//                    .'  \\|     |//  `.                         //
//                   /  \\|||  :  |||//  \                        //
//                  /  _||||| -:- |||||-  \                       //
//                  |   | \\\  -  /// |   |                       //
//                  | \_|  ''\---/''  |   |                       //
//                  \  .-\__  `-`  ___/-. /                       //
//                ___`. .'  /--.--\  `. . ___                     //
//              ."" '<  `.___\_<|>_/___.'  >'"".                  //
//            | | :  `- \`.;`\ _ /`;.`/ - ` : | |                 //
//            \  \ `-.   \_ __\ /__ _/   .-` /  /                 //
//      ========`-.____`-.___\_____/___.-`____.-'========         //
//                           `=---='                              //
//      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^        //
//               佛祖保佑       永无BUG     永不修改                 //
////////////////////////////////////////////////////////////////////


#import "XDB.h"
#import "FMDatabaseAdditions.h"
#import "XDBaseItem.h"


@interface XDB(){
}
@property (nonatomic,strong) NSString *path;
@property (nonatomic,assign) BOOL inTransaction;
@property (nonatomic,strong) NSLock* inTransactionLock;
@property (nonatomic,strong) FMDatabase *dbW;
@property (nonatomic,strong) FMDatabase *dbR;
@property (nonatomic,strong) dispatch_queue_t query;
@property (nonatomic,strong) dispatch_queue_t update;
@end

@implementation XDB

+ (id)dbPath:(NSString*)aAbsPath pwd:(NSString*)pwd{
    XDB *q = [[self alloc] initWithPath:aAbsPath pwd:pwd];
    FMDBAutorelease(q);
    return q;
}

- (id)initWithPath:(NSString*)aPath pwd:(NSString*)pwd{
    self = [super init];
    if (self != nil) {
        [FMDatabase isSQLiteThreadSafe];
        sqlite3_config(SQLITE_CONFIG_MULTITHREAD);
        _path = FMDBReturnRetained(aPath);
        if(aPath){
            if (![self databaseForWriteWithPwd:pwd] || ![self databaseForReadWithPwd:pwd]) {
                return self;
            }
        }else{
            if (![self databaseForWriteWithPwd:pwd]) {
                return self;
            }else{
                self.dbR = self.dbW;
            }
        }
        _update = dispatch_queue_create([[NSString stringWithFormat:@"fmdb.%@.write", self] UTF8String], DISPATCH_QUEUE_SERIAL);
        _query = dispatch_queue_create([[NSString stringWithFormat:@"fmdb.%@.read", self] UTF8String], DISPATCH_QUEUE_SERIAL);
        _inTransactionLock = [NSLock new];
    }
    return self;
}

- (void)dealloc {
    [self close];
}

- (void)close {
    dispatch_sync(_query, ^() {
        [_dbW close];
        _dbW = 0x00;
    });
    dispatch_sync(_update, ^() {
        [_dbR close];
        _dbR = 0x00;
    });
}

- (FMDatabase*)databaseForReadWithPwd:(NSString*)pwd {
    if (!self.dbR) {
        self.dbR = FMDBReturnRetained([FMDatabase databaseWithPath:_path]);
        
        if (![self.dbR openWithFlags:SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE]) {
            NSLog(@"FMDatabaseQueue could not reopen database for path %@", _path);
            FMDBRelease(_db_read);
            self.dbR  = 0x00;
            return 0x00;
        }
        if(pwd)
            [ self.dbR setKey:pwd];
        
        if (SQLITE_VERSION_NUMBER >= 3007000 /*&& [[[UIDevice currentDevice] systemVersion] floatValue]>4.25*/){
            NSString* wal = [self.dbR stringForQuery:@"PRAGMA journal_mode = WAL"];
            NSLog(@"%@",wal);
        } else{
            NSString* wal =[self.dbR stringForQuery:@"PRAGMA journal_mode = DELETE"];
            NSLog(@"%@",wal);
        }
        [self.dbR setShouldCacheStatements:YES];
    }
    return self.dbR;
}

- (FMDatabase*)databaseForWriteWithPwd:(NSString*)pwd  {
    if (!self.dbW) {
        self.dbW = FMDBReturnRetained([FMDatabase databaseWithPath:_path]);
        
        if (![self.dbW openWithFlags:SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE]) {
            NSLog(@"FMDatabaseQueue could not reopen database for path %@", _path);
            FMDBRelease(_db_write);
            self.dbW  = 0x00;
            return 0x00;
        }
        
        if(pwd)
            [ self.dbR setKey:pwd];
        
   
        if (SQLITE_VERSION_NUMBER >= 3007000 /*&& [[[UIDevice currentDevice] systemVersion] floatValue]>4.25*/){
            NSString* wal = [self.dbR stringForQuery:@"PRAGMA journal_mode = WAL"];
            NSLog(@"%@",wal);
        } else{
            NSString* wal =[self.dbR stringForQuery:@"PRAGMA journal_mode = DELETE"];
            NSLog(@"%@",wal);
        }
        //[self.dbR setShouldCacheStatements:YES];
        
        [self.dbW setShouldCacheStatements:YES];
    }
    return self.dbW;
}


- (BOOL)Database:(FmdbTransaction)type
           query:(BOOL)query
        callback:(void (^)(FMDatabase *db, BOOL *rollback))block{
    
    FMDBRetain(self);
    __block BOOL shouldRollback = NO;
    dispatch_queue_t q=self.update;;
    if(query)
        q=self.query;
    
    dispatch_sync(q, ^() {
        
        FMDatabase *db = self.dbW;
        if(query)
            db = self.dbR;
        
        if(!query){
            if(kTransaction_deferred == type ||
               kTransaction_exclusive == type){
                [_inTransactionLock lock];
                self.inTransaction=YES;
            } 
            if(kTransaction_deferred == type)
                [db beginDeferredTransaction];
            else if(kTransaction_exclusive == type)
                [db beginTransaction];
        }
        
        @autoreleasepool {
            block(db, &shouldRollback);
        }
        
        if ([db hasOpenResultSets])
            NSLog(@"Warning: there is at least one open result set around after performing [FMDatabaseQueue inDatabase:]");
        
        if(!query){
            if (shouldRollback)
                [db rollback];
            else if(kTransaction_deferred == type ||
                    kTransaction_exclusive == type){
                [db commit];
            }
            if(self.inTransaction){
                self.inTransaction=NO;
                [_inTransactionLock unlock];
            }
        }
    });
    FMDBRelease(self);
    
    if(shouldRollback)
        return NO;
    else
        return YES;
}

-(sqlite_int64)lastInsertRowId{
    return [self.dbW lastInsertRowId];
}

-(NSInteger) dbVersion{
    __block NSInteger version = 0;
    
    [self Database:kTransaction_DontUse
             query:YES
          callback:^(FMDatabase *db, BOOL *rollback){
              FMResultSet *rs = [self.dbR executeQuery:@"PRAGMA user_version"];
              if ([rs next]){
                  version = [rs intForColumnIndex:0];
              }
              [rs close];
          }];
    return version;
}

#if SQLITE_VERSION_NUMBER >= 3007000
- (NSError*)inSavePoint:(void (^)(FMDatabase *db, BOOL *rollback))block {
    
    static unsigned long savePointIdx = 0;
    __block NSError *err = 0x00;
    FMDBRetain(self);
    
    void(^saveBlock)(void) = ^{
        NSString *name = [NSString stringWithFormat:@"savePoint%ld", savePointIdx++];
        BOOL shouldRollback = NO;
        if ([self.dbW startSavePointWithName:name error:&err]) {
            block(self.dbW, &shouldRollback);
            if (shouldRollback) {
                [self.dbW rollbackToSavePointWithName:name error:&err];
            } else {
                [self.dbW releaseSavePointWithName:name error:&err];
            }
        }
    };
    
    dispatch_sync(_update, ^() {
        saveBlock();
    });
    
    FMDBRelease(self);
    return err;
}
#endif

@end



#pragma mark -  XDB (UPDATA)
@implementation XDB (UPDATA)
-(BOOL)TransactionBlock:(void (^)(XDB *xdb, BOOL *rollback))blk{
    BOOL res = [self Database:kTransaction_deferred query:NO callback:^(FMDatabase *db, BOOL *rollback){
        blk(self, rollback);
    }];
    return res;
}
-(BOOL)addObject:(XDBaseItem*)item{
    if(self.inTransaction){
        Class class = [item class];
        return [self.dbW executeUpdate:[class sqlInsert]  withDataItem:item];
    }else{
        BOOL res = [self Database:kTransaction_DontUse query:NO callback:^(FMDatabase *db, BOOL *rollback){
            Class class = [item class];
            [db executeUpdate:[class sqlInsert]  withDataItem:item];
        }];
        return res;
    }
}
-(BOOL)addObjects:(NSArray*)items{
    if(self.inTransaction){
        BOOL suc = YES;
        for(XDBaseItem* item in items){
            Class class = [item class];
            if(![self.dbW executeUpdate:[class sqlInsert]  withDataItem:item])
                suc=NO;
        }
        return suc;
    }else{
    BOOL res = [self Database:kTransaction_deferred query:NO callback:^(FMDatabase *db, BOOL *rollback){
        for(XDBaseItem* item in items){
            Class class = [item class];
            [db executeUpdate:[class sqlInsert]  withDataItem:item];
        }
    }];
    return res;
    }
}
-(BOOL)removeObject:(XDBaseItem*)item{
    if(self.inTransaction){
        Class class = [item class];
        return [self.dbW executeUpdate:[class sqlDeleteByDbId] ,item.DBId];
    }else{
    BOOL res = [self Database:kTransaction_DontUse query:NO callback:^(FMDatabase *db, BOOL *rollback){
        Class class = [item class];
        [db executeUpdate:[class sqlDeleteByDbId] ,item.DBId];
    }];
    return res;
    }
}
-(BOOL)removeObjects:(NSArray*)items{
    if(self.inTransaction){
        BOOL suc = YES;
        for(XDBaseItem* item in items){
        Class class = [item class];
        if(![self.dbW executeUpdate:[class sqlDeleteByDbId] ,item.DBId])
            suc=NO;
        }
        return suc;
    }else{
    BOOL res = [self Database:kTransaction_deferred query:NO callback:^(FMDatabase *db, BOOL *rollback){
        for(XDBaseItem* item in items){
            Class class = [item class];
            [db executeUpdate:[class sqlDeleteByDbId] ,item.DBId];
        }
    }];
    return res;
    }
}
-(BOOL)executeUpdate:(NSString*)sql{
   __block BOOL ret = NO;
    [self Database:kTransaction_DontUse
             query:NO
          callback:^(FMDatabase *db, BOOL *rollback){
            ret = [db executeUpdate:sql];
          }];
    return ret;
}
-(BOOL)dropTable:(Class)class{
    if(![class isSubclassOfClass:[XDBaseItem class]]){
        NSLog(@"CreateTable Error: %@ MUST be subClassOf XDBaseItem", class);
        return NO;
    }
    NSString *tableName = [class tableName];
    NSString* sql = [NSString stringWithFormat:@"drop table %@", tableName ];
    
    return [self executeUpdate:sql];
}
-(BOOL)createTable:(Class)class{
    if(![class isSubclassOfClass:[XDBaseItem class]]){
        NSLog(@"CreateTable Error: %@ MUST be subClassOf XDBaseItem", class);
        return NO;
    }
    NSArray* sqls = @[[class createTableSQL]];
    
    for( NSString* sql in sqls){
      [self executeUpdate:sql];
    }
    return YES;
}



-(BOOL)createIndex:(Class)subClassOfXDBaseItem{
    if(![subClassOfXDBaseItem isSubclassOfClass:[XDBaseItem class]]){
        NSLog(@"CreateTable Error: %@ MUST be subClassOf XDBaseItem", subClassOfXDBaseItem);
        return NO;
    }
    
    NSArray* sqls = @[[subClassOfXDBaseItem createIndexSqls]];
    if(!sqls)return NO;
    
    for( NSString* sql in sqls){
        [self executeUpdate:sql];
    }
    return YES;
    
}
-(BOOL)alertTable{
//    ALTER TABLE orders ADD FOREIGN KEY (C_Id) REFERENCES customers(C_Id);
    return YES;
}
@end






