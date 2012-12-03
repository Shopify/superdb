/*   BlockStackElem.h Copyright (c) 2001-2009 Philippe Mougin.  */
/*   This software is open source. See the license.    */  

#import <Foundation/Foundation.h>

@class FSBlock;

@interface BlockStackElem : NSObject <NSCoding>
{
 NSInteger firstCharIndex; 
 NSInteger lastCharIndex;
 NSString *errorStr;
 FSBlock *block;
}

+ (BlockStackElem *)blockStackElemWithBlock:(FSBlock *)theBlock errorStr:(NSString *)theErrorStr firstCharIndex:(NSInteger)first lastCharIndex:(NSInteger)last;

- (FSBlock *)block;
- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (NSString *)errorStr;
- (NSInteger) firstCharIndex;
- (BlockStackElem *)initWithBlock:(FSBlock *)theBlock errorStr:(NSString *)theErrorStr firstCharIndex:(NSInteger)first lastCharIndex:(NSInteger)last;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (NSInteger) lastCharIndex;


@end
