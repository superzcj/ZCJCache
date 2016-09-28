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

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

- (void)objectForKey:(NSString *)key block:(ZCJCacheObjectBlock)block;

-(void)setObject:(id)object forKey:(NSString *)key block:(ZCJCacheObjectBlock)block;

-(void)removeObjectForKey:(NSString *)key;
@end
