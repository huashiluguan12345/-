//
//  ViewController.m
//  01-掌握-多图下载综合案例-数据展示
//
//  Created by xiaomage on 16/6/20.
//  Copyright © 2016年 小码哥. All rights reserved.
//

#import "ViewController.h"
#import "XMGApp.h"

@interface ViewController ()
@property (nonatomic, strong) NSArray *apps;
@property (nonatomic, strong) NSMutableDictionary *operations;
@property (nonatomic, strong) NSMutableDictionary *images;
/** 队列 */
@property (nonatomic ,strong) NSOperationQueue *queue;
@end

@implementation ViewController

-(NSMutableDictionary *)operations
{
    if (_operations == nil) {
        _operations = [NSMutableDictionary dictionary];
    }
    return _operations;
}

-(NSOperationQueue *)queue
{
    if (_queue == nil) {
        _queue = [[NSOperationQueue alloc]init];
        
    }
    return _queue;
}
-(NSMutableDictionary *)images
{
    if (_images == nil) {
        _images = [NSMutableDictionary dictionary];
    }
    return _images;
}

-(NSArray *)apps
{
    if (_apps == nil) {
        NSArray *arrayM = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"apps.plist" ofType:nil]];
        
        //字典数组--->模型数组
        NSMutableArray *array = [NSMutableArray array];
        for (NSDictionary *dict in arrayM) {
            [array addObject:[XMGApp appWithDict:dict]];
        }
        _apps = array;
    }
    
    return _apps;
}

#pragma mark UITabelViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.apps.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //1.创建cell
    static NSString *ID = @"app";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    //2.设置cell
    //2.0 得到该行cell对应的数据
    XMGApp *appM = self.apps[indexPath.row];
    //2.1 设置标题
    cell.textLabel.text = appM.name;
    //2.2 设置子标题
    cell.detailTextLabel.text = appM.download;
    
    //2.3 设置图标
    
    //内存缓存的处理思路
    //1)当图片下载完成之后,除了显示之外,还要保存一份
    //2)当图片需要展示的时候,先检查之前是否已经下载过,如果已经下载过了,那么就直接用,否则那么下载
    //字典|数组
    
    UIImage *image = [self.images objectForKey:appM.icon];
    if (image) {
         cell.imageView.image = image;
        NSLog(@"第%zd行cell对应的图片使用了内存缓存",indexPath.row);
    }else
    {
         //磁盘缓存的处理思路
         //1)当图片下载完成之后,除了保存一份到内存缓存中之外,还要保存一份到沙盒里面
         //2)查看是否有磁盘缓存,如果有那么直接使用磁盘缓存,保存一份到内存中
        
        //得到caches路径
        NSString *caches= [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        //文件名称
        NSString *fileName = [appM.icon lastPathComponent];
        
        //拼接文件的全路径
        NSString *fullPath = [caches stringByAppendingPathComponent:fileName];

        
        //尝试查看是否有磁盘缓存
        NSData *data = [NSData dataWithContentsOfFile:fullPath];
        
        //废弃磁盘缓存
//        data = nil;
//        磁盘缓存中是否有
        if (data) {
            UIImage *image = [UIImage imageWithData:data];
            cell.imageView.image = image;
            
            //保存一份到内存中
            [self.images setObject:image forKey:appM.icon];
            
            NSLog(@"第%zd行对应的图片从磁盘中加载",indexPath.row);
        }else
        {
            
            //清空
            //cell.imageView.image = nil;
            //设置占位图片
            cell.imageView.image = [UIImage imageNamed:@"Snip20160621_9"];
            
            //先检查该图片的下载操作是否存在
            NSBlockOperation *download = [self.operations objectForKey:appM.icon];
            if (download) {
                //等待
                NSLog(@"%zd行cell对应的图片下载操作已经存在,请稍等....",indexPath.row);
            }else
            {
                //封装图片的下载操作
                download = [NSBlockOperation blockOperationWithBlock:^{
                    NSURL *url = [NSURL URLWithString:appM.icon];
                    
                    //模拟网速很慢的情况
                    for (int i = 0; i < 1000000000; ++i) {
                        
                    }
                    NSData *imageData = [NSData dataWithContentsOfURL:url];
                    UIImage *image = [UIImage imageWithData:imageData];
                    
                    //容错性处理
                    if (image == nil) {
                        [self.operations removeObjectForKey:appM.icon];
                        return ;
                    }
                    
                    //保存一份到内存中
                    [self.images setObject:image forKey:appM.icon];
                    
                    //保存图片到磁盘
                    [imageData writeToFile:fullPath atomically:YES];
                    
                    //回到主线程设置图片
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        //cell.imageView.image = image;
                        
                        //[tableView reloadData];//刷新整个tableView
                        //刷新指定的行
                        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                    }];
                    NSLog(@"下载并显示第%zd行对应的图片",indexPath.row);
                }];
                
                //把操作保存到操作缓存中
                [self.operations setObject:download forKey:appM.icon];
                
                //添加操作到队列
                [self.queue addOperation:download];
            }
            
        }
    }
    //3.返回cell
    return cell;
}

-(void)didReceiveMemoryWarning
{
    //当发生内存警告的时候手动的清理内存缓存
    [self.images removeAllObjects];  //1000M
    
    //取消所有的操作
    [self.queue cancelAllOperations];
}
/*
 问题1:UI卡顿(原因:所有的下载操作都在主线程中处理)-->开子线程下载图片
 问题2:图片重复下载(用户上下滚动)-->内存缓存--->优化(磁盘缓存)
 问题3:当网速很慢的时候,图片的下载操作会被添加到队列中多次
    当内存缓存和磁盘缓存中图片都不存在的时候,先检查该图片的下载操作是否存在,如果存在那么等待即可,如果图片下载操作不存在,那么这个时候再封装操作去下载该图片--->操作缓存
 问题4:数据显示错乱  -----    先清空cell的图片或者是设置占位图片(建议)
 问题5:url不正确等数据问题--- 下载完图片之后先判断图片是否有值,如果没有值,那么就直接返回|从操作缓存中删除
 */
/*
 Documents  缓存文件不能写在这个文件路径(规定)
 Library
    caches     缓存文件
    preference 偏好设置
 Tmp    临时路径(随时可能被删除)
 */
@end
