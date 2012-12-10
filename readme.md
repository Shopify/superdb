superdb: The Super Debugger
===========================

Instructions forthcoming…

The Super Debugger (`superdb` for short) is a dynamic, wireless debugger for iOS (and theoretically, Cocoa) apps. It works as two parts: a static library that runs built in to your app and a Mac app to send commands to the app, wirelessly. Your app starts up the debugger via this library, which broadcasts itself on your local network. The Mac app can discover these debug sessions via Bonjour and connect to them.

You can then send messages to your live objects as the app is running on the device (or Simulator). No need to set any break points. Any message you can send in code can also be sent this way. This allows you to rapidly test changes and see their results, without the need to recompile and deploy.

The debugger will even let you rapidly resend messages involving numeric values. When trying to tweak an interface measurement, for example, you can just click and drag on the value and see the changes reflected instantly on the device.

See below for precise installation instructions, how to make use of the debugger, and how you can contribute.

Installation
------------

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
