/* FSNSArray.h Copyright (c) 2001-2009 Philippe Mougin.   */
/*   This software is open source. See the license.  */  

#import "FSNSArray.h"

///////////////////////////////////// MACROS
#define VERIF_OP_NSARRAY(METHOD) {if (![operand isKindOfClass:[NSArray class]]) FSArgumentError(operand,1,@"NSArray",METHOD);}


@interface NSArray(FSNSArrayPrivate)

- (NSString *)descriptionLimited:(NSUInteger)nbElem;

@end
