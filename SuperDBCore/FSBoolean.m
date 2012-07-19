/*   FSBoolean.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "build_config.h"

#import <Foundation/Foundation.h>
#import "FSBooleanPrivate.h" 
#import "FScriptFunctions.h" 
#import "FSBlock.h"
#import "FSNumber.h"
#import "FSMiscTools.h" 

FSBoolean  *fsTrue  = nil;   
FSBoolean  *fsFalse = nil;

BOOL BooleanSetupTooLate = NO;

//   MACROS

#define VERIF_OP_BOOLEAN(METHOD) {if (operand != fsTrue && operand != fsFalse && ![operand isKindOfClass:[FSBoolean class]]) FSArgumentError(operand,1,@"FSBoolean",METHOD);}


@implementation FSBoolean

+ (FSBoolean *) fsFalse {return fsFalse;}

+ (FSBoolean *)  fsTrue  {return fsTrue;}

+ (FSBoolean *) booleanWithBool:(BOOL)theBool {return theBool ? fsTrue : fsFalse;}

+ (void)initialize
{
  static BOOL tooLate = NO;
  if ( !tooLate ) 
  {
    tooLate = YES;
    fsTrue = [[True alloc] init];
    fsFalse = [[False alloc] init];
  }
}

-(id)autorelease                     {return self;}     
     
-(id)copy                            {return self;}

-(id)copyWithZone:(NSZone *)zone     {return self;}

-(void)encodeWithCoder:(NSCoder *)coder {}

-(id)initWithCoder:(NSCoder *)coder  {self = [super init]; return self;}

-(NSUInteger)hash {return self == fsTrue;}

#if !TARGET_OS_IPHONE
- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder
{
  if ([encoder isBycopy]) return self;
  return [super replacementObjectForPortCoder:encoder];
}
#endif

-(void)release                       {}

-(id)retain                          {return self;}

-(NSUInteger)retainCount           {return  UINT_MAX;}
     
////////////////////////////// USER METHODS FOR BOOLEAN //////////////////////

- (FSBoolean *)and:(FSBlock*)operand
{ FSExecError(@"You are using an instance of the abstract class FSBoolean. You should use an instance of the True or False classes instead"); }

- (FSBoolean*) clone {return self;}

- (id) ifFalse:(FSBlock *)falseBlock
{ FSExecError(@"You are using an instance of the abstract class FSBoolean. You should use an instance of the True or False classes instead"); }

- (id) ifFalse:(FSBlock *)falseBlock ifTrue:(FSBlock *)trueBlock
{ FSExecError(@"You are using an instance of the abstract class FSBoolean. You should use an instance of the True or False classes instead"); }

- (id) ifTrue:(FSBlock *)trueBlock
{ FSExecError(@"You are using an instance of the abstract class FSBoolean. You should use an instance of the True or False classes instead"); }

- (id) ifTrue:(FSBlock *)trueBlock ifFalse:(FSBlock *)falseBlock
{ FSExecError(@"You are using an instance of the abstract class FSBoolean. You should use an instance of the True or False classes instead"); }

- (FSBoolean*)not
{ FSExecError(@"You are using an instance of the abstract class FSBoolean. You should use an instance of the True or False classes instead"); }

- (FSBoolean*) operator_ampersand:(FSBoolean*)operand 
{ FSExecError(@"You are using an instance of the abstract class FSBoolean. You should use an instance of the True or False classes instead"); }

- (FSBoolean*) operator_bar:(FSBoolean*)operand
{ FSExecError(@"You are using an instance of the abstract class FSBoolean. You should use an instance of the True or False classes instead"); }

- (FSBoolean *) operator_less:(id)operand
{ FSExecError(@"You are using an instance of the abstract class FSBoolean. You should use an instance of the True or False classes instead"); }

-(NSNumber *) operator_plus:(id)operand
{ FSExecError(@"You are using an instance of the abstract class FSBoolean. You should use an instance of the True or False classes instead"); }

- (FSBoolean *)operator_equal:(id)operand
{ FSExecError(@"You are using an instance of the abstract class FSBoolean. You should use an instance of the True or False classes instead"); }

- (FSBoolean *)operator_tilde_equal:(id)operand  
{ FSExecError(@"You are using an instance of the abstract class FSBoolean. You should use an instance of the True or False classes instead"); }

- (FSBoolean *)or:(FSBlock*)operand
{ FSExecError(@"You are using an instance of the abstract class FSBoolean. You should use an instance of the True or False classes instead"); }

@end  

@implementation True

- awakeAfterUsingCoder:(NSCoder *)aDecoder
{
  [self release];
  return fsTrue;
}

- (NSString *)description  { return @"YES"; }

- (double) doubleValue  { return 1; }

- (BOOL) isTrue { return YES; }

///////////////////////////////// USER METHODS FOR TRUE //////////////////////

- (FSBoolean *)and:(FSBlock*)operand
{
  id operandValue;
  
  FSVerifClassArgsNoNil(@"and:",1,operand,[FSBlock class]);
  
  operandValue = [operand value]; 
  if (operandValue == fsTrue || operandValue == fsFalse)
    return operandValue;
  else if ([operandValue isKindOfClass:[FSBoolean class]]) return [operandValue isTrue] ? fsTrue : fsFalse;
  else
    FSExecError([NSString stringWithFormat:@"argument 1 of method \"and:\" is a block evaluating to %@, it should evaluate to a boolean", descriptionForFSMessage(operandValue)]); 
}

- (id) ifFalse:(FSBlock *)falseBlock {FSVerifClassArgsNoNil(@"ifFalse:",1,falseBlock,[FSBlock class]); return nil;}

- (id) ifFalse:(FSBlock *)falseBlock ifTrue:(FSBlock *)trueBlock 
{
  FSVerifClassArgsNoNil(@"ifFalse:ifTrue:",2,falseBlock,[FSBlock class],trueBlock,[FSBlock class]);
  return [trueBlock value];
}

- (id) ifTrue:(FSBlock *)trueBlock 
{
  FSVerifClassArgsNoNil(@"ifTrue:",1,trueBlock,[FSBlock class]); 
  return [trueBlock value];
}

- (id) ifTrue:(FSBlock *)trueBlock ifFalse:(FSBlock *)falseBlock
{
  FSVerifClassArgsNoNil(@"ifTrue:ifFalse:",2,trueBlock,[FSBlock class],falseBlock,[FSBlock class]);
  return [trueBlock value];
}  

- (BOOL)isEqual:(id)object
{
  return (object == fsTrue || ([object isKindOfClass:[FSBoolean class]] && [object isTrue]));
}

- (FSBoolean*) not  { return fsFalse; }

- (FSBoolean*)operator_ampersand:(FSBoolean *)operand
{
  if (operand == fsTrue || operand == fsFalse) return operand;
  else if ([operand isKindOfClass:[FSBoolean class]]) return [operand isTrue] ? fsTrue : fsFalse;
  else FSArgumentError(operand,1,@"FSBoolean",@"&");
}

- (FSBoolean*)operator_bar:(FSBoolean *)operand  
{
  VERIF_OP_BOOLEAN(@"|") 
  return fsTrue; 
}

- (FSBoolean *) operator_less:(id)operand
{
  if   (operand == fsTrue || operand == fsFalse || [operand isKindOfClass:[FSBoolean class]]) return fsFalse;
  else FSArgumentError(operand,1,@"FSBoolean",@"<");
}

- (NSNumber *)operator_plus:(id)operand
{
  VERIF_OP_BOOLEAN(@"+")
  return (id)[FSNumber numberWithDouble:1+[operand doubleValue]];
}  

- (FSBoolean *)operator_equal:(id)operand
{
  return ([self isEqual:operand] ? fsTrue : fsFalse);
}    

- (FSBoolean *)operator_tilde_equal:(id)operand  
{
  return (![self isEqual:operand] ? fsTrue : fsFalse);
}

- (FSBoolean*)or:(FSBlock*)operand
{
  FSVerifClassArgsNoNil(@"or:",1,operand,[FSBlock class]);
  return fsTrue; 
}

@end

@implementation False

- awakeAfterUsingCoder:(NSCoder *)aDecoder
{
  [self release];
  return fsFalse;
}

- (NSString *)description { return @"NO"; }

- (double) doubleValue { return 0;}

- (BOOL) isTrue { return NO; }


///////////////////////////////// USER METHODS FOR FALSE //////////////////////

- (FSBoolean*)and:(FSBlock*)operand
{
  FSVerifClassArgsNoNil(@"and:",1,operand,[FSBlock class]);
  return fsFalse; 
}

- (id) ifFalse:(FSBlock *)falseBlock 
{ 
  FSVerifClassArgsNoNil(@"ifFalse:",1,falseBlock,[FSBlock class]); 
  return [falseBlock value]; 
}

- (id) ifFalse:(FSBlock *)falseBlock ifTrue:(FSBlock *)trueBlock 
{
  FSVerifClassArgsNoNil(@"ifFalse:ifTrue:",2,falseBlock,[FSBlock class],trueBlock,[FSBlock class]);
  return [falseBlock value];
}

-(id) ifTrue:(FSBlock *)trueBlock {FSVerifClassArgsNoNil(@"ifTrue:",1,trueBlock,[FSBlock class]); return nil; }

- (id) ifTrue:(FSBlock *)trueBlock ifFalse:(FSBlock *)falseBlock  
{ 
  FSVerifClassArgsNoNil(@"ifTrue:ifFalse:",2,trueBlock,[FSBlock class],falseBlock,[FSBlock class]);
  return [falseBlock value]; 
}  

- (BOOL)isEqual:(id)object
{
  return (object == fsFalse || ([object isKindOfClass:[FSBoolean class]] && ![object isTrue]));
}

- (FSBoolean*) not  { return fsTrue; }

- (FSBoolean *)operator_ampersand:(FSBoolean *)operand
{ 
  VERIF_OP_BOOLEAN(@"&")
  return fsFalse; 
}

- (FSBoolean *)operator_bar:(FSBoolean *)operand
{
  if (operand == fsTrue || operand == fsFalse) return operand;
  else if ([operand isKindOfClass:[FSBoolean class]]) return [operand isTrue] ? fsTrue : fsFalse;
  else FSArgumentError(operand,1,@"FSBoolean",@"|");
}

- (FSBoolean *) operator_less:(id)operand
{
  if      (operand == fsTrue || operand == fsFalse) return operand;
  else if ([operand isKindOfClass:[FSBoolean class]]) return [operand isTrue] ? fsTrue : fsFalse;
  else FSArgumentError(operand,1,@"FSBoolean",@"<");
}

- (NSNumber *)operator_plus:(id)operand
{
  VERIF_OP_BOOLEAN(@"+")
  return (id)[FSNumber numberWithDouble:[operand doubleValue]];
}

- (FSBoolean *)operator_equal:(id)operand
{
  return ([self isEqual:operand] ? fsTrue : fsFalse);
}    

- (FSBoolean *)operator_tilde_equal:(id)operand  
{
  return (![self isEqual:operand] ? fsTrue : fsFalse);
}

- (FSBoolean *)or:(FSBlock*)operand
{
  id operandValue;
  
  FSVerifClassArgsNoNil(@"or:",1,operand,[FSBlock class]);
  
  operandValue = [operand value]; 
  if (operandValue == fsTrue || operandValue == fsFalse)
    return operandValue;
  else if ([operandValue isKindOfClass:[FSBoolean class]]) return [operandValue isTrue] ? fsTrue : fsFalse;
  else
    FSExecError([NSString stringWithFormat:@"argument 1 of method \"or:\" is a block evaluating to %@, it should evaluate to a boolean", descriptionForFSMessage(operandValue)]); 
}

@end
