//
//  JTObjectMappingItem.m
//  JTObjectMappingDemo
//
//  Created by Admin on 4/5/14.
//  Copyright (c) 2014 Jason Tang. All rights reserved.
//

#import "JTObjectMappingItem.h"

@implementation JTObjectMappingItem
{
    NSSet           *_propertiesForMapping;
    NSDictionary    *_propertyMappings;
    NSMutableDictionary     *_dependentMappingItems;
}

- (NSArray *)dependentMappingItems
{
    return [_dependentMappingItems allValues];
}


+ (instancetype)itemWithKeyPath:(NSString *)keyPath mappingClass:(Class)mappingClass
{
    return [[[self alloc] initWithKeyPath:keyPath mappingClass:mappingClass] autorelease];
}

+ (instancetype)itemWithKeyPath:(NSString *)keyPath mappingClass:(Class)mappingClass propertiesForMapping:(NSArray *)properties
{
    return [[[self alloc] initWithKeyPath:keyPath mappingClass:mappingClass propertiesForMapping:properties] autorelease];
}

+ (instancetype)itemWithKeyPath:(NSString *)keyPath mappingClass:(Class)mappingClass propertyMappingsFromDictionary:(NSDictionary *)mappingDictionary
{
    return [[[self alloc] initWithKeyPath:keyPath mappingClass:mappingClass propertyMappingsFromDictionary:mappingDictionary] autorelease];
}

- (id)initWithKeyPath:(NSString *)keyPath mappingClass:(Class)mappingClass
{
    if(self = [super init])
    {
        self.keyPath = keyPath;
        self.mappingClass = mappingClass;
        _dependentMappingItems = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (id)initWithKeyPath:(NSString *)keyPath mappingClass:(Class)mappingClass propertiesForMapping:(NSArray *)properties
{
    if([self initWithKeyPath:keyPath mappingClass:mappingClass])
    {
        _propertiesForMapping = [[NSSet alloc] initWithArray:properties];
    }

    return self;
}

- (id)initWithKeyPath:(NSString *)keyPath mappingClass:(Class)mappingClass propertyMappingsFromDictionary:(NSDictionary *)mappingDictionary
{
    if([self initWithKeyPath:keyPath mappingClass:mappingClass])
    {
        _propertyMappings = [mappingDictionary retain];
    }

    return self;
}

- (void)dealloc
{
    self.keyPath = nil;
    [_propertiesForMapping release];
    [_propertyMappings release];
    [_dependentMappingItems release];
    [super dealloc];
}

- (void)addDependentMappingItems:(NSArray *)items
{
    for (JTObjectMappingItem *item in items) {
        if(!_dependentMappingItems[item.keyPath])
        {
            _dependentMappingItems[item.keyPath] = item;
        }
    }
}

- (NSString *)mappedKeyNameForProperty:(NSString *)property
{
    if(!_propertiesForMapping && !_propertyMappings)
    {
        return property;
    }
    else if(_propertiesForMapping)
    {
        return [_propertiesForMapping containsObject:property]?property:nil;
    }
    else
    {
        NSString *mappingKey =  _propertyMappings[property];
        return mappingKey ? mappingKey : property;
    }
}

- (JTObjectMappingItem *)dependentMappingItemForProperty:(NSString *)property
{
    if(!_dependentMappingItems)
        return nil;

    NSString *mappedKey = [self mappedKeyNameForProperty:property];
    return _dependentMappingItems[mappedKey];
}

@end
