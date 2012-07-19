/*   FSClassDefinition.h Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import <Foundation/Foundation.h>

@interface FSClassDefinition : NSObject 
{
@package
  NSMutableArray  *methodHolders;
  NSSet           *ivarNames;
}

+ classDefinition;
- (NSSet *)ivarNames;
- (NSMutableArray *)methodHolders;
- (void)setIvarNames:(NSSet *)theIvarNames;

@end
