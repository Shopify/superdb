/*   NamedNumber Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import <Foundation/Foundation.h>

@interface FSNamedNumber : NSNumber
{
  double value;
  NSString *name;
}

+ namedNumberWithDouble:(double)val name:(NSString *)theName;
- initWithDouble:(double)val name:(NSString *)theName;  //designated initializer
- (void) dealloc;
- (NSString *)description;

@end
