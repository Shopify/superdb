/*
 *  iOS-glue.m
 *  FScript-iOS
 *
 *  Created by Steve White on 8/16/11.
 *  Copyright 2011 Steve White. All rights reserved.
 *
 */

#include "iOS-glue.h"

void *
NSAllocateCollectable(NSUInteger size, NSUInteger options)
{
  return NSZoneCalloc(NSDefaultMallocZone(), 1, size);
}

void *
NSReallocateCollectable(void *ptr, NSUInteger size, NSUInteger options)
{
  return NSZoneRealloc(0, ptr, size);
}

void *objc_memmove_collectable(void *dst, const void *src, size_t size)
{
  return memmove(dst,src,size);
}
