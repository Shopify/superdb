//
//  JBShellViewBlockTypedefs.h
//  Super Debug
//
//  Created by Jason Brennan on 12-07-19.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#ifndef Super_Debug_JBShellViewBlockTypedefs_h
#define Super_Debug_JBShellViewBlockTypedefs_h

@class JBShellView;
typedef void (^JBShellViewInputProcessingHandler)(NSString *input, JBShellView *sender);
typedef void (^JBShellViewDragHandler)(id draggedObject);

#endif
