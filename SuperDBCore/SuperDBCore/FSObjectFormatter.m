/* FSObjectFormatter.m Copyright (c) 2002-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import <Foundation/Foundation.h>
#import "FSObjectFormatter.h"
#import "FSNSObject.h"
#import "FSMiscTools.h"
#import "Number_fscript.h"


@implementation FSObjectFormatter

- (NSString *)stringForObjectValue:(id)anObject
// Precondition: [anObject isKindOfClass:[NSString class]] || [anObject isKindOfClass:[Number class]]
{
  if ([anObject isKindOfClass:[NSNumber class]])
  {
    return [NSString stringWithFormat:@"% 10g", [anObject doubleValue]];
  }
  return anObject;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary *)attributes
{
  if ([anObject isKindOfClass:[NSAttributedString class]]) return anObject;
  else return nil;
}

@end
