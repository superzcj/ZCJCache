//
//  ZCJMemoryCache.h
//  ZCJCache
//
//  Created by zhangchaojie on 16/9/26.
//  Copyright © 2016年 zhangchaojie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZCJMemoryCache;
typedef void(^ZCJMemoryCacheObjectBlock)(ZCJMemoryCache *memoryCache, NSString *key, id object);

@interface ZCJMemoryCache : NSObject

+(instancetype)sharedInstance;

- (void)objectForKey:(NSString *)key block:(ZCJMemoryCacheObjectBlock)block;

-(void)setObject:(id)object forKey:(NSString *)key block:(ZCJMemoryCacheObjectBlock)block;

-(void)removeObjectForKey:(NSString *)key;

@end
