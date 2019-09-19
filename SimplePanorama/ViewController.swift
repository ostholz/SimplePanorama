//
//  ViewController.swift
//  SimplePanorama
//

import UIKit
import SceneKit
import CoreMotion


class ViewController: UIViewController {
    
    let scene = SCNScene()
    let scnView = SCNView()
    
    //    var lastPoint_x: CGFloat = 0
    //    var lastPoint_y: CGFloat = 0
    //    var fingerRotationY: CGFloat = 0
    //    var fingerRotationX: CGFloat = 0
    var cameraNode: SCNNode?
    var images = [String: UIImage]()
    
    var cameraTracingStarted = false
    
    var motionManager = CMMotionManager()
    
    var lastRoll: Float = -361
    var lastW: Float = 0
    var shouldStartTrackingCamera = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupScene()
    }

    private func setupScene() {
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.automaticallyAdjustsZRange = true
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0) //z was 15
        self.cameraNode = cameraNode
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLight.LightType.omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the SCNView
        let scnView = SCNView(frame: view.frame)
        scnView.tag = 100
        view.addSubview(scnView)
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.debugOptions = .showCameras
        
        if #available(iOS 11, *) {
            //negativ number: scene moves in same direction as pan gesture recognizer
            scnView.cameraControlConfiguration.rotationSensitivity = -0.2
        }
        scnView.debugOptions = [.showWireframe, .showBoundingBoxes]
        
        /*
         let pan = UIPanGestureRecognizer(target: self, action: #selector(panPanorama(gesture:)))
         scnView.addGestureRecognizer(pan)
         
         let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture(gesture:)))
         scnView.addGestureRecognizer(pinch)
         */
        
        // show statistics such as fps and timing information
        //scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black

        setupPanoramaScene()
    }
    
    private func setupPanoramaScene() {
        var sceneImages = [UIImage]()
        sceneImages.append(UIImage(named: "r.jpg")!)
        sceneImages.append(UIImage(named: "l.jpg")!)
        sceneImages.append(UIImage(named: "u.jpg")!)
        sceneImages.append(UIImage(named: "d.jpg")!)
        sceneImages.append(UIImage(named: "f.jpg")!)
        sceneImages.append(UIImage(named: "b.jpg")!)
        scene.background.contents = sceneImages
        
        startCameraTracking(cameraNode: cameraNode!)
    }
    
    
    private func startCameraTracking(cameraNode: SCNNode) {
        motionManager.deviceMotionUpdateInterval = 0.1 // 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (data, error) in
            guard let data = data else { return }
            
//            cameraNode.orientation = self.orientationFromQuaternion(data.attitude.quaternion)
//            if self.shouldStartTrackingCamera || self.logCurrentMotion(attitude: data.attitude) {
                cameraNode.orientation = data.gaze(atOrientation: UIApplication.shared.statusBarOrientation)
//            }
        }
    }
    
    private func logCurrentMotion(attitude: CMAttitude) -> Bool {
        
        let roll = GLKMathRadiansToDegrees(Float(attitude.roll))
        let pitch = GLKMathRadiansToDegrees(Float(attitude.pitch))
        let yaw = GLKMathRadiansToDegrees(Float(attitude.yaw))
        
        if lastRoll == -361 {
            lastRoll = roll
            lastW = pitch
        } else {
//            print("delta roll: \(attitude.quaternion.x - lastRoll), delta w: \(attitude.quaternion.w - lastW)")
            let deltaX = roll - lastRoll
            let deltaW = pitch - lastW
            if abs(deltaX) > 20 ||  abs(deltaW) > 20 {
                print("deltaX: \(deltaX), deltaW: \(deltaW)")
                shouldStartTrackingCamera = true
                return true
            }
        }
        return false
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if let scnView = view.viewWithTag(100) {
            scnView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        }
    }
}

//  https://gist.github.com/travisnewby/96ee1ac2bc2002f1d480
extension CMDeviceMotion {
    
    func gaze(atOrientation orientation: UIInterfaceOrientation) -> SCNVector4 {
        
        let attitude = self.attitude.quaternion
        let aq = GLKQuaternionMake(Float(attitude.x), Float(attitude.y), Float(attitude.z), Float(attitude.w))
        
        let final: SCNVector4
        
        switch orientation {
            
        case .landscapeRight:
            
            let cq = GLKQuaternionMakeWithAngleAndAxis(Float.pi / 2, 0, 1, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            
            final = SCNVector4(x: -q.y, y: q.x, z: q.z, w: q.w)
            
        case .landscapeLeft:
            
            let cq = GLKQuaternionMakeWithAngleAndAxis(-Float.pi / 2, 0, 1, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            
            final = SCNVector4(x: q.y, y: -q.x, z: q.z, w: q.w)
            
        case .portraitUpsideDown:
            
            let cq = GLKQuaternionMakeWithAngleAndAxis(Float.pi / 2, 1, 0, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            
            final = SCNVector4(x: -q.x, y: -q.y, z: q.z, w: q.w)
            
        case .unknown:
            
            fallthrough
            
        case .portrait:
            
            fallthrough
            
        @unknown default:
            
            let cq = GLKQuaternionMakeWithAngleAndAxis(-Float.pi / 2, 1, 0, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            
            final = SCNVector4(x: q.x, y: q.y, z: q.z, w: q.w)
        }
        
        return final
    }
}
