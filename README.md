# XDB

给懒人的小玩意
哪位朋友使用这个软件。麻烦告诉一声。谢谢
希望些代码值得你细细品味。哈哈


//
//  Facade.m
//  eContact
//
//  Created by zouxu on 14/6/14.
//  Copyright (c) 2014 zouxu. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "XDB.h"
#import "NSObject+XDB.h"
#import "UtilOC.h"

#define tstart(num) double _tStartTime##num =[[NSDate date]timeIntervalSince1970]
#define tend(num) double _tEndTime##num =[[NSDate date]timeIntervalSince1970]
#define toff(ss, ee) (_tEndTime##ee - _tStartTime##ss)

@interface DBSqlBase1 : NSObject
@property(nonatomic, strong)NSString* Str1;
@property(nonatomic, assign)double  Rea1;
@property(nonatomic, assign)int  Num111;
@property(nonatomic, assign)NSNumber*  Num222;
@end
@implementation DBSqlBase1
@end

@interface DBSqlBase12 : DBSqlBase1<XDB_protocol>
@property(nonatomic, strong)NSString* Str12;
@property(nonatomic, strong)NSString* str43;
-(BOOL)compare:(DBSqlBase12*)item;
@end

@implementation DBSqlBase12

//////////////////////////////////
//////// DB //////////////////////
XDB_ENABLE
XDB_NAME(@"tableName")
//XDB_ATTR_INDEX((@{@"DBId":@"PRIMARY KEY AUTOINCREMENT NOT NULL",@"Num222":@"DEFAULT -2"}),(@[@"'Rea1' ASC, 'Str12' ASC"]))
//XDB_ATTR_INDEX((@{@"Str12":@"PRIMARY KEY",@"Num222":@"DEFAULT 100"}),(@[@"'Rea1' ASC, 'Num222' ASC"]))
XDB_ATTR_INDEX((@{@"Num222":@"DEFAULT 100"}),(@[@"'Rea1' ASC, 'Num222' ASC"]))
XDB_EXCLUDE_COLUMN((@[@"str43"]))
XDB_EXTRA_COLUMN(@[SQLTableInfo(@"extra", kAttSqlType_INTEGER)])

-(BOOL)compare:(DBSqlBase12*)item{
if([self.Str12 isEqualToString:item.Str12] &&
[self.Str1 isEqualToString:item.Str1] &&
self.Rea1 == item.Rea1 )//&& self.DBId == self.DBId
return YES;
return NO;
}
@end

static int kNum = 0;
#define ITEM NewBase12()

DBSqlBase12* NewBase12(){
kNum++;
DBSqlBase12* item = [DBSqlBase12 new];
item.Str1=@"str1";
item.Rea1=0.123;
item.Num111=kNum;
item.Num222 = @(kNum);
item.Str12= [NSString stringWithFormat:@"str12_%d", kNum ];
return item;
}


@interface AXDBTest : XCTestCase
@end

@implementation AXDBTest


-(XDB*)InitDb:(NSString*)dbName c:(Class)c{
NSString* absPath = [UtilOC  mkDocABS:dbName];
[UtilOC fileDeleteABS:absPath];

XDB* xdb =  [XDB dbPath:absPath pwd:nil];
[xdb createTable:c];
[xdb createIndex:c];
return xdb;
}

-(void)testXDB_Updata{
//sqlUpdataByDbId
XDB* xdb = [self InitDb:@"zxDB.sqlite" c:[DBSqlBase12 class]];
DBSqlBase12* item =ITEM;
[xdb addObject:item];
item.Num111 = 2;
[xdb updataObject:item];
[DBSqlBase12 updateInDb:xdb data:@{@"Num111":@99999} where:@"Str1 = ?",item.Str1];
NSArray* array = [DBSqlBase12 objectsInDb:xdb sql: [NSString stringWithFormat:@"select * from %@", [DBSqlBase12 tableName]]];

XCTAssert(array.count == 1 , @"array Must Be 1" );
DBSqlBase12* item122 =array[0];
XCTAssert(item122.Num111 == 99999 , @"item Must Be 1000" );

[xdb executeUpdate:@"update tableName set Num111 = ?",@21];
int number = [xdb intWithSql:@"select Num111 from tableName"];
XCTAssert(number == 21);

[DBSqlBase12 updateInDb:xdb data:@{@"extra":@99} where:@"Num111 = ?",@21];

id object = [DBSqlBase12 value:@"extra" InDb:xdb where:@"Num111 = ?",@21];

XCTAssert([object integerValue] == 99);
}

-(void)testXDB_SetGet{
XDB* xdb = [self InitDb:@"zxDB.sqlite" c:[DBSqlBase12 class]];

[xdb addObject:ITEM];
for (int i=0; i<100; i++){
DBSqlBase12* item =ITEM;
[xdb addObject:item];
[xdb removeObject:item];
}
DBSqlBase12* item =nil;
for (int i=0; i<10; i++){
item =ITEM;
[xdb addObject:item];
}
NSArray* array = [DBSqlBase12 objectsInDb:xdb sql: [NSString stringWithFormat:@"select * from %@", [DBSqlBase12 tableName]]];
NSLog(@"arrayCount SQL: %lu,  dbId: %llu",  array.count, item.DBId);
}


-(void)testXDB_Method{
kNum=0;
NSString* absPath = [UtilOC  mkDocABS:@"zxDB.sqlite"];
[UtilOC fileDeleteABS:absPath];

XDB* xdb =  [XDB dbPath:absPath pwd:nil];
[xdb createTable:[DBSqlBase12 class]]; 

//    DBSqlBase12* item = NewBase12();

[xdb addObject:ITEM];

NSArray* array = [DBSqlBase12 objectsInDb:xdb sql: [NSString stringWithFormat:@"select * from %@", [DBSqlBase12 tableName]]];
NSLog(@"arrayCount SQL: %lu",  array.count);

NSArray* allArray =  [DBSqlBase12 objectsInDb:xdb where:nil];
NSLog(@"arrayCount All: %lu",  allArray.count);

int count = [DBSqlBase12  countInDb:xdb where:nil];
NSLog(@"arrayCount count: %d", count);

//[xdb addObjects:@[ITEM]];

tstart(1);
[xdb transactionBlock:^(FMDatabase *db, BOOL *rollback){
for (int i=0; i<10000; i++) {
[xdb addObject:ITEM];
[xdb addObject:ITEM];
[xdb addObjects:@[ITEM]];
}
}];
tend(1);
NSLog(@"off: %f", toff(1, 1));

NSArray*   itemArray =  [DBSqlBase12 objectsInDb:xdb  where:nil];
count = [DBSqlBase12  countInDb:xdb where:nil];
NSLog(@"arrayCount count: %d", count);
NSLog(@"arrayCount count: %d", count);
NSLog(@"arrayCount count: %lu", (unsigned long)itemArray.count);
}

-(void)testXDB_CompareWithFMDB{
int KInsertItem =100000;
NSLog(@"default");
NSLog(@"myDataItem");

tstart(2);
NSMutableArray*array1 = [self Compare:YES msgItem:KInsertItem];
tend(2);
NSLog(@"FMDBSetGet: %f", toff(2, 2));

tstart(1);
NSMutableArray*array2 = [self Compare:NO msgItem:KInsertItem];
tend(1);
NSLog(@"XDBSetGet: %f", toff(1, 1));

for (int i=0; i<KInsertItem; i++) {
DBSqlBase12* defautlItem =array1[i];
DBSqlBase12* dbDbItem =array2[i];

if(![defautlItem compare:dbDbItem])
NSLog(@"errror DB");
}
NSLog(@"testFMDBDataItem OK");
}

-(NSMutableArray* )Compare:(BOOL)defaultFuncation msgItem:(int)msgItem{

int KInsertItem =msgItem;

kNum =0 ;


NSString* absPath = [UtilOC  mkDocABS:@"xDBitemDB4.sqlite"];
if(defaultFuncation)
absPath = [UtilOC  mkDocABS:@"defaultDB4.sqlite"];
if(absPath)
[UtilOC fileDeleteABS:absPath];


NSArray* sqls = @[[DBSqlBase12 createTableSQL],[DBSqlBase12 createIndexSqls][0]];


XDB* dbWapper =  [XDB dbPath:absPath pwd:nil];
BOOL sucTableIndex= [dbWapper Database:kTransaction_DontUse
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
DBSqlBase12* item = ITEM;
[db executeUpdate:@"INSERT OR IGNORE INTO tableName( Str1,Rea1,Num111,Num222,Str12)VALUES(?,?,?,?,?)", item.Str1, @(item.Rea1),@(item.Num111),item.Num222,  item.Str12 ];
}
}];
}else{
[dbWapper transactionBlock:^(FMDatabase *db, BOOL *rollback){
for (int i=0; i<KInsertItem; i++) {
DBSqlBase12* item = ITEM;
[dbWapper addObject:item];
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
//item.DBId =[rs intForColumn:@"DBId"];
item.Str1=[rs stringForColumn:@"Str1"];
item.Rea1=[rs doubleForColumn:@"Rea1"];
item.Num222=@([rs intForColumn:@"Num222"]);
item.Num111 = [rs intForColumn:@"Num111"];
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

return itemArray;
}


-(void)testDBOverride{
//    NSLog(@"2: %@",   [DBSqlBase12 tableItemName]);
//    NSLog(@"1: %@",   [DBSqlBase1 tableItemName]);
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

@end

