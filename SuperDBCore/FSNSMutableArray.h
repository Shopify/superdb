/* FSNSMutableArray.h Copyright (c) 2003-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import <Foundation/Foundation.h>


@interface NSMutableArray(FSNSMutableArray) 

// User methods 
- (void)add:(id)elem;
- (id)at:(id)index put:(id)elem;
- (void)insert:(id)obj at:(NSNumber *)index;
- (void)removeAt:(id)index;
- (void)setValue:(NSArray *)operand;

@end
