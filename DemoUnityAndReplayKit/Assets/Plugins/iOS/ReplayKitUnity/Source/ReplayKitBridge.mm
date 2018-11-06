#import <ReplayKit/ReplayKit.h>

//** This import is required in order for Swift functions & properties to be exposed to this class
#include "ReplayKitUnityBridge-Swift.h"
#include <string>


#pragma mark - C interface

extern "C" {
    
#pragma mark - Functions

    void _startStreaming(const char* key) {
        [[ReplayKitNative shared] startStreamingWithKey: [NSString stringWithCString:key encoding:NSUTF8StringEncoding]];
    }

    void _stopStreaming() {
        [[ReplayKitNative shared] stopStreaming];
    }


    ////////////////////////////////////////////////////

    
#pragma mark - Getters

    BOOL _isStreaming() {
        return [[ReplayKitNative shared] isStreaming];
    }

    // is camera available?
    // is mic available?

}

