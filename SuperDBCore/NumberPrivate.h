/* NumberPrivate.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

extern id FSNumberClass; 
extern id NSNumberClass;  

//   MACROS
#define VERIF_OP_NSNUMBER(METHOD) {if (![operand isKindOfClass:NSNumberClass]) FSArgumentError(operand,1,@"NSNumber",METHOD);}
