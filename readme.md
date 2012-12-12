superdb: The Super Debugger
===========================

Instructions forthcoming…

The Super Debugger (`superdb` for short) is a dynamic, wireless debugger for iOS (and theoretically, Cocoa) apps. It works as two parts: a static library that runs built in to your app and a Mac app to send commands to the app, wirelessly. Your app starts up the debugger via this library, which broadcasts itself on your local network. The Mac app can discover these debug sessions via Bonjour and connect to them.

You can then send messages to your live objects as the app is running on the device (or Simulator). No need to set any break points. Any message you can send in code can also be sent this way. This allows you to rapidly test changes and see their results, without the need to recompile and deploy.

The debugger will even let you rapidly resend messages involving numeric values. When trying to tweak an interface measurement, for example, you can just click and drag on the value and see the changes reflected instantly on the device.

See below for precise installation instructions, how to make use of the debugger, and how you can contribute.

Installation
------------

1. Add the repository as a submodule to your Project's repository

		\>git submodule add https://github.com/Shopify/superdb.git MyApp/Libraries/superdb

2. Find the superdbCore project in Finder and drag it in to your currently open Xcode project. This will add it as a subproject.

3. In your Target's settings, expand the "Link with Libraries" section, press the + icon, and add the libSuperDBCore.a library.

4. Also add the `CFNetwork.framework` in the same way.

5. On the "Build Settings" for your Target, find the "Header Search Paths" setting and add an entry (for at least your Debug configuration or optionally all configurations). This entry should be for `$(BUILT_PRODUCTS_DIR)` and it should be marked as `recursive`.

6. Next, pick which class is going to house your Interpreter service. A good spot for this is your AppDelegate.

7. In your file, add `#import <SuperDBCore/SuperDBCore.h>`.

8. Create an instance variable or property for `SuperInterpreterService *_interpreterService;`

9. Initialze as follows:

		_interpreterService = [SuperInterpreterService new];
		if ([_interpreterService startServer]) {
			[_interpreterService publishServiceWithCallback:^(id success, NSDictionary *errorDictionary) {
				if (errorDictionary) {
					NSLog(@"There was a problem starting the SuperDebugger service: %@", errorDictionary);
					return;
				}
				
				// The service is now on the network, ready to run interpreter events.
			}];
		}
		[_interpreterService setCurrentSelfPointerBlock:^id {
			// Return whatever you'd like to be pointed to by `self`.
			// This might be whatever your topmost view controller is
			// How you get it is up to you!
			// return _navigationController.topViewController;
			return _customMenuSystem.rootViewController;
		}];

You should be good to go. Fire up the app in either the Simulator or on a device, and launch the Super Debugger Mac app, double click your app in the list, and debug away! The only requirement is the apps be on the same local network (This could potentially work over a WAN, too, but for now we use Bonjour for finding devices. WAN would have higher latency, too).

Demo application
----------------

Contributing
------------

Using
-----

###Sending messages
###Updating the `self` pointer
###Dragging
###Dot commands
