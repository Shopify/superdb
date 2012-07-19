/*   FSCNStatementList.m Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNStatementList.h"


@implementation FSCNStatementList

- (void)dealloc
{
  for (NSUInteger i = 0; i < statementCount; i++) [statements[i] release];
  free(statements);
  [super dealloc];
}

- (NSString *)description
{
  return @"Statement list"; 
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:[NSArray arrayWithObjects:statements count:statementCount] forKey:@"statements"];
}  

- (id)initWithCoder:(NSCoder *)coder
{
  self     = [super initWithCoder:coder];
  nodeType = STATEMENT_LIST;

  NSArray *theStatements = [coder decodeObjectForKey:@"statements"];
  statementCount = [theStatements count];
  statements     = NSAllocateCollectable(statementCount * sizeof(id), NSScannedOption);
  [theStatements getObjects:statements];
  [theStatements makeObjectsPerformSelector:@selector(retain)]; 

  return self;
}

- (id)initWithStatements:(NSArray *)theStatements
{
  self = [super init];
  if (self != nil) 
  {
    nodeType = STATEMENT_LIST;
    statementCount = [theStatements count];
    statements     = NSAllocateCollectable(statementCount * sizeof(id), NSScannedOption);
    [theStatements getObjects:statements];
    [theStatements makeObjectsPerformSelector:@selector(retain)]; 
  }
  return self;
}

- (NSArray *)statements
{
  return [NSArray arrayWithObjects:statements count:statementCount];
}

- (void)translateCharRange:(int32_t)translation
{
  [super translateCharRange:translation];
  
  for (NSUInteger i = 0; i < statementCount; i++) [statements[i] translateCharRange:translation];
}


@end
