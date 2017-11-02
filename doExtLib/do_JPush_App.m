//
//  do_JPush_App.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_JPush_App.h"
#import "JPUSHService.h"
#import "doServiceContainer.h"
#import "doIModuleExtManage.h"
#import "do_JPush_SM.h"
#import "doScriptEngineHelper.h"
#import "doJsonHelper.h"
#import "doServiceContainer.h"
#import "doIAppSecurity.h"

static do_JPush_App* instance;
@implementation do_JPush_App
@synthesize OpenURLScheme;
+(id) Instance
{
    if(instance==nil)
        instance = [[do_JPush_App alloc]init];
    return instance;
}
- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //注册推送
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        //可以添加自定义categories
        [JPUSHService registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                          UIUserNotificationTypeSound |
                                                          UIUserNotificationTypeAlert)
                                              categories:nil];
    } else {
        //categories 必须为nil
        [JPUSHService registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                          UIRemoteNotificationTypeSound |
                                                          UIRemoteNotificationTypeAlert)
                                              categories:nil];
    }
    NSString *appKey = [[doServiceContainer Instance].ModuleExtManage GetThirdAppKey:@"do_JPush.plist" :@"JPushAppKey"];
    //初始化
    id<doIAppSecurity> appInfo = [doServiceContainer Instance].AppSecurity;
    if ([appInfo.appVersion isEqualToString:@"debug"]) {
        [JPUSHService setupWithOption:launchOptions appKey:appKey channel:@"Publish channel" apsForProduction:NO];
    }
    else
    {
        [JPUSHService setupWithOption:launchOptions appKey:appKey channel:@"Publish channel" apsForProduction:YES];
    }
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        [JPUSHService handleRemoteNotification:userInfo];
        [self fireEvent:userInfo];
    }
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {

}

- (void)applicationWillEnterForeground:(UIApplication *)application {

}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"%@", [NSString stringWithFormat:@"Device Token: %@", deviceToken]);
    [JPUSHService registerDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"did Fail To Register For Remote Notifications With Error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [JPUSHService handleRemoteNotification:userInfo];
    
    NSLog(@"收到通知:%@", [self logDic:userInfo]);

    if (application.applicationState == UIApplicationStateInactive) {
        [self fireEvent:userInfo];
    }
    else if (application.applicationState == UIApplicationStateActive)
    {
        [self fireMessage:userInfo];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [JPUSHService handleRemoteNotification:userInfo];
    
    NSLog(@"收到通知:%@", [self logDic:userInfo]);
    
    if (application.applicationState == UIApplicationStateInactive) {
        [self fireEvent:userInfo];
    }
    else if (application.applicationState == UIApplicationStateActive)
    {
        [self fireMessage:userInfo];
    }
    completionHandler(UIBackgroundFetchResultNewData);
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

//收到推送触发
- (void)fireMessage:(NSDictionary *)messageDict
{
    do_JPush_SM *jpush = (do_JPush_SM*)[doScriptEngineHelper ParseSingletonModule:nil :@"do_JPush" ];
    NSString *message = [[messageDict objectForKey:@"aps"] objectForKey:@"alert"];
    NSMutableDictionary *customDict = [NSMutableDictionary dictionary];
    for (NSString *infoKey in messageDict) {
        if (![infoKey isEqualToString:@"aps"]&&![infoKey isEqualToString:@"_j_msgid"]) {
            [customDict setValue:[messageDict valueForKey:infoKey] forKey:infoKey];
        }
    }
    NSString *customContent = [self getExtraContent:customDict];
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    [resultDict setObject:message forKey:@"content"];
    [resultDict setObject:customContent forKey:@"extra"];
    doInvokeResult *resul = [[doInvokeResult alloc]init:jpush.UniqueKey];
    [resul SetResultNode:resultDict];
    [jpush.EventCenter FireEvent:@"message" :resul];
}
//点击推送触发
- (void)fireEvent:(NSDictionary *)userInfo
{
    UIApplicationState appState = [UIApplication sharedApplication].applicationState;
    if (appState == UIApplicationStateActive) {
        return;
    }
    do_JPush_SM *jpush = (do_JPush_SM*)[doScriptEngineHelper ParseSingletonModule:nil :@"do_JPush" ];
    doInvokeResult *resul = [[doInvokeResult alloc]init];
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    NSString *description = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
    NSString *customContent;
    NSMutableDictionary *customDict = [NSMutableDictionary dictionary];
    for (NSString *infoKey in userInfo) {
        if (![infoKey isEqualToString:@"aps"]&&![infoKey isEqualToString:@"_j_msgid"]) {
            [customDict setValue:[userInfo valueForKey:infoKey] forKey:infoKey];
        }
    }
    customContent = [self getExtraContent:customDict];
    [resultDict setValue:description forKey:@"content"];
    [resultDict setValue:customContent forKey:@"extra"];
    [resul SetResultNode:resultDict];
    [jpush.EventCenter FireEvent:@"messageClicked" :resul];
}
- (NSString *)getExtraContent:(NSDictionary *)dict
{
    NSString *extContent;
    if (dict.allKeys.count >= 1) {
        extContent = [doJsonHelper ExportToText:dict :NO];
    }
    else
    {
        extContent = @"";
    }
    return extContent;
}

@end
