# oXigen Protocol Explorer 4

"oXigen Protocol Explorer 4" is a little tool that developers can use to better understand the oXigen 4 dongle protocol.
I.e, the protocol that is used by slot.it's digital slot car system between a dongle and an RMS program.


## Hardware and software requirements

- An oXigen 4 dongle.
- A computer/device capable of running a 64-bit desktop version of Windows 7/8/10/11, macOS or Linux. A Raspberry Pi will work, but it needs at least 1GB RAM. "oXigen Protocol Explorer 4" is written in Flutter, so for details about supported OS versions, [please read the Flutter supported platforms documentation](https://docs.flutter.dev/reference/supported-platforms). In addition to that documentation, for macOS at least 10.14 is required.



## Installation

As this is a simple developement tool, it's not available from an app store, i.e. from the Microsoft Store, from Apple's app store, or as a Linux snap.
Instead, download a version for your operating system from the release page (link to the right), extract the compressed file, and start the excecutable file.


### Windows

After extracting the .zip file, simply start oxigen_protocol_explorer_4.exe. You'll get a warning that you're trying to run a file from an untrusted source.
Click on "more information" (or similar), and accept to run it anyway.


### macOS

After extracting the .zip file (it if doesn't happen automatically), simply start oxigen_protocol_explorer_4.app. You'll get a warning that you're trying to run a file from an untrusted source.
It's a bit complicated to get around this in macOS, but by clicking the question mark in the warning popup and **very** carefully following the instructions, you should be able to start it.


### Linux

On Raspberry Pi OS, extract the compressed file and you should then be able to start oxigen_protocol_explorer_4.

On Ubuntu, it's a bit more complicated, as your user account typically doesn't have access to the serial port (it's not a member of the dialup group).
The easiest to solve this is by running the program as root:

<code>sudo ./oxigen_protocol_explorer_4</code>

On Ubuntu on a Raspberry Pi, you might get the following error:

<code>Failed to start Flutter renderer: Unable to create a GL context</code>

It's caused by missing graphic drivers, and the easiest way to run the program anyway is to add an environment variable so that software rendering is used instead:

<code>export LIBGL_ALWAYS_SOFTWARE=1</code>


## Licensing

"oXigen Protocol Explorer 4" uses a MIT license, essentially meaning that you use the source code anyway you want.

The source code has a dependency upon Syncfusion Flutter Charts, which [requries a specific license](https://pub.dev/packages/syncfusion_flutter_charts/license). If you use source code parts that require a Syncfusion library, you're required to [get a Syncfusion license yourself](https://www.syncfusion.com/sales/communitylicense).