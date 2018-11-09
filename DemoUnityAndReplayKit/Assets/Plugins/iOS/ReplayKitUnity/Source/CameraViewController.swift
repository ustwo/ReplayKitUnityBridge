import Foundation
import HaishinKit
import AVFoundation
import UIKit
import VideoToolbox

class CameraViewController: UIViewController {

    private var innerCameraView: HKView!

    override func viewDidLoad() {
        print("cam viewDidLoad")
        super.viewDidLoad()

        view.isHidden = true
        view.backgroundColor = .clear
    }

    // Called when the view is added to a parent view
    override func viewWillAppear(_ animated: Bool) {
        print("cam viewWillAppear")
        super.viewWillAppear(animated)

        // inner camera view
        innerCameraView = HKView(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
        innerCameraView.videoGravity = AVLayerVideoGravity.resizeAspectFill

        view.addSubview(innerCameraView)
    }

    override func viewWillLayoutSubviews() {
        if true {

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view.superview!, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view.superview!, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 240).isActive = true
        NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 135).isActive = true

        } else {

        view.translatesAutoresizingMaskIntoConstraints = true
        view.center = CGPoint(x: view.superview!.bounds.midX, y: view.superview!.bounds.midY)
        view.autoresizingMask = [
            UIView.AutoresizingMask.flexibleLeftMargin,
            UIView.AutoresizingMask.flexibleRightMargin,
            UIView.AutoresizingMask.flexibleTopMargin,
            UIView.AutoresizingMask.flexibleBottomMargin
        ]

        }
        innerCameraView.frame = view.bounds
    }

    public func renderCameraStream(stream: RTMPStream) {
        NSLog("attched begin")
        innerCameraView.attachStream(stream)
        view.isHidden = false
        NSLog("attched done")
    }

    public func hideView() {
        view.isHidden = true
    }
}
