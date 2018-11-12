#include "NativeStreamingBridge-Swift.h"
#include <string>

#pragma mark - C interface

extern "C" {

    void _initialize() {
        [[NativeStreaming shared] initialize];
    }
    BOOL _isStreaming() {
        return [[NativeStreaming shared] isStreaming];
    }
    void _startStreaming(const char* optionsString) {
        [[NativeStreaming shared] startStreamingWithOptionsString: [NSString stringWithCString:optionsString encoding:NSUTF8StringEncoding]];
    }
    void _stopStreaming() {
        [[NativeStreaming shared] stopStreaming];
    }

    BOOL _isMicActive() {
        return [[NativeStreaming shared] isMicActive];
    }
    void _setMicActive(BOOL active) {
        [[NativeStreaming shared] setMicActive: active];
    }

    BOOL _isCameraActive() {
        return [[NativeStreaming shared] isCameraActive];
    }
    void _setCameraActive(BOOL active) {
        [[NativeStreaming shared] setCameraActive: active];
    }

    BOOL _isUsingFrontCamera() {
        return [[NativeStreaming shared] isUsingFrontCamera];
    }
    void _switchCamera(BOOL useFrontCamera) {
        [[NativeStreaming shared] switchCamera: useFrontCamera];
    }

    BOOL _isFullscreenCamera() {
        return [[NativeStreaming shared] isFullscreenCamera];
    }
    void _setFullscreenCamera(BOOL isFullscreen) {
        [[NativeStreaming shared] setFullscreenCamera: isFullscreen];
    }

    // TODO
    // is camera available on this device?
    // is mic available on this device?

}

