/* FSNSObject.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "build_config.h"
#import "FSNSObject.h"
#import "ArrayPrivate.h"
#import "FSNumber.h"
#import "NumberPrivate.h"
#import "FSBoolean.h"
#import "FSBooleanPrivate.h"
#import "FSNSStringPrivate.h"
#import "FSNSString.h"
#import "FSNSNumber.h"
#import <Foundation/Foundation.h>
#import "FSReplacementForCoderForClass.h"
#import "FScriptFunctions.h"
#import "FSKeyedArchiver.h"
#import "FSArchiver.h"
#import "FSBlock.h"
#if TARGET_OS_IPHONE
# import <objc/runtime.h>
#else
# import <objc/objc-runtime.h>
#endif
#import "FSMiscTools.h"
#import <objc/objc-api.h>
#import "FSAssociation.h"

#if !TARGET_OS_IPHONE
# import <AppKit/AppKit.h>
#endif

@interface NSObject (DebugDescriptionDeclaration) 

- (NSString *) debugDescription;

@end


@implementation NSObject (FSNSObject)

+ replacementObjectForCoder:(NSCoder *)encoder
{
  if (!encoder || [encoder isKindOfClass:[FSArchiver class]] || [encoder isKindOfClass:[FSKeyedArchiver class]]) // we provide a replacment only for archiving.
                                                  // Distributing seems to be automaticaly handled
                                                  // in Openstep 4.2
                                                  // Note that the "!encoder" test is a woraround for what seems 
                                                  // to be a bug in Jag, where nil is sometimes passed a the encoder.
    return [[[FSReplacementForCoderForClass alloc] initWithClass:self] autorelease];
  else
    return self;
}


//////////////////// USER METHODS /////////////////////

+ (NSString *)printString
{
  NSString *description = [self description];
    
  if (description == nil) description = @""; // Some Cocoa classes return nil when asked for their descriptions! 
        
  if ([self classOrMetaclass] == [NSObject classOrMetaclass] && self != (id)[NSObject class]) 
    return [description stringByAppendingString:@" (meta)"];
  else  
    return description;
}

- (id)applyBlock:(FSBlock *)block
{
  return [block value:self];
}

- (id)classOrMetaclass
{
  return object_getClass(self);
}

- (FSArray *) enlist
{
  return [FSArray arrayWithObject:self];
}

- (FSArray *)enlist:(NSNumber *)operand // raise if not enough memory
{  
  double operandDouble;
  FSArray *r;
  
  VERIF_OP_NSNUMBER(@"enlist:")
  
  operandDouble = [operand doubleValue];

  if (operandDouble < 0)
        FSExecError([NSString stringWithFormat:@"argument of method \"enlist:\" must be non-negative"]);

  if (operandDouble > NSUIntegerMax)
    FSExecError([NSString stringWithFormat:@"argument of method \"enlist:\" must be less or equal to %lu",(unsigned long)NSUIntegerMax]);
  
  if (r = [[[FSArray alloc] initFilledWith:self count:operandDouble] autorelease])
    return r;
  else
    FSExecError(@"not enough memory");
}

- (NSString *)printString
{
  NSString *result;
  
  if ([self respondsToSelector:@selector(debugDescription)]) result = [self debugDescription];
  else                                                       result = [self description];
  
  if (result == nil) result = @""; // Some Cocoa classes return nil when asked for their descriptions! 
  
  return result;
}

- (FSBoolean *)operator_equal_equal:(id)operand
{
  return ((self == operand) ? fsTrue : fsFalse);
}

- (FSAssociation *)operator_hyphen_greater:(id)operand
{
  return [FSAssociation associationWithKey:self value:operand];
}

- (FSBoolean *)operator_tilde_tilde:(id)operand
{
  return ((self == operand) ?  fsFalse : fsTrue);
}

- (void)save:(NSString *)operand
{
  NSString *logFmt = @"failure while saving on file \"%@\" %@";
  NSMutableData *data;
  NSKeyedArchiver *archiver;
  
  VERIF_OP_NSSTRING(@"save:")

  data = [NSMutableData data]; 
  archiver = [[[FSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease];
  //[archiver setOutputFormat:NSPropertyListXMLFormat_v1_0]; 
  
  @try
  {
    [archiver encodeObject:self forKey:@"root"];
    [archiver finishEncoding];
  }
  @catch (id exception)
  {
    FSExecError([NSString stringWithFormat:logFmt, operand, FSErrorMessageFromException(exception)]);
  }
  
  if (![data writeToFile:operand atomically:YES]) 
    FSExecError([NSString stringWithFormat:@"failure while saving on file \"%@\"",[NSString stringWithString:operand]]);
}  
       
- (void)save
{
#if !TARGET_OS_IPHONE
  NSSavePanel *panel = [NSSavePanel savePanel];
  //const char *dir;
  //dir = NXHomeDirectory();  
  //[panel setRequiredFileType:@"fsobject"];
  
  if ([panel runModal] == NSOKButton)
    [self save:[panel filename]];
#endif
}      

- (void)throw
{
  @throw self;
}
 
#if TARGET_OS_IPHONE
- (id) vend:(NSString *)operand
{
  return nil;
}
#else
- (NSConnection *)vend:(NSString *)operand
{
  NSConnection *theConnection;

  VERIF_OP_NSSTRING(@"vend:")

  theConnection = [[NSConnection alloc] init];
  [theConnection setRootObject:self];
  if ([theConnection registerName:operand] == NO)
  {
    [theConnection release];
    return nil;
  }
  else return theConnection;
}
#endif

///////////////////////////////// PRIVATE FOR USE BY FSExecEngine ///////////////

- (NSUInteger) _ul_count  { return 1; }

- _ul_objectAtIndex:(NSUInteger)index  { return self;}

//////////////////////////////// PRIVATE for use by FSNSDistantObject ////////////////

- (NSString *) _printString_remote {return [self printString];}
 
@end
