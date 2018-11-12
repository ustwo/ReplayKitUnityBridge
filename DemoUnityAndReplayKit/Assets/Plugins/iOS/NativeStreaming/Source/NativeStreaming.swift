import Foundation
import HaishinKit
import AVFoundation
import UIKit

// name of the gameobject that will listen to UnitySendMessage
public let kUnityCallbackTarget = "NativeStreamingGameObject"

@objc public class NativeStreaming: NSObject {

    // singleton
    @objc static let shared = NativeStreaming()

    private var cameraViewController: CameraBubbleViewController!
    private var rtmpConnection: RTMPConnection!
    private var rtmpStream: RTMPStream!

    // visible to unity bridge
    @objc var isStreaming: Bool = false
    @objc var isMicActive: Bool = false
    @objc var isCameraActive: Bool = true
    @objc var isUsingFrontCamera: Bool = true
    @objc var isFullscreenCamera: Bool {
        get {
            return cameraViewController.isFullscreenCamera
        }
        set {}
    }

    @objc func startStreaming(optionsString: String) {
        guard !isStreaming else {
            print("stream already connected and publishing")
            return
        }
        
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setActive(true)
        } catch {
            print("Error: session.setActive(true) failed!")
        }

        rtmpConnection = RTMPConnection()
        rtmpStream = RTMPStream(connection: rtmpConnection)

        let streamOptions = configureStream(rtmpStream, options: optionsString)
        
        guard let options = streamOptions else {
            print("Failed to configure stream with the options: \(optionsString)")
            return
        }


        rtmpConnection.connect(options.address)
        rtmpStream.publish(options.streamName)

        self.isStreaming = true

        if isCameraActive {
            cameraViewController.hideLogoShowCamera()
        } else {
            cameraViewController.hideCameraShowLogo()
        }

        // display camera
        DispatchQueue.main.async {
            self.cameraViewController.addCameraStream(stream: self.rtmpStream)
            self.cameraViewController.showView()
        }

        // notify stream started
        UnitySendMessage(kUnityCallbackTarget, "OnStartStreaming", "")
    }

    @objc func stopStreaming() {

        guard isStreaming else {
            print("stream already stopped")
            return
        }

        cameraViewController.hideView()

        rtmpStream.close()
        rtmpStream.dispose()
        rtmpConnection.close()
        
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setActive(false)
        } catch {
            NSLog("Error: session.setActive(false) failed!")
        }

        self.isStreaming = false
        UnitySendMessage(kUnityCallbackTarget, "OnStopStreaming", "")
    }

    @objc func setMicActive(_ active: Bool) {
        self.isMicActive = active

        if isStreaming {
            rtmpStream.audioSettings["muted"] = !active
        }
    }

    @objc func setCameraActive(_ active: Bool) {
        self.isCameraActive = active

        rtmpStream.attachCamera(getCameraDevice())
        
        if active {
            cameraViewController.hideLogoShowCamera()
        } else {
            cameraViewController.hideCameraShowLogo()
        }
    }

    @objc func switchCamera(_ useFrontCamera: Bool) {
        isUsingFrontCamera = useFrontCamera

        guard isCameraActive && isStreaming else {
            return
        }

        rtmpStream.attachCamera(getCameraDevice()) { error in
            NSLog("switchCamera - attachCamera error - " + error.localizedDescription)
        }

        UnitySendMessage(kUnityCallbackTarget, "OnCameraSwitched", "")
    }

    @objc func setFullscreenCamera(_ isFullscreen: Bool) {
        guard isCameraActive else {
            return
        }
        cameraViewController.isFullscreenCamera = isFullscreen
    }

}


// MARK - Configure stream

extension NativeStreaming {

    @objc func initialize() {

        guard let currentVC = UnityGetGLViewController() else {
            assertionFailure("Cannot get the current view controller from unity!")
            return
        }

        // add camera container on top of the unity game view
        cameraViewController = CameraBubbleViewController()

        currentVC.addChildViewController(cameraViewController)
        currentVC.view.addSubview(cameraViewController.view);
        cameraViewController.didMove(toParentViewController: currentVC)

        DispatchQueue.global(qos: .background).async {
            self.initSession()

            DispatchQueue.main.async {
                UnitySendMessage(kUnityCallbackTarget, "OnInitialized", "")
            }
        }
    }

    /* Configure iOS video and audio session */
    private func initSession() {
        let session = AVAudioSession.sharedInstance()

        do {
            // TODO: use arg samplerate
            try session.setPreferredSampleRate(44_100)
            // https://stackoverflow.com/questions/51010390/avaudiosession-setcategory-swift-4-2-ios-12-play-sound-on-silent
            if #available(iOS 10.0, *) {
                try session.setCategory(
                    AVAudioSessionCategoryPlayAndRecord,
                    mode: AVAudioSessionModeDefault,
                    options: [AVAudioSessionCategoryOptions.allowBluetooth]
                )
            } else {
                session.perform(
                    NSSelectorFromString("setCategory:withOptions:error:"),
                    with: AVAudioSessionCategoryPlayAndRecord,
                    with: [AVAudioSession.CategoryOptions.allowBluetooth]
                )
            }
            try session.setMode(AVAudioSessionModeDefault)

        } catch {
            NSLog("session error caught")
        }
    }

    private func getCameraDevice() -> AVCaptureDevice? {
        guard isCameraActive else {
            return nil
        }
        return DeviceUtil.device(withPosition: self.isUsingFrontCamera ? .front : .back)!
    }

    private func configureStream(_ stream: RTMPStream, options: String) -> StreamOptions? {
        print("configureStream options: \(options)")
        // add audio and video to stream
        // what if user connects their microphone some time later? I think it wont be used
        stream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
            NSLog("attachAudio error - " + error.localizedDescription)
        }
        stream.attachCamera(getCameraDevice()) { error in
            NSLog("attachCamera error - " + error.localizedDescription)
        }

        // configure quality options
        let optionsArr = options.split(separator: " ")

//        var streamKey: String!
        var address_: String!
        var streamName_: String!
        var width_: Int!
        var height_: Int!
        var videoBitrate_: Int!
        // audioBitrate
        // audioSampleRate
        for opt in optionsArr {
            let pairArr = opt.split(separator: "=")
            let key = pairArr[0]
            let value = pairArr[1]
            switch key {
            case "address":
                address_ = String(value)
            case "streamName":
                streamName_ = String(value)
//                case "streamKey":
//                    streamKey = String(value)
            case "width":
                width_ = Int(value)!
            case "height":
                height_ = Int(value)!
            case "videoBitrate":
                videoBitrate_ = Int(value)!
            default:
                print("Unknown option " + String(opt))
            }
        }

        // settings

        guard let width = width_ else {
            print("width must be in options when starting stream")
            return nil
        }

        guard let height = height_ else {
            print("height must be in options when starting stream")
            return nil
        }
        
        guard let videoBitrate = videoBitrate_ else {
            print("videoBitrate must be in options when starting stream")
            return nil
        }

        stream.videoSettings = [
            "width": width, // video output width
            "height": height, // video output height
            "bitrate": videoBitrate, // video output bitrate
            // "dataRateLimits": [160 * 1024 / 8, 1], optional kVTCompressionPropertyKey_DataRateLimits property
            // "profileLevel": kVTProfileLevel_H264_Baseline_3_1, // H264 Profile require "import VideoToolbox"
            "maxKeyFrameIntervalDuration": 2, // seconds
        ]
        stream.audioSettings = [
            "muted": !isMicActive,
            // "bitrate": audioBitrate,
        ]
        
        return StreamOptions(address: address_, streamName: streamName_)
    }
}

struct StreamOptions {
    var address: String
    var streamName: String
}
