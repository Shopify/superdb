/*   FSMethod.m Copyright (c) 2007-2009 Philippe Mougin.  */
/*   This software is open source. See the license.     */   

#import "FSMethod.h"
#import <objc/message.h>
#import "FSBlock.h"
#import "FSSymbolTable.h"
#import "FScriptFunctions.h"
#import "FSCompiler.h"
#import "FSClassDefinition.h"
#include <sys/mman.h>
#import "FSExecEngine.h"
#import "FSMiscTools.h"
#import "FScriptFunctions.h"
#import "FSReturnSignal.h"
#import "FSSymbolTable.h"

@class FSMethodHolder;

//static NSMutableDictionary *classes;
static CFMutableDictionaryRef          classes;
static CFMutableDictionaryRef          instances;

@interface FSMethodHolder : NSObject 
{
  @package
  FSMethod *method;
}

- (void *) dispatcher;
- initWithMethod:(FSMethod *)theMethod;
- (void)setMethod:(FSMethod *)theMethod;

@end

void __attribute__ ((constructor)) initializeFScriptClassSystem(void)
{
  CFDictionaryKeyCallBacks keycb = {
    0,
    kCFTypeDictionaryKeyCallBacks.retain,
    kCFTypeDictionaryKeyCallBacks.release,
    kCFTypeDictionaryKeyCallBacks.copyDescription,
    NULL,
    NULL
  };

  classes = CFDictionaryCreateMutable(NULL, 0, &keycb, &kCFTypeDictionaryValueCallBacks);
  instances = CFDictionaryCreateMutable(NULL, 0, &keycb, &kCFTypeDictionaryValueCallBacks);
}


static id executeMethod(FSMethod *method, FSSymbolTable *symbolTable, id receiver) 
{
  NSInteger errorFirstCharIndex, errorLastCharIndex; // Not currently used. TODO: make use of the information available in these variables
  id result;
  
  @try
  {
    result = execute_rec(method->code, symbolTable, &errorFirstCharIndex, &errorLastCharIndex);
  }
  @catch (FSReturnSignal *returnSignal)
  {
    FSSymbolTable *signalSymbolTable = [returnSignal symbolTable];
    
    while (signalSymbolTable != nil && signalSymbolTable != symbolTable)
      signalSymbolTable = [signalSymbolTable parent];
    
    if (signalSymbolTable != nil) result = [returnSignal result]; 
    else                          
    {
      @throw;
      assert(0); return nil;  
    }
  }  
  @finally 
  {
    if (method->selector == @selector(dealloc))
    {
      // The receiver has been deallocated. Therefore, we must ensure that when symbolTable gets deallocated, it does not send a release message to this deallocated object.  
      symbolTable->locals[0].value = nil;      
    }
    else if (! symbolTable->receiverRetained)
    {
      [symbolTable->locals[0].value retain];
      symbolTable->receiverRetained = YES;
    }
  } 
  
  if (method->selector == @selector(dealloc))
  {
    @synchronized((NSDictionary *)instances)
    {
      CFDictionaryRemoveValue(instances, receiver);
    }
  }
  
  return result;  
}

static void dispatch(ffi_cif *cif, void *result, void **args, void *userdata)
{
  id             receiver    = *(id  *)args[0];
  SEL            selector    = *(SEL *)args[1];
  FSMethod      *method      = ((FSMethodHolder *)userdata)->method;
  
  FSSymbolTable *symbolTable = [[method->symbolTable copyWithZone:NULL] autorelease];
  
  symbolTable->locals[0].value  = receiver; 
  symbolTable->receiverRetained = NO;
  symbolTable->locals[0].status = DEFINED;
  
  for (NSUInteger i = 2; i < method->argumentCount; i++)
  {
    char fsEncodedType = method->fsEncodedTypes[i+1];
    
    if (fsEncodedType == '@')
      symbolTable->locals[i-1].value = *(id *)args[i];
    else
      symbolTable->locals[i-1].value = FSMapToObject(args[i], 0, fsEncodedType, method->typesByArgument[i], nil, nil);
    
    [symbolTable->locals[i-1].value retain];
    symbolTable->locals[i-1].status = DEFINED;
  }
  
  char returnType = method->fsEncodedTypes[0];
  
  switch (returnType)
  {
    case 'v' :                    executeMethod(method, symbolTable, receiver); break;  
    case '@' : *(id    *)result = executeMethod(method, symbolTable, receiver); break;      
    default  : FSMapFromObject(result, 0, returnType, executeMethod(method, symbolTable, receiver), FSMapReturnValue, 0, selector, nil, NULL);
  }    
}

id fscript_dynamicIvarValue(id instance, NSString *ivarName, BOOL *found)
{ 
  FSSymbolTable *dynamicIvars;
  id value;
  
  @synchronized((NSDictionary *)instances)
  {
    dynamicIvars = (id)CFDictionaryGetValue(instances, instance);
    if (dynamicIvars) 
    {
      value = [dynamicIvars objectForSymbol:ivarName found:found];
      if (*found) return value;
    }
  }
      
  @synchronized((NSDictionary *)classes)
  {
    Class class = object_getClass(instance);
    
    while (class)
    {
      FSClassDefinition *classDefinition = (id)CFDictionaryGetValue(classes, class);
    
      if (!classDefinition) break;
      else if ([[classDefinition ivarNames] containsObject:ivarName])
      {
        *found = YES;
        return nil;
      }
      
      class = [class superclass];
    }
  }
  
  *found = NO;
  return nil;    
}
 
NSSet *fscript_dynamicIvarNames(Class class)
{
  // Note: do not return the names of inherited dynamic ivars, only the names of dynamic ivar directly defined by the class 
  
  NSSet *result; // We use this temp because ObjC emits wacky warnings ("control reaching end of non void function") 
                 // if we simply return from the @synchonized block (GCC 4.2)
  
  @synchronized((NSDictionary *)classes)
  {
    FSClassDefinition *classDefinition = (id)CFDictionaryGetValue(classes, class);
    
    if (classDefinition) result = [classDefinition ivarNames];
    else                 result = [NSSet set];
  }
  return result;
}

BOOL fscript_isFScriptClass(Class class)
{  
  BOOL r;
  
  @synchronized((NSDictionary *)classes)
  {
    r = CFDictionaryGetValue(classes, class) != NULL;
  }
  return r;
}

void fscript_registerFScriptClassPair(Class class)
{
  @synchronized((NSDictionary *)classes)
  {
    if (CFDictionaryGetValue(classes, class) == NULL) 
    {
      CFDictionarySetValue(classes, class, [FSClassDefinition classDefinition]);
    }
        
    if (CFDictionaryGetValue(classes, object_getClass(class)) == NULL) 
    {
      CFDictionarySetValue(classes, object_getClass(class), [FSClassDefinition classDefinition]);
    }
  }
}

BOOL fscript_setDynamicIvarValue(id instance, NSString *ivarName, id value)
{   
  FSSymbolTable *dynamicIvars;
  BOOL found = NO;
  
  @synchronized((NSDictionary *)instances)
  {
    dynamicIvars = (id)CFDictionaryGetValue(instances, instance);
    if (!dynamicIvars)
    {
      dynamicIvars = [FSSymbolTable symbolTable];
      CFDictionarySetValue(instances, instance, dynamicIvars);
    }
    
    struct FSContextIndex locationInContext = [dynamicIvars indexOfSymbol:ivarName];
  
    if (locationInContext.index != -1)
    {
      found = YES;
      [dynamicIvars setObject:value forIndex:locationInContext];
    }
    else
    {
      Class class = [instance classOrMetaclass];

      @synchronized((NSDictionary *)classes)
      {
        while (class != nil && !found) 
        {
          FSClassDefinition *classDefinition = (id)CFDictionaryGetValue(classes, class);
          if ([[classDefinition ivarNames] containsObject:ivarName])
          {
            found = YES;
            [dynamicIvars setObject:value forSymbol:ivarName];
          }
          else 
          {
            class = [class superclass];
          }
        }
      }
    }      
  }
    
  return found;  
}

void fscript_setDynamicIvarNames(Class class, NSSet *ivarNames)
{
  // precondition: class must be a registered F-Script class
  
  @synchronized((NSDictionary *)classes)
  {
    FSClassDefinition *classDefinition = (id)CFDictionaryGetValue(classes, class);
    
    if (classDefinition)
    {
      [classDefinition setIvarNames:ivarNames];
    } 
    else FSExecError(@"F-Script internal error in fscript_setDynamicIvarNames(): class definition not found");
  }
}

@implementation FSMethodHolder

- initWithMethod:(FSMethod *)theMethod
{
  self = [super init];
  if (self != nil) 
  {
    method = [theMethod retain];
  }
  return self;
}

- (void *) dispatcher
{
  ffi_status    status;
  ffi_type    **ffiTypesByArgument;  
  ffi_cif      *cif;
  ffi_closure  *closure;
  ffi_type     *returnType = ffiTypeFromFSEncodedType(method->fsEncodedTypes[0]);
  
  size_t size = sizeof(ffi_type *) * method->argumentCount;
  ffiTypesByArgument = malloc(size);
  
  ffiTypesByArgument[0] = ffiTypeFromFSEncodedType(method->fsEncodedTypes[1]);
  ffiTypesByArgument[1] = ffiTypeFromFSEncodedType(method->fsEncodedTypes[2]);
  
  for (NSUInteger i = 2; i < method->argumentCount; i++) 
    ffiTypesByArgument[i] = ffiTypeFromFSEncodedType(method->fsEncodedTypes[i+1]);
  
  // Prepare the ffi_cif structure.
  cif = malloc(sizeof(ffi_cif));
  
  if ((status = ffi_prep_cif(cif, FFI_DEFAULT_ABI, method->argumentCount, returnType, ffiTypesByArgument)) != FFI_OK)
  {
    free(ffiTypesByArgument);
    free(cif);
    FSExecError(@"F-Script internal error: can't prepare the ffi_cif structure");
  }
  
  // Allocate a page to hold the closure with read and write permissions.
  if ((closure = mmap(NULL, sizeof(ffi_closure), PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0)) == (void*)-1)
  {
    free(ffiTypesByArgument);
    free(cif);
    FSExecError(@"F-Script internal error: can't allocate memory for the ffi_closure structure");
  }
  
  if ((status = ffi_prep_closure(closure, cif, dispatch, self)) != FFI_OK)
  {
    free(ffiTypesByArgument);
    free(cif);
    if (munmap(closure, sizeof(closure)) == -1)
    {
      FSExecError(@"F-Script internal error: can't free the memory associated with the ffi_closure");
    }      
    FSExecError(@"F-Script internal error: can't prepare the ffi_closure structure");
  }
  
  // Ensure that the closure will execute on all architectures.
  if (mprotect(closure, sizeof(closure), PROT_READ | PROT_EXEC) == -1)  
  {
    free(ffiTypesByArgument);
    free(cif);
    if (munmap(closure, sizeof(closure)) == -1)
    {
      FSExecError(@"F-Script internal error: can't free the memory associated with the ffi_closure");
    }          
    FSExecError(@"F-Script internal error: can't mprotect() the ffi closure memory");
  }
  return closure;
  
  // Note: once the closure is returned (and then installed in the run-time), we don't attempt to ever free it 
  // (neither the associated structures: ffiTypesByArgument and cif) as it might become referenced from other parts 
  // of the system (e.g. KVO's dynamicaly generated classes like to reference existing IMPs)
}

- (void)setMethod:(FSMethod *)theMethod
{
  [theMethod retain];
  [method release];
  method = theMethod;
}


@end


@implementation FSMethod

- (BOOL) addToClass:(Class)class
{
  // NSLog(@"Trying to add method %@ with types %@ and FSEncoded types %@ to class %@", NSStringFromSelector(selector), [NSString stringWithUTF8String:types], [NSString stringWithUTF8String:fsEncodedTypes], class);
  
  if (FSIsIgnoredSelector(selector))
  {        
    // We are in presence of a method with an "ignored selector"
    // Under GC, selectors for retain, release, autorelease, retainCount and dealloc are all represented by the same special non-functional "ignored" selector     
    // Since the method we try to add will never get called, we don't add it and we just return (adding it would cause problems because of the special selector)
    return YES; 
  }
  
  @synchronized((NSDictionary *)classes)
  {
    if (!CFDictionaryGetValue(classes, class)) CFDictionarySetValue(classes, class, [FSClassDefinition classDefinition]);
  }

  unsigned int methodCount, i;     
  Method *methods = class_copyMethodList(class, &methodCount); 

  for (i = 0; i < methodCount && method_getName(methods[i]) != selector ; i++);
  
  if (i < methodCount) 
  {
    // A method with the same selector is already defined in this class
    
    if (strcmp(method_getTypeEncoding(methods[i]), types) == 0)
    {
      @synchronized((NSDictionary *)classes)
      {
        NSMutableArray *methodHolders = [(id)CFDictionaryGetValue(classes, class) methodHolders];        
        unsigned int j = 0;
        for (FSMethodHolder *holder in methodHolders)
        {
          if (holder->method->selector == selector) break;
          j++;
        }
        
        if (j < [methodHolders count]) 
          [[methodHolders objectAtIndex:j] setMethod:self];
        else                           
        {
          FSMethodHolder *holder = [[[FSMethodHolder alloc] initWithMethod:self] autorelease];
          method_setImplementation(methods[i], [holder dispatcher]); 
          [methodHolders addObject:holder];
        }
      }
      free(methods);
      return YES;  
    }
    else 
    {
      free(methods);
      FSExecError([NSString stringWithFormat:@"can't modify the signature of method \"%@\" in class %@. When redefining an existing method, the new one and the original must have the same signature.", NSStringFromSelector(selector), NSStringFromClass(class)]);
    }
  }
  else
  {
    // This is a new method for this class
    
    BOOL done;
    free(methods);
    @synchronized((NSDictionary *)classes)
    {
      FSMethodHolder *holder = [[[FSMethodHolder alloc] initWithMethod:self] autorelease];
      done = class_addMethod(class, selector, [holder dispatcher], types);
      if (done) [[(id)CFDictionaryGetValue(classes, class) methodHolders] addObject:holder];
    }
    return done;
  }
}

- (void) dealloc
{
  [code release];
  [symbolTable release];
  free(types);
  free(fsEncodedTypes);
  for (NSUInteger i = 0; i < argumentCount; i++) 
  {
    free(typesByArgument[i]);
  }
  free(typesByArgument);  
  [super dealloc];
}


/*
- (void)encodeWithCoder:(NSCoder *)coder
{  
  [coder encodeObject:NSStringFromSelector(selector) forKey:@"selectorString"];
  [coder encodeObject:symbolTable forKey:@"symbolTable"];
  [coder encodeObject:code forKey:@"code"];
  [coder encodeInt32:argumentCount forKey:@"argumentCount"];  
  [coder encodeObject:[NSString stringWithCString:fsEncodedTypes encoding:NSUTF8StringEncoding] forKey:@"fsEncodedTypes"];
  [coder encodeObject:[NSString stringWithCString:types encoding:NSUTF8StringEncoding] forKey:@"types"];
  
  NSMutableArray *typesByArgumentNSArray = [NSMutableArray array];
  for (NSUInteger i = 0; i < argumentCount; i++)
  {
    [typesByArgumentNSArray addObject:[NSString stringWithCString:typesByArgument[i] encoding:NSUTF8StringEncoding]];
  }
  [coder encodeObject:typesByArgumentNSArray forKey:@"typesByArgument"];
}     


- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  
  selector = NSSelectorFromString([coder decodeObjectForKey:@"selector"]); 
  symbolTable = [[coder decodeObjectForKey:@"symbolTable"] retain];
  code = [[coder decodeObjectForKey:@"code"] retain];
  argumentCount = [coder decodeInt32ForKey:@"argumentCount"]; 
  
  NSString *fsEncodedTypesNSString = [coder decodeObjectForKey:@"fsEncodedTypes"];
  NSUInteger fsEncodedTypesLength = [fsEncodedTypesNSString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]+1;
  fsEncodedTypes = NSAllocateCollectable(fsEncodedTypesLength, 0);
  [fsEncodedTypesNSString getCString:fsEncodedTypes maxLength:fsEncodedTypesLength encoding:NSUTF8StringEncoding];  
  
  NSString *typesNSString = [coder decodeObjectForKey:@"types"];
  NSUInteger typesLength = [typesNSString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]+1;
  types = NSAllocateCollectable(typesLength, 0);
  [typesNSString getCString:types maxLength:typesLength encoding:NSUTF8StringEncoding];  
  
  NSArray *typesByArgumentNSArray= [coder decodeObjectForKey:@"typesByArgument"];
  typesByArgument = NSAllocateCollectable(argumentCount * sizeof(char *), NSScannedOption);
  for (NSUInteger i = 0; i < argumentCount; i++)
  {
    NSString *type = [typesByArgumentNSArray objectAtIndex:i];
    NSUInteger typeLength = [type lengthOfBytesUsingEncoding:NSUTF8StringEncoding]+1;
    typesByArgument[i] = NSAllocateCollectable(typeLength, 0);
    [type getCString:typesByArgument[i] maxLength:typeLength encoding:NSUTF8StringEncoding];
  }
  
  return self;
} 
*/

- (id) initWithSelector:(SEL)theSelector fsEncodedTypesPtr:(char *)theFSEncodedTypes typesPtr:(char *)theTypes typesByArgumentPtr:(char  **)theTypesByArgument argumentCount:(NSUInteger)theArgumentCount code:(FSCNBase *)theCode symbolTable:(FSSymbolTable *)theSymbolTable 
{
  self = [super init];
  if (self != nil) 
  {
    selector        = theSelector;
    fsEncodedTypes  = theFSEncodedTypes;
    types           = theTypes;
    typesByArgument = theTypesByArgument;    
    argumentCount   = theArgumentCount;
    code            = [theCode retain];
    symbolTable     = [theSymbolTable retain];
  }
  
  return self;  
}

- (id) initWithSelector:(SEL)theSelector fsEncodedTypes:(NSString *)theFSEncodedTypes types:(NSString *)theTypes typesByArgument:(NSArray *)theTypesByArgument argumentCount:(NSUInteger)theArgumentCount code:(FSCNBase *)theCode symbolTable:(FSSymbolTable *)theSymbolTable 
{
  selector        = theSelector;
  argumentCount   = theArgumentCount;
  code            = [theCode retain];
  symbolTable     = [theSymbolTable retain];
  
  NSUInteger fsEncodedTypesLength = [theFSEncodedTypes lengthOfBytesUsingEncoding:NSUTF8StringEncoding]+1;
  fsEncodedTypes = NSAllocateCollectable(fsEncodedTypesLength, 0);
  if (fsEncodedTypes == NULL)
  {
    [super dealloc];
    return nil;
  }  
  [theFSEncodedTypes getCString:fsEncodedTypes maxLength:fsEncodedTypesLength encoding:NSUTF8StringEncoding];
  
  NSUInteger typesLength = [theTypes lengthOfBytesUsingEncoding:NSUTF8StringEncoding]+1;
  types = NSAllocateCollectable(typesLength, 0);
  if (types == NULL)
  {
    [super dealloc];
    return nil;
  }  
  [theTypes getCString:types maxLength:typesLength encoding:NSUTF8StringEncoding];
  
  typesByArgument = NSAllocateCollectable(argumentCount * sizeof(char *), NSScannedOption);
  for (NSUInteger i = 0; i < argumentCount; i++)
  {
    NSString *type = [theTypesByArgument objectAtIndex:i];
    NSUInteger typeLength = [type lengthOfBytesUsingEncoding:NSUTF8StringEncoding]+1;
    typesByArgument[i] = NSAllocateCollectable(typeLength, 0);
    [type getCString:typesByArgument[i] maxLength:typeLength encoding:NSUTF8StringEncoding];
  }
  
  return self; 
}

@end
