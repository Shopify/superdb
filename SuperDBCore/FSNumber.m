/*   FSNumber.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "build_config.h"

#import "FSNumber.h"
#import "NumberPrivate.h"
#import "FSNSNumber.h"
#import "FScriptFunctions.h"
#import "FSArray.h"  
#import "FSBooleanPrivate.h"
#import <Foundation/Foundation.h>
#import <math.h>
#import "FSBlock.h"
#import "BlockPrivate.h"

@class NSPortCoder;

id FSNumberClass;
id NSNumberClass; 

void __attribute__ ((constructor)) initializeFSNumber(void) 
{
  [NSKeyedUnarchiver setClass:[FSNumber class] forClassName:@"Number"];
#if !TARGET_OS_IPHONE
  [NSUnarchiver decodeClassName:@"Number" asClassName:@"FSNumber"];
#endif
  FSNumberClass = [FSNumber class];
  NSNumberClass = [NSNumber class]; 
}

FSNumber *numberWithDouble(double val)
{
  FSNumber *r = (FSNumber *)NSAllocateObject(FSNumberClass, 0, NULL); //
  r->value = val;
  r->retainCount = 1;
    
  // We can optimize out the "init" call because it does nothing at the NSNumber level (Number's superclass).
  // return [[r init] autorelease]; 
  
  return [r autorelease]; 
}

@implementation FSNumber  

///////////////////////////////   USER METHODS

+ new
{
  return numberWithDouble(0);
}

- (NSNumber *)abs
{ 
  return numberWithDouble(fabs(value));
}

- (NSNumber *)arcCos
{
  if((value < -1.0) || (value > 1.0))
    FSExecError(@"receiver of message \"arcCos\" must be a number between -1 and 1");
  return numberWithDouble(acos(value));  
}

- (NSNumber *)arcCosh
{
  if (value < 1.0) FSExecError(@"receiver of message \"arcCosh\" must be a number equal to or greater than 1");
  return numberWithDouble(acosh(value));  
}

- (NSNumber *)arcSin
{
  if((value < -1.0) || (value > 1.0))
    FSExecError(@"receiver of message \"arcSin\" must be a number between -1 and 1");
  return numberWithDouble(asin(value));
}

- (NSNumber *)arcSinh
{
  return numberWithDouble(asinh(value));
}

- (NSNumber *)arcTan
{
  return numberWithDouble(atan(value));
}

- (NSNumber *)arcTanh
{
  if ((value <= -1.0) || (value >= 1.0)) FSExecError(@"receiver of message \"arcTanh\" must be a number greater than -1 and less than 1");
  return numberWithDouble(atanh(value));
}

- (NSDate *)asDate
{
  return [NSDate dateWithTimeIntervalSinceReferenceDate:value];
}

- (FSBoolean *)between:(NSNumber *)a and:(NSNumber *)b
{
  if (a && ((id)a)->isa == FSNumberClass && b && ((id)b)->isa == FSNumberClass) 
  {
    if ( ((FSNumber *)a)->value <= ((FSNumber *)b)->value )
      return value >= ((FSNumber *)a)->value && value <= ((FSNumber *)b)->value ? fsTrue : fsFalse;
    else
      return value >= ((FSNumber *)b)->value && value <= ((FSNumber *)a)->value ? fsTrue : fsFalse;  
  }
  else return [super between:a and:b];
}

- (NSNumber *)bitAnd:(NSNumber *)operand 
{
  if (operand && ((id)operand)->isa == FSNumberClass && value >=0 && ((FSNumber *)operand)->value >= 0 && value <= UINT_MAX && ((FSNumber *)operand)->value <= UINT_MAX && value == floor(value) && ((FSNumber *)operand)->value == floor(((FSNumber *)operand)->value))
    return [FSNumber numberWithDouble:(NSUInteger)value & (NSUInteger)(((FSNumber *)operand)->value)];
  else 
    return [super bitAnd:operand];
}

- (NSNumber *)bitOr:(NSNumber *)operand 
{
  if (operand && ((id)operand)->isa == FSNumberClass && value >=0 && ((FSNumber *)operand)->value >= 0 && value <= UINT_MAX && ((FSNumber *)operand)->value <= UINT_MAX && value == floor(value) && ((FSNumber *)operand)->value == floor(((FSNumber *)operand)->value))
    return [FSNumber numberWithDouble:(NSUInteger)value | (NSUInteger)(((FSNumber *)operand)->value)];
  else 
    return [super bitOr:operand];
}

- (NSNumber *)bitXor:(NSNumber *)operand 
{
  if (operand && ((id)operand)->isa == FSNumberClass && value >=0 && ((FSNumber *)operand)->value >= 0 && value <= UINT_MAX && ((FSNumber *)operand)->value <= UINT_MAX && value == floor(value) && ((FSNumber *)operand)->value == floor(((FSNumber *)operand)->value))
    return [FSNumber numberWithDouble:(NSUInteger)value ^ (NSUInteger)(((FSNumber *)operand)->value)];
  else 
    return [super bitXor:operand];
}       

- (NSNumber *)ceiling
{
  return numberWithDouble(ceil(value));
}

- (NSNumber *)clone { return [[self copy] autorelease]; }

- (NSNumber *)cos
{
  return numberWithDouble(cos(value));
}

- (NSNumber *)cosh
{
  return numberWithDouble(cosh(value));
}

- (NSNumber *)erf
{
  return numberWithDouble(erf(value));
}

- (NSNumber *)erfc
{
  return numberWithDouble(erfc(value));
}

- (NSNumber *)exp
{
  return numberWithDouble(exp(value));  
}  

- (NSNumber *)floor
{
  return numberWithDouble(floor(value));  
}  

- (NSNumber *)fractionPart
{
  double ip;
  return numberWithDouble(modf(value,&ip));
}

- (NSNumber *)integerPart
{
  double ip;
  modf(value,&ip);
  return numberWithDouble(ip);
}

- (NSNumber *)ln
{ 
  if(value <= 0.0) FSExecError(@"receiver of message \"ln\" must be positive");
  return numberWithDouble(log(value));
}

- (NSNumber *)log
{
  if(value <= 0.0) FSExecError(@"receiver of message \"log\" must be positive");
  return numberWithDouble(log10(value));
}

- (NSNumber *)max:(NSNumber *)operand
{
  if (operand && ((id)operand)->isa == FSNumberClass) return value > ((FSNumber *)operand)->value ? (NSNumber *)self : operand;
  else return [super max:operand]; 
}  

- (NSNumber *)min:(NSNumber *)operand
{
  if (operand && ((id)operand)->isa == FSNumberClass)  return value < ((FSNumber *)operand)->value ? (NSNumber *)self : operand;
  else return [super min:operand];
}  

- (NSNumber *) negated
{
  return numberWithDouble(-value);
}

- (NSNumber *)operator_asterisk:(NSNumber *)operand 
{  
  if (operand && ((id)operand)->isa == FSNumberClass) return numberWithDouble(value * ((FSNumber *)operand)->value); 
  else                                              return [super operator_asterisk:operand];   
}  

- (NSNumber *)operator_hyphen:(NSNumber *)operand
{
  if (operand && ((id)operand)->isa == FSNumberClass) return numberWithDouble(value - ((FSNumber *)operand)->value); 
  else                                              return [super operator_hyphen:operand];   
}        

#if TARGET_OS_IPHONE
- (CGPoint)operator_less_greater:(NSNumber *)operand
{
  if (operand && ((id)operand)->isa == FSNumberClass && value >= -CGFLOAT_MAX && value <= CGFLOAT_MAX && ((FSNumber *)operand)->value >= -CGFLOAT_MAX && ((FSNumber *)operand)->value <= CGFLOAT_MAX) 
    return CGPointMake(value,((FSNumber *)operand)->value); 
  else                                              
    return [super operator_less_greater:operand];   
}
#else
- (NSPoint)operator_less_greater:(NSNumber *)operand
{
  if (operand && ((id)operand)->isa == FSNumberClass && value >= -CGFLOAT_MAX && value <= CGFLOAT_MAX && ((FSNumber *)operand)->value >= -CGFLOAT_MAX && ((FSNumber *)operand)->value <= CGFLOAT_MAX) 
    return NSMakePoint(value,((FSNumber *)operand)->value); 
  else                                              
    return [super operator_less_greater:operand];   
}
#endif

- (NSNumber *)operator_plus:(id)operand
{
  if (operand && ((id)operand)->isa == FSNumberClass) return numberWithDouble(value + ((FSNumber *)operand)->value); 
  else if (operand == fsFalse)                      return self;
  else if (operand == fsTrue)                       return numberWithDouble(value + 1);
  else                                              return [super operator_plus:operand];
} 
         
- (NSNumber *)operator_slash:(NSNumber *)operand
{
  if (operand && ((id)operand)->isa == FSNumberClass && ((FSNumber *)operand)->value != 0.0) 
    return numberWithDouble(value / ((FSNumber *)operand)->value);
  else                                                                                       
    return [super operator_slash:operand];    
}

- (FSBoolean *)operator_equal:(id)operand  
{ 
  if (operand && ((id)operand)->isa == FSNumberClass)  return (value == ((FSNumber *)operand)->value ? fsTrue : fsFalse);
  else                                               return [super operator_equal:operand];   
}

- (FSBoolean *)operator_tilde_equal:(id)operand
{ 
  if (operand && ((id)operand)->isa == FSNumberClass)  return (value != ((FSNumber *)operand)->value ? fsTrue : fsFalse);
  else                                               return [super operator_tilde_equal:operand];   
}

- (FSBoolean *)operator_greater:(NSNumber *)operand
{ 
  if (operand && ((id)operand)->isa == FSNumberClass)  return (value > ((FSNumber *)operand)->value ? fsTrue : fsFalse);
  else                                               return [super operator_greater:operand];   
}

- (FSBoolean *)operator_greater_equal:(NSNumber *)operand 
{
  if (operand && ((id)operand)->isa == FSNumberClass)  return (value >= ((FSNumber *)operand)->value ? fsTrue : fsFalse);
  else                                               return [super operator_greater_equal:operand];   
}    

- (FSBoolean *)operator_less:(id)operand
{
  if (operand && ((id)operand)->isa == FSNumberClass) return (value < ((FSNumber *)operand)->value ? fsTrue : fsFalse);
  else                                              return [super operator_less:operand];   
} 
    
- (FSBoolean *)operator_less_equal:(NSNumber *)operand  
{
  if (operand && ((id)operand)->isa == FSNumberClass) return (value <= ((FSNumber *)operand)->value ? fsTrue : fsFalse);
  else                                              return [super operator_less_equal:operand];   
} 

- (NSNumber *)raisedTo:(NSNumber *)operand 
{
  if (operand && ((id)operand)->isa == FSNumberClass) 
  {
    double operandValue = ((FSNumber *)operand)->value;
    if ((value < 0.0 && [(FSNumber *)operand hasFrac_bool]) || (value == 0.0 && operandValue <= 0.0)) 
      return [super raisedTo:operand];
    else      
      return numberWithDouble(pow(value, operandValue));
  }
  else return [super raisedTo:operand];  
}  

- (NSNumber *)random
{
  if (value > 2147483647) FSExecError([NSString stringWithFormat:@"receiver of message \"random\" must be less than 2 raisedTo:31 (i.e., 2147483648)"]);
  else if (value < 1)     FSExecError(@"receiver of message \"random\" must be greater or equal to 1");
                        
  return numberWithDouble(random() % ((long)value));
} 
  
- (NSNumber *)rem:(NSNumber *)operand 
{  
  if (operand && ((id)operand)->isa == FSNumberClass && ((FSNumber *)operand)->value != 0.0)
    return numberWithDouble(fmod(value,((FSNumber *)operand)->value));
  else 
    return [super rem:operand];   
}

- (NSNumber *)sin
{
  return numberWithDouble(sin(value));
}

- (NSNumber *)sign
{
  if      (value > 0) return numberWithDouble(1);
  else if (value < 0) return numberWithDouble(-1);
  else                return numberWithDouble(0);
}

- (NSNumber *)sinh
{
  return numberWithDouble(sinh(value));
}

- (NSNumber *)sqrt
{
  if(value < 0.0)
    FSExecError(@"receiver of message \"sqrt\" must not be negative");
             
  return numberWithDouble(sqrt(value));
}

- (NSNumber *)tan
{
  return numberWithDouble(tan(value));
}

- (NSNumber *)tanh
{
  return  numberWithDouble(tanh(value));
}

- (NSNumber *)truncated
{
  return numberWithDouble((value > 0 ? floor(value) : ceil(value)));  
}

/*
- (void) testperf
{
   NSUInteger nb = 2000000;
   NSInteger *t = malloc(sizeof(double) * nb);
   NSUInteger i;
   NSDate *s;   
   NSDate *e; 
   double acu;
   NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

   for (i=0; i < nb; i++) t[i] = i;

   s = [NSDate date];
   
   acu = t[0];

   for (i=1; i < nb; i++) acu += t[i];

   e = [NSDate date];
  
    NSLog([NSString stringWithFormat:@"result = %.20g , time =%.20g",acu,[e timeIntervalSinceReferenceDate] - [s timeIntervalSinceReferenceDate]]);

   free(t);
   
   [pool release];
}
*/

/////////////////////////////////   SYSTEM METHODS  
             
+ (id) alloc
{
   return NSAllocateObject(self, 0, NULL);
}             
                                       
+ allocWithZone:(NSZone *)zone
{
  return NSAllocateObject(self, 0, NULL);
}

+ numberWithDouble:(double)val
{
   return numberWithDouble(val);
}  

- copy                        {retainCount++; return self; }

- copyWithZone:(NSZone *)zone {retainCount++; return self; }

- (void)dealloc
{
  NSDeallocateObject(self);
  return; [super dealloc]; // To avoid the warning "missing a [super dealloc] call"
}  

/*- (NSString *) description
{
  return [NSString stringWithFormat:@"%.16g",value];
} */

- (double)doubleValue
{
  return value;
}    
  
- (BOOL) hasFrac_bool
{
  return (value != floor(value));
}  

- (id)initWithCoder:(NSCoder *)coder // this method is here for backward compatibility with old archives (when Number was not a subclass of NSNumber)
{
  //NSLog(@"initWithCoder:");
  self = [super init];
  retainCount = 1;

  if ([coder allowsKeyedCoding])
  {
    value = [coder decodeDoubleForKey:@"Number value"];
  } 
  else 
  {
    double tmp;
    [coder decodeValueOfObjCType:@encode(double) at:&tmp];
	value = tmp;
  }
  return self;
}

- (id)initWithBool:(BOOL)val {return [self initWithDouble:val];}
- (id)initWithChar:(char)val {return [self initWithDouble:val];}

- initWithDouble:(double)val // designated initializer
{
  if ((self = [super init]))
  {
    retainCount = 1;
    value = val;
    return self;
  }
  return nil;
}

- (id)initWithFloat:(float)val {return [self initWithDouble:val];}
- (id)initWithInt:(int)val {return [self initWithDouble:val];}
- (id)initWithLong:(long)val {return [self initWithDouble:val];}
- (id)initWithShort:(short)val {return [self initWithDouble:val];}
- (id)initWithUnsignedChar:(unsigned char)val {return [self initWithDouble:val];}
- (id)initWithUnsignedInt:(unsigned int)val {return [self initWithDouble:val];}
- (id)initWithUnsignedLong:(unsigned long)val {return [self initWithDouble:val];}
- (id)initWithUnsignedShort:(unsigned short)val {return [self initWithDouble:val];}
   
- (BOOL) isEqual:anObject
{
  if (anObject && anObject->isa == FSNumberClass) // direct isa access for better performance
    return value == ((FSNumber *)anObject)->value;
  else 
    return [super isEqual:anObject];
}
   
- (id)retain  { retainCount++; return self; }

- (NSUInteger)retainCount  { return retainCount; }

- (void)release  { if (--retainCount == 0) [self dealloc]; }  


///////////////// NSValue Class cluster primitives methods are implemented here

- (void)getValue:(void *)buffer
{
  //NSLog(@"getValue: called");
  *(double *)buffer = value;
}

- (const char *)objCType 
{
  //NSLog(@"objCType called");
  return @encode(typeof(value));
}

@end
