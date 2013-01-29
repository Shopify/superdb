#ifdef __OBJC__

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

#endif