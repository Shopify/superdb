/*   FSCNClassDefinition.m Copyright (c) 2007-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSCNClassDefinition.h"
#import "FSCNMethod.h"

@implementation FSCNClassDefinition

- (NSString *)className 
{ 
  return className; 
}

- (NSArray  *) civarNames
{
  return civarNames;
}


-(void)dealloc
{
  [className      release];
  [superclassName release];
  [civarNames     release];
  [ivarNames      release];
  [methods        release];
  [super dealloc];
}

- (NSString *)description
{
  return @"Class definition"; 
}

- (void)encodeWithCoder:(NSCoder *)coder
{  
  [super encodeWithCoder:coder];
  [coder encodeObject:className forKey:@"className"];
  [coder encodeObject:superclassName forKey:@"superclassName"];
  [coder encodeObject:civarNames forKey:@"civarNames"];
  [coder encodeObject:ivarNames forKey:@"ivarNames"];
  [coder encodeObject:methods forKey:@"methods"];
}     

- (id) initWithClassName:(NSString *)theClassName superclassName:(NSString *)theSuperclassName civarNames:(NSArray *)theCIvarNames ivarNames:(NSArray *)theIvarNames methods:(NSArray *)theMethods
{
  self = [super init];
  if (self != nil) 
  {
    nodeType       = CLASS_DEFINITION;
    className      = [theClassName retain];
    superclassName = [theSuperclassName retain];
    civarNames     = [theCIvarNames retain];
    ivarNames      = [theIvarNames retain];
    methods        = [theMethods retain];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  className      = [[coder decodeObjectForKey:@"className"] retain];
  superclassName = [[coder decodeObjectForKey:@"superclassName"] retain];
  civarNames      = [[coder decodeObjectForKey:@"civarNames"] retain];
  ivarNames      = [[coder decodeObjectForKey:@"ivarNames"] retain];
  methods        = [[coder decodeObjectForKey:@"methods"] retain];
  return self;
}

- (NSArray  *) ivarNames
{
  return ivarNames;
}

- (NSString *) superclassName
{ 
  return superclassName; 
}

- (void)translateCharRange:(long)translation
{
  [super translateCharRange:translation];
  
  for (FSCNMethod *method in methods) 
  {
    [method translateCharRange:translation];
  }
}

@end