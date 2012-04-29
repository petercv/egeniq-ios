//
//  EFDataManager.m
//  Egeniq
//
//  Created by Peter Verhage on 31-01-12.
//  Copyright (c) 2012 Egeniq. All rights reserved.
//

#import "EFDataManager.h"

/**
 * Extension.
 */
@interface EFDataManager ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly) NSURL *persistentStoreURL;
@property (nonatomic, strong) NSString *modelName;

- (NSPersistentStore *)persistentStoreWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistenStoreCoordinator error:(NSError **)error;

@end

/**
 * Implementation.
 */
@implementation EFDataManager

@synthesize managedObjectContext = managedObjectContext_;
@synthesize managedObjectModel = managedObjectModel_;
@synthesize persistentStoreCoordinator = persistentStoreCoordinator_;
@synthesize modelName = modelName_;

#pragma mark - 
#pragma mark Initialization
- (id)initWithModelName:(NSString *)modelName {
    self = [super init];
    
    if (self != nil) {
        self.modelName = modelName;
    }
    
    return self;
}

#pragma mark -
#pragma mark Core data

- (NSManagedObjectContext *)managedObjectContext {
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    
    return managedObjectContext_;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel_ != nil) {
        return managedObjectModel_;
    }
	
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:self.modelName ofType:@"momd"];
    
	if (modelPath == nil) {
		modelPath = [[NSBundle mainBundle] pathForResource:self.modelName ofType:@"mom"];
	}
	
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel_;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    // Create the persistent store.
    __autoreleasing NSError *error = nil;
    NSPersistentStore *persistentStore = [self persistentStoreWithPersistentStoreCoordinator:persistentStoreCoordinator error:&error];
    
    if (persistentStore == nil) {
        NSURL *persistentStoreURL = self.persistentStoreURL;
        
        // If the persistent store could not be created and an existing store file exists, remove it and retry once.
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [[NSFileManager defaultManager] removeItemAtURL:persistentStoreURL error:NULL];
        
        if ([fileManager fileExistsAtPath:[persistentStoreURL path]]) {
            NSLog(@"%@: Persistent store could not be added at %@. Removing existing persistent store file and retrying.", [self class], persistentStoreURL);
            [[NSFileManager defaultManager] removeItemAtURL:persistentStoreURL error:NULL];
            persistentStore = [self persistentStoreWithPersistentStoreCoordinator:persistentStoreCoordinator error:&error];
        }
    }
    
    // Only assign to property if persistent store was created.
    if (persistentStore != nil) {
        persistentStoreCoordinator_ = persistentStoreCoordinator;
    }
    
    return persistentStoreCoordinator_;
}

- (NSURL *)persistentStoreURL {
    NSURL *documentDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *persistentStoreURL = [[documentDirectory URLByAppendingPathComponent:self.modelName] URLByAppendingPathExtension:@"sqlite"];
    return persistentStoreURL;
}

- (NSPersistentStore *)persistentStoreWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistenStoreCoordinator error:(NSError **)error {
    NSPersistentStore *persistentStore = [persistenStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                                 configuration:nil
                                                                                           URL:self.persistentStoreURL
                                                                                       options:nil
                                                                                         error:error];
    return persistentStore;
}

@end