import Foundation
import ReplayKit
import HaishinKit
import AVFoundation
import UIKit

// name of the c-sharp file in Unity that will listen to messages being sent from Xcode
let kCallbackTarget = "ReplayKitUnity"


@objc class ReplayKitNative: UIViewController {

    var rtmpConnection: RTMPConnection = RTMPConnection()
    var rtmpStream: RTMPStream!
    var isAVSessionReady: Bool = false
    var session: AVAudioSession!

    @objc static let shared = ReplayKitNative()

    @objc var isStreaming: Bool = false
    @objc var isMicActive: Bool = false
    @objc var isCameraActive: Bool = true
    @objc var isUsingFrontCamera: Bool = true

    private let startRecordBtn = UIButton(type: UIButtonType.roundedRect)

    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
        super.viewWillAppear(animated)

        displayCameraFeed(stream: rtmpStream)
    }

    /* Configure iOS video and audio session */
    func initialize() {
        NSLog("initialize sesh")
        session = AVAudioSession.sharedInstance()
        NSLog("initialize sesh opts -- begin")

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

            isAVSessionReady = true
        } catch {
            NSLog("session error caught")
        }
        NSLog("initialize sesh opts -- end")
    }


    func displayCameraFeed(stream: RTMPStream) {
        // Display camera feed
        let hkView = HKView(frame: self.view.bounds)
        hkView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        hkView.attachStream(stream)

        // add ViewController#view
        self.view.addSubview(hkView)
    }

    /* options is a string of space seperated key=value pairs
       address=rtmp://us1.twitch.tv/stream streamName=hello streamKey=abc123 width=1280 height=720 videoBitrate=1234 muted=true audioBitrate audioSampleRate
    */
    @objc func startStreaming(options: String) {
        NSLog("=== startStreaming === options: \"\(options)\" ===")

        if !isAVSessionReady {
            initialize()
        }

        if isStreaming {
            return
        }

        do {
            try session.setActive(true)
        } catch is Error {
            NSLog("Failed to activate iOS audio/video session")
        }
        /* Configure stream */

        var optionsArr = options.split(separator: " ")

        var address: String = "rtmp://192.168.1.203:1935/stream"
        var streamName: String = "hello"
        var streamKey: String
        var width: Int = 1280
        var height: Int = 720
        var videoBitrate: Int = 160 * 1024
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

        rtmpStream = RTMPStream(connection: rtmpConnection)

        // add audio and video to stream
        rtmpStream.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { error in
            NSLog("attachAudio error - " + error.localizedDescription)
        }
        rtmpStream.attachCamera(DeviceUtil.device(withPosition: isUsingFrontCamera ? .front : .back)) { error in
            NSLog("attachCamera error - " + error.localizedDescription)
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

        // displayCameraFeed(stream: rtmpStream)

        rtmpConnection.connect(address)
        rtmpStream.publish(streamName)
        print("=== live at: " + address + "/" + streamName + ".m3u8")

        isStreaming = true

        // notify stream started
        // UnitySendMessage(kCallbackTarget, "OnStartStreaming")
        NSLog("=== start streaming -- end")
    }

    @objc func stopStreaming() {
        NSLog("=== stopStreaming ===")

        if !isStreaming {
            return
        }

        rtmpStream.close()
        rtmpStream.dispose()
        do {
            try session.setActive(false)
        } catch {
            NSLog("Failed to deactivate iOS audio/video session: \(error)")
        }
        isStreaming = false
    }

    @objc func setMicActive(_ active: Bool) {
        if isStreaming {
            rtmpStream.audioSettings["muted"] = !active
        }
        isMicActive = active
    }

    @objc func setCameraActive(_ active: Bool) {
        // TODO
        // rtmpStream.???
        isCameraActive = active
    }

    @objc func switchCamera(_ useFrontCamera: Bool) {
        isUsingFrontCamera = useFrontCamera
        if !isCameraActive || !isStreaming {
            return
        }

        rtmpStream.attachCamera(DeviceUtil.device(withPosition: isUsingFrontCamera ? .front : .back)) { error in
            NSLog("switchCamera - attachCamera error - " + error.localizedDescription)
        }
    }

}