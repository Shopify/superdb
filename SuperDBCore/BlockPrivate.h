/* BlockPrivate.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSBlock.h"

@class FSInterpreterResult;
@class FSBlockCompilationResult;

@interface FSBlock (BlockPrivate)

- (BlockRep *)blockRep;
- (id)body_compact_valueArgs:(id*)args count:(NSUInteger)count;
- (id)body_notCompact_valueArgs:(id*)args count:(NSUInteger)count;
- (FSBlockCompilationResult *)compilation; // Compil the receiver if needed. Return the result of the compilation. 
- (void)evaluateWithDoubleFrom:(double)start to:(double)stop by:(double)step;
- (BlockInspector *)inspector; 
- (SEL)messageToArgumentSelector;
- (FSBlock *)totalCopy;
- (void)setNewRepAfterCompilation:(BlockRep*)newRep;
- sync;         

@end
