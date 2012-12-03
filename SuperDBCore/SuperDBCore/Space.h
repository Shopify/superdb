/* Space.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSExecutor.h"
#import "FSNSObject.h" 

@class FSSymbolTable;

@interface Space:NSObject <NSCoding>
{
@public
  FSSymbolTable *localSymbolTable;
}


////////////////////////  SYSTEM METHODS ////////////////////////////




- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)coder;
- initSymbolTableLocale:(FSSymbolTable*)symb_loc;  // Will point to symb_loc
- (id)initWithCoder:(NSCoder *)coder;
- (FSSymbolTable*)localSymbolTable;

@end
