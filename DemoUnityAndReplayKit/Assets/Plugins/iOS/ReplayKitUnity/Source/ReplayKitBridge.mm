#include "ReplayKitUnityBridge-Swift.h"
#include <string>

#pragma mark - C interface

extern "C" {

    BOOL _isStreaming() {
        return [[ReplayKitNative shared] isStreaming];
    }
    void _startStreaming(const char* options) {
        [[ReplayKitNative shared] startStreamingWithOptions: [NSString stringWithCString:options encoding:NSUTF8StringEncoding]];
    }
    void _stopStreaming() {
        [[ReplayKitNative shared] stopStreaming];
    }

    BOOL _isMicActive() {
        return [[ReplayKitNative shared] isMicActive];
    }
    void _setMicActive(BOOL active) {
        [[ReplayKitNative shared] setMicActive: active];
    }

    BOOL _isCameraActive() {
        return [[ReplayKitNative shared] isCameraActive];
    }
    void _setCameraActive(BOOL active) {
        [[ReplayKitNative shared] setCameraActive: active];
    }

    BOOL _isUsingFrontCamera() {
        return [[ReplayKitNative shared] isUsingFrontCamera];
    }
    void _switchCamera(BOOL useFrontCamera) {
        [[ReplayKitNative shared] switchCamera: useFrontCamera];
    }


    // TODO
    // is camera available on this device?
    // is mic available on this device?

}

