//
//  XMGApp.h
//  01-掌握-多图下载综合案例-数据展示
//
//  Created by xiaomage on 16/6/20.
//  Copyright © 2016年 小码哥. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMGApp : NSObject

/** 名称 */
@property (nonatomic ,strong) NSString *name;
@property (nonatomic ,strong) NSString *icon;
@property (nonatomic ,strong) NSString *download;

+(instancetype)appWithDict:(NSDictionary *)dict;
@end
