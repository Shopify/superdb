/*   FSCNDictionary.h Copyright (c) 2009 Philippe Mougin. */
/*   This software is open source. See the license.       */

#import "FSCNBase.h"

@interface FSCNDictionary : FSCNBase 
{
  @public
    unsigned count;
    __strong FSCNBase **entries;
}

- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;
- (id)initWithEntries:(NSArray *)theElements;
- (void)translateCharRange:(long)translation;

@end

