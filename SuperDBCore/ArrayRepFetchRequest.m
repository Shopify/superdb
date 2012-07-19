/*   ArrayRepFetchRequest.m Copyright (c) 2004-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "ArrayRepFetchRequest.h"
#import "ArrayRepId.h"
#import "FSArray.h"

@implementation ArrayRepFetchRequest

+ (ArrayRepFetchRequest *) arrayRepFetchRequestWithFetchRequest:(NSFetchRequest *)theFetchRequest objectContext:(NSManagedObjectContext *)theObjectContext
{
  return [[[self alloc] initWithFetchRequest:theFetchRequest objectContext:theObjectContext] autorelease];
}

- (ArrayRepId *) asArrayRepId 
{
  NSError *error = nil;
  NSArray *objects;
    
  objects = [objectContext executeFetchRequest:fetchRequest error:&error];
  
  if (error)
  { 
    NSLog(@"Error when fetching an ArrayRepFetchRequest: %@", error);
    objects = [NSArray array];
  }

  return [ArrayRepId arrayWithArray:objects];  
}

- copyWithZone:(NSZone *)zone
{
  return [[ArrayRepFetchRequest allocWithZone:zone] initWithFetchRequest:fetchRequest objectContext:objectContext];  
}

- (void)dealloc
{
  [fetchRequest release];
  [objectContext release];
  [super dealloc];
} 

- initWithFetchRequest:(NSFetchRequest *)theFetchRequest objectContext:(NSManagedObjectContext *)theObjectContext
{
  if ((self = [super init]))
  {
    fetchRequest = [theFetchRequest retain];
    objectContext = [theObjectContext retain];
  }
  return self;    
}

- (enum ArrayRepType)repType {return FETCH_REQUEST;}

@end
