//
//  TDPerformanceMonitor.h
//  TDApplicationMonitor
//
//  Created by TudouDong on 16/7/21.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDPerformanceMonitor : NSObject


+ (instancetype)shareInstance;

- (void)startMonitor;

- (void)stopMonior;

@end
