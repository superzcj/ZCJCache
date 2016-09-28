//
//  ZCJDiskCache.m
//  ZCJCache
//
//  Created by zhangchaojie on 16/9/26.
//  Copyright © 2016年 zhangchaojie. All rights reserved.
//

#import "ZCJDiskCache.h"

static NSString const *ZCJDiskCachePrefix = @"com.zcj.ZCJDiskCache";

@interface ZCJDiskCache()

@property (nonatomic, strong) dispatch_queue_t currentQueue;

@property (strong, nonatomic) dispatch_semaphore_t lockSemaphore;

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSURL *cacheUrl;
@end

@implementation ZCJDiskCache

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
        _name = [name copy];
        
        _currentQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@ Asynchronous Queue", ZCJDiskCachePrefix] UTF8String], DISPATCH_QUEUE_CONCURRENT);
        
        _lockSemaphore = dispatch_semaphore_create(1);
        
        NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *pathComponment = [NSString stringWithFormat:@"%@.%@", ZCJDiskCachePrefix, name];
        _cacheUrl = [NSURL fileURLWithPathComponents:@[rootPath, pathComponment]];
    }
    return self;
}


- (void)setObject:(id)object forKey:(NSString *)key block:(ZCJDiskCacheObjectBlock)block {
    if (!key || !object) {
        return;
    }
    
    __weak ZCJDiskCache *weakSelf= self;
    dispatch_sync(_currentQueue, ^{
        NSURL *fileUrl = nil;
        dispatch_semaphore_wait(_lockSemaphore, DISPATCH_TIME_FOREVER);
        fileUrl = [self encodedFileURLForKey:key];
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
        NSError *writeErr = nil;
        BOOL written = [data writeToURL:fileUrl options:NSDataWritingAtomic error:&writeErr];
        if (!written) {
            fileUrl = nil;
        }
        dispatch_semaphore_signal(_lockSemaphore);
        
        if (block) {
            block(weakSelf, key, object);
        }
    });
}

- (void)objectForKey:(NSString *)key block:(ZCJDiskCacheObjectBlock)block {
    if (!key) {
        return;
    }
    
    dispatch_sync(_currentQueue, ^{
        __weak ZCJDiskCache *weakSelf = self;
        id object = [weakSelf objectForKey:key];
        if (block) {
            block(weakSelf, key, object);
        }
    });
}

- (id)objectForKey:(NSString *)key {
    
    NSURL *fileUrl = nil;
    
    id object = nil;
    dispatch_semaphore_wait(_lockSemaphore, DISPATCH_TIME_FOREVER);
    
    fileUrl = [self encodedFileURLForKey:key];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[fileUrl path]]) {
        object = [NSKeyedUnarchiver unarchiveObjectWithFile:[fileUrl path]];
    }
    
    dispatch_semaphore_signal(_lockSemaphore);
    return object;
}

-(void)removeObjectForKey:(NSString *)key {
    if (!key) {
        return;
    }
    
    dispatch_semaphore_wait(_lockSemaphore, DISPATCH_TIME_FOREVER);
    NSURL *fileUrl = [self encodedFileURLForKey:key];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[fileUrl path]]) {
        
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:[fileUrl path] error:&error];
        if (error) {
            NSLog(@"File delete error:%@",error.description);
        }
    }
    
    dispatch_semaphore_signal(_lockSemaphore);
}

- (NSURL *)encodedFileURLForKey:(NSString *)key {
    if (![key length]) {
        return nil;
    }
    
    return [_cacheUrl URLByAppendingPathComponent:[self encodedString:key]];
}

- (NSString *)encodedString:(NSString *)string
{
    if (![string length]) {
        return @"";
    }
    
        return [string stringByAddingPercentEncodingWithAllowedCharacters:[[NSCharacterSet characterSetWithCharactersInString:@".:/%"] invertedSet]];
}
@end
