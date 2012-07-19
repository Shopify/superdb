/*
 *  allocations.h
 *  FScript-iOS
 *
 *  Created by Steve White on 8/16/11.
 *  Copyright 2011 Steve White. All rights reserved.
 *
 */

#import <Foundation/NSObjCRuntime.h>

enum {
  NSScannedOption = (1<<0),
  NSCollectorDisabledOption = (1<<1),
};

void *
NSAllocateCollectable(NSUInteger size, NSUInteger options);

void *
NSReallocateCollectable(void *ptr, NSUInteger size, NSUInteger options); 

void *objc_memmove_collectable(void *dst, const void *src, size_t size);
