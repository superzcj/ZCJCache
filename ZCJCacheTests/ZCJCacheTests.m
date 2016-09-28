//
//  ZCJCacheTests.m
//  ZCJCacheTests
//
//  Created by zhangchaojie on 16/9/26.
//  Copyright © 2016年 zhangchaojie. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZCJCache.h"
static const NSTimeInterval ZCJCacheTestBlockTimeout = 10.0;

@interface ZCJCacheTests : XCTestCase

@property (nonatomic, strong) ZCJCache *cache;

@end

@implementation ZCJCacheTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _cache = [ZCJCache sharedInstance];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}


#pragma mark - Private Methods

- (UIImage *)image
{
    static UIImage *image = nil;
    
    if (!image) {
        NSError *error = nil;
        NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"Default-568h@2x" withExtension:@"png"];
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:imageURL
                                                          options:NSDataReadingUncached
                                                            error:&error];
        image = [[UIImage alloc] initWithData:imageData scale:2.f];
    }
    
    NSAssert(image, @"test image does not exist");
    
    return image;
}

- (dispatch_time_t)timeout
{
    return dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ZCJCacheTestBlockTimeout * NSEC_PER_SEC));
}

- (void)testObjectSet {
    
    NSString *key = @"key";
    __block UIImage *image = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self.cache setObject:[self image] forKey:key block:^(ZCJCache *cache, NSString *key, id object) {
        image = (UIImage *)object;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, [self timeout]);
    
    XCTAssertNotNil(image, @"object was not set");
    
}


- (void)testObjectSetWithDuplicateKey
{
    NSString *key = @"key";
    NSString *value1 = @"value1";
    NSString *value2 = @"value2";
    __block NSString *cachedValue = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self.cache setObject:value1 forKey:key block:nil];
    [self.cache setObject:value2 forKey:key block:nil];
    
    [self.cache objectForKey:key block:^(ZCJCache *cache, NSString *key, id object) {
        cachedValue = (NSString *)object;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, [self timeout]);
    
    XCTAssertEqual(cachedValue, value2, @"set did not overwrite previous object with same key");
}

- (void)testObjectGet {
    NSString *key = @"key";
    __block UIImage *image = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self.cache setObject:[self image] forKey:key block:nil];
    
    [self.cache objectForKey:key block:^(ZCJCache *cache, NSString *key, id object) {
        image = (UIImage *)object;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, [self timeout]);
    
    XCTAssertNotNil(image, @"object was not got");
}

- (void)testObjectGetWithInvalidKey
{
    NSString *key = @"key";
    NSString *invalidKey = @"invalid";
    __block UIImage *image = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self.cache setObject:[self image] forKey:key block:nil];
    
    [self.cache objectForKey:invalidKey block:^(ZCJCache *cache, NSString *key, id object) {
        image = (UIImage *)object;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, [self timeout]);
    
    XCTAssertNil(image, @"object with non-existent key was not nil");
}


- (void)testObjectRemove
{
    NSString *key = @"key";
    __block UIImage *image = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self.cache setObject:[self image] forKey:key block:^(ZCJCache *cache, NSString *key, id object) {
        image = (UIImage *)object;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, [self timeout]);
    
    [self.cache removeObjectForKey:key];
    
    __block id objectImage = nil;
    [self.cache objectForKey:key block:^(ZCJCache *cache, NSString *key, id object) {
        objectImage = (UIImage *)object;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, [self timeout]);
    
    XCTAssertNil(objectImage, @"object was not removed");
}
@end
