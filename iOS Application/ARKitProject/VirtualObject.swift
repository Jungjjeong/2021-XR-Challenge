// MARK: - Object define Node


import Foundation
import SceneKit.ModelIO
import ARKit


class VirtualObject: SCNNode, URLSessionDownloadDelegate{
	static let ROOT_NAME = "Virtual object root node"
	var fileExtension: String = ""
	var thumbImage: UIImage!
	var title: String = ""
	var modelName: String = ""
	var modelLoaded: Bool = false
	var id: Int!
    var handle: Bool = false
    
    let fileManager = FileManager.default
//    let progressViewController = ProgressViewController()
    let popUpView = UIStoryboard.init(name: "ProgressViewController", bundle: nil).instantiateViewController(identifier: "popUpView")



	var viewController: MainViewController?

	override init() {
		super.init()
		self.name = VirtualObject.ROOT_NAME
	}
    
    init(modelName: String, fileExtension : String, thumbImageFilename: String, title: String, handle : Bool) {
		super.init()
		self.id = VirtualObjectsManager.shared.generateUid()
		self.name = VirtualObject.ROOT_NAME
		self.modelName = modelName
		self.fileExtension = fileExtension
		self.thumbImage = UIImage(named: thumbImageFilename)
		self.title = title
        self.handle = handle
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:)가 구현되지 않았습니다.")
	}

    // MARK: - 3D model load function
	func loadModel() {
        print("---------------------Start loadModel function")

        let downloadedScenePath = getDocumentsDirectory().appendingPathComponent("\(modelName).usdz")
        
        //1. Create The Filename
        print("loadModel Bool ----------------\(fileManager.fileExists(atPath: downloadedScenePath.path))")
        if !fileManager.fileExists(atPath: downloadedScenePath.path) {
            showPopup()
            downloadSceneTask()
        }
        
        let asset = MDLAsset(url: downloadedScenePath)
        asset.loadTextures()
        
        let object = asset.object(at: 0)
        
        let node = SCNNode.init(mdlObject: object)
        if modelName == "Teapot" || modelName == "AirForce" || modelName == "fender_stratocaster" {
            node.scale = SCNVector3(0.01, 0.01, 0.01)
        }
        
        if modelName == "hanssemchair01" {
            node.scale = SCNVector3(0.001, 0.001, 0.001)
        }
        
        // MARK: - Light & Shadow Node
        
//        let shadowPlane = SCNPlane(width: 5000, height: 5000)
//
//        let material = SCNMaterial()
//        material.isDoubleSided = false
//        material.lightingModel = .shadowOnly // Requires SCNLight shadowMode = .forward and
//        // light가 .omni거나 .spot이면 검은색으로 변하는 이슈 발생
//
//        shadowPlane.materials = [material]
//
//        let shadowPlaneNode = SCNNode(geometry: shadowPlane)
//        shadowPlaneNode.name = modelName
//        shadowPlaneNode.eulerAngles.x = -.pi / 2
//        shadowPlaneNode.castsShadow = false
//
//        self.addChildNode(shadowPlaneNode)
//
//        let light = SCNLight()
//        light.type = .directional
//        light.castsShadow = true
//        light.shadowRadius = 20
//        light.shadowSampleCount = 64
//
//        light.shadowColor = UIColor(white: 0, alpha: 0.5)
//        light.shadowMode = .forward
//        light.maximumShadowDistance = 11000
////        let constraint = SCNLookAtConstraint(target: self)
////
////        guard let lightEstimate = MainViewController.sceneView.session.currentFrame?.lightEstimate else {
////            return
////        }
//
//        // light node
//        let lightNode = SCNNode()
//        lightNode.light = light
////        lightNode.light?.intensity = lightEstimate.ambientIntensity
////        lightNode.light?.temperature = lightEstimate.ambientColorTemperature
////            lightNode.position = SCNVector3(object.position.x + 10, object.position.y + 30, object.position.z + 30)
//        lightNode.eulerAngles = SCNVector3(45.0,0,0)
////        lightNode.constraints = [constraint]
//        self.addChildNode(lightNode)
        
        
        
        self.addChildNode(node)

        print("---------------finish \(modelName) loadmodel func")
        
    }
    
    // MARK: - Model unload function
	func unloadModel() {
		for child in self.childNodes {
			child.removeFromParentNode()
		}
        print("unloadModel func")
		modelLoaded = false
	}

    
    // MARK: - Gesture
	func translateBasedOnScreenPos(_ pos: CGPoint, instantly: Bool, infinitePlane: Bool) {
        print("Translate BasedOn")
		guard let controller = viewController else {
			return
		}
		let result = controller.worldPositionFromScreenPosition(pos, objectPos: self.position, infinitePlane: infinitePlane)
		controller.moveVirtualObjectToPosition(result.position, instantly, !result.hitAPlane)
	}
    
    func translateHandleTrue(_ pos: CGPoint, instantly: Bool, infinitePlane: Bool) {
        print("Translate Handle True")
        guard let controller = viewController else {
            return
        }
        let result = controller.worldPositionFromScreenPosition(pos, objectPos: self.position, infinitePlane: infinitePlane)
        let result2 = controller.worldPositionFromScreenPosition(pos, objectPos: self.position, infinitePlane: infinitePlane)
        print(result)
        print(result2)
        controller.moveVirtualObjectToPosition(result.position, instantly, !result.hitAPlane)
    }
    
    // MARK: - PopUp setting
    
    func showPopup() {
        DispatchQueue.main.async{
            self.popUpView.modalPresentationStyle = .overCurrentContext

            print("Show PopUp")
            
            self.viewController!.present(self.popUpView, animated: true, completion: nil)
        }
    }
    
    
    func closePopup() {
        DispatchQueue.main.async {
//            self.progressViewController.setProgress100()
            self.popUpView.dismiss(animated: true, completion: nil)
        }
    }
    
    
    
    // MARK: - download from URL
    func downloadSceneTask() {
        //1. Create The Filename
        print("start downloadscenetask function")
        let url : URL
        switch modelName
        {
        case "Teapot":
            print("Teapot")
            url = URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/teapot/teapot.usdz")!
        case "AirForce":
            print("AirForce")
            url = URL(string: "https://devimages-cdn.apple.com/ar/photogrammetry/AirForce.usdz")!
        case "fender_stratocaster":
            print("fender_stratocaster")
            url = URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/stratocaster/fender_stratocaster.usdz")!
        case "moa_rose" :
            print("moa_rose")
            url = URL(string: "https://github.com/Jungjjeong/2021-Summer-Hanssem/raw/main/models/moa_rose.usdz")!
        case "hanssemchair01" :
            print("hanssemchair01")
            url = URL(string: "https://github.com/Jungjjeong/2021-Summer-Hanssem/raw/main/models/hanssemchair01.usdz")!
        default:
            print("Default")
            url = URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/teapot/teapot.usdz")!
        }
         // getDownloadSize
        getDownloadSize(url: url, completion: { (size, error) in
            if error != nil {
                print("An error occurred when retrieving the download size: \(error!.localizedDescription)")
            } else {
                print("The download size is \(size).")
            }
        })
        
        
        //2. Create The Download Session
        print("create the download session")
        let downloadSession = URLSession(configuration: URLSession.shared.configuration, delegate: self, delegateQueue: nil)
        
        
        //3. Create The Download Task & Run It
        print("create the download task & run it")

        let downloadTask = downloadSession.downloadTask(with: url)
        downloadTask.resume()
    }
    
    
    
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        //1. Create The Filename
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(modelName).usdz")
        print("----------------\(fileManager.fileExists(atPath: fileURL.path))")
        
//        var fileSize : UInt64
        
        
        if !fileManager.fileExists(atPath: fileURL.path) {
            //2. Copy It To The Documents Directory
            do {
                try fileManager.copyItem(at: location, to: fileURL)
                
//                do{
//                    let attr = try fileManager.attributesOfItem(atPath: fileURL.path)
//                    fileSize = attr[FileAttributeKey.size] as! UInt64
//
//                    print("\(fileSize) byte")
//
//                } catch {
//                    print("Error : \(error)")
//                }
                
                print("Successfuly Saved File \(fileURL)")
                loadModel()
                closePopup()
            } catch {
                
                print("Error Saving: \(error)")
            }
        }
    }
    
    
    
    func getDocumentsDirectory() -> URL {
        
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    
    func getDownloadSize(url: URL, completion: @escaping (Int64, Error?) -> Void ) {
        let timeoutInterval = 5.0
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: timeoutInterval)
        request.httpMethod = "HEAD"
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            let contentLength = response?.expectedContentLength ?? NSURLSessionTransferSizeUnknown
            completion(contentLength, error)
        }.resume()
    }
}


// MARK: - Extension

extension VirtualObject {

	static func isNodePartOfVirtualObject(_ node: SCNNode) -> Bool {
		if node.name == VirtualObject.ROOT_NAME {
//            print("VirtualObject - isnodepartOfVirtualObject")
			return true
		}

		if node.parent != nil {
//            print("VirtualObeject - is Not nodepartofVirtualObject")
			return isNodePartOfVirtualObject(node.parent!)
		}

		return false
	}
}


// MARK: - Protocols for Virtual Objects

protocol ReactsToScale {
	func reactToScale()
}

extension SCNNode {

	func reactsToScale() -> ReactsToScale? {
		if let canReact = self as? ReactsToScale {
			return canReact
		}

		if parent != nil {
			return parent!.reactsToScale()
		}

		return nil
	}
}
