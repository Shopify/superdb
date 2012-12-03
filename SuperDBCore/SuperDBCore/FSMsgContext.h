/*   MsgContext.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import <Foundation/Foundation.h> 

@interface FSMsgContext:NSObject
{
@public
  BOOL               initialized;  
  BOOL               return_void;
  BOOL               shouldConvertArguments;
  BOOL               specialReturnType;
  BOOL               unsuportedReturnType;
  char               returnType;
  __strong char     *argumentTypes;
  NSMethodSignature *signature;
}

+ (FSMsgContext *) msgContext;

- (void)dealloc;
- init;
- (void)prepareForMessageWithReceiver:(id)receiver selector:(SEL)selector; // May raise
- (NSInteger)unsuportedArgumentIndex;
- (BOOL)unsuportedReturnType;

@end
