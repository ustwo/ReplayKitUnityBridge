//
//  ReplayKitNative.swift
//  ReplayKitUnityBridge
//
//  Created by Sonam on 12/7/17.
//  Copyright © 2017 ustwo. All rights reserved.
//

import Foundation
import UIKit
import ReplayKit


// Defines the name of the c-sharp file in Unity itself that will listen to messages being sent from Xcode
let kCallbackTarget = "ReplayKitUnity"


@objc public class ReplayKitNative: NSObject {
    
    //Mark each property and function with the @objc flag to ensure that the function and/or property is exposed to Objective-C
    @objc static let shared = ReplayKitNative()
    let screenRecorder = RPScreenRecorder.shared()
    
    // Check to see if the iOS you are building on has ReplayKit and allows for the screen to be recorded
    @objc var screenRecorderAvailable: Bool {
        return self.screenRecorder.isAvailable
    }
    
    // Check current state of recording
    @objc var isRecording: Bool {
        return self.screenRecorder.isRecording
    }
    
    // An optional value. If this is set the recording time will be limited to a specified duration and immediatley stop recording when time is up
    @objc var recordTime: CGFloat = 0 
    
    // Set subject line for an email being shared via the iOS standard share sheet
    @objc var mailSubjectText = ""
    
    // *** Not implementment at the moment ***
    // *** The plugin does not allow for support of the camera being recorded while screen is being recorded **
    @objc var cameraEnabled: Bool {
        get {
            return self.screenRecorder.isCameraEnabled
        } set {
            self.screenRecorder.isCameraEnabled = newValue
            return
        }
    }
    
    // *** Not implementment at the moment ***
    // *** The plugin does not allow for support of the mic to be recorded ***
    public var microphoneEnabled: Bool {
        get {
            return self.screenRecorder.isMicrophoneEnabled
        } set {
            self.screenRecorder.isMicrophoneEnabled = newValue
            return
        }
    }
    
    public var fileURLCallback: ((URL) -> ())?
    
    // ** For File handling & internal framework use only**
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var micInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var replayPath = ""
    private var buttonWindow: UIWindow?
    
    
    private override init() {
        super.init()
        self.screenRecorder.delegate = self
    }
    
    
    // Adds a new window on top of current one with recording UI elements. These elements will be excluded from the interface
    func addDefaultButtonWindow(fromVC: UIViewController) {
        buttonWindow = UIWindow(frame: fromVC.view.frame)
        buttonWindow?.rootViewController = RecordViewController()
        buttonWindow?.rootViewController?.view.backgroundColor = .clear
        buttonWindow?.makeKeyAndVisible()
    }
    
    // For Unity to add a default interface that will be excluded from the interface during playback
    @objc func addDefaultButtonWindowForUnity() {
       
        if let currentVC = UnityGetGLViewController() {
            buttonWindow = UIWindow(frame: currentVC.view.frame)
            let recordVC = RecordViewController()
            recordVC.recordDuration = recordTime
            buttonWindow?.rootViewController = recordVC
            buttonWindow?.rootViewController?.view.backgroundColor = .clear
            buttonWindow?.makeKeyAndVisible()
        } else {
            assertionFailure("cannot get the current vc from unity")
        }
    }
    
    @objc func startScreenCaptureAndSaveToFile() {
        
        // Sends a message to Unity that iOS has started to record the screen
        // In this Xcode Project this line will return an error since you do not have the UnityInterface file imported into this project. Once this file and the source code is dragged into Unity > Plugins> iOS folder,and you build the Xcode project it will work.
       UnitySendMessage(kCallbackTarget, "OnStartRecording", "")
    
        let fileAppendValue = FileHandler.fetchAllReplays().count > 0 ? FileHandler.fetchAllReplays().count + 1 : 0
        self.replayPath = "recording_\(fileAppendValue)"
        self.setupMP4CaptureToAssetWritingWith(self.replayPath)
            
        guard let safeAssetWriter = self.assetWriter else {
            assertionFailure("asset writer failed to configure")
            return
        }
        
        // Called everytime replaykit is ready to hand back a sample
        self.screenRecorder.startCapture(handler: { [weak self] (samples, rpSampleType, error) in
            
            if CMSampleBufferDataIsReady(samples) {
        
                    //Start the asset writer
                    if safeAssetWriter.status == AVAssetWriterStatus.unknown {
                        safeAssetWriter.startWriting()
                        safeAssetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(samples))
                    }
                    
                    // Handle Samples passed back from ReplayKit
                    switch rpSampleType {
                    case RPSampleBufferType.video:
                        guard let safeVideoInput = self?.videoInput, safeVideoInput.isReadyForMoreMediaData == true else { return }
                        safeVideoInput.append(samples)
                        
                    case RPSampleBufferType.audioApp:
                        guard let safeAudioInput = self?.audioInput, safeAudioInput.isReadyForMoreMediaData == true else { return }
                        safeAudioInput.append(samples)
                        
                    case RPSampleBufferType.audioMic:
                        guard let safeMicInput = self?.micInput else { return }
                        safeMicInput.append(samples)
                    }
                }
                
            }) { (error) in
                
                // Update UI
                print(error?.localizedDescription)
        }
    }
    
    // Allow for Unity to call this method if desired. It will immeditaley stop the screen recording
    @objc func stopScreenCapture() {
        
        self.screenRecorder.stopCapture { [weak self] (error) in
            
            // Remove the window that included the interface elements
            if self?.buttonWindow != nil  {
                DispatchQueue.main.async {
                    self?.buttonWindow?.isHidden = true
                }
            }
            
            guard let safeAssetWriter = self?.assetWriter else {
                print("asset writer nil on error callback")
                return
            }
            
            // Finish writing to the AVAssetWriter, complete the file creation
            safeAssetWriter.finishWriting {
                guard let file = FileHandler.fetchAllReplays().last else {
                    print("could not get file")
                    return
                }
                
                // Send a message to Unity with the file path itself.
            UnitySendMessage(kCallbackTarget, "OnStopRecording", file.absoluteString)
                
                if self?.fileURLCallback != nil {
                    self?.fileURLCallback!(file)
                }
            }
        }
    }
    
    // Configure the asset writer with the video, audio, and mic inputs
    //**
    private func setupMP4CaptureToAssetWritingWith(_ fileName: String) {
        
        let fileURL = URL(fileURLWithPath: FileHandler.filePath(fileName))
        do {
            try assetWriter = AVAssetWriter(outputURL: fileURL, fileType: AVFileType.mp4)
        } catch  {
            print (error)
        }
        
        guard let safeAssetWriter = assetWriter,
            let safeVideoInput = setupVideoInput(),
            let safeAudioInput = setupAudioInput() else {
                assertionFailure("Asset writer and inputs failed to initalize")
                return
        }
        
        safeAssetWriter.add(safeVideoInput)
        safeAssetWriter.add(safeAudioInput)
        
        //TODO MIC *** implementation
    }
    
    // ** Video
    private func setupVideoInput() -> AVAssetWriterInput? {
        
        let videoOutputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: UIScreen.main.bounds.size.width,
            AVVideoHeightKey: UIScreen.main.bounds.size.height
        ]
        
        videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
        guard let safeVideoInput = videoInput else {
            print("video input is nil")
            return nil
        }
        
        safeVideoInput.expectsMediaDataInRealTime = true
        return safeVideoInput
    }
    
    // ** Audio
    private func setupAudioInput() -> AVAssetWriterInput? {
        
        let audioOutputSettings: [String: Any] = [
            AVFormatIDKey : NSInteger(kAudioFormatMPEG4AAC),
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: NSNumber(value: 44100.00)
        ]
        
        audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
        audioInput?.expectsMediaDataInRealTime = true
        
        guard let safeAudioInput = audioInput else {
            print("audio input is nil")
            return nil
        }
        
        return safeAudioInput
    }
    
    // ** Mic
    private func setupMicInput() -> AVAssetWriterInput? {
        //TODO!
        return nil
    }
    
    
    //MARK: - Share Sheet
    
    // Allow Unity to trigger a share sheet which only includes email and default options.
    @objc func showEmailShareSheet() {
        
        if let videoFile = FileHandler.fetchAllReplays().last {
            let objectsToShare = [videoFile] as [Any]
            
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.setValue(mailSubjectText, forKey: "subject")
            
            //New Excluded Activities Code
            activityVC.excludedActivityTypes = [.assignToContact, .saveToCameraRoll, .openInIBooks]
            
//          Once this file is in your built Unity Xcode project, this function allows for you to fetch the current view controller being displayed from Unity
            if let currentVC = UnityGetGLViewController() {
                activityVC.popoverPresentationController?.sourceView = currentVC.view
                currentVC.present(activityVC, animated: true, completion: nil)
            } else {
                assertionFailure("cannot get current vc from unity")
            }
        }
    
    }
}

extension ReplayKitNative: RPScreenRecorderDelegate {
    
    public func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWith previewViewController: RPPreviewViewController?, error: Error?) {
        
        //** TODO: return error to Unity if error occurs
    }
}
