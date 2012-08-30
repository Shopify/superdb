/* FSNSManagedObjectContext.h Copyright (c) 2005-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */ 
 
#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class FSSystem;

@interface NSManagedObjectContext(FSNSManagedObjectContext)

- (void)inspectWithSystem:(FSSystem *)system;

@end

