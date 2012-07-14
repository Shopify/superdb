//
//  JBServicesBrowser.m
//  Lecture12
//
//  Created by Jason Brennan on 12-03-22.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBServicesBrowser.h"
#import "SuperDBCore.h"

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


//- (void)publishServiceForUsername:(NSString *)serviceName publicationCallback:(JBServicesBrowserPublishedServiceCallback)publicationCallback {
//	
//	if (_alreadyConnected)
//		return;
//	
//	_alreadyConnected = YES;
//	
//	self.publishedServiceCallback = publicationCallback;
//	
//	
//	[self setupNetworkService];
//	
//	self.publishedService = [[NSNetService alloc] initWithDomain:kIMServiceDomain type:kIMServiceName name:serviceName port:DEFAULT_PORT];
//	
//	if (nil == self.publishedService) {
//		NSLog(@"There was an error publishing the service!");
//		self.publishedServiceCallback(nil, [NSDictionary dictionaryWithObject:@"The publication failed" forKey:@"reason"]);
//		return;
//	}
//	
//	[self.publishedService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//	[self.publishedService setDelegate:self];
//	
//	[self.publishedService publish];
//}


- (void)startBrowsingForServices {
	self.servicesBrowser = [[NSNetServiceBrowser alloc] init];
	
	[self.servicesBrowser setDelegate:self];
	//[self.servicesBrowser searchForServicesOfType:kIMServiceName inDomain:kIMServiceDomain];
}


#pragma mark -
#pragma mark NSNetServiceDelegate methods

- (void)netServiceDidPublish:(NSNetService *)sender {
	// huzzah! execute the block
	self.publishedServiceCallback(@"The service was successfully published!", nil);
	//[self netServiceBrowser:nil didFindService:sender moreComing:YES];
}

/* Sent to the NSNetService instance's delegate when an error in publishing the instance occurs. The error dictionary will contain two key/value pairs representing the error domain and code (see the NSNetServicesError enumeration above for error code constants). It is possible for an error to occur after a successful publication.
 */
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
	
//	if (sender != self.publishedService)
//		return;
	
	
	[self teardownNetworkService];
	
	[self unpublishService];
	
	_alreadyConnected = NO;
	self.publishedServiceCallback(nil, errorDict);
	
}


- (void)unpublishService {
//	[self.publishedService stop];
//	[self.publishedService removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//	self.publishedService = nil;
}


- (void)setupNetworkService {
//	self.hostedService = [[JBAuctionServer alloc] init];
//	[self.hostedService startServer];
	
}


- (void)teardownNetworkService {
//	[self.hostedService stopServer];
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
