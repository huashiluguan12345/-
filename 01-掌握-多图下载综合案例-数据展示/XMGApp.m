//
//  XMGApp.m
//  01-掌握-多图下载综合案例-数据展示
//
//  Created by xiaomage on 16/6/20.
//  Copyright © 2016年 小码哥. All rights reserved.
//

#import "XMGApp.h"

@implementation XMGApp

+(instancetype)appWithDict:(NSDictionary *)dict
{
    XMGApp *appM = [[XMGApp alloc]init];
    //appM.name = dict[@"name"];
    //KVC
    [appM setValuesForKeysWithDictionary:dict];
    return appM;
}
@end
