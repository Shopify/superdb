superdb: The Super Debugger
===========================

Instructions forthcoming…

The Super Debugger (`superdb` for short) is a dynamic, wireless debugger for iOS (and theoretically, Mac) apps. It works as two parts: a static library that runs built in to your app and a Mac app to send commands to the app, wirelessly. Your app starts up the debugger via this library, which broadcasts itself on your local network. The Mac app can discover these debug sessions via Bonjour and connect to them.

You can then send messages to your live objects as the app is running on the device (or Simulator). No need to set any break points. Any message you can send in code can also be sent this way. This allows you to rapidly test changes and see their results, without the need to recompile and deploy.

The debugger will even let you rapidly resend messages involving numeric values. When trying to tweak an interface measurement, for example, you can just click and drag on the value and see the changes reflected instantly on the device.

![Super Debugger running on a Mac debugging an included iOS app.](https://raw.github.com/Shopify/superdb/develop/screenshot.png?login=jbrennan&token=1080ab57c1c5e5a1f4f9481d10e2e640 "Super Debugger running on a Mac debugging an included iOS app.")

See below for precise installation instructions, how to make use of the debugger, and how you can contribute.

Installation
------------

1. Set up git settings (you might want to do this in a fresh branch...`git checkout feature/superdb`):
	
	1. Add the repository as a submodule to your Project's repository

			git submodule add https://github.com/Shopify/superdb.git MyApp/Libraries/superdb
	
	2. Initialize all of superdb's submodules, too (if you get stuck, use a graphical tool like Gitbox. It makes submodules so much easier).
		
			git submodule update --init --recursive

2. Find the superdbCore project in Finder and drag it in to your currently open Xcode project. This will add it as a subproject.

3. In your Target's settings, expand the "Link with Libraries" section, press the + icon, and add the libSuperDBCore.a library.

4. Also add the `CFNetwork`, `Security`, `CoreData` and `CoreGraphics` frameworks in the same way.

5. On the "Build Settings" for your Target, find the "Header Search Paths" setting and add an entry (for at least your Debug configuration or optionally all configurations). This entry should be for `"path/to/superdb/SuperDBCore"`  (relative to your project's root... this is the same path you used when specifying where to put the submodule) and it should be marked as `recursive`.

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

Now all that's left is to get the Mac component running. Provided you've got your `submodules` all updated:

1. Open the `SuperWorkspace.xcworkspace` file (found wherever you cloned the `superdb` submodule to).
2. Build and run the `Super Debugger` target (which will build the library component for the Mac, as well).


You should be good to go. Fire up the app in either the Simulator or on a device, and launch the Super Debugger Mac app, double click your app in the list, and debug away! The only requirement is the apps be on the same local network (This could potentially work over a WAN, too, but for now we use Bonjour for finding devices. WAN would have higher latency, too).

Demo application
----------------


Using
-----

###Sending messages
###Updating the `self` pointer
###Dragging
###Dot commands

Contributing
------------

Contributions are absolutely welcomed. The shell works well enough for everyday use, but there's definitely room to grow. If you'd like to fix a bug or implement a feature, do the following:

1. Create a fork of this project.
2. Take note that the default branch we work on is `develop`, **not** `master`. If your fork doesn't default to using `develop`, you can set this in your fork's Settings page.
3. Create a topic branch in your fork and try to give it a meaningful name like `feature/device-pairing` or `bugfix/network-timeouts`.
4. Write code (or better, delete some!) on your branch. **Important**: Keep the code style consistent with surrounding code. If your code deviates too far from this, you'll be asked to clean it up.
5. When ready, make a Pull Request for your topic branch to the main repository's `develop` branch.
6. Feel good about yourself because you just made a contribution to this project, and that's really awesome!

Details for Nerds
-----------------

The history of superdb is as follows:

Philippe Mougin wrote a piece of software called `F-Script`, which applies a Smalltalk-like syntax on top of the Cocoa (OS X) object system. It's a great tool for exploring Cocoa objects, he calls it a "Finder for your Objects".

GitHub user @pablomarx got a version of F-Script running on iOS with a very basic user interface.

I took the project and cleaned it up (the iOS fork needed substantial work to get running with Clang), created a modern [Cocoa Shell](https://github.com/jbrennan/JBShellView) and slapped a network layer between the two. Although the project uses `F-Script`, not all of the desktop features are supported. Because it's such a large codebase, even I don't fully know what it's capable of. I'm learning and I'm modernizing it as I go. For more information, check out [F-Script's homepage](http://www.fscript.org) and its [Programming Guide in particular (PDF)](http://www.fscript.org/documentation/FScriptGuide.pdf).

The result is an F-Script interpreter which runs on iOS, a shell program which runs on OS X, and `JSTP`, a simple JSON-based transfer protocol between the two (`JSTP` looks quite a lot like `HTTP` except every session is essentially a `POST` and it's bi-directional). You can send messages to your objects from the shell and they'll execute on the device without the need for breakpoints.

The F-Script code is still pretty old and rough. It needs major overhauling to be modernized to new Objective C style (it's still manually memory managed), and there are lots of leaks or little bugs, but it works well enough.

License
-------

SuperDB is licensed under a **BSD**-3-clause license:

	Copyright (c) 2012-2013, Shopify, Inc.
	All rights reserved.
	
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:
		* Redistributions of source code must retain the above copyright
		  notice, this list of conditions and the following disclaimer.
		* Redistributions in binary form must reproduce the above copyright
		  notice, this list of conditions and the following disclaimer in the
		  documentation and/or other materials provided with the distribution.
		* Neither the name of the Shopify, Inc. nor the
		  names of its contributors may be used to endorse or promote products
		  derived from this software without specific prior written permission.
	
	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL Shopify, Inc. BE LIABLE FOR ANY
	DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
