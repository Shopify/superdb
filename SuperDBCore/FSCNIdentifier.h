/*   FSCNIdentifier.h Copyright (c) 2007-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNBase.h"
#import "FSSymbolTable.h" 

@interface FSCNIdentifier : FSCNBase 
{
  @public
    NSString *identifierString;
    struct FSContextIndex locationInContext;
}

- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;
- (id)initWithIdentifierString:(NSString *)theIdentifierString locationInContext:(struct FSContextIndex)theLocationInContext;

@end
