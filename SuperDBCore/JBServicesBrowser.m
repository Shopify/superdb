//
//  JBServicesBrowser.m
//  Lecture12
//
//  Created by Jason Brennan on 12-03-22.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBServicesBrowser.h"


@interface JBServicesBrowser () <NSNetServiceDelegate, NSNetServiceBrowserDelegate>

@property (nonatomic, copy) JBServicesBrowserCallback servicesCallback;
@property (nonatomic, copy) JBServicesBrowserPublishedServiceCallback publishedServiceCallback;
@property (nonatomic, strong) NSNetServiceBrowser *servicesBrowser;
@property (nonatomic, strong) NSMutableArray *foundServices;

@end



@implementation JBServicesBrowser {
	BOOL _alreadyConnected;
}
@synthesize servicesCallback = _servicesCallback;
@synthesize servicesBrowser = _servicesBrowser;
@synthesize publishedServiceCallback = _publishedServiceCallback;
@synthesize foundServices = _foundServices;



- (id)initWithServicesCallback:(JBServicesBrowserCallback)callback {
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
