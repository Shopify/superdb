/*   FSCNSuper.h Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNIdentifier.h"

@interface FSCNSuper : FSCNIdentifier 
{
@public
  NSString *className;
  BOOL isInClassMethod;
}

- (void)dealloc;
- (id)initWithCoder:(NSCoder *)coder;
- (id)initWithLocationInContext:(struct FSContextIndex)theLocationInContext className:(NSString *)theClassName isInClassMethod:(BOOL)incm;
- (void)encodeWithCoder:(NSCoder *)coder;

@end
