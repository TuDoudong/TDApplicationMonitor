//
//  TDPerformanceMonitor.m
//  TDApplicationMonitor
//
//  Created by TudouDong on 16/7/21.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import "TDPerformanceMonitor.h"

#import <CrashReporter/CrashReporter.h>
@interface TDPerformanceMonitor ()

{
    CFRunLoopObserverRef observer;
    NSMutableArray *fibobacciItems;
    NSInteger timeoutCount;
@public
    dispatch_semaphore_t semaphore;
    CFRunLoopActivity activity;
}

@end

@implementation TDPerformanceMonitor

+(instancetype)shareInstance{
    static id instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    return instance;
    
}

- (instancetype)init{
    if (self = [super init]) {
        fibobacciItems = [NSMutableArray arrayWithObjects:@2,@3, nil];
        for (NSInteger i = 1; i < fibobacciItems.count; i++) {
            NSInteger fib1 = [fibobacciItems[i] integerValue];
            NSInteger fib2 = [fibobacciItems[i-1] integerValue];
            if (fib1 + fib2 > UINT16_MAX) {
                break;
            }
            [fibobacciItems addObject:@(fib1+fib2)];
        }
        
        timeoutCount = 0;
        
    }
    return self;
}

static void monitorRunLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    
    TDPerformanceMonitor *monitor = (__bridge TDPerformanceMonitor *)(info);
    monitor ->activity = activity;
    
    dispatch_semaphore_t semaphore = monitor -> semaphore;
    dispatch_semaphore_signal(semaphore);
    
}

- (void)startMonitor{
    
    if (observer) {
        return;
    }
    
    semaphore = dispatch_semaphore_create(0);
    
    CFRunLoopObserverContext context = {0,(__bridge void*)self,NULL,NULL};
    observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &monitorRunLoopObserverCallBack, &context);
    
    CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (YES) {
            
            NSNumber *fibonacciItem = fibobacciItems[timeoutCount];
            
            
            long slot =  dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(fibonacciItem.doubleValue * NSEC_PER_SEC)));
            if (slot != 0) {
                if (!observer)
                {
                    timeoutCount = 0;
                    semaphore = 0;
                    activity = 0;
                    return;
                }
                
                if (activity == kCFRunLoopBeforeSources || activity == kCFRunLoopAfterWaiting)
                {
                    timeoutCount ++;
                    [NSThread sleepForTimeInterval:fibonacciItem.doubleValue];
                    @autoreleasepool {
                        
                        [self dumpPerformanceData];
                        
                    }
                    
                }
                
            }else{
                timeoutCount = 0;
            }
            
        }
        
    });
    
}


- (void)stopMonior
{
    if (!observer)
        return;
    
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
    CFRelease(observer);
    observer = NULL;
}


- (void)dumpPerformanceData{
    
    PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeBSD
                                                                       symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll];
    PLCrashReporter *crashReporter = [[PLCrashReporter alloc] initWithConfiguration:config];
    
    NSData *data = [crashReporter generateLiveReport];
    PLCrashReport *reporter = [[PLCrashReport alloc] initWithData:data error:NULL];
    NSString *report = [PLCrashReportTextFormatter stringValueForCrashReport:reporter
                                                              withTextFormat:PLCrashReportTextFormatiOS];
    NSLog(@"------report------:%@",report);
    
}


@end
