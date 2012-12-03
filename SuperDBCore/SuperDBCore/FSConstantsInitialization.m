/* ConstantsInitialisation.m Copyright (c) 1999-2009 Philippe Mougin.  */
/*   This software is open source. See the licence.  */  

#import "FSConstantsInitialization.h"
#import "FSInterpreter.h"
#import "FSGenericPointerPrivate.h"

#if !TARGET_OS_IPHONE
# import <AppKit/AppKit.h>
# import <CoreAudio/AudioHardware.h>
# import <IOBluetooth/OBEX.h>
#endif

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

void FSConstantsInitialization(NSMutableDictionary *d)
{
  NSString *path;
  NSBundle *bundle = [NSBundle bundleForClass:[FSInterpreter class]];
  NSString *constantsDictionaryFileName = @"constantsDictionary";

  if ((path = [bundle pathForResource:constantsDictionaryFileName ofType:@""]))
  {
    [d addEntriesFromDictionary:[NSKeyedUnarchiver unarchiveObjectWithFile:path]]; 
  } 
 
  if (NSErrorMergePolicy)                      [d setObject:NSErrorMergePolicy                      forKey:@"NSErrorMergePolicy"]; 
  if (NSMergeByPropertyStoreTrumpMergePolicy)  [d setObject:NSMergeByPropertyStoreTrumpMergePolicy  forKey:@"NSMergeByPropertyStoreTrumpMergePolicy"]; 
  if (NSMergeByPropertyObjectTrumpMergePolicy) [d setObject:NSMergeByPropertyObjectTrumpMergePolicy forKey:@"NSMergeByPropertyObjectTrumpMergePolicy"]; 
  if (NSOverwriteMergePolicy)                  [d setObject:NSOverwriteMergePolicy                  forKey:@"NSOverwriteMergePolicy"]; 
  if (NSRollbackMergePolicy)                   [d setObject:NSRollbackMergePolicy                   forKey:@"NSRollbackMergePolicy"]; 
 
  [d setObject:[NSNumber numberWithUnsignedLongLong:NSNotFound]   forKey:@"NSNotFound"];
  [d setObject:[NSNumber numberWithLong:NSIntegerMax]             forKey:@"NSIntegerMax"];
  [d setObject:[NSNumber numberWithLong:NSIntegerMin]             forKey:@"NSIntegerMin"];
  [d setObject:[NSNumber numberWithUnsignedLong:NSUIntegerMax]    forKey:@"NSUIntegerMax"];
  [d setObject:[NSNumber numberWithLong:NSUndefinedDateComponent] forKey:@"NSUndefinedDateComponent"];
  
#if !TARGET_OS_IPHONE
  if (NSMultipleValuesMarker) [d setObject:NSMultipleValuesMarker forKey:@"NSMultipleValuesMarker"]; 
  if (NSNoSelectionMarker)    [d setObject:NSNoSelectionMarker    forKey:@"NSNoSelectionMarker"]; 
  if (NSNotApplicableMarker)  [d setObject:NSNotApplicableMarker  forKey:@"NSNotApplicableMarker"];

#ifdef __LP64__
  // 64-bit code
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:(CGFloat *)NSFontIdentityMatrix freeWhenDone:NO type:"d"] autorelease] forKey:@"NSFontIdentityMatrix"];
#else
  // 32-bit code
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:(CGFloat *)NSFontIdentityMatrix freeWhenDone:NO type:"f"] autorelease] forKey:@"NSFontIdentityMatrix"];
#endif

  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioAggregateDeviceIsPrivateKey       freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioAggregateDeviceIsPrivateKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioAggregateDeviceMasterSubDeviceKey freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioAggregateDeviceMasterSubDeviceKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioAggregateDeviceNameKey            freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioAggregateDeviceNameKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioAggregateDeviceSubDeviceListKey   freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioAggregateDeviceSubDeviceListKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioAggregateDeviceUIDKey             freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioAggregateDeviceUIDKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioHardwareRunLoopMode               freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioHardwareRunLoopMode"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioSubDeviceDriftCompensationKey     freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioSubDeviceDriftCompensationKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioSubDeviceExtraInputLatencyKey     freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioSubDeviceExtraInputLatencyKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioSubDeviceExtraOutputLatencyKey    freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioSubDeviceExtraOutputLatencyKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioSubDeviceInputChannelsKey         freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioSubDeviceInputChannelsKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioSubDeviceNameKey                  freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioSubDeviceNameKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioSubDeviceOutputChannelsKey        freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioSubDeviceOutputChannelsKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioSubDeviceUIDKey                   freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioSubDeviceUIDKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioSubDeviceDriftCompensationKey     freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioSubDeviceDriftCompensationKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioSubDeviceExtraInputLatencyKey     freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioSubDeviceExtraInputLatencyKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioSubDeviceExtraOutputLatencyKey    freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioSubDeviceExtraOutputLatencyKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioSubDeviceInputChannelsKey         freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioSubDeviceInputChannelsKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioSubDeviceNameKey                  freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioSubDeviceNameKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioSubDeviceOutputChannelsKey        freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioSubDeviceOutputChannelsKey"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kAudioSubDeviceUIDKey                   freeWhenDone:NO type:"c"] autorelease] forKey:@"kAudioSubDeviceUIDKey"];

  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kCharsetStringISO88591         freeWhenDone:NO type:"c"] autorelease] forKey:@"kCharsetStringISO88591"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kCharsetStringUTF8             freeWhenDone:NO type:"c"] autorelease] forKey:@"kCharsetStringUTF8"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kEncodingString8Bit            freeWhenDone:NO type:"c"] autorelease] forKey:@"kEncodingString8Bit"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kEncodingStringBase64          freeWhenDone:NO type:"c"] autorelease] forKey:@"kEncodingStringBase64"];
  [d setObject:[[[FSGenericPointer alloc] initWithCPointer:kEncodingStringQuotedPrintable freeWhenDone:NO type:"c"] autorelease] forKey:@"kEncodingStringQuotedPrintable"];

  [d setObject:[NSValue valueWithPoint:NSZeroPoint] forKey:@"NSZeroPoint"];
  [d setObject:[NSValue valueWithRect:NSZeroRect]   forKey:@"NSZeroRect"];
  [d setObject:[NSValue valueWithSize:NSZeroSize]   forKey:@"NSZeroSize"];
#else
  [d setObject:[NSValue valueWithCGPoint:CGPointZero] forKey:@"CGPointZero"];
  [d setObject:[NSValue valueWithCGRect:CGRectZero]   forKey:@"CGRectZero"];
  [d setObject:[NSValue valueWithCGSize:CGSizeZero]   forKey:@"CGSizeZero"];
#endif  
  // NSLog(@"constantsDictionary count = %lu", (unsigned long)[d count]);
}
