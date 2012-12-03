/*   PointerPrivate.h Copyright (c) 2002-2009 Philippe Mougin.   */
/*   This software is open source. See the license.         */  

#import "Pointer.h"

@interface Pointer(PointerPrivate)

+ (Pointer *) pointerWithCPointer:(void *)p type:(const char *)t; // t is copied. 
- (id) copyWithZone:(NSZone *)zone;
- (void *) cPointer; 
- (Pointer *) initWithCPointer:(void *)p type:(const char *)t;    // t is copied. 
- (char *) pointerType;

@end
