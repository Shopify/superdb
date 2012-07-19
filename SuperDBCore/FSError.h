/* FSError.h Copyright (c) 2002-2006 Philippe Mougin.  */
/* This software is open source. See the license. */  

#import <Foundation/Foundation.h>

@class FSBoolean;

@interface FSError : NSObject <NSCopying> // NSCopying is needed to be an object value in an NSCell
{
  NSString *description;
}

+ (FSError *) errorWithDescription:(NSString*)desc;

- (id)copyWithZone:(NSZone *)zone;
- (NSString *)description;
- (void) dealloc;
- initWithDescription:(NSString*)desc;
- (FSBoolean *)operator_less:(id)operand;  

@end
