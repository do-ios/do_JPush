//
//  do_JPush_SM.m
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_JPush_SM.h"

#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"
#import "JPUSHService.h"
#import "UIKit/UIKit.h"
#import "doJsonHelper.h"
#import "doIOHelper.h"
#import "doIPage.h"
#import "doServiceContainer.h"
#import "doLogEngine.h"
@implementation do_JPush_SM
{
    id<doIScriptEngine> _scritEngine;
    NSString *_callbackName;
}
- (instancetype)init
{
    if (self = [super init]) {
        [self onObserveAllNotifications];
    }
    return self;
}
- (void)dealloc
{
    [self unObserveAllNotifications];
}
#pragma mark - 方法
#pragma mark - 同步异步方法的实现
//同步
- (void)getIconBadgeNumber:(NSArray *)parms
{
    //自己的代码实现
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    //_invokeResult设置返回值
    NSInteger quantity = [UIApplication sharedApplication].applicationIconBadgeNumber;
    [_invokeResult SetResultInteger:(int)quantity];
}
- (void)getRegistrationID:(NSArray *)parms
{
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    if ([JPUSHService registrationID]) {
        [_invokeResult SetResultText:[JPUSHService registrationID]];
    }
}
- (void)resumePush:(NSArray *)parms
{
    
}
- (void)setIconBadgeNumber:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    NSInteger quantity = [[_dictParas objectForKey:@"quantity"] integerValue];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:quantity];
    [JPUSHService setBadge:quantity];
    
}
- (void)stopPush:(NSArray *)parms
{
    
}

- (void)setRinging:(NSArray *)parms {
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    _scritEngine = [parms objectAtIndex:1];
    NSString *ringName = [doJsonHelper GetOneText:_dictParas :@"ringing" :@""];
    
    NSString *path = @"";
    NSString *fileName = @"";
    if (ringName.length>0&&[ringName hasPrefix:@"data://"]) {
        path = [doIOHelper GetLocalFileFullPath:_scritEngine.CurrentPage.CurrentApp :ringName];
        fileName = [path lastPathComponent];
        if (fileName.length>0&&![fileName hasSuffix:@"/"]) {
            NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES) firstObject];
            NSString *name = [NSString stringWithFormat:@"%@/Sounds",libraryPath];
            if (![doIOHelper ExistDirectory:name]) {
                [doIOHelper CreateDirectory:name];
            }
            NSString *targetFile = [NSString stringWithFormat:@"%@/Sounds/%@",libraryPath,fileName];
            [doIOHelper FileCopy:path :targetFile];
        }
        if (fileName.length>0) {
            NSString *extension = [fileName pathExtension];
            if (!([extension isEqualToString:@"m4a"] || [extension isEqualToString:@"wav"] || [extension isEqualToString:@"caf"] || [extension isEqualToString:@"aiff"])) {
                [[doServiceContainer Instance].LogEngine WriteError:nil:@"iOS仅支持m4a、wav、caf和aiff格式音频"];
            }
        }else {
            [[doServiceContainer Instance].LogEngine WriteError:nil:@"文件名不能为空"];
        }
    }else {
        [[doServiceContainer Instance].LogEngine WriteError:nil:@"仅支持data目录"];
    }
}

//异步

- (void)setTags:(NSArray *)parms
{
    //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    
    _callbackName = [parms objectAtIndex:2];
    //回调函数名_callbackName
    //_invokeResult设置返回值
    NSArray *tagArray = [doJsonHelper GetOneArray:_dictParas :@"tag"];
    NSSet *tagSet = [NSSet setWithArray:tagArray];
    [JPUSHService setTags:tagSet callbackSelector:@selector(tagsAliasCallback:tags:alias:) object:self];
}
- (void)tagsAliasCallback:(int)iResCode tags:(NSSet*)tags alias:(NSString*)alias
{
    doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
    if (iResCode == 0) {
        [_invokeResult SetResultBoolean:YES];
    }
    else{
        [_invokeResult SetResultBoolean:NO];
    }
    [_scritEngine Callback:_callbackName :_invokeResult];
}
- (void)setAlias:(NSArray *)parms
{
    //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    
    _callbackName = [parms objectAtIndex:2];
    NSString *alias = [doJsonHelper GetOneText:_dictParas :@"alias" :@""];
    [JPUSHService setAlias:alias callbackSelector:@selector(tagsAliasCallback:tags:alias:) object:self];
    
}

- (void)onObserveAllNotifications
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(networkDidSetup:)
                          name:kJPFNetworkDidSetupNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(networkDidClose:)
                          name:kJPFNetworkDidCloseNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(networkDidRegister:)
                          name:kJPFNetworkDidRegisterNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(networkDidLogin:)
                          name:kJPFNetworkDidLoginNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(networkDidReceiveMessage:)
                          name:kJPFNetworkDidReceiveMessageNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(serviceError:)
                          name:kJPFServiceErrorNotification
                        object:nil];
}
- (void)unObserveAllNotifications
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self
                             name:kJPFNetworkDidSetupNotification
                           object:nil];
    [defaultCenter removeObserver:self
                             name:kJPFNetworkDidCloseNotification
                           object:nil];
    [defaultCenter removeObserver:self
                             name:kJPFNetworkDidRegisterNotification
                           object:nil];
    [defaultCenter removeObserver:self
                             name:kJPFNetworkDidLoginNotification
                           object:nil];
    [defaultCenter removeObserver:self
                             name:kJPFNetworkDidReceiveMessageNotification
                           object:nil];
    [defaultCenter removeObserver:self
                             name:kJPFServiceErrorNotification
                           object:nil];
}

- (void)networkDidSetup:(NSNotification *)notification {
    NSLog(@"已连接");
    [self.EventCenter FireEvent:@"didConnect" :nil];
}

- (void)networkDidClose:(NSNotification *)notification {
    NSLog(@"未连接");
    [self.EventCenter FireEvent:@"didClose" :nil];
}

- (void)networkDidRegister:(NSNotification *)notification {
    NSLog(@"%@", [notification userInfo]);
    NSLog(@"已注册");
}

- (void)networkDidLogin:(NSNotification *)notification {
    NSLog(@"已登录");
    
    if ([JPUSHService registrationID]) {
        doInvokeResult *invokeResult = [[doInvokeResult alloc]init];
        NSMutableDictionary *node = [NSMutableDictionary dictionary];
        [node setObject:[JPUSHService registrationID] forKey:@"registrationID"];
        [invokeResult SetResultNode:node];
        [self.EventCenter FireEvent:@"didLogin" :invokeResult];
    }
}

- (void)networkDidReceiveMessage:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSString *content = [userInfo valueForKey:@"content"];
    NSDictionary *extra = [userInfo valueForKey:@"extras"];
    NSMutableDictionary *customDict = [NSMutableDictionary dictionary];
    NSString *customContent = @"";
    if (extra) {
        customContent = [doJsonHelper ExportToText:extra :NO];
    }
    [customDict setObject:content forKey:@"content"];
    [customDict setObject:customContent forKey:@"extra"];
    doInvokeResult *invokeResult = [[doInvokeResult alloc]init];
    [invokeResult SetResultNode:customDict];
    [self.EventCenter FireEvent:@"customMessage" :invokeResult];
    
}

- (NSString *)logDic:(NSDictionary *)dic {
    if (![dic count]) {
        return nil;
    }
    NSString *tempStr1 =
    [[dic description] stringByReplacingOccurrencesOfString:@"\\u"
                                                 withString:@"\\U"];
    NSString *tempStr2 =
    [tempStr1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *tempStr3 =
    [[@"\"" stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
    NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    NSString *str =
    [NSPropertyListSerialization propertyListFromData:tempData
                                     mutabilityOption:NSPropertyListImmutable
                                               format:NULL
                                     errorDescription:NULL];
    return str;
}

- (void)serviceError:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSString *error = [userInfo valueForKey:@"error"];
    NSLog(@"%@", error);
}
@end
