//
//  ViewController.m
//  ReactiveCocoaTest
//
//  Created by Corotata on 15/8/24.
//  Copyright (c) 2015年 Corotata. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa.h>

@protocol Programmer <NSObject>
@optional
- (void)makeAnApp;
@end


@interface ViewController ()<Programmer>
@property (nonatomic, copy) NSString *value;
@property (nonatomic, copy) NSString *valueA;
@property (nonatomic, copy) NSString *valueB;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self test11];
    
    
    
}

//条件

- (void)test22{
    [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
            [subscriber sendNext:@"直到世界的尽头才能把我们分开"];
        }];
        return nil;
    }] takeUntil:[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"世界的尽头到了");
            [subscriber sendNext:@"世界的尽头到了"];
        });
        return nil;
    }]] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}


//节流(这个有问题，不易理解)

- (void)test21{
    [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"旅客A"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [subscriber sendNext:@"旅客B"];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [subscriber sendNext:@"旅客C"];
            [subscriber sendNext:@"旅客D"];
            [subscriber sendNext:@"旅客E"];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [subscriber sendNext:@"旅客F"];
        });
        return nil;
    }] throttle:1] subscribeNext:^(id x) {
        NSLog(@"%@通过了",x);
    }];

}


//重试
- (void)test20{
    __block int failedCount = 0;
    [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        if (failedCount < 10000) {
            failedCount++;
            NSLog(@"我失败了");
            [subscriber sendError:nil];
        }else{
            NSLog(@"经历了数百次失败后");
            [subscriber sendNext:nil];
        }
        return nil;
    }] retry] subscribeNext:^(id x) {
        NSLog(@"终于成功了");
    }];

}



//超时

- (void)test19{
    [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            NSLog(@"我快到了");
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
            return nil;
        }] delay:10] subscribeNext:^(id x) {
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
            NSLog(@"我已经在了，你还在不在");
        }];
        return nil;
    }] timeout:5 onScheduler:[RACScheduler mainThreadScheduler]] subscribeError:^(NSError *error) {
        NSLog(@"等了你一个小时了，你还没来，我走了");
    }];
}

//定时
- (void)test18{
    [[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        NSLog(@"吃药");
    }];
}


//重放

- (void)test17{
    RACSignal *replaySignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSLog(@"大导演拍了一部电影《我的男票是程序员》");
        [subscriber sendNext:@"《我的男票是程序员》"];
        return nil;
    }] replay];
    [replaySignal subscribeNext:^(id x) {
        NSLog(@"小明看了%@", x);
    }];
    [replaySignal subscribeNext:^(id x) {
        NSLog(@"小红也看了%@", x);
    }];
    
}


//延迟
- (void)test16{
    [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSLog(@"等等我，我还有10秒钟就到了");
        [subscriber sendNext:nil];
        [subscriber sendCompleted];
        return nil;
    }] delay:10] subscribeNext:^(id x) {
        NSLog(@"我到了");
    }];
}



//命令
- (void)test15{
    RACCommand *aCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            NSLog(@"我投降了");
            [subscriber sendCompleted];
            return nil;
        }];
    }];
    [aCommand execute:nil];

}


//秩序

- (void)test14{
    [[[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSLog(@"打开冰箱门");
        [subscriber sendCompleted];
        return nil;
    }] then:^RACSignal *{
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            NSLog(@"把大象塞进冰箱");
            [subscriber sendCompleted];
            return nil;
        }];
    }] then:^RACSignal *{
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            NSLog(@"关上冰箱门");
            [subscriber sendCompleted];
            return nil;
        }];
    }] subscribeCompleted:^{
        NSLog(@"把大象塞进冰箱了");
    }];

}

//扁平
- (void)test13{
    
    [[[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSLog(@"打蛋液");
        [subscriber sendNext:@"蛋液"];
        [subscriber sendCompleted];
        return nil;
    }] flattenMap:^RACStream *(NSString* value) {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            NSLog(@"把%@倒进锅里面煎",value);
            [subscriber sendNext:@"煎蛋"];
            [subscriber sendCompleted];
            return nil;
        }];
    }] flattenMap:^RACStream *(NSString* value) {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            NSLog(@"把%@装到盘里", value);
            [subscriber sendNext:@"上菜"];
            [subscriber sendCompleted];
            return nil;
        }];
    }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
}



//过滤

- (void)test12{
    [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@(15)];
        [subscriber sendNext:@(17)];
        [subscriber sendNext:@(21)];
        [subscriber sendNext:@(14)];
        [subscriber sendNext:@(30)];
        return nil;
    }] filter:^BOOL(NSNumber* value) {
        return value.integerValue >= 18;
    }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];

}


//归约(不知道在写什么归约你妹)

- (void)test11{
    
    RACSignal *sugarSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"糖"];
        [subscriber sendNext:@"白"];
        return nil;
    }];
    RACSignal *waterSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"水"];
        [subscriber sendNext:@"灰"];

        return nil;
    }];
    [[RACSignal combineLatest:@[sugarSignal, waterSignal] reduce:^id (NSString* sugar, NSString*water){
        return [sugar stringByAppendingString:water];
    }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    
    
}


//映射

- (void)test10{
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"石"];
        return nil;
    }] map:^id(NSString* value) {
        if ([value isEqualToString:@"石"]) {
            return @"金";
        }
        return value;
    }];
    [signal subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}


//压缩 每次取同一排的两个进行组合，A信号的第一个和B信号的第一个，类推
- (void)test9{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"红"];
        [subscriber sendNext:@"黑"];
    
        return nil;
    }];
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"白"];
        [subscriber sendNext:@"灰"];
        
        return nil;
    }];
    [[signalA zipWith:signalB] subscribeNext:^(RACTuple* x) {
        RACTupleUnpack(NSString *stringA, NSString *stringB) = x;
        NSLog(@"我们是%@%@的", stringA, stringB);
    }];
    

}

//组合，每次都取signalA的最后和signalB的进行组合
- (void)test8{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"红"];
        [subscriber sendNext:@"白"];
//         [subscriber sendNext:@"蓝"];
        return nil;
    }];
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"白"];
         [subscriber sendNext:@"灰"];
        return nil;
    }];
    [[RACSignal combineLatest:@[signalA, signalB]] subscribeNext:^(RACTuple* x) {
        RACTupleUnpack(NSString *stringA, NSString *stringB) = x;
        NSLog(@"我们是%@%@的", stringA, stringB);
    }];

}


//合并
- (void)test7{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"纸厂污水"];
        return nil;
    }];
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"电镀厂污水"];
        return nil;
    }];
    [[RACSignal merge:@[signalA, signalB]] subscribeNext:^(id x) {
        NSLog(@"处理%@",x);
    }];
}


//连接
- (void)test6{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"我恋爱啦"];
        [subscriber sendCompleted];
        return nil;
    }];
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"我结婚啦"];
        [subscriber sendCompleted];
        return nil;
    }];
    [[signalA concat:signalB] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];

}



//广播
- (void)test5{
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:@"代码之道频道" object:nil] subscribeNext:^(NSNotification* x) {
        NSLog(@"技巧：%@", x.userInfo[@"技巧"]);
        NSLog(@"object：%@", x.object);
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"代码之道频道" object:@"123" userInfo:@{@"技巧":@"用心写"}];

}



//代理
- (void)test4{
    RACSignal *ProgrammerSignal =
    [self rac_signalForSelector:@selector(makeAnApp)
                   fromProtocol:@protocol(Programmer)];
    [ProgrammerSignal subscribeNext:^(RACTuple* x) {
        NSLog(@"花了一个月，app写好了");
    }];
    [self makeAnApp];
}

//双边
- (void)test3{
    RACChannelTerminal *channelA = RACChannelTo(self, valueA);
    RACChannelTerminal *channelB = RACChannelTo(self, valueB);
    [[channelA map:^id(NSString *value) {
        if ([value isEqualToString:@"西"]) {
            return @"东";
        }
        return value;
    }] subscribe:channelB];
    
    [[channelB map:^id(NSString *value) {
        if ([value isEqualToString:@"左"]) {
            return @"右";
        }
        return value;
    }] subscribe:channelA];
    
    [[RACObserve(self, valueA) filter:^BOOL(id value) {
        return value ? YES : NO;
    }] subscribeNext:^(NSString* x) {
        NSLog(@"你向%@", x);
    }];
    
    [[RACObserve(self, valueB) filter:^BOOL(id value) {
        return value ? YES : NO;
    }] subscribeNext:^(NSString* x) {
        NSLog(@"他向%@", x);
    }];
    
    self.valueA = @"西";
    self.valueB = @"左";
}


/**
 *  单边
 */
- (void)test2
{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"我是A"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    RAC(self, value) = [signalA map:^id(NSString* value) {
        if ([value isEqualToString:@"我是A"]) {
            return @"改你名字，你是B";
        }
        return @"";
    }];
    
    [RACObserve(self, value) subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}

/**
 *  观察值
 */
- (void)test
{
    [RACObserve(self, value) subscribeNext:^(id x) {
        NSLog(@"我变化了%@",x);
    }];
    self.value = @"123";
}





- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
