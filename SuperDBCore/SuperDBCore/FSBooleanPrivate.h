/* FSBooleanPrivate.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSBoolean.h"

extern FSBoolean *fsTrue; 
extern FSBoolean *fsFalse;

@interface FSBoolean(FSBooleanPrivate)

- (double)doubleValue;
- (BOOL) isTrue;

@end

@interface False(FalsePrivate)

- awakeAfterUsingCoder:(NSCoder *)aDecoder;

@end

@interface True(TruePrivate)

- awakeAfterUsingCoder:(NSCoder *)aDecoder;

@end
