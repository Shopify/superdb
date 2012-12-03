/* FSNSProxy.h Copyright (c) 1998-2009 Philippe Mougin.  */
/* This software is open source. See the license.  */  


#import "FSNSObject.h"
#import <Foundation/NSProxy.h>

@class FSBlock;


@interface NSProxy(FSNSProxy)

///////////////// USER METHODS //////////////

+ (id)classOrMetaclass;
+ (FSBoolean *)operator_equal_equal:(id)operand;
+ (FSBoolean *)operator_tilde_tilde:(id)operand;
+ (NSString *)printString;

- (id)classOrMetaclass;  


@end
