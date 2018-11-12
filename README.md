# NativeStreaming iOS plugin

## Building the demo

### Assumptions
1. Your machine is a mac (or is running MacOS)
2. You have an iPhone connect to your mac with iOS 10.3 or greater
  - Change the Build settings in Unity to use an iPhone simulator

### Signing the iOS app
Once unity has opened the Xcode project, add your development team in Project Settings > Signing

### Essential manual steps to follow
If you run the project without doing the steps below, it will crash.

For whatever reason, the 'pop' framework is not automatically added.
To add it, follow the steps below.

1. Go to the Xcode Project Settings > General > Embedded Binaries
2. Add pop.framework by searching for 'pop'
3. Run the project (Cmd + R) again
4. You may need to verify the app on the device you are using


### Features

- Drag the camera bubble around
- Switch to front/back camera
- Mute microphone
- Disable camera (only audio is uploaded)