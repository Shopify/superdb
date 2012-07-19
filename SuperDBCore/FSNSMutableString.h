/*   FSNSMutableString.h Copyright (c) 2000 Philippe Mougin.  */
/*   This software is open source. See the license.       */  

#import <Foundation/Foundation.h>

@interface NSMutableString (FSNSMutableString)

- (NSString *)clone __attribute__((deprecated));
- (void)insert:(NSString *)str at:(NSNumber *)index;
- (void)setValue:(id)operand;

@end
