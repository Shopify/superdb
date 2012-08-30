/*   FSVoid.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  


#import "FSVoid.h"
#import "build_config.h"

FSVoid *fsVoid;

@implementation FSVoid

+ (FSVoid *)fsVoid 
{ 
  return fsVoid;
}

+ (void)initialize
{
  static BOOL tooLate = NO;
  if ( !tooLate ) 
  {
    fsVoid = [[FSVoid alloc] init];
    tooLate = YES;
  }
}

-(id)autorelease                 {return self;}  

- awakeAfterUsingCoder:(NSCoder *)aDecoder
{
  [self release];
  return fsVoid;
}   
     
-(id)copy                        {return self;}

-(id)copyWithZone:(NSZone *)zone {return self;}

-(void)encodeWithCoder:(NSCoder *)coder {}

-(id)initWithCoder:(NSCoder *)coder {self = [super init]; return self;}

- (NSString *) printString   {return [NSMutableString stringWithString:@""]; }

- (void) release                    {}

- (id) retain                       {return self;}

- (NSUInteger) retainCount        {return  UINT_MAX;}

@end
