//
//  SuperDebugAreaWindowController.m
//  Super Debug
//
//  Created by Jason Brennan on 12-07-19.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "SuperDebugAreaWindowController.h"
#import "JBShellContainerView.h"
#import "JBShellView.h"
#import "JBShellViewBlockTypedefs.h"
#import "JBSuggestionWindowController.h"


@interface SuperDebugAreaWindowController () <NSNetServiceDelegate>
@property (nonatomic, strong) SuperInterpreterClient *networkClient;
@property (nonatomic, strong) JBShellContainerView *shellContainer;
@property (nonatomic, strong) NSColorPanel *colorPanel;
@property (nonatomic, strong) JBSuggestionWindowController *suggestionWindowController;
@end

@implementation SuperDebugAreaWindowController


+ (id)new {
	return [[[self class] alloc] initWithWindowNibName:@"SuperDebugAreaWindowController"];
}


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
   	CGRect bounds = [[self.window contentView] bounds];
	NSString *prompt = [NSString stringWithFormat:@"%@> ", [self.netService name]?: @""];
	self.suggestionWindowController = [JBSuggestionWindowController new];
	
    self.shellContainer = [[JBShellContainerView alloc] initWithFrame:bounds prompt:prompt shellInputProcessingHandler:^(NSString *input, JBShellView *sender) {
		
		[sender beginDelayedOutputMode];
		
		
		if ([self isCommand:input]) {
			NSString *choppedInput = [self inputFromCommand:input];
			NSString *choppedCommand = [self commandFromCommand:input];
			
			[self.networkClient requestWithCommand:choppedCommand input:choppedInput responseHandler:^(SuperNetworkMessage *response) {
				if ([[[response body] objectForKey:kSuperNetworkMessageBodyStatusKey] isEqualToString:kSuperNetworkMessageBodyStatusOK]) {
					NSString *output = [[response body] objectForKey:kSuperNetworkMessageBodyOutputKey];
					[sender appendOutputWithNewlines:[output description]];
//					[self.suggestionWindowController beginForParentTextView:sender];
				} else {
					// there was an error, show it.
					NSString *errorMessage = [[response body] objectForKey:kSuperNetworkMessageBodyErrorMessageKey];
					id r = [[response body] objectForKey:kSuperNetworkMessageBodyErrorRange];
					NSRange range = NSRangeFromString(r);
					
					[sender showErrorOutput:errorMessage errorRange:range];
				}
				[sender endDelayedOutputMode];

				//[self.suggestionWindowController beginForParentTextView:sender];
			}];
			
		} else {
			[self.networkClient requestWithStringToEvaluate:input responseHandler:^(SuperNetworkMessage *response) {
				if ([[[response body] objectForKey:kSuperNetworkMessageBodyStatusKey] isEqualToString:kSuperNetworkMessageBodyStatusOK]) {
					NSString *output = [[response body] objectForKey:kSuperNetworkMessageBodyOutputKey];
					[sender appendOutputWithNewlines:[output description]];
				} else {
					// there was an error, show it.
					NSString *errorMessage = [[response body] objectForKey:kSuperNetworkMessageBodyErrorMessageKey];
					id r = [[response body] objectForKey:kSuperNetworkMessageBodyErrorRange];
					NSRange range = NSRangeFromString(r);
					
					[sender showErrorOutput:errorMessage errorRange:range];
				}
				[sender endDelayedOutputMode];
			}];
		}
		
		

	}];
	
	[self.shellContainer.shellView setNumberDragHandler:^(id draggedItem) {
		[self.networkClient requestWithStringToEvaluate:draggedItem responseHandler:^(SuperNetworkMessage *response) {
			NSLog(@"%@", draggedItem);
			[response log];
		}];
	}];
	
	
	if (self.disconnectedShell) {
		[self configureDisconnectedShell];
	}
	self.shellView.suggestionWindowController = self.suggestionWindowController;
	
	[[[self window] contentView] addSubview:self.shellContainer];
	[self.window makeFirstResponder:self.shellContainer.shellView];
	
	
	//self.colorPanel = [NSColorPanel sharedColorPanel];
	[self.colorPanel setTarget:self];
	[self.colorPanel setAction:@selector(updateColor:)];
	[self.colorPanel setContinuous:YES];
	[self.colorPanel orderFront:self];
	
	//[self.suggestionWindowController showWindow:self];
	
}



- (BOOL)isCommand:(NSString *)input {
	return [input hasPrefix:@"."];
}


- (NSString *)inputFromCommand:(NSString *)inputCommand {
	NSArray *words = [inputCommand componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	return [words lastObject];
}


- (NSString *)commandFromCommand:(NSString *)inputCommand {
	NSArray *words = [inputCommand componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if (![words count])
		return @"";
	return words[0];
}


- (void)updateColor:(NSColorPanel *)sender {
	//NSLog(@"Color: %@", [sender color]);
	CGFloat r, g, b, a;
	[[sender color] getRed:&r green:&g blue:&b alpha:&a];
	NSLog(@"%f %f %f %f", r, g, b, a);
	
	NSString *colorCommand = [NSString stringWithFormat:@"UIApplication sharedApplication delegate window setBackgroundColor:(UIColor colorWithRed:%f green:%f blue:%f alpha:%f)", r, g, b, a];
	[self.networkClient requestWithStringToEvaluate:colorCommand responseHandler:^(SuperNetworkMessage *response) {
		
	}];
	
}


- (void)configureDisconnectedShell {
	self.prompt = @"> ";
	[self.shellView setInputHandler:^(NSString *input, JBShellView *sender) {
		
		NSMutableArray *array = [@[] mutableCopy];
		NSString *completion = @"a";
		for (NSInteger i = 0; i < 10; i++) {
			[array addObject:@{@"title" : completion}];
			completion = [completion stringByAppendingString:@"a"];
		}
		[self.suggestionWindowController setSuggestions:array];
		[self.suggestionWindowController beginForParentTextView:sender];

	}];
}


- (JBShellView *)shellView {
	return self.shellContainer.shellView;
}


- (void)setPrompt:(NSString *)prompt {
	self.shellContainer.shellView.prompt = prompt;
}


- (NSString *)prompt {
	return self.shellContainer.shellView.prompt;
}


- (void)setNetService:(NSNetService *)netService {
	if (netService == _netService)
		return;
	
	_netService = netService;
	
	_netService.delegate = self;
	[_netService resolveWithTimeout:0];
	
}


#pragma mark -
#pragma mark NSNetServiceDelegate methods

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
	// Now ask for the addresses, and get the first one
	NSArray *addresses = [sender addresses];
	NSData *info = [addresses objectAtIndex:0];
	
	self.networkClient = [[SuperInterpreterClient alloc] initWithHostData:info];
	[self.networkClient startNetworkConnectionWithResponseHandler:^(SuperNetworkMessage *response) {
		[response log];
	}];
	
}


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
	
	NSLog(@"Room could not resolve a connection! %@", errorDict);
}





@end
