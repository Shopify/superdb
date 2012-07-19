/*   FSCNUnaryMessage.h Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNMessage.h"

@interface FSCNUnaryMessage : FSCNMessage 
{}

- (id)initWithCoder:(NSCoder *)coder;
- (id)initWithReceiver:(FSCNBase *)theReceiver selectorString:(NSString *)theSelectorString pattern:(FSPattern *)thePattern;

@end
