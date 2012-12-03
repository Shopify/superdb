/*   MessagePatternCodeNode.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "CompiledCodeNode.h"

@class FSPattern;

@interface MessagePatternCodeNode: CompiledCodeNode
{
@public
  FSPattern *pattern;
}

- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;
- setMessageWithReceiver:(CompiledCodeNode *) theReceiver 
                selector:(NSString *)  theSelector
                operatorSymbols:(NSString *) theOperatorSymbols
                pattern:(FSPattern *) thePattern;

- (FSPattern*)pattern;



@end
