/*   FSCNClassDefinition.h Copyright (c) 2007-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSCNBase.h"

@interface FSCNClassDefinition : FSCNBase 
{
  @public  
    NSString *className;
    NSString *superclassName;
    NSArray  *civarNames;
    NSArray  *ivarNames;
    NSArray  *methods;
}

- (NSString *) className;
- (NSArray  *) civarNames; 
- (void) dealloc;
- (void) encodeWithCoder:(NSCoder *)coder;
- (id) initWithCoder:(NSCoder *)coder;
- (id) initWithClassName:(NSString *)theClassName superclassName:(NSString *)theSuperclassName civarNames:(NSArray *)theCIvarNames ivarNames:(NSArray *)theIvarNames methods:(NSArray *)theMethods;
- (NSArray  *) ivarNames; 
- (NSString *) superclassName;
- (void)translateCharRange:(long)translation;

@end