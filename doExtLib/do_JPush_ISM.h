//
//  do_JPush_IMethod.h
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol do_JPush_ISM <NSObject>

//实现同步或异步方法，parms中包含了所需用的属性
@required
- (void)getIconBadgeNumber:(NSArray *)parms;
- (void)getRegistrationID:(NSArray *)parms;
- (void)resumePush:(NSArray *)parms;
- (void)setIconBadgeNumber:(NSArray *)parms;
- (void)stopPush:(NSArray *)parms;
- (void)setRinging:(NSArray*)parms;

@end
