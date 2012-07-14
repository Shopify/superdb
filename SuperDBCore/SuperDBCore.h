//
//  SuperDBCore.h
//  SuperDBCore
//
//  Created by Jason Brennan on 12-07-07.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Foundation/Foundation.h>
#define SOMETHING YES

#define DEFAULT_PORT 4789

NSString *kNetServiceName = @"superdebug._tcp.";
NSString *kNetServiceDomain = @"local"; // If I leave this blank, then the Simulator finds 2 entries.. One for the local domain, and one for the iCloud domain (BTMM = Back To My Mac)... WE DON'T WANT THAT.

#import "JBServicesBrowser.h"

