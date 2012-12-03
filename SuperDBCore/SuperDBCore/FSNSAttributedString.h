/*   FSNSAttributedString.h Copyright (c) 2004-2009 Philippe Mougin.  */
/*   This software is open source. See the license.   */  

#if TARGET_OS_IPHONE
# import <Foundation/Foundation.h>
#else
# import <AppKit/AppKit.h>
#endif

@interface NSAttributedString (FSNSAttributedString)

-(void)inspect;

@end

