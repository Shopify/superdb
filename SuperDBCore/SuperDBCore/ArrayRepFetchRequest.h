/*   ArrayRepFetchRequest.h Copyright (c) 2004-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import <CoreData/CoreData.h>

#import "ArrayRep.h"

@interface ArrayRepFetchRequest : NSObject <ArrayRep>
{
  NSFetchRequest *fetchRequest;
  NSManagedObjectContext *objectContext;
}

+ (ArrayRepFetchRequest *) arrayRepFetchRequestWithFetchRequest:(NSFetchRequest *)theFetchRequest objectContext:(NSManagedObjectContext *)theObjectContext;

- (ArrayRepId *) asArrayRepId; 
- copyWithZone:(NSZone *)zone;
- (void)dealloc;
- initWithFetchRequest:(NSFetchRequest *)theFetchRequest objectContext:(NSManagedObjectContext *)theObjectContext;
- (enum ArrayRepType) repType;

@end
