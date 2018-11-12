import Foundation
import HaishinKit
import AVFoundation
import UIKit
import pop

class CameraBubbleViewController: UIViewController {

    private var innerCameraView: HKView!
    private var innerLogoView: UIImageView!
    private var logoImage: UIImage!
    
    // drawing
    private let cameraBubbleSize: CGFloat = 135
    private let logoSize: CGFloat = 80
    // TODO: use game logo
    private let logoUrl: URL = URL(string: "https://i.imgur.com/N7RjzSC.png")!
    // TODO: let unity set exact height
    // height of the topbar in unity that has fullscreen button etc
    private let topBarMenuHeight: CGFloat = 40

    private let borderWidth: CGFloat = 2.5;
    private let borderColor: CGColor = UIColor.white.cgColor
    private var isFirstLayout: Bool = true
    private var _isFullscreenCamera: Bool = false
    public var isFullscreenCamera: Bool {
        get {
            return _isFullscreenCamera
        }
        set {
            _isFullscreenCamera = newValue

            self.pop_removeAllAnimations()

            if _isFullscreenCamera {
                bubbleFrameBeforeFullscreen = view.frame
                updateInnerViewForFullscreen()
            } else {
                view.frame = bubbleFrameBeforeFullscreen!
                viewRadius = targetViewRadius
            }
            
            panGesture.isEnabled = !_isFullscreenCamera
            tapGesture.isEnabled = !_isFullscreenCamera
        }
    }
    private var bubbleFrameBeforeFullscreen: CGRect?
    private var viewRadius: CGFloat!

    // touch and drag view
    private let DRAG_ANIMATION_KEY: String = "dragBubble"
    private let GROW_ANIMATION_KEY: String = "growShrinkBubble"
    private var panGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    private var dragStartLocation = CGPoint(x: 0, y: 0)
    private var isDragging: Bool = false
    private var draggingBounds: CGRect!
    private var circleBorder: CALayer!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        view.isHidden = true
        view.backgroundColor = .clear

        // handle touch
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedView))
        view.addGestureRecognizer(tapGesture)
        // handle drag view
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(viewWasDragged))
        view.addGestureRecognizer(panGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        view.clipsToBounds = true
        view.layer.masksToBounds = true

        // camera view
        innerCameraView = HKView(frame: view.bounds)
        innerCameraView.videoGravity = AVLayerVideoGravity.resizeAspectFill

        view.addSubview(innerCameraView)

        // logo view
        innerLogoView = UIImageView(frame: CGRect(x: 0, y: 0, width: logoSize, height: logoSize))
        innerLogoView.isHidden = true

        // TODO: add actual logo image
        // is it possible to include both 1x and 2x sizes?
        // let imageUrl = URL(string: logoUrl)
        innerLogoView.setImage(from: logoUrl)

        viewRadius = targetViewRadius

        view.addSubview(innerLogoView)

        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewWillLayoutSubviews() {
        // not everything is ready on the first layout call
        if isFirstLayout {
            view.frame.size = CGSize(width: cameraBubbleSize, height: cameraBubbleSize)
            view.frame.origin = CGPoint(
                x: view.superview!.bounds.minX + 10,
                y: view.superview!.bounds.maxY - view.frame.height - 10
            )
            bubbleFrameBeforeFullscreen = view.frame
            // extra width of draggable view to keep inside area
            let draggableKeepInside = cameraBubbleSize / 4
            // area to contain view within
            draggingBounds = view.superview!.frame.insetBy(dx: draggableKeepInside, dy: draggableKeepInside)

            isFirstLayout = false
            return
        }
        if isFullscreenCamera {
            updateInnerViewForFullscreen()
        } else {
            updateInnerView()
        }
    }

    private func updateInnerView() {
        let radius = self.viewRadius!

        // update in case radius changed
        view.frame.origin = view.frame.center.add(dx: -radius, dy: -radius)
        view.frame.size = CGSize(width: radius * 2, height: radius * 2)

        cropToCircle(radius)
        drawBorder(radius)

        // fit inner views to the view
        innerCameraView.frame = view.bounds
        innerCameraView.frame.origin = view.bounds.center.add(dx: -radius, dy: -radius)

        innerLogoView.frame = view.bounds
        innerLogoView.frame.origin = view.bounds.center.add(dx: -radius, dy: -radius)
    }

    private func updateInnerViewForFullscreen() {
        let screen = view.superview!.frame
        view.frame = CGRect(
            x: screen.origin.x,
            y: screen.origin.y + topBarMenuHeight,
            width: screen.width,
            height: screen.height - topBarMenuHeight
        )

        innerCameraView.frame = view.bounds

        removeBorder()
        removeCircleCropping()
    }


    private func animateUpdateInnerView(_ newRadius: CGFloat) {
        // animate shrinking / growing

        if let prop = POPAnimatableProperty.property(withName: "CameraBubbleViewController.viewRadius", initializer: { prop in
            guard let prop = prop else {
                return
            }
            // read value
            prop.readBlock = { obj, values in
                guard let obj = obj as? CameraBubbleViewController, let values = values else {
                    return
                }

                values[0] = obj.viewRadius
            }
            // write value
            prop.writeBlock = { obj, values in
                guard let obj = obj as? CameraBubbleViewController, let values = values else {
                    return
                }

                obj.viewRadius = values[0]
                // update view
                self.updateInnerView()
            }
            // dynamics threshold
            prop.threshold = 0.01
        }) as? POPAnimatableProperty {
            if let growAnim = view.pop_animation(forKey: DRAG_ANIMATION_KEY) as? POPSpringAnimation {
                /* update to value to new destination */
                growAnim.toValue = newRadius
            } else {
                /* create and start a new animation */
                print("created grow/shrikn anim to \(newRadius), from \(self.viewRadius!)")
                let growAnim = POPSpringAnimation()
                growAnim.property = prop
                growAnim.springSpeed = 17
                growAnim.springBounciness = 5
                growAnim.toValue = newRadius
                self.pop_add(growAnim, forKey: DRAG_ANIMATION_KEY)
            }
        }
    }

    public func addCameraStream(stream: RTMPStream) {
        innerCameraView.attachStream(stream)
    }

    public func showView() {
        view.isHidden = false
    }
    public func hideView() {
        view.isHidden = true
    }

    public func hideCameraShowLogo() {
        innerCameraView.isHidden = true
        innerLogoView.isHidden = false
        if isFullscreenCamera {
            updateInnerViewForFullscreen()
        } else {
            animateUpdateInnerView(targetViewRadius)
        }
    }
    public func hideLogoShowCamera() {
        innerLogoView.isHidden = true
        innerCameraView.isHidden = false
        if isFullscreenCamera {
            updateInnerViewForFullscreen()
        } else {
            animateUpdateInnerView(targetViewRadius)
        }
    }

    private var targetViewRadius: CGFloat {
        var radius: CGFloat!
        if !self.innerCameraView.isHidden {
            // radius when showing camera
            radius = min(self.cameraBubbleSize / 2, self.cameraBubbleSize / 2)
        }
        if !self.innerLogoView.isHidden {
            // radius when showing logo
            radius = self.logoSize / 2
        }
        return radius
    }

    // MARK - drag around the bubble view & tap

    override func touchesBegan(_ touches: (Set<UITouch>?), with event: UIEvent!) {
        guard !isFullscreenCamera else {
            return
        }

        dragStartLocation = view.frame.center
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isFullscreenCamera && isDragging else {
            return
        }

        isDragging = false
        var originString = view.frame.origin.toString()
        var topRightString = CGPoint(x: view.frame.maxX, y: view.frame.minY).toString()

        UnitySendMessage(
            kUnityCallbackTarget,
            "OnCameraBubbleMoved",
            "\(originString),\(topRightString)"
        )
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isFullscreenCamera && isDragging else {
            return
        }

        isDragging = false
        var originString = view.frame.origin.toString()
        var topRightString = CGPoint(x: view.frame.maxX, y: view.frame.minY).toString()

        UnitySendMessage(
            kUnityCallbackTarget,
            "OnCameraBubbleMoved",
            "\(originString),\(topRightString)"
        )
    }

    @objc func tappedView(sender: UITapGestureRecognizer) {
        UnitySendMessage(kUnityCallbackTarget, "OnTapCameraBubble", "")
    }

    @objc func viewWasDragged() {
        let translation = panGesture.translation(in: view.superview)
        if !isDragging {
            let translationDistance = simd_length(simd_make_float2(Float(translation.x), Float(translation.y)))

            if translationDistance > 7 {
                isDragging = true
            }
        }

        guard isDragging else {
            return
        }

        // clamp to within screen
        let dragTo = dragStartLocation.add(translation)
        let clampedCenter = CGPoint(
            x: dragTo.x.clamped(to: draggingBounds.minX...draggingBounds.maxX),
            y: dragTo.y.clamped(to: draggingBounds.minY...draggingBounds.maxY)
        )
        // calculate origin from new clamped center
        let clampedNewOrigin = clampedCenter.add(
            dx: -view.frame.width / 2,
            dy: -view.frame.height / 2
        )

        // animate dragging

        let toValue = NSValue(cgRect: CGRect(origin: clampedNewOrigin, size: view.frame.size))
        if let anim = view.pop_animation(forKey: DRAG_ANIMATION_KEY) as? POPSpringAnimation {
            /* update to value to new destination */
            anim.toValue = toValue
        } else {
            /* create and start a new animation */
            let dragAnimation = POPSpringAnimation(propertyNamed: kPOPViewFrame)!
            dragAnimation.springSpeed = 16.5
            dragAnimation.springBounciness = 13.5
            dragAnimation.toValue = toValue
            view.pop_add(dragAnimation, forKey: DRAG_ANIMATION_KEY)
        }
    }


    // drawing

    private func cropToCircle(_ radius: CGFloat) {
        if !view.layer.masksToBounds {
            view.layer.masksToBounds = true
        }
        // crop view to circle
        let circleShape = CAShapeLayer()
        circleShape.path = getCircleCenteredInView(radius).cgPath
        view.layer.mask = circleShape

        // crop inner camera view to smaller circle
        // allowing space for the border
        let innerCircleShape = CAShapeLayer()
        innerCircleShape.path = getCircleCenteredInView(radius - borderWidth).cgPath

        // apply mask
        innerCameraView.layer.mask = innerCircleShape
        innerLogoView.layer.mask = innerCircleShape
    }
    private func removeCircleCropping() {
        view.layer.mask = nil
        innerCameraView.layer.mask = nil
    }

    private func drawBorder(_ radius: CGFloat) {
        removeBorder()
        let circlePath = getCircleCenteredInView(radius - borderWidth / 2)

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath

        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = borderColor
        shapeLayer.lineWidth = borderWidth

        view.layer.addSublayer(shapeLayer)
        self.circleBorder = shapeLayer
    }
    private func removeBorder() {
        if let border = self.circleBorder {
            border.removeFromSuperlayer()
            self.circleBorder = nil
        }
    }

    private func getCircleCenteredInView(_ radius: CGFloat) -> UIBezierPath {
        return UIBezierPath(
            arcCenter: CGPoint(x: view.frame.width / 2, y: view.frame.height / 2),
            radius: radius,
            startAngle: 0.0,
            endAngle: CGFloat(2 * Double.pi),
            clockwise: true
        )
    }
}


// download and set image
extension UIImageView {
    private func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }

    func setImage(from url: URL) {
        // print("Download Started")
        DispatchQueue.global(qos: .background).async {
            self.getData(from: url) { data, response, error in
                guard let data = data, error == nil else { return }
                // print(response?.suggestedFilename ?? url.lastPathComponent)
                // print("Download Finished")
                DispatchQueue.main.async {
                    self.image = UIImage(data: data)
                }
            }
        }
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension CGRect {
    var center: CGPoint { return CGPoint(x: midX, y: midY) }
}

extension CGPoint {
    func add(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: x + point.x, y: y + point.y)
    }
    func add(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: x + dx, y: y + dy)
    }
    func toString() -> String {
        return "\(x.description),\(y.description)"
    }
}
