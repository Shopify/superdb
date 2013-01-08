//
//  SuperServicesBrowser.m
//  Lecture12
//
//  Created by Jason Brennan on 12-03-22.
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

#import "SuperServicesBrowser.h"


@interface SuperServicesBrowser () <NSNetServiceDelegate, NSNetServiceBrowserDelegate>

@property (nonatomic, copy) SuperServicesBrowserCallback servicesCallback;
@property (nonatomic, copy) SuperServicesBrowserPublishedServiceCallback publishedServiceCallback;
@property (nonatomic, strong) NSNetServiceBrowser *servicesBrowser;
@property (nonatomic, strong) NSMutableArray *foundServices;

@end


@implementation SuperServicesBrowser {
	BOOL _alreadyConnected;
}


- (id)initWithServicesCallback:(SuperServicesBrowserCallback)callback {
	if ((self = [super init])) {
		self.servicesCallback = callback;
		self.foundServices = [NSMutableArray array];
		
		[self startBrowsingForServices];
	}
	
    return self;
}


+ (NSString *)netServiceType {
	return @"_superdebug._tcp.";
}


+ (NSString *)netServiceDomain {
	// If I leave this blank, then the Simulator finds 2 entries.. One for the local domain, and one for the iCloud domain (BTMM = Back To My Mac)... WE DON'T WANT THAT.
	return @"local";
}


- (void)startBrowsingForServices {
	self.servicesBrowser = [[NSNetServiceBrowser alloc] init];
	
	[self.servicesBrowser setDelegate:self];
	[self.servicesBrowser searchForServicesOfType:[[self class] netServiceType] inDomain:[[self class] netServiceDomain]];
}


#pragma mark -
#pragma mark NSNetServiceBrowserDelegate methods

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
	
	[self.foundServices addObject:aNetService];
	NSLog(@"Found a service: %@", aNetService);
	self.servicesCallback(self.foundServices, moreComing, nil);
	
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
	
	[self.foundServices removeObject:aNetService];
	self.servicesCallback(self.foundServices, moreComing, nil);
	
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict {
	self.servicesCallback(nil, NO, errorDict);
}


@end
