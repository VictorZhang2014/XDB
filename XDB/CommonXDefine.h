


#define RGB(colorRgb,__a)  [UIColor colorWithRed:((colorRgb & 0xFF0000) >> 16)/255.0 green:((colorRgb & 0xFF00) >> 8)/255.0 blue:((colorRgb & 0xFF)/255.0) alpha:__a]


//STR(abc);//NSLog(@"text: %@", K_abc);
#define KSTR(str)  static NSString* const K_##str=@#str;
#define STR(str)   static NSString* const str=@#str;
//General util keyword
STR(Notify_ApplicationIconNumber);//NSNumber


//current time
#define CURTIME  [UtilOC GetCurTime]


//for performance test
//tstart(1);
//tend(1);
//NSLog(@"off: %f", toff(1, 1));
#define tstart(num) double _tStartTime##num =[[NSDate date]timeIntervalSince1970]
#define tend(num) double _tEndTime##num =[[NSDate date]timeIntervalSince1970]
#define toff(ss, ee) (_tEndTime##ee - _tStartTime##ss)















