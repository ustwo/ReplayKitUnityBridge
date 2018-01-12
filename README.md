
[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/ustwo/ReplayKitUnityBridge)


## Summary 

This is a Unity plugin for iOS that allows you to record the screen and capture gameplay. It includes the Xcode project that it was built in. To start using it, simply drag the PluginSource folder into your Unity project as a sub-folder in the following directory/file path: Assets > Plugins > iOS > ReplayKitUnity (drag source and editor folders into here )

## Disclaimer:

This plugin is a work in progress and has been built to show the steps of creating a Unity iOS plugin using Swift

## Features

- [x] Record Screen
- [x] Stop recording of screen
- [x] Recieve video file (.mp4) of recording
- [x] Set a restricting time to allow for recording the screen
- [x] A record button and progress bar of your recording playback that is excluded from the screen recording
- [x] Share the recorded file via the standard iOS share sheet (mail, twitter, facebook)


## Requirements

- iOS 11.0 or later

## Getting Started

- Go to the "Demo" folder, Main Scene. View the RecordController script for sample code


## Communication

- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.


## Installation

- Open the Plugin Source folder, Drag the "Source" and "Editor" folder into your Unity project.
- It must be dragged into the following Unity file path : Assets > Plugins > iOS > ReplayKitUnity

## How To Use



1. Start a screen recording

```csharp
ReplayKitUnity.StartRecording();
```

2. Stop the screen recording


```csharp
ReplayKitUnity.StopRecording();
```

### Recieve Recorded video file

//TODO:


## Contact：
- Email:  sonam@ustwo.com


