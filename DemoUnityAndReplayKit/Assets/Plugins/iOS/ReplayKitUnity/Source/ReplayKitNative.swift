import Foundation
import HaishinKit
import AVFoundation
import UIKit

// name of the c-sharp file in Unity that will listen to messages being sent from Xcode
public let kUnityCallbackTarget = "NativeStreamingGameObject"

@objc public class ReplayKitNative: NSObject {

    // singleton
    @objc static let shared = ReplayKitNative()

    private var cameraViewController: CameraBubbleViewController!
    private var rtmpConnection: RTMPConnection!
    private var rtmpStream: RTMPStream!
    private var audioSession: AVAudioSession?

    // visible to unity bridge
    @objc var isStreaming: Bool = false
    @objc var isMicActive: Bool = false
    @objc var isCameraActive: Bool = true
    @objc var isUsingFrontCamera: Bool = true

    /* options is a string of space seperated key=value pairs
       address=rtmp://us1.twitch.tv/stream streamName=hello streamKey=abc123 width=1280 height=720 videoBitrate=1234 muted=true audioBitrate audioSampleRate
    */
    @objc func startStreaming(optionsString: String) {
        guard let session = self.audioSession else {
            print("stream already connected and publishing")
            return
        }

        do {
            try session.setActive(true)
        } catch {
            print("Error: session.setActive(true) failed!")
        }

        guard !isStreaming else {
            print("stream already connected and publishing")
            return
        }

        rtmpConnection = RTMPConnection()
        rtmpStream = RTMPStream(connection: rtmpConnection)

        let streamOptions = configureStream(rtmpStream, options: optionsString)
        
        guard let options = streamOptions else {
            print("Failed to configure stream with the options: \(optionsString)")
            return
        }

        // display camera
        DispatchQueue.main.async {
            self.cameraViewController.addCameraStream(stream: self.rtmpStream)
        }

        rtmpConnection.connect(options.address)
        rtmpStream.publish(options.streamName)

        self.isStreaming = true

        if isCameraActive {
            cameraViewController.hideLogoShowCamera()
        } else {
            cameraViewController.hideCameraShowLogo()
        }

        cameraViewController.showView()

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

        guard let session = self.audioSession else {
            print("Mistake: av session is not initialized")
            return
        }

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

        if active {
            rtmpStream.attachCamera(getCameraDevice())
            cameraViewController.hideLogoShowCamera()
        } else {
            rtmpStream.attachCamera(nil)
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

}


// MARK - Configure stream

extension ReplayKitNative {

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
        self.audioSession = AVAudioSession.sharedInstance()

        guard let session = self.audioSession else {
            print("Mistake: av session is not initialized")
            return
        }

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
        // stream.captureSettings = [
        //     "sessionPreset": AVCaptureSession.Preset.hd1280x720.rawValue,
        //     "continuousAutofocus": true,
        //     "continuousExposure": true
        // ]
//        print("confgure strm \(address) \(streamName) \(width!)x\(height!)")
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
            // "sampleRate": audioSampleRate,
        ]
        
        return StreamOptions(address: address_, streamName: streamName_)
    }
}

struct StreamOptions {
    var address: String
    var streamName: String
}
