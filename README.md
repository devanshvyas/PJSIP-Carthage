# PJSIP-Carthage

Carthage support for PJSIP (https://github.com/chebur/pjsip)

## Installation
Add the following line to your ```Cartfile``` and run ```carthage update``` command.

```github "devanshvyas/PJSIP-Carthage" ~> 1.0```

## Requirements
1. General -> Add Framework -> VideoToolBox
2. Build Settings -> Enable Bitcode -> No
3. Build Settings -> Preprocessor macros -> PJ_AUTOCONF=1
4. Signing & Capabilities -> Background Modes -> Voice over IP
5. Add following code in Info.plist:
```
<key>NSMicrophoneUsageDescription</key>
<string>To use microphone while calling</string>
<key>NSCameraUsageDescription</key>
<string>To use microphone while calling</string>
<key>UIBackgroundModes</key>
<array>
    <string>voip</string>
</array>
```
## Example Project
VOIP-Demo (https://github.com/devanshvyas/VOIP-Demo)

## Author
[Devansh Vyas](http://github.com/devanshvyas)
