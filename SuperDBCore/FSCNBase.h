/*   FSCNBase.h Copyright (c) 2007-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import <Foundation/Foundation.h>
#import "FSArray.h"
#import "FSMsgContext.h"

enum FSCNType {IDENTIFIER, MESSAGE, STATEMENT_LIST, OBJECT, ARRAY, TEST_ABORT, BLOCK, ASSIGNMENT, NUMBER, CASCADE, 
               UNARY_MESSAGE, BINARY_MESSAGE, KEYWORD_MESSAGE, SUPER, CLASS_DEFINITION, CATEGORY, METHOD, RETURN, DICTIONARY};
// Note: in older versions of F-Script, the node type was archived directly as its FSCNType integer value. 
// Therefore, for backward compatibility with older archives, the order of this enum should not be modified.

@interface FSCNBase : NSObject <NSCoding>
{
  @public
    enum FSCNType nodeType;
    int32_t firstCharIndex;
    int32_t lastCharIndex;     
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (id)init;
- (void)setFirstCharIndex:(int32_t)first lastCharIndex:(int32_t)last;
- (void)translateCharRange:(int32_t)translation;
                
@end
