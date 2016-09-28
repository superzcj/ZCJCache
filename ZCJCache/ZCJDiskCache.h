//
//  ZCJDiskCache.h
//  ZCJCache
//
//  Created by zhangchaojie on 16/9/26.
//  Copyright © 2016年 zhangchaojie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZCJDiskCache;
typedef void(^ZCJDiskCacheObjectBlock)(ZCJDiskCache *diskCache, NSString *key, id object);
@interface ZCJDiskCache : NSObject

+(instancetype)sharedInstance;

- (instancetype)initWithName:(NSString *)name;

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

- (void)objectForKey:(NSString *)key block:(ZCJDiskCacheObjectBlock)block;

-(void)setObject:(id)object forKey:(NSString *)key block:(ZCJDiskCacheObjectBlock)block;

-(void)removeObjectForKey:(NSString *)key;
@end
