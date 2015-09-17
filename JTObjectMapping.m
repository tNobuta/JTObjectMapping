//
//  ObjectParser.m
//  MallTower
//
//  Created by mini2 on 12-3-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#include <objc/runtime.h>
#import "JTObjectMapping.h"

static NSArray *objectTypes;

@implementation JTObjectMapping
{
    NSMutableArray  *_mappingItems;
}

+ (void)initialize
{
    objectTypes=[[NSArray alloc] initWithObjects:@"NSArray",@"NSMutableArray", nil];
}


+ (JTObjectMapping *)mapping
{
    return [[[JTObjectMapping alloc] init] autorelease];
}

+ (JTObjectMapping *)mappingWithMappingItems:(NSArray *)mappingItems
{
    JTObjectMapping *mapping = [[[JTObjectMapping alloc] init] autorelease];
    [mapping addMappingItems:mappingItems];
    return mapping;
}

- (id)init
{
    if(self = [super init])
    {
        _mappingItems = [[NSMutableArray alloc] init];
    }

    return self;
}

- (void)dealloc
{
    [_mappingItems release];
    [super dealloc];
}

- (void)addMappingItems:(NSArray *)mappingItems
{
    [_mappingItems addObjectsFromArray:mappingItems];
}

- (NSDictionary *)fetchMappingResultFromDictionary:(NSDictionary *)dictionary
{
    return [self fetchMappingResultFromDictionary:dictionary inContext:nil];
}

- (NSDictionary *)fetchMappingResultFromDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    if(!dictionary || (NSNull *)dictionary == [NSNull null])
        return nil;

    NSMutableDictionary *mappedDictionary = [[NSMutableDictionary alloc] init];

    for (JTObjectMappingItem *mappingItem in _mappingItems) {
        NSString *keyPath = mappingItem.keyPath;
        if(!mappingItem.keyPath || (NSNull *)keyPath == [NSNull null] || [keyPath isEqualToString:@""])
        {
            continue;
        }

        id value = [dictionary valueForKeyPath:keyPath];

        if([value isKindOfClass:[NSDictionary class]])
        {
            id object = [self objectFromDictionary:value usingMappingItem:mappingItem inContext:context];
            if(object)
            {
                mappedDictionary[mappingItem.keyPath] = object;
            }
        }
        else if ([value isKindOfClass:[NSArray class]])
        {
            NSArray *objects = [self objectsFromDictionaryArray:value usingMappingItem:mappingItem inContext:context];
            if(objects)
            {
                mappedDictionary[mappingItem.keyPath] = objects;
            }
        }
    }

    if(context)
    {
        [context save:nil];
    }

    return [mappedDictionary autorelease];
}

- (id)fetchObjectFromDictionary:(NSDictionary *)dictionary
{
    return [self fetchObjectFromDictionary:dictionary inContext:nil];
}

- (id)fetchObjectFromDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    if(![dictionary isKindOfClass:[NSDictionary class]])
        return nil;

    if(_mappingItems.count > 0)
    {
        JTObjectMappingItem *defaultItem = _mappingItems[0];

        id newObject = [self objectFromDictionary:dictionary usingMappingItem:defaultItem inContext:context];

        if(context)
        {
            [context save:nil];
        }

        return newObject;
    }
    else
    {
        return nil;
    }
}


- (NSArray *)fetchObjectsFromArray:(NSArray *)array
{
    return [self fetchObjectsFromArray:array inContext:nil];
}

- (NSArray *)fetchObjectsFromArray:(NSArray *)array inContext:(NSManagedObjectContext *)context
{
    if(![array isKindOfClass:[NSArray class]])
        return nil;

    if(_mappingItems.count > 0)
    {
        JTObjectMappingItem *defaultItem = _mappingItems[0];
        NSArray *mappedObjects = [self objectsFromDictionaryArray:array usingMappingItem:defaultItem inContext:context];

        if(context)
        {
            [context save:nil];
        }

        return mappedObjects;
    }
    else
    {
        return nil;
    }
}

- (NSDictionary *)fetchDictionaryFromObject:(id)object
{
    if(_mappingItems.count > 0)
    {
        JTObjectMappingItem *defaultItem = _mappingItems[0];
        return [self dictionaryFromObject:object usingMappingItem:defaultItem];
    }
    else
    {
        return nil;
    }
}

- (NSArray *)fetchArrayFromObjects:(NSArray *)objects
{
    if(_mappingItems.count > 0)
    {
        JTObjectMappingItem *defaultItem = _mappingItems[0];
        return [self dictionaryArrayFromObjects:objects usingMappingItem:defaultItem];
    }
    else
    {
        return nil;
    }
}


#pragma mark - Private Methods

- (NSDictionary *)propertiesFromClass:(Class)class
{
    BOOL isCoreDataEntityClass = [class isSubclassOfClass:[NSManagedObject class]];
    Class rootClass = isCoreDataEntityClass?[NSManagedObject class]:[NSObject class];
    NSMutableDictionary *propertiesDict = [[NSMutableDictionary alloc] init];
    
    Class currentClass = class;
    while (currentClass != rootClass) {
        unsigned int propertyCount;
        objc_property_t *properties=class_copyPropertyList(currentClass,&propertyCount);
        for(int i=0;i<propertyCount;i++)
        {
            NSString *propertyName=[NSString stringWithCString:property_getName(properties[i]) encoding:NSUTF8StringEncoding];
            
            NSString *propertyAttributes=[NSString stringWithCString:property_getAttributes(properties[i]) encoding:NSUTF8StringEncoding];
            
            if(propertyName)
            {
                propertiesDict[propertyName] = propertyAttributes;
            }
        }
        
        free(properties);
        
        currentClass = [currentClass superclass];
    }
    
    return [propertiesDict autorelease];
}

- (id)objectFromDictionary:(NSDictionary *)objectDictionary usingMappingItem:(JTObjectMappingItem *)mappingItem inContext:(NSManagedObjectContext *)context
{
    if(!objectDictionary || (NSNull *)objectDictionary==[NSNull null])
        return nil;

    Class classType = mappingItem.mappingClass;

    id newObject = nil;
    if(!context)
    {
        newObject = [[[classType alloc] init] autorelease];
    }
    else
    {
        newObject = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(classType) inManagedObjectContext:context];
    }

    NSDictionary *propertiesDict = [self propertiesFromClass:classType];
    
    NSInteger propertyCount = propertiesDict.allKeys.count;
  
    for(int i=0;i<propertyCount;i++)
    {
        NSString *propertyName= propertiesDict.allKeys[i];
        NSString *propertyAttributes= propertiesDict[propertyName];

        NSString *type=[propertyAttributes substringWithRange:NSMakeRange(1, 1)];

        BOOL isObject=[type isEqualToString:@"@"];

        NSString *mappedKeyName = [mappingItem mappedKeyNameForProperty:propertyName];

        if(!mappedKeyName) continue;

        id objectValue = [objectDictionary objectForKey:mappedKeyName];
     
        if(objectValue){
            if(isObject)
            {
                NSUInteger index = [objectTypes indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    return [objectValue isKindOfClass:NSClassFromString(obj)];
                }];
                
                if(index != NSNotFound)
                {
                    NSString *typeName = objectTypes[index];
                    if(([typeName isEqualToString:@"NSArray"] || [typeName isEqualToString:@"NSMutableArray"]))
                    {
                        JTObjectMappingItem *dependentItem = [mappingItem dependentMappingItemForProperty:propertyName];
                        if(dependentItem)
                        {
                            objectValue = [self objectsFromDictionaryArray:objectValue usingMappingItem:dependentItem inContext:context];
                        }
                    }
                }
                else
                {
                    JTObjectMappingItem *dependentItem = [mappingItem dependentMappingItemForProperty:propertyName];
                    if(dependentItem)
                    {
                        objectValue = [self objectFromDictionary:objectValue usingMappingItem:dependentItem inContext:context];
                    }
                }
            }
            
            if(objectValue)
                [newObject setValue:objectValue forKey:propertyName];
        }
    }
    
    return newObject;
}

- (NSArray *)objectsFromDictionaryArray:(NSArray *)dictionaryArray usingMappingItem:(JTObjectMappingItem *)mappingItem inContext:(NSManagedObjectContext *)context
{
    NSMutableArray *objects=[NSMutableArray array];
    for(NSDictionary *dict in dictionaryArray)
    {
        id object=[self objectFromDictionary:dict usingMappingItem:mappingItem inContext:context];
        [objects addObject:object];
    }

    return objects;
}

- (NSDictionary *)dictionaryFromObject:(id)object usingMappingItem:(JTObjectMappingItem *)mappingItem
{
    if(!object || (NSNull *)object==[NSNull null])
        return nil;

    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
 
    NSDictionary *propertiesDict = [self propertiesFromClass:mappingItem.mappingClass];
    
    int propertyCount = propertiesDict.allKeys.count;

    for(int i=0;i<propertyCount;i++)
    {
        NSString *propertyName= propertiesDict.allKeys[i];
        NSString *propertyAttribute= propertiesDict[propertyName];
        
        NSString *type=[propertyAttribute substringWithRange:NSMakeRange(1, 1)];

        NSString *mappedKeyName = [mappingItem mappedKeyNameForProperty:propertyName];

        if(!mappedKeyName) continue;

        id value = [object valueForKey:propertyName];

        if([type isEqualToString:@"@"])
        {

            NSUInteger index = [objectTypes indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                return [value isKindOfClass:NSClassFromString(obj)];
            }];

            if(index != NSNotFound)
            {
                NSString *typeName = objectTypes[index];
                if(([typeName isEqualToString:@"NSArray"] || [typeName isEqualToString:@"NSMutableArray"]))
                {
                    JTObjectMappingItem *dependentItem = [mappingItem dependentMappingItemForProperty:propertyName];
                    if(dependentItem)
                    {
                        value = [self dictionaryArrayFromObjects:value usingMappingItem:dependentItem];
                    }
                }
            }
            else
            {
                JTObjectMappingItem *dependentItem = [mappingItem dependentMappingItemForProperty:propertyName];
                if(dependentItem)
                {
                    value = [self dictionaryFromObject:value usingMappingItem:dependentItem];
                }
            }
        }

        if (value) {
            [dict setObject:value?value:[NSNull null] forKey:mappedKeyName];
        }
    }
 
    return dict;
}

- (NSArray *)dictionaryArrayFromObjects:(NSArray *)objects usingMappingItem:(JTObjectMappingItem *)mappingItem
{
    NSMutableArray *dicts=[NSMutableArray array];
    for (int i=0; i<[objects count]; i++)
    {
        NSDictionary *dict=[self dictionaryFromObject:[objects objectAtIndex:i] usingMappingItem:mappingItem];
        [dicts addObject:dict];
    }

    return dicts;
}

@end
