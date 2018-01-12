//
//  ReplayKitBridge.mm
//  ReplayKitSandbox
//
//  Created by Sonam on 12/7/17.
//  Copyright © 2017 ustwo. All rights reserved.
//

#import <ReplayKit/ReplayKit.h>

//** This import is required in order for Swift functions & properties to be exposed to this class
#include "ReplayKitUnityBridge-Swift.h"
#include <string>


#pragma mark - C interface

extern "C" {
    
#pragma mark - Functions
    
    void _rp_startRecording() {
        [[ReplayKitNative shared] startScreenCaptureAndSaveToFile];
    }
    
    void _rp_stopRecording() {
        [[ReplayKitNative shared] stopScreenCapture];
    }
    
    void _rp_addDefaultButtonWindow() {
        [[ReplayKitNative shared] addDefaultButtonWindowForUnity];
    }
    
    void _rp_showEmailShareSheet() {
        [[ReplayKitNative shared] showEmailShareSheet];
    }
    
    
#pragma mark - Getters
    
    BOOL _rp_isRecording() {
        return [[ReplayKitNative shared] isRecording];
    }
    
    BOOL _rp_screenRecordingIsAvail() {
        return [[ReplayKitNative shared] screenRecorderAvailable];
    }
    
    BOOL _rp_isCameraEnabled() {
        return [[ReplayKitNative shared] cameraEnabled];
    }
    
    float _rp_allowedRecordTime() {
        return [[ReplayKitNative shared] recordTime];
    }
    
    const char* _rp_mailSubjectText() {
        const char *mailStringC = [[ReplayKitNative shared].mailSubjectText UTF8String];
        return mailStringC;
    }
    
#pragma mark - Setters
    
    void _rp_setCameraEnabled(BOOL cameraEnabled) {
        [[ReplayKitNative shared] setCameraEnabled: cameraEnabled];
    }
    
    void _rp_setMailSubject(const char* mailSubject) {
        [ReplayKitNative shared].mailSubjectText = [NSString stringWithCString:mailSubject encoding:NSUTF8StringEncoding];
    }
    
    void _rp_setAllowedTimeToRecord(float seconds) {
        [ReplayKitNative shared].recordTime = seconds;
    }
}

