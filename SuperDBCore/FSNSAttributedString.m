/*   FSNSAttributedString.m Copyright (c) 2004-2009 Philippe Mougin.  */
/*   This software is open source. See the license.   */

#import "FSNSAttributedString.h"
#if !TARGET_OS_IPHONE
# import "FSAttributedStringInspector.h"
#endif

@implementation NSAttributedString (FSNSAttributedString)

-(void)inspect
{
#if !TARGET_OS_IPHONE
  [FSAttributedStringInspector attributedStringInspectorWithAttributedString:self];
#endif
}

@end

