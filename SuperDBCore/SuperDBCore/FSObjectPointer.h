/*   FSObjectPointer.h Copyright (c) 2004-2009 Philippe Mougin.   */
/*   This software is open source. See the license.    */  

#import "FSPointer.h"

@interface FSObjectPointer : FSPointer 
{
  size_t count;
} 
 
- (id)at:(id)i;
- (id)at:(id)i put:(id)elem;

@end
