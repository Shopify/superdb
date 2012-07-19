/* FSNSStringPrivate.h Copyright (c) 2000-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

//////////////  MACROS

#define VERIF_OP_NSSTRING(METHOD) {if (![operand isKindOfClass:[NSString class]]) FSArgumentError(operand,1,@"NSString",METHOD);}
