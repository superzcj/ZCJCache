//
//  ZCJCache.m
//  ZCJCache
//
//  Created by zhangchaojie on 16/9/26.
//  Copyright © 2016年 zhangchaojie. All rights reserved.
//

#import "ZCJCache.h"
#import "ZCJMemoryCache.h"
#import "ZCJDiskCache.h"

static NSString * const ZCJCachePrefix = @"com.zcj.ZCJCache";

@interface ZCJCache()

@property (nonatomic, strong) ZCJMemoryCache *memoryCache;

@property (nonatomic, strong) ZCJDiskCache *diskCache;

@property (nonatomic, strong) dispatch_queue_t currentQueue;
@end

@implementation ZCJCache


+(instancetype)sharedInstance {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initWithName:@"ZCJDiskCacheShared"];
    });
    return instance;
}


-(instancetype)initWithName:(NSString *)name {
    if (!name) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        _diskCache = [[ZCJDiskCache alloc] initWithName:name];
        _memoryCache = [[ZCJMemoryCache alloc] init];
        
        NSString *queueName = [[NSString alloc] initWithFormat:@"%@.%p", ZCJCachePrefix, (void *)self];
        _currentQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@ Asynchronous Queue", queueName] UTF8String], DISPATCH_QUEUE_CONCURRENT);

    }
    return self;
}

-(void)setObject:(id)object forKey:(NSString *)key block:(ZCJCacheObjectBlock)block {
    if (!key || !object) {
        return;
    }
    
    //向group追加任务队列，如果所有的任务都执行或者超时，它发出通知
    dispatch_group_t group = nil;
    ZCJMemoryCacheObjectBlock memBlock = nil;
    ZCJDiskCacheObjectBlock diskBlock = nil;
    
    if (block) {
        group = dispatch_group_create();
        dispatch_group_enter(group);
        dispatch_group_enter(group);
        
        memBlock = ^(ZCJMemoryCache *memoryCache, NSString *memoryCacheKey, id memoryCacheObject) {
            dispatch_group_leave(group);
        };
        
        diskBlock = ^(ZCJDiskCache *diskCache, NSString *key, id object) {
            dispatch_group_leave(group);
        };
    }
    [_memoryCache setObject:object forKey:key block:memBlock];
    [_diskCache setObject:object forKey:key block:diskBlock];
    
    if (group) {
        __weak ZCJCache *weakSelf = self;
        dispatch_group_notify(group, _currentQueue, ^{
            ZCJCache *strongSelf = weakSelf;
            if (strongSelf)
                block(strongSelf, key, object);
        });
    }
}

- (void)objectForKey:(NSString *)key block:(ZCJCacheObjectBlock)block {
    if (!key) {
        return;
    }
    
    __weak ZCJCache *weakSelf = self;
    dispatch_sync(_currentQueue, ^{
        ZCJCache *strongSelf = weakSelf;
        [strongSelf.memoryCache objectForKey:key block:^(ZCJMemoryCache *memoryCache, NSString *key, id object) {
            if (object) {
                dispatch_sync(_currentQueue, ^{
                    ZCJCache *strongSelf = weakSelf;
                    block(strongSelf, key, object);
                });
            }
            else {
                [strongSelf.diskCache objectForKey:key block:^(ZCJDiskCache *diskCache, NSString *key, id object) {
                    if (object) {
                        dispatch_sync(_currentQueue, ^{
                            ZCJCache *strongSelf = weakSelf;
                            block(strongSelf, key, object);
                        });
                    }
                }];
            }
        }];
    });
}

-(void)removeObjectForKey:(NSString *)key {
    if (!key) {
        return;
    }
    
    [_memoryCache removeObjectForKey:key];
    [_diskCache removeObjectForKey:key];
}

@end
