//
//  ZCJCache.h
//  ZCJCache
//
//  Created by zhangchaojie on 16/9/26.
//  Copyright © 2016年 zhangchaojie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZCJCache;
typedef void(^ZCJCacheObjectBlock)(ZCJCache *cache, NSString *key, id object);

@interface ZCJCache : NSObject


+(instancetype)sharedInstance;

- (instancetype)initWithName:(NSString *)name;

//标记init方法不可用
-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

//根据key异步取缓存数据
- (void)objectForKey:(NSString *)key block:(ZCJCacheObjectBlock)block;

//异步存储缓存数据
-(void)setObject:(id)object forKey:(NSString *)key block:(ZCJCacheObjectBlock)block;

//删除缓存数据
-(void)removeObjectForKey:(NSString *)key;

@end
