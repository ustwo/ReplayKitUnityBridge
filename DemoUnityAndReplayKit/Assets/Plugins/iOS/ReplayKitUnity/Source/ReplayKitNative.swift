import Foundation
import UIKit
import ReplayKit
import HaishinKit
import AVFoundation

// name of the c-sharp file in Unity that will listen to messages being sent from Xcode
let kCallbackTarget = "ReplayKitUnity"


@objc public class ReplayKitNative: NSObject {
    var rtmpConnection: RTMPConnection = RTMPConnection()
    var rtmpStream: RTMPStream!

    // connectionAddress is the complete address to be passed to .connect() e.g. "rtmp://192.168.1.203:1935/stream"
    // @objc func startStreaming(connectionAddress: String, streamName: String, streamKey: String) {
    @objc func startStreaming(key: String) {
        print(".swift === startStreaming using key \"\(key)\" ===")

        /* Configure iOS video and audio session */

        let session: AVAudioSession = AVAudioSession.sharedInstance()

        do {
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

        } catch {
            print("session error caught")
        }

        /* Configure livestream */

        rtmpStream = RTMPStream(connection: rtmpConnection)

        rtmpStream.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { error in
           print("attachAudio error - " + error.localizedDescription)
        }
        rtmpStream.attachCamera(DeviceUtil.device(withPosition: .front)) { error in
            print("attachCamera error - " + error.localizedDescription)
        }

        // let hkView = HKView(frame: view.bounds)

        // hkView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        // hkView.attachStream(rtmpStream)

        // // add ViewController#view
        // view.addSubview(hkView)

        let serverAddress = "192.168.1.203:1935"
        rtmpConnection.connect("rtmp://\(serverAddress)/stream")
        rtmpStream.publish("hello")

        _isStreaming = true

        // notify stream started
        // UnitySendMessage(kCallbackTarget, "OnStopRecording", file.absoluteString)
    }

    @objc func stopStreaming() {
        print(".swift === stopStreaming ===")
        rtmpStream.removeObserver(self, forKeyPath: "currentFPS")
        rtmpStream.close()
        rtmpStream.dispose()
        _isStreaming = false
    }

    var _isStreaming: Bool = false

    @objc var isStreaming: Bool {
        // TODO
        return _isStreaming
    }


    @objc static let shared = ReplayKitNative()

    // Adds a new window on top of current one with UI elements
    // func addDefaultButtonWindow(fromVC: UIViewController) {
    //     buttonWindow = UIWindow(frame: fromVC.view.frame)
    //     buttonWindow?.rootViewController = RecordViewController()
    //     buttonWindow?.rootViewController?.view.backgroundColor = .clear
    //     buttonWindow?.makeKeyAndVisible()
    // }
}
