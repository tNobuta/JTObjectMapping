//
//  JTObjectMappingItem.h
//  JTObjectMappingDemo
//
//  Created by Admin on 4/5/14.
//  Copyright (c) 2014 Jason Tang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JTObjectMappingItem : NSObject

@property (nonatomic,copy) NSString *keyPath;
@property (nonatomic,assign) Class mappingClass;
@property (nonatomic,readonly) NSArray *dependentMappingItems;

+ (instancetype)itemWithKeyPath:(NSString *)keyPath mappingClass:(Class)mappingClass;
+ (instancetype)itemWithKeyPath:(NSString *)keyPath mappingClass:(Class)mappingClass propertiesForMapping:(NSArray *)properties;
+ (instancetype)itemWithKeyPath:(NSString *)keyPath mappingClass:(Class)mappingClass propertyMappingsFromDictionary:(NSDictionary *)mappingDictionary;

- (id)initWithKeyPath:(NSString *)keyPath mappingClass:(Class)mappingClass;
- (id)initWithKeyPath:(NSString *)keyPath mappingClass:(Class)mappingClass propertiesForMapping:(NSArray *)properties;
- (id)initWithKeyPath:(NSString *)keyPath mappingClass:(Class)mappingClass propertyMappingsFromDictionary:(NSDictionary *)mappingDictionary;

- (void)addDependentMappingItems:(NSArray *)items;

- (NSString *)mappedKeyNameForProperty:(NSString *)property;

- (JTObjectMappingItem *)dependentMappingItemForProperty:(NSString *)property;

@end
