//
//  ObjectParser.h
//  MallTower
//
//  Created by mini2 on 12-3-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JTObjectMappingItem.h"

@import CoreData;

@interface JTObjectMapping : NSObject
 
+ (JTObjectMapping *)mapping;
+ (JTObjectMapping *)mappingWithMappingItems:(NSArray *)mappingItems;

- (void)addMappingItems:(NSArray *)mappingItems;

//mapping from data to objects
- (id)fetchObjectFromDictionary:(NSDictionary *)dictionary;
- (id)fetchObjectFromDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;

- (NSArray *)fetchObjectsFromArray:(NSArray *)array;
- (NSArray *)fetchObjectsFromArray:(NSArray *)array inContext:(NSManagedObjectContext *)context;

- (NSDictionary *)fetchMappingResultFromDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)fetchMappingResultFromDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;

//mapping from objects to data
- (NSDictionary *)fetchDictionaryFromObject:(id)object;
- (NSArray *)fetchArrayFromObjects:(NSArray *)objects;

@end
