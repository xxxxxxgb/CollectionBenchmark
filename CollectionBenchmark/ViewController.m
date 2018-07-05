//
//  ViewController.m
//  CollectionBenchmark
//
//  Created by 许桂斌 on 2018/7/2.
//  Copyright © 2018年 xgb. All rights reserved.
//

#import "ViewController.h"
#include <mach/mach_time.h>
#include <mach/mach.h>
#import <stdlib.h>
#import "YYThreadSafeDictionary.h"

#define NUMBERS_ENUMERATE(...) \
[randomAccessNumbers enumerateObjectsUsingBlock:^(NSNumber *number, BOOL *stop) { \
__VA_ARGS__; \
}];


static const NSInteger kMultipleTimes = 10;

@interface NSArray (Printf)
- (void)printf;
@end
@implementation NSArray (Printf)
- (void)printf {
    for (NSObject *obj in self) {
        printf("%s", [obj.description UTF8String]);
    }
}
@end

@interface ViewController ()
@property (copy, nonatomic) NSArray *runTimesArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.runTimesArray = @[@(10000), @(100000)];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self arrayBenchmark];
//        [self dictionaryBenchmark];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)arrayBenchmark {
    [self.runTimesArray enumerateObjectsUsingBlock:^(NSNumber *entriesNumber, NSUInteger runCount, BOOL *stop) {
        NSInteger entries = entriesNumber.integerValue;
        printf("\n执行次数: %ld [run %tu]: \n", entries, runCount+1);
        
        NSMutableSet *randomAccessNumbers = [NSMutableSet set];
        for (NSUInteger accessIdx = 0; accessIdx < entries/100; accessIdx++) {
            [randomAccessNumbers addObject:@(arc4random_uniform((u_int32_t)entries))];
        }
        
        // 测试NSMutableArray
        @autoreleasepool {
            NSMutableArray *array = [NSMutableArray array];
            double addTime = PerformAndTrackTime(^{
                for (NSUInteger idx = 0; idx < entries; idx++) {
                    [array addObject:EntryForIDX(idx)];
                }
            });
            NSMutableArray *copyArray = [array mutableCopy];
            double randomInsertTime = PerformAndTrackTime(^{
                NUMBERS_ENUMERATE([copyArray insertObject:number atIndex:number.unsignedIntegerValue])
            });
            double racTime = RandomPerformAndTrackTimeMultiple(^(NSSet *randomAccessNumbers) {
                NUMBERS_ENUMERATE(__unused id object = array[number.unsignedIntegerValue])
            }, kMultipleTimes, NSMakeRange(0, entries));
            double setTime = PerformAndTrackTime(^{
                for (NSUInteger idx = 0; idx < entries; idx++) {
                    array[idx] = EntryForIDX(idx);
                }
            });
            double containsTime = RandomPerformAndTrackTimeMultiple(^(NSSet *randomAccessNumbers) {
                NUMBERS_ENUMERATE([array containsObject:number])
            }, kMultipleTimes, NSMakeRange(0, entries));
            copyArray = [array mutableCopy];
            double delHeadTime = PerformAndTrackTime(^{
                for (NSUInteger idx = 0; idx < entries; idx++) {
                    [copyArray removeObjectAtIndex:0];
                }
            });
            copyArray = [array mutableCopy];
            double delTailTime = PerformAndTrackTime(^{
                for (NSUInteger idx = 0; idx < entries; idx++) {
                    [copyArray removeLastObject];
                }
            });
            double delRandomTime = 0.0f;
            if (entries < 1e7) {
                copyArray = [array mutableCopy];
                delRandomTime = PerformAndTrackTime(^{
                    [randomAccessNumbers enumerateObjectsUsingBlock:^(NSNumber *number, BOOL *stop) {
                        __unused NSUInteger idx = number.unsignedIntegerValue;
                        if (idx < copyArray.count) {
                            [copyArray removeObjectAtIndex:idx];
                        }
                    }];
                });
            }
            
            double times[10] = {0.0f};
            times[0] = addTime;
            times[1] = randomInsertTime;
            times[2] = racTime;
            times[3] = setTime;
            times[4] = containsTime;
            times[5] = delHeadTime;
            times[6] = delTailTime;
            times[7] = delRandomTime;
            PrintResultAndStoreLogString("NSMutableArray", times);
        }
        
        // 测试NSMutableOrderedSet
        @autoreleasepool {
            NSMutableOrderedSet *orderedSet = [NSMutableOrderedSet orderedSet];
            double addTime = PerformAndTrackTime(^{
                for (NSUInteger idx = 0; idx < entries; idx++) {
                    [orderedSet addObject:EntryForIDX(idx)];
                }
            });
            NSMutableOrderedSet *copyOrderedSet = [orderedSet mutableCopy];
            double randomInsertTime = PerformAndTrackTime(^{
                NUMBERS_ENUMERATE([copyOrderedSet insertObject:number atIndex:number.unsignedIntegerValue])
            });
            double racTime = RandomPerformAndTrackTimeMultiple(^(NSSet *randomAccessNumbers) {
                NUMBERS_ENUMERATE(__unused id object = [orderedSet objectAtIndex:number.unsignedIntegerValue])
            }, kMultipleTimes, NSMakeRange(0, entries));
            double setTime = PerformAndTrackTime(^{
                for (NSUInteger idx = 0; idx < entries; idx++) {
                    [orderedSet setObject:EntryForIDX(idx) atIndex:idx];
                }
            });
            double containsTime = RandomPerformAndTrackTimeMultiple(^(NSSet *randomAccessNumbers) {
                NUMBERS_ENUMERATE([orderedSet containsObject:number])
            }, kMultipleTimes, NSMakeRange(0, entries));
            double delHeadTime = 0.0f;
            double delTailTime = 0.0f;
            double delRandomTime = 0.0f;
            if (entries < 1e7) {
                copyOrderedSet = [orderedSet mutableCopy];
                delHeadTime = PerformAndTrackTime(^{
                    for (NSUInteger idx = 0; idx < entries; idx++) {
                        [copyOrderedSet removeObjectAtIndex:0];
                    }
                });
                copyOrderedSet = [orderedSet mutableCopy];
                delTailTime = PerformAndTrackTime(^{
                    for (NSInteger idx = entries - 1; idx >= 0; idx--) {
                        [copyOrderedSet removeObjectAtIndex:idx];
                    }
                });
                copyOrderedSet = [orderedSet mutableCopy];
                delRandomTime = PerformAndTrackTime(^{
                    [randomAccessNumbers enumerateObjectsUsingBlock:^(NSNumber *number, BOOL *stop) {
                        __unused NSUInteger idx = number.unsignedIntegerValue;
                        if (idx < copyOrderedSet.count) {
                            [copyOrderedSet removeObjectAtIndex:idx];
                        }
                    }];
                });
            }
            
            
            double times[10] = {0.0f};
            times[0] = addTime;
            times[1] = randomInsertTime;
            times[2] = racTime;
            times[3] = setTime;
            times[4] = containsTime;
            times[5] = delHeadTime;
            times[6] = delTailTime;
            times[7] = delRandomTime;
            PrintResultAndStoreLogString("NSMutableOrderedSet", times);
        }
        
        // 测试NSPointerArray
        @autoreleasepool {
            NSPointerArray *pointerArray = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsStrongMemory];
            double addTime = PerformAndTrackTime(^{
                for (NSUInteger idx = 0; idx < entries; idx++) {
                    [pointerArray addPointer:(__bridge void *)(EntryForIDX(idx))];
                }
            });
            NSData *pointerArrayData = [NSKeyedArchiver archivedDataWithRootObject:pointerArray];
            NSPointerArray *copyPointerArray = [NSKeyedUnarchiver unarchiveObjectWithData:pointerArrayData];
            double randomInsertTime = PerformAndTrackTime(^{
                NUMBERS_ENUMERATE([copyPointerArray insertPointer:(__bridge void *)number atIndex:number.unsignedIntegerValue])
            });
            double racTime = RandomPerformAndTrackTimeMultiple(^(NSSet *randomAccessNumbers) {
                NUMBERS_ENUMERATE(__unused void *object = [pointerArray pointerAtIndex:number.unsignedIntegerValue])
            }, kMultipleTimes, NSMakeRange(0, entries));
            double setTime = PerformAndTrackTime(^{
                for (NSUInteger idx = 0; idx < entries; idx++) {
                    [pointerArray replacePointerAtIndex:idx withPointer:(__bridge void *)(EntryForIDX(idx))];
                }
            });
            
            double delHeadTime = 0.0f;
            double delTailTime = 0.0f;
            double delRandomTime = 0.0f;
            if (entries < 1e6) {
                copyPointerArray = [NSKeyedUnarchiver unarchiveObjectWithData:pointerArrayData];
                delHeadTime = PerformAndTrackTime(^{
                    for (NSUInteger idx = 0; idx < entries; idx++) {
                        [copyPointerArray removePointerAtIndex:0];
                    }
                });
                copyPointerArray = [NSKeyedUnarchiver unarchiveObjectWithData:pointerArrayData];
                delTailTime = PerformAndTrackTime(^{
                    for (NSInteger idx = entries - 1; idx >= 0; idx--) {
                        [copyPointerArray removePointerAtIndex:idx];
                    }
                });
                copyPointerArray = [NSKeyedUnarchiver unarchiveObjectWithData:pointerArrayData];
                delRandomTime = PerformAndTrackTime(^{
                    [randomAccessNumbers enumerateObjectsUsingBlock:^(NSNumber *number, BOOL *stop) {
                        __unused NSUInteger idx = number.unsignedIntegerValue;
                        if (idx < copyPointerArray.count) {
                            [copyPointerArray removePointerAtIndex:idx];
                        }
                    }];
                });
            }

            double times[10] = {0.0f};
            times[0] = addTime;
            times[1] = randomInsertTime;
            times[2] = racTime;
            times[3] = setTime;
            times[5] = delHeadTime;
            times[6] = delTailTime;
            times[7] = delRandomTime;
            PrintResultAndStoreLogString("NSPointerArray", times);
        }
        
        PrintCompareResult();
    }];
}

- (void)dictionaryBenchmark {
    [self.runTimesArray enumerateObjectsUsingBlock:^(NSNumber *entriesNumber, NSUInteger runCount, BOOL *stop) {
        NSInteger entries = entriesNumber.integerValue;
        printf("\n执行次数: %ld [run %tu]: \n", entries, runCount+1);
        
        NSMutableSet *randomAccessNumbers = [NSMutableSet set];
        for (NSUInteger accessIdx = 0; accessIdx < entries/100; accessIdx++) {
            [randomAccessNumbers addObject:@(arc4random_uniform((u_int32_t)entries))];
        }
        
        // 测试NSMutableDictionary
        @autoreleasepool {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            double addTime = PerformAndTrackTime(^{
                for (NSUInteger idx = 0; idx < entries; idx++) {
                    dictionary[@(idx)] = EntryForIDX(idx);
                }
            });
            double racTime = RandomPerformAndTrackTimeMultiple(^(NSSet *randomAccessNumbers) {
                NUMBERS_ENUMERATE(__unused id object = dictionary[number])
            }, kMultipleTimes, NSMakeRange(0, entries));
            double delRandomTime = PerformAndTrackTime(^{
                NUMBERS_ENUMERATE([dictionary removeObjectForKey:number])
            });
            
            double times[10] = {0.0f};
            times[0] = addTime;
            times[2] = racTime;
            times[7] = delRandomTime;
            PrintResultAndStoreLogString("NSMutableDictionary", times);
        }
        
        // 测试YYThreadDictionary
        @autoreleasepool {
            YYThreadSafeDictionary *threadSafeDictionary = [YYThreadSafeDictionary dictionary];
            double addTime = PerformAndTrackTime(^{
                for (NSUInteger idx = 0; idx < entries; idx++) {
                    [threadSafeDictionary setObject:EntryForIDX(idx) forKey:@(idx)];
                }
            });
            double racTime = RandomPerformAndTrackTimeMultiple(^(NSSet *randomAccessNumbers) {
                NUMBERS_ENUMERATE(__unused id object = threadSafeDictionary[number])
            }, kMultipleTimes, NSMakeRange(0, entries));
            double delRandomTime = PerformAndTrackTime(^{
                NUMBERS_ENUMERATE([threadSafeDictionary removeObjectForKey:number])
            });
            
            double times[10] = {0.0f};
            times[0] = addTime;
            times[2] = racTime;
            times[7] = delRandomTime;
            PrintResultAndStoreLogString("YYThreadSafeDictionary", times);
        }
        
        // 测试NSCache
        @autoreleasepool {
            if (entries < 1E7) {
                NSCache *cache = [NSCache new];
                double addTime = PerformAndTrackTime(^{
                    for (NSUInteger idx = 0; idx < entries; idx++) {
                        [cache setObject:EntryForIDX(idx) forKey:@(idx)];
                    }
                });
                double racTime = RandomPerformAndTrackTimeMultiple(^(NSSet *randomAccessNumbers) {
                    NUMBERS_ENUMERATE(__unused id object = [cache objectForKey:number])
                }, kMultipleTimes, NSMakeRange(0, entries));
                double delRandomTime = PerformAndTrackTime(^{
                    NUMBERS_ENUMERATE([cache removeObjectForKey:number])
                });

                double times[10] = {0.0f};
                times[0] = addTime;
                times[2] = racTime;
                times[7] = delRandomTime;
                PrintResultAndStoreLogString("NSCache", times);
            }
        }
        
        // 测试NSMutableSet
        @autoreleasepool {
            NSMutableSet *set = [NSMutableSet set];
            double addTime = PerformAndTrackTime(^{
                for (NSUInteger idx = 0; idx < entries; idx++) {
                    [set addObject:EntryForIDX(idx)];
                }
            });
            double racTime = RandomPerformAndTrackTimeMultiple(^(NSSet *randomAccessNumbers) {
                NUMBERS_ENUMERATE(__unused NSUInteger idx = number.unsignedIntegerValue; [set anyObject])
            }, kMultipleTimes, NSMakeRange(0, entries));
            double delRandomTime = PerformAndTrackTime(^{
                NUMBERS_ENUMERATE([set removeObject:number])
            });
            
            double times[10] = {0.0f};
            times[0] = addTime;
            times[2] = racTime;
            times[7] = delRandomTime;
            PrintResultAndStoreLogString("NSMutableSet", times);
        }
        
        // 测试NSMapTable
        @autoreleasepool {
            NSMapTable *mapTable = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsObjectPersonality valueOptions:NSPointerFunctionsObjectPersonality capacity:0];
            double addTime = PerformAndTrackTime(^{
                for (NSUInteger idx = 0; idx < entries; idx++) {
                    [mapTable setObject:EntryForIDX(idx) forKey:@(idx)];
                }
            });
            double racTime = RandomPerformAndTrackTimeMultiple(^(NSSet *randomAccessNumbers) {
                NUMBERS_ENUMERATE(__unused id object = [mapTable objectForKey:number])
            }, kMultipleTimes, NSMakeRange(0, entries));
            double delRandomTime = PerformAndTrackTime(^{
                NUMBERS_ENUMERATE([mapTable removeObjectForKey:number])
            });

            double times[10] = {0.0f};
            times[0] = addTime;
            times[2] = racTime;
            times[7] = delRandomTime;
            PrintResultAndStoreLogString("NSMapTable", times);
        }
        
        // 测试NSHashTable
        @autoreleasepool {
            NSHashTable *hashTable = [NSHashTable hashTableWithOptions:NSPointerFunctionsStrongMemory];
            double addTime = PerformAndTrackTime(^{
                for (NSUInteger idx = 0; idx < entries; idx++) {
                    [hashTable addObject:EntryForIDX(idx)];
                }
            });
            double racTime = RandomPerformAndTrackTimeMultiple(^(NSSet *randomAccessNumbers) {
                NUMBERS_ENUMERATE([hashTable anyObject])
            }, kMultipleTimes, NSMakeRange(0, entries));
            double delRandomTime = PerformAndTrackTime(^{
                NUMBERS_ENUMERATE([hashTable removeObject:number])
            });

            double times[10] = {0.0f};
            times[0] = addTime;
            times[2] = racTime;
            times[7] = delRandomTime;
            PrintResultAndStoreLogString("NSHashTable", times);
        }
        
        // 测试NSMutableOrderedSet
        @autoreleasepool {
            NSMutableOrderedSet *orderedSet = [NSMutableOrderedSet orderedSet];
            double addTime = PerformAndTrackTime(^{
                for (NSUInteger idx = 0; idx < entries; idx++) {
                    [orderedSet addObject:EntryForIDX(idx)];
                }
            });
            double racTime = RandomPerformAndTrackTimeMultiple(^(NSSet *randomAccessNumbers) {
                NUMBERS_ENUMERATE(__unused BOOL isContains = [orderedSet containsObject:number])
            }, kMultipleTimes, NSMakeRange(0, entries));
            double delRandomTime = PerformAndTrackTime(^{
                NUMBERS_ENUMERATE([orderedSet removeObject:number])
            });
            
            double times[10] = {0.0f};
            times[0] = addTime;
            times[2] = racTime;
            times[7] = delRandomTime;
            PrintResultAndStoreLogString("NSMutableOrderedSet", times);
        }
        
        PrintCompareResult();
    }];
}



#pragma mark - Helper
static inline id EntryForIDX(NSUInteger idx) {
    char buf[100];
    snprintf(buf, 100, "%tu", idx);
    return @(buf);
}

double GetElapsedTimeInNanoseconds(uint64_t elapsedTime) {
    static double ticksToNanoseconds = 0.0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mach_timebase_info_data_t timebase;
        mach_timebase_info(&timebase);
        ticksToNanoseconds = (double)timebase.numer / timebase.denom;
    });
    
    double elapsedTimeInNanoseconds = elapsedTime * ticksToNanoseconds;
    return elapsedTimeInNanoseconds;
}

// Benchmark feature. Returns time in nanoseconds. (nsec/1E9 = seconds)
double PerformAndTrackTime(dispatch_block_t block) {
    uint64_t startTime = mach_absolute_time();
    block();
    uint64_t endTime = mach_absolute_time();
    uint64_t elapsedTime = endTime - startTime;
    
    return GetElapsedTimeInNanoseconds(elapsedTime);
}
/**
 * @param randomAccessNumbers 产生的随机数组
 */
typedef void(^RandomTestBlock)(NSSet *randomAccessNumbers);

double RandomPerformAndTrackTimeMultiple(RandomTestBlock block, NSUInteger times, NSRange range) {
    if (range.length > 1e6) return 0.0f;
    
    double totalTime = 0;
    for (NSUInteger runIndex = 0; runIndex < times; runIndex++) {
        @autoreleasepool {
            NSMutableSet *randomAccessNumbers = [NSMutableSet set];
            for (NSUInteger accessIdx = 0; accessIdx < range.length/100; accessIdx++) {
                [randomAccessNumbers addObject:@(arc4random_uniform((u_int32_t)(range.length)) + range.location)];
            }
            
            uint64_t startTime = mach_absolute_time();
            block(randomAccessNumbers);
            uint64_t endTime = mach_absolute_time();
            uint64_t elapsedTime = endTime - startTime;
            totalTime += GetElapsedTimeInNanoseconds(elapsedTime);
        }
    }
    return totalTime/times;
}

#pragma mark - Log
static NSMutableArray<NSMutableArray *> *logStringArrays;
static NSArray<NSString *> *titleArray;

/**
 *  @param name   测试模块名称。
 *  @param times  测试的各种时间，顺序为对应titleArray，不需要打印的时间以0表示。
 */
void PrintResultAndStoreLogString(char *name, double times[]) {
    if (titleArray == nil) {
        titleArray = @[@"添加元素", @"随机插入", @"随机访问", @"修改元素", @"随机查询", @"从头删除", @"从尾删除", @"随机删除"];
    }
    
    PrintResult(name, times);
    StoreLogString(name, times);
}

void PrintResult(char *name, double times[]) {
    printf("\t%s:\n", name);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    for (NSInteger i = 0; i < titleArray.count; i++) {
        times[i]==0?:printf("\t%s:\t%f [ms]\n", [titleArray[i] UTF8String], times[i]/1E6);
    }
#pragma clang diagnostic pop
}

void StoreLogString(char *name, double times[]) {
    if (logStringArrays == nil) {
        logStringArrays = [NSMutableArray new];
        for (NSInteger i = 0; i < titleArray.count; i++) {
            [logStringArrays addObject:[NSMutableArray new]];
        }
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    for (NSInteger i = 0; i < titleArray.count; i++) {
        times[i]==0?:[logStringArrays[i] addObject:PrintfString(name, times[i])];
    }
#pragma clang diagnostic pop
}

void PrintCompareResult() {
    printf("\n");
    for (NSInteger i = 0; i < titleArray.count; i++) {
        if (logStringArrays[i].count > 1) {
            printf("\t%s时间对比：\n", [titleArray[i] UTF8String]);
            [logStringArrays[i] printf];
        }
    }
    
    logStringArrays = nil;
}

NSString *PrintfString(char *name, double time) {
    NSInteger length = strlen(name);
    NSInteger needTabCount = 4 - length / 5;
    NSString *tabString = @"";
    for (NSInteger i = 0; i < needTabCount; i++) {
        tabString = [tabString stringByAppendingString:@"\t"];
    }
    return [NSString stringWithFormat:@"\t%s:%@%f [ms]\n", name, tabString, time/1E6];
}

@end
