/* FSArchiver.m Copyright (c) 2001-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */

#import "FSArchiver.h"

@implementation FSArchiver

- (void)encodeValueOfObjCType:(const char *)valueType at:(const void *)address
{
  // NSLog([NSString stringWithFormat:@"%s , %s , %d", valueType, @encode(id), strcmp(valueType,@encode(id))]);
  if (strcmp(valueType,@encode(id)) != 0 || [*(id*)address conformsToProtocol:@protocol(NSCoding)] || *(id*)address == nil)
  {
    [super encodeValueOfObjCType:valueType at:address];
  }
  else
  {
    id objectToEncode = [*(id*)address replacementObjectForCoder:self];
    
    if ([objectToEncode conformsToProtocol:@protocol(NSCoding)] || objectToEncode == nil ) 
      [super encodeValueOfObjCType:valueType at:address]; // We supose that "replacementObjectForCoder:" is idempotent (it will be called again in the super implementation).
    else
    {
      objectToEncode = [NSNull null];
      NSLog(@"Can't archive an instance of %@ because this class doesn't support archiving (NSCoding protocol). Archiving an NSNull instance instead.", [*(id*)address class]); // the case of archiving a class is managed elsewhere
      [super encodeValueOfObjCType:valueType at:&objectToEncode];
    }
  }
}

- (void)encodeObject:(id)object
{
  if ([object conformsToProtocol:@protocol(NSCoding)] || object == nil)
  {
    [super encodeObject:object];
  }
  else
  {
    id objectToEncode = [object replacementObjectForCoder:self];
    
    if ([objectToEncode conformsToProtocol:@protocol(NSCoding)] || objectToEncode == nil)
    {
      [super encodeObject:object];  // We supose that "replacementObjectForCoder:" is idempotent (it will be called again in the super implementation).
    }
    else
    {
      NSLog(@"Can't archive an instance of %@ because this class doesn't support archiving (NSCoding protocol). Archiving an NSNull instance instead.", [object class]); // the case of archiving a class is managed elsewhere
      [super encodeObject:[NSNull null]];
    }  
  }     
}

@end
