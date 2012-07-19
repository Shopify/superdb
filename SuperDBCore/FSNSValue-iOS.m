/* FSNSValue.m Copyright (c) 2003-2009 Philippe Mougin.   */
/*   This software is open source. See the license.  */  

#import "FSNSValue-iOS.h"
#import "FSNSObject.h"
#import "FSNumber.h"
#import "FScriptFunctions.h"
#import "FSBooleanPrivate.h"

@implementation NSValue (FSNSValue) 

/////////////////////////// USER METHODS ////////////////////////////

+ (NSRange)rangeWithLocation:(NSUInteger)location length:(NSUInteger)length
{
  return NSMakeRange(location,length);
}
 
+ (CGSize)sizeWithWidth:(CGFloat)width height:(CGFloat)height
{
  return CGSizeMake(width, height);
}

- (id)clone { return  [[self copy] autorelease];}

- (CGPoint)corner
{
  if (strcmp([self objCType],@encode(CGRect)) != 0)
  {
    if ([self isKindOfClass:[NSNumber class]])
      FSExecError(@"message \"corner\" sent to a number");
    else
      FSExecError(@"message \"corner\" sent to an NSValue that does not contain an CGRect");
  }
  else
  {
    CGRect rectValue = [self CGRectValue];
    return CGPointMake(rectValue.origin.x + rectValue.size.width, rectValue.origin.y + rectValue.size.height);
  }
}

- (CGRect)corner:(CGPoint)operand
{
  if (strcmp([self objCType],@encode(CGPoint)) != 0)
  {
    if ([self isKindOfClass:[NSNumber class]])
      FSExecError(@"message \"corner:\" sent to a number");
    else
      FSExecError(@"message \"corner:\" sent to an NSValue that does not contain an CGPoint");
  }
  else
  {
    CGPoint pointValue = [self CGPointValue];
    if (operand.x < pointValue.x || operand.y < pointValue.y) FSExecError(@"argument 1 of method \"corner:\" must be a valid corner");
    return CGRectMake(pointValue.x,pointValue.y,operand.x - pointValue.x,operand.y - pointValue.y);
  }
}

- (CGPoint)extent
{
  if (strcmp([self objCType],@encode(CGRect)) != 0)
  {
    if ([self isKindOfClass:[NSNumber class]])
      FSExecError(@"message \"extent\" sent to a number");
    else
      FSExecError(@"message \"extent\" sent to an NSValue that does not contain an CGRect");
  }
  else
  {
    CGRect rectValue = [self CGRectValue];
    return CGPointMake(rectValue.size.width,rectValue.size.height);
  }
}

- (CGRect)extent:(CGPoint)operand
{
  if (strcmp([self objCType],@encode(CGPoint)) != 0) 
  {
    if ([self isKindOfClass:[NSNumber class]])
      FSExecError(@"message \"extent:\" sent to a number");
    else
      FSExecError(@"message \"extent:\" sent to an NSValue that does not contain an CGPoint");
  }
  else
  {
    if (operand.x < 0 || operand.y < 0) FSExecError(@"argument 1 of method \"extent:\" must be a point with no negative coordinate");
    CGPoint pointValue = [self CGPointValue];
    return CGRectMake(pointValue.x,pointValue.y,operand.x,operand.y);
  }  
}

- (CGFloat)height
{
  if (strcmp([self objCType],@encode(CGSize)) != 0)
  {
    if ([self isKindOfClass:[NSNumber class]])
      FSExecError(@"message \"height\" sent to a number");
    else
      FSExecError(@"message \"height\" sent to an NSValue that does not contain an CGSize");
  }
  else return [self CGSizeValue].height;
}

- (NSUInteger)length
{
  if (strcmp([self objCType],@encode(NSRange)) != 0) 
  {
    if ([self isKindOfClass:[NSNumber class]])
      FSExecError(@"message \"length\" sent to a number");
    else
      FSExecError(@"message \"length\" sent to an NSValue that does not contain an NSRange");
  }
  else return [self rangeValue].length;
}

- (NSUInteger)location
{
  if (strcmp([self objCType],@encode(NSRange)) != 0) 
  {
    if ([self isKindOfClass:[NSNumber class]])
      FSExecError(@"message \"location\" sent to a number");
    else
      FSExecError(@"message \"location\" sent to an NSValue that does not contain an NSRange");
  }
  else return [self rangeValue].location;
}

- (CGPoint)origin
{
  if (strcmp([self objCType],@encode(CGRect)) != 0) 
  {
    if ([self isKindOfClass:[NSNumber class]])
      FSExecError(@"message \"origin\" sent to a number");
    else
      FSExecError(@"message \"origin\" sent to an NSValue that does not contain an CGRect");
  }
  else return [self CGRectValue].origin;
}

- (FSBoolean *)operator_equal:(id)operand
{
  return ([self isEqual:operand] ? fsTrue : fsFalse);
}    

- (FSBoolean *)operator_tilde_equal:(id)operand  
{
  return (![self isEqual:operand] ? fsTrue : fsFalse);
}

- (NSString *)printString
{
  const char *objCType = [self objCType];
  
  if (strcmp(objCType,@encode(CGPoint)) == 0)
  {
    CGPoint pointValue = [self CGPointValue];
    BOOL yIsNegativeZero = [[[FSNumber numberWithDouble:pointValue.y] printString] isEqualToString:@"-0"];
    if (pointValue.y >= 0 && ! yIsNegativeZero) 
      return [NSString stringWithFormat:@"(%@<>%@)",[FSNumber numberWithDouble:pointValue.x],[FSNumber numberWithDouble:pointValue.y]];
    else                                        
      return [NSString stringWithFormat:@"(%@ <> %@)",[FSNumber numberWithDouble:pointValue.x],[FSNumber numberWithDouble:pointValue.y]];
  }
  else if (strcmp(objCType,@encode(NSRange)) == 0)
  { 
    NSRange rangeValue = [self rangeValue];
    return [NSString stringWithFormat:@"(Range location = %lu length = %lu)",(unsigned long)(rangeValue.location),(unsigned long)(rangeValue.length)];
  }
  else if (strcmp(objCType,@encode(CGRect)) == 0)
  { 
    CGRect rectValue = [self CGRectValue];
    CGFloat originX = rectValue.origin.x;
    CGFloat originY = rectValue.origin.y;
    CGFloat width = rectValue.size.width;
    CGFloat height = rectValue.size.height;
    BOOL originYIsNegativeZero = [[[FSNumber numberWithDouble:originY] printString] isEqualToString:@"-0"];
    BOOL heightIsNegativeZero  = [[[FSNumber numberWithDouble:height]  printString] isEqualToString:@"-0"];
    NSString *formatString; 
    
    if      (originY >= 0 && !originYIsNegativeZero  && height >= 0 && !heightIsNegativeZero) formatString = @"(%@<>%@ extent:%@<>%@)";
    else if ((originY <  0 || originYIsNegativeZero) && height >= 0 && !heightIsNegativeZero) formatString = @"(%@ <> %@ extent:%@<>%@)";
    else if (originY >= 0 && !originYIsNegativeZero && (height < 0 || heightIsNegativeZero))  formatString = @"(%@<>%@ extent:%@ <> %@)";   
    else                                                                                      formatString = @"(%@ <> %@ extent:%@ <> %@)"; 
    
    return [NSString stringWithFormat:formatString, [FSNumber numberWithDouble:originX], [FSNumber numberWithDouble:originY], [FSNumber numberWithDouble:width], [FSNumber numberWithDouble:height]];
  }
  else if (strcmp(objCType,@encode(CGSize)) == 0)
  { 
    CGSize sizeValue = [self CGSizeValue];
    return [NSString stringWithFormat:@"(Size width = %@ height = %@)", [FSNumber numberWithDouble:sizeValue.width], [FSNumber numberWithDouble:sizeValue.height]];
  }
  
  return [super printString]; 
}

/*- (CGSize)size
{
  if (strcmp([self objCType],@encode(CGRect)) != 0) FSExecError(@"Receiver of message \"size\" must be an NSValue containing an CGRect");
  return [self CGRectValue].size;
}*/

- (CGFloat)width
{
  if (strcmp([self objCType],@encode(CGSize)) != 0)
  {
    if ([self isKindOfClass:[NSNumber class]])
      FSExecError(@"message \"width\" sent to a number");
    else
      FSExecError(@"message \"width\" sent to an NSValue that does not contain an CGSize");
  }
  else return [self CGSizeValue].width;
}

- (CGFloat)x 
{
  if (strcmp([self objCType],@encode(CGPoint)) != 0)   
  {
    if ([self isKindOfClass:[NSNumber class]])
      FSExecError(@"message \"x\" sent to a number");
    else
      FSExecError(@"message \"x\" sent to an NSValue that does not contain an CGPoint");
  }
  else return [self CGPointValue].x;
}

- (CGFloat)y 
{
  if (strcmp([self objCType],@encode(CGPoint)) != 0) 
  {
    if ([self isKindOfClass:[NSNumber class]])
      FSExecError(@"message \"y\" sent to a number");
    else
      FSExecError(@"message \"y\" sent to an NSValue that does not contain an CGPoint");
  }
  else return [self CGPointValue].y;
}

@end
