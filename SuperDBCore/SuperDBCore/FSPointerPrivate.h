/*   FSPointerPrivate.h Copyright (c) 2004-2009 Philippe Mougin.   */
/*   This software is open source. See the license.  */  

@interface FSPointer (Private)
- (id) initWithCPointer:(void *)p;  // designated initializer
@end

extern void FSPointer_validateDereferencingWithSelector_index(FSPointer *s, SEL selector, id i);
