//
//  SuperDebugAreaWindowController.m
//  Super Debug
//
//  Created by Jason Brennan on 12-07-19.
//
//  Copyright (c) 2012-2013, Shopify, Inc.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//      * Neither the name of the Shopify, Inc. nor the
//        names of its contributors may be used to endorse or promote products
//        derived from this software without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL Shopify, Inc. BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "SuperDebugAreaWindowController.h"
#import "JBShellContainerView.h"
#import "JBShellView.h"
#import "JBShellViewBlockTypedefs.h"
#import "JBSuggestionWindowController.h"
#import "SuperDraggableShellView.h"
#import "NSData+Base64.h"


@interface SuperDebugAreaWindowController () <NSNetServiceDelegate>
@property (nonatomic, weak) IBOutlet NSImageView *imageViewer;
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
	
    self.shellContainer = [[JBShellContainerView alloc] initWithFrame:bounds shellViewClass:[SuperDraggableShellView class] prompt:prompt shellInputProcessingHandler:^(NSString *input, JBShellView *sender) {
		
		[sender beginDelayedOutputMode];
		
		
		if ([self isCommand:input]) {
			NSString *choppedInput = [self longInputFromCommand:input];
			NSString *choppedCommand = [self commandFromCommand:input];
			
            __weak __typeof__(self) weakSelf = self;

			[self.networkClient requestWithCommand:choppedCommand input:choppedInput responseHandler:^(SuperNetworkMessage *response) {
				if ([[[response body] objectForKey:kSuperNetworkMessageBodyStatusKey] isEqualToString:kSuperNetworkMessageBodyStatusOK]) {
                    
                    // TODO: move this hardcoded command to a header file,
                    // common with the super interpreter.
                    // Ask Jason about that.
                    if ([choppedCommand isEqualToString:@".image"])
                    {
                        NSString *output = [[response body] objectForKey:kSuperNetworkMessageBodyOutputKey];
                        NSString *bodyDataRep = output;
                        NSData *bodyData = [NSData dataFromBase64String:bodyDataRep];
                        weakSelf.imageViewer.image = [[NSImage alloc] initWithData:bodyData];
                        [[weakSelf.imageViewer window] makeKeyAndOrderFront:weakSelf];
                    }
                    else
                    {
                        NSString *output = [[response body] objectForKey:kSuperNetworkMessageBodyOutputKey];
                        [sender appendOutputWithNewlines:[output description]];
//                        [weakSelf.suggestionWindowController beginForParentTextView:sender];
                    }
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
			// Do something with the response if you'd like.
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


- (NSString *)longInputFromCommand:(NSString *)inputCommand {
	NSArray *words = [inputCommand componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSMutableArray *mutWords = [words mutableCopy];
	if ([words count] < 2)
        return @"";
    [mutWords removeObjectAtIndex:0];
	return [mutWords componentsJoinedByString:@" "];
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
