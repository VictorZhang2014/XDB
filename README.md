# XDB

给懒人的小玩意



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
