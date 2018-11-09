import Foundation
import HaishinKit
import AVFoundation
import UIKit

// name of the c-sharp file in Unity that will listen to messages being sent from Xcode
let kCallbackTarget = "ReplayKitUnity"

@objc public class ReplayKitNative: NSObject {

    // singleton
    @objc static let shared = ReplayKitNative()

    private var rtmpConnection: RTMPConnection = RTMPConnection()
    private var rtmpStream: RTMPStream!
    private var isAVSessionReady: Bool = false
    private var session: AVAudioSession!

    private var cameraViewController: CameraViewController = CameraViewController()

    // visible to unity bridge
    @objc var isStreaming: Bool = false
    @objc var isMicActive: Bool = false
    @objc var isCameraActive: Bool = true
    @objc var isUsingFrontCamera: Bool = true

    override init() {
        super.init()

        rtmpStream = RTMPStream(connection: rtmpConnection)

        guard let currentVC = UnityGetGLViewController() else {
            assertionFailure("Cannot get the current view controller from unity!")
            return
        }
        // add camera view on top of the unity game view
        currentVC.addChildViewController(cameraViewController)
        currentVC.view.addSubview(cameraViewController.view);
        cameraViewController.didMove(toParentViewController: currentVC)

        DispatchQueue.global(qos: .background).async {
            self.initSession()
        }
    }

    /* Configure iOS video and audio session */
    private func initSession() {
        NSLog("initialize AV session")
        session = AVAudioSession.sharedInstance()
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
            try session.setActive(true)

            isAVSessionReady = true

        } catch {
            NSLog("session error caught")
        }
        NSLog("initialize AV session end.")
    }

    /* options is a string of space seperated key=value pairs
       address=rtmp://us1.twitch.tv/stream streamName=hello streamKey=abc123 width=1280 height=720 videoBitrate=1234 muted=true audioBitrate audioSampleRate
    */
    private func _startStreaming(options: String) {
        NSLog("=== startStreaming === options: \"\(options)\" ===")

        guard !isStreaming && isAVSessionReady else {
            return
        }

        /* Configure stream */
        
        // add audio and video to stream
        rtmpStream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
            NSLog("attachAudio error - " + error.localizedDescription)
        }
        rtmpStream.attachCamera(DeviceUtil.device(withPosition: isUsingFrontCamera ? .front : .back)) { error in
            NSLog("attachCamera error - " + error.localizedDescription)
        }

        // configure quality options
        let optionsArr = options.split(separator: " ")

        var address: String = "rtmp://192.168.1.203:1935/stream"
        var streamName: String = "hello"
        var streamKey: String
        var width: Int = 1280
        var height: Int = 720
        var videoBitrate: Int = 160 * 1024 * 3
        // audioBitrate
        // audioSampleRate
        for opt in optionsArr {
            let pairArr = opt.split(separator: "=")
            let key = pairArr[0]
            let value = pairArr[1]
            switch key {
                case "address":
                    address = String(value)
                case "streamName":
                    streamName = String(value)
                case "streamKey":
                    streamKey = String(value)
                case "width":
                    // use default value if convert to Int fails
                    width = Int(value) ?? width
                case "height":
                    height = Int(value) ?? height
                case "videoBitrate":
                    videoBitrate = Int(value) ?? videoBitrate
                default:
                    print("Unknown option " + String(opt))
            }
        }

        // settings
        // rtmpStream.captureSettings = [
        //     "sessionPreset": AVCaptureSession.Preset.hd1280x720.rawValue,
        //     "continuousAutofocus": true,
        //     "continuousExposure": true
        // ]
        rtmpStream.videoSettings = [
            "width": width, // video output width
            "height": height, // video output height
            "bitrate": videoBitrate, // video output bitrate
            // "dataRateLimits": [160 * 1024 / 8, 1], optional kVTCompressionPropertyKey_DataRateLimits property
            // "profileLevel": kVTProfileLevel_H264_Baseline_3_1, // H264 Profile require "import VideoToolbox"
            "maxKeyFrameIntervalDuration": 2, // seconds
        ]
        rtmpStream.audioSettings = [
            "muted": !isMicActive,
            // "bitrate": audioBitrate,
            // "sampleRate": audioSampleRate,
        ]

        // show camera feed
        DispatchQueue.main.async {
            self.cameraViewController.renderCameraStream(stream: self.rtmpStream)
        }

        rtmpConnection.connect(address)
        rtmpStream.publish(streamName)

        self.isStreaming = true

        // notify stream started
        // UnitySendMessage(kCallbackTarget, "OnStartStreaming")
        NSLog("=== start streaming -- end")
    }

    @objc func startStreaming(options: String) {
        DispatchQueue.global(qos: .background).async {
            self._startStreaming(options: options)
        }
    }

    @objc func stopStreaming() {
        print("=== stopStreaming ===")

        guard isStreaming else {
            return
        }

        rtmpStream.close()
        rtmpStream.dispose()

        cameraViewController.hideView()

        self.isStreaming = false
    }

    @objc func setMicActive(_ active: Bool) {
        if isStreaming {
            rtmpStream.audioSettings["muted"] = !active
        }
        self.isMicActive = active
    }

    @objc func setCameraActive(_ active: Bool) {
        // TODO
        // rtmpStream.???
        // perhaps stream.attachCamera(nil) ?
        self.isCameraActive = active
    }

    @objc func switchCamera(_ useFrontCamera: Bool) {
        isUsingFrontCamera = useFrontCamera

        guard isCameraActive && isStreaming else {
            return
        }

        rtmpStream.attachCamera(DeviceUtil.device(withPosition: isUsingFrontCamera ? .front : .back)) { error in
            NSLog("switchCamera - attachCamera error - " + error.localizedDescription)
        }
    }

}