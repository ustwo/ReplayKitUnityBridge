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
    private let cameraWidth: CGFloat = 240
    private let cameraHeight: CGFloat = 135
    private let logoSize: CGFloat = 70
    private let logoUrl: URL = URL(string: "https://cdn4.iconfinder.com/data/icons/various-icons-2/476/Unity.png")!

    private let borderWidth: CGFloat = 2.5;
    private let borderColor: CGColor = UIColor.white.cgColor
    private var isFirstLayout: Bool = true
    private var useCircleMask: Bool = true

    // touch and drag view
    private let dragAnimationKey: String = "drag"
    private var panGesture: UIPanGestureRecognizer!
    private var dragStartLocation = CGPoint(x: 0, y: 0)
    private var isDragging: Bool = false
    private var draggingBounds: CGRect!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.isHidden = true
        view.backgroundColor = .clear

        // touch to drag view
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(viewWasDragged))
//        panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.clipsToBounds = true

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
        
        view.addSubview(innerLogoView)
    }

    override func viewWillLayoutSubviews() {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view.superview!, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view.superview!, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: cameraWidth).isActive = true
        NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: cameraHeight).isActive = true

        // not everything is ready on the first layout call
        if isFirstLayout {
            // extra width of draggable view to keep inside area
            let draggableKeepInside = min(cameraHeight, cameraWidth) / 4
            // area to contain view within
            draggingBounds = view.superview!.frame.insetBy(dx: draggableKeepInside, dy: draggableKeepInside)

            isFirstLayout = false
            return
        }

        innerCameraView.frame = view.bounds
        innerLogoView.frame = view.bounds
        
        var radius: CGFloat!
        
        if !innerCameraView.isHidden {
            // radius when showing camera
            radius = min(view.bounds.width / 2, view.bounds.height / 2)
        } else {
            // radius when showing logo
            radius = logoSize
        }
        
        if useCircleMask {
            cropToCircle(radius)
            drawBorder(radius)
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
    }
    public func hideLogoShowCamera() {
        innerLogoView.isHidden = true
        innerCameraView.isHidden = false
    }

    // touch and drag the view around

    override func touchesBegan(_ touches: (Set<UITouch>?), with event: UIEvent!) {
        dragStartLocation = view.frame.center
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isDragging {
            // view was touched
            UnitySendMessage(kUnityCallbackTarget, "OnTapCameraBubble", "")
            return
        }
        isDragging = false
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
    }

    @objc func viewWasDragged() {
        let translation = panGesture.translation(in: view.superview)
        if !isDragging {
            let translationDistance = simd_length(simd_make_float2(Float(translation.x), Float(translation.y)))

            if (translationDistance > 7) {
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
        if let anim = view.pop_animation(forKey: dragAnimationKey) as? POPSpringAnimation {
            /* update to value to new destination */
            anim.toValue = toValue
        } else {
            /* create and start a new animation */
            let dragAnimation = POPSpringAnimation(propertyNamed: kPOPViewFrame)!
            dragAnimation.springSpeed = 16.5
            dragAnimation.springBounciness = 13.5
            dragAnimation.toValue = toValue
            view.pop_add(dragAnimation, forKey: dragAnimationKey)
        }
    }


    // drawing

    private func cropToCircle(_ radius: CGFloat) {
        // crop view to circle
        let circleShape = CAShapeLayer()
        circleShape.path = getCircleCenteredInView(radius).cgPath
        view.layer.mask = circleShape

        // crop inner camera view to smaller circle
        // allowing space for the border
        let innerCircleShape = CAShapeLayer()
        innerCircleShape.path = getCircleCenteredInView(radius - borderWidth).cgPath
        innerCameraView.layer.mask = innerCircleShape
    }

    private func drawBorder(_ radius: CGFloat) {
        let circlePath = getCircleCenteredInView(radius - borderWidth / 2)

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath

        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = borderColor
        shapeLayer.lineWidth = borderWidth

        view.layer.addSublayer(shapeLayer)
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
}
