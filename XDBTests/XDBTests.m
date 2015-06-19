//
//  Facade.m
//  eContact
//
//  Created by zouxu on 14/6/14.
//  Copyright (c) 2014 zouxu. All rights reserved.
//

//@property(nonatomic, strong)NSString<SocketProxyCB>* strIgnore;
//#import "CommonX.h"
#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "XDBaseItem.h"
#import "UtilOC.h"
#import "CommonXDefine.h"

@interface DBSqlBase1 : XDBaseItem
@property(nonatomic, strong)NSString* Str1;
@property(nonatomic, assign)double  Rea1;
@property(nonatomic, assign)NSNumber*  Num222;
@end
@implementation DBSqlBase1
@end

@interface DBSqlBase12 : DBSqlBase1
@property(nonatomic, strong)NSString* Str12;
@property(nonatomic, strong)NSString* str43;
-(BOOL)compare:(DBSqlBase12*)item;
@end

@implementation DBSqlBase12
XDB_ENABLE
XDB_NAME(@"tableName")
XDB_ATTR_INDEX((@{@"DBId":@"PRIMARY KEY AUTOINCREMENT NOT NULL",@"Num222":@"DEFAULT -2"}),(@[@"'Rea1' ASC, 'Str12' ASC"]))
XDB_EXCLUDE_COLUME((@[@"Str12"]))

//XDB_ATTR((@{@"DBId":@"PRIMARY KEY AUTOINCREMENT NOT NULL",@"Num222":@"DEFAULT -2"}))
//XDB_INDEX((@[@"'Rea1' ASC, 'Str12' ASC"]))
//+ (NSString*)tableName{
//    return @"tableABC123";
//}
//+ (NSDictionary*)tableAttr{
//    return @{@"DBId":@"PRIMARY KEY AUTOINCREMENT NOT NULL",@"Num222":@"DEFAULT -2"};   // return @{@"Str12":@"PRIMARY KEY",@"Num222":@"DEFAULT -2"};
//}
//+ (NSArray*)tableIndex{
//    return @[@"'Rea1' ASC, 'Str12' ASC"];
//}
-(BOOL)compare:(DBSqlBase12*)item{
    if([self.Str12 isEqualToString:item.Str12] &&
       [self.Str1 isEqualToString:item.Str1] &&
       self.Rea1 == item.Rea1 )
        return YES;
    return NO;
}
@end

DBSqlBase12* NewBase12(){
    DBSqlBase12* item = [DBSqlBase12 new];
    item.Str1=@"str11111111";
    item.Rea1=0.456789;
    item.Num222 = @(999);
    item.Str12=@"str122222";
    return item;
}


@interface XDBTest : XCTestCase
@end

@implementation XDBTest

-(void)testXDBMethod{
    
    NSString* absPath = [UtilOC  mkDocABS:@"zxDB.sqlite"];
    [UtilOC fileDeleteABS:absPath];
    
    XDB* xdb =  [XDB dbPath:absPath pwd:nil];
    [xdb createTable:[DBSqlBase12 class]];
    
    DBSqlBase12* item = NewBase12();
    
    [xdb addObject:item];
    
    NSArray* array = [DBSqlBase12 objectsInDb:xdb sql: [NSString stringWithFormat:@"select * from %@", [DBSqlBase12 tableName]]];
    NSLog(@"arrayCount SQL: %lu",  array.count);
    
    NSArray* allArray =  [DBSqlBase12 objectsInDb:xdb where:nil];
    NSLog(@"arrayCount All: %lu",  allArray.count);
    
    int count = [DBSqlBase12  countInDb:xdb where:nil];
    NSLog(@"arrayCount count: %d", count);
    
    tstart(1);
    [xdb TransactionBlock:^(XDB *xdb, BOOL *rollback){
        for (int i=0; i<100000; i++) {
            [xdb addObject:item];
            [xdb addObject:item];
            [xdb addObjects:@[item]];
        }
    }];
    tend(1);
    NSLog(@"off: %f", toff(1, 1));
    
    count = [DBSqlBase12  countInDb:xdb where:nil];
    NSLog(@"arrayCount count: %d", count);
    NSLog(@"arrayCount count: %d", count);
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(NSMutableArray* )Compare:(BOOL)defaultFuncation msgItem:(int)msgItem{
    
    int KInsertItem =msgItem;
    
    DBSqlBase12* item = NewBase12();
    
    
    NSString* absPath = [UtilOC  mkDocABS:@"dataItemDB4.sqlite"];
   // absPath = nil;
    if(defaultFuncation)
        absPath = [UtilOC  mkDocABS:@"defaultDB4.sqlite"];
    if(absPath)
    [UtilOC fileDeleteABS:absPath];
    
    
    NSArray* sqls = @[[DBSqlBase12 createTableSQL],[DBSqlBase12 createIndexSqls][0]];
 
    
    XDB* dbWapper =  [XDB dbPath:absPath pwd:nil];
    [dbWapper Database:kTransaction_DontUse
                 query:NO
              callback:^(FMDatabase *db, BOOL *rollback){
                  for( NSString* sql in sqls){
                      [db executeUpdate:sql];
                  }
              }];
    
    
    double insertStartTime =[[NSDate date]timeIntervalSince1970];
    if(defaultFuncation){
        [dbWapper Database:kTransaction_exclusive
                     query:NO
                  callback:^(FMDatabase *db, BOOL *rollback){
                      for (int i=0; i<KInsertItem; i++) {
//                          if(defaultFuncation){
                              [db executeUpdate:[DBSqlBase12 sqlInsert],item.Str1, @(item.Rea1),item.Num222,  item.Str12 ];
//                          }else{
//                              [db executeUpdate:[DBSqlBase12 sqlInsert]  withDataItem:item];
//                          }
                      }
                  }];
    }else{
        [dbWapper TransactionBlock:^(XDB *xdb, BOOL *rollback){
            for (int i=0; i<KInsertItem; i++) {
                [xdb addObject:item];
            }
        }];
        
    }

    double insertEndTime =[[NSDate date]timeIntervalSince1970];
    double insertTakedTime = insertEndTime - insertStartTime;
    NSLog(@"insertTakedTime: %f ", insertTakedTime);
    
    
    NSMutableArray* itemArray =  [NSMutableArray new];
    
    double selectStartTime =[[NSDate date]timeIntervalSince1970];
     if(defaultFuncation){
    [dbWapper Database:kTransaction_exclusive
                 query:NO
              callback:^(FMDatabase *db, BOOL *rollback){
                  
                  NSString* sql = [NSString stringWithFormat:@"SELECT * FROM %@",[DBSqlBase12 tableName] ];
                  FMResultSet* rs = [db executeQuery:sql];
                  while ([rs next]) {
                          DBSqlBase12* item =[DBSqlBase12 new];
                           [rs intForColumn:@"DBId"];
                      item.Str1=[rs stringForColumn:@"Str1"];
                      item.Rea1=[rs doubleForColumn:@"Rea1"];
                      item.Num222=@([rs intForColumn:@"Num222"]);
                          item.Str12=[rs stringForColumn:@"Str12"];
                          
                          [itemArray addObject:item ];
                  }
                  [rs close];
              }];
     }else{
         itemArray =  [DBSqlBase12 objectsInDb:dbWapper  where:nil];
     }
    
    double selectEndTime =[[NSDate date]timeIntervalSince1970];
    double selectTakedTime = selectEndTime - selectStartTime;
    NSLog(@"selectTakedTime: %f , %lu", selectTakedTime, (unsigned long)itemArray.count);
    
//    [dbWapper close];
    
    return itemArray;
}

-(void)testFMDBDataItem{
    
    
    // id objectValue = [self objectForColumnIndex:columnIdx];
    
    int KInsertItem =1000;
    NSLog(@"default");
    NSLog(@"myDataItem");
    NSMutableArray*array2 = [self Compare:NO msgItem:KInsertItem];
    NSMutableArray*array1 = [self Compare:YES msgItem:KInsertItem];
    
    for (int i=0; i<KInsertItem; i++) {
        DBSqlBase12* item1 =array1[i] ;
        DBSqlBase12* item2 =array2[i] ;
        
        if(![item1 compare:item2])
             NSLog(@"errror DB");
    }
    NSLog(@"testFMDBDataItem OK");
}

-(void)testFMDBCreateSQL{
    
    NSLog(@"sql12: %@", [DBSqlBase12 createTableSQL]);
    NSLog(@"sql1: %@", [DBSqlBase1 createTableSQL]);
    
//    DBSqlIndexItem* indexItem =SQL_INDEX(@"Str12",kSqlIndex_NA);
//    NSArray* attArray =@[indexItem];
    
    NSLog(@"createTable: %@", [DBSqlBase12 createIndexSqls][0]);
    
    NSLog(@"sql1: %@", [DBSqlBase1 createTableSQL]);
    
}


-(void)testDBOverride{
    NSLog(@"2: %@",   [DBSqlBase12 tableItemName]);
    NSLog(@"1: %@",   [DBSqlBase1 tableItemName]);
}





@end




