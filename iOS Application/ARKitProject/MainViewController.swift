// MARK: - Main View Controller

import ARKit
//import Foundation -> UIKit에 포함됨
//import SceneKit -> ARkit에 포함됨
import UIKit // app의 model 객체를 정의하는데 필요한 기본 타입들을 제공한다.
import Photos

class MainViewController: UIViewController { // 가장 상위에 위치할 Controller
	var dragOnInfinitePlanesEnabled = false // 평면이 있다는 가정 하에 계속 드래그할 수 있는 선택창
	var currentGesture: Gesture?
	var screenCenter: CGPoint?

	let session = ARSession() // ar scene의 고유 런타임 인스턴스 관리
	var sessionConfig: ARConfiguration = ARWorldTrackingConfiguration() // 주변의 변화에도 anchor 고정하는 역할

	var trackingFallbackTimer: Timer?


	var recentVirtualObjectDistances = [CGFloat]()
	let DEFAULT_DISTANCE_CAMERA_TO_OBJECTS = Float(10)

	override func viewDidLoad() { // view initialized
        super.viewDidLoad()
        
        
        let mainCustomAlertView = UIStoryboard.init(name: "Main", bundle: nil)
        
        let popUpView = mainCustomAlertView.instantiateViewController(identifier: "popUpView")
        popUpView.modalPresentationStyle = .overCurrentContext
        present(popUpView, animated: true, completion: nil)
        
        
        Setting.registerDefaults()
        setupScene()
        setupDebug()
        setupUIControls()
		setupFocusSquare()
		updateSettings()
		resetVirtualObject() // view가 처음 로드될 때 필요한 요소들 initialized
        sessionConfig.isLightEstimationEnabled = true
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        session.run(sessionConfig)
        HandlingButton.isHidden = true

    }

	override func viewDidAppear(_ animated: Bool) { // view 보여진 후, animation appear
		super.viewDidAppear(animated)

		UIApplication.shared.isIdleTimerDisabled = true // 일정 시간 지나면 꺼지는 타이머가 설정 되지 않았는가 -> true
        // 계속해서 contents를 표시해야 하는 mapping app 같은 경우, 유후 카메라를 끈다.
		restartPlaneDetection() // 뷰가 나타날때마다 plane detection을 수행한다.
	}

	override func viewWillDisappear(_ animated: Bool) { // view 사라지기 전
		super.viewWillDisappear(animated)
		session.pause() // session 멈춘다.
        sceneView.scene.rootNode.removeFromParentNode()
	}
    
    

    // MARK: - ARKit / ARSCNView

	@IBOutlet var sceneView: ARSCNView!
    // ARSCNView는 SCNView 하위 class
    // Scenekit의 가상 3D contents를 ar화면 위에 띄워주는 viewer

    // MARK: - Virtual Object Loading
	var isLoadingObject: Bool = false { // 초기화 진행
		didSet { // 값 변경된 직후에 수행
			DispatchQueue.main.async { // DispatchQueue -> 동시성 프로그래밍 (async)
				self.settingsButton.isEnabled = !self.isLoadingObject // setting list button
				self.addObjectButton.isEnabled = !self.isLoadingObject // object add button
				self.restartExperienceButton.isEnabled = !self.isLoadingObject // restart button (anchor init)
			}
		}
	}

	@IBOutlet weak var addObjectButton: UIButton!

	@IBAction func chooseObject(_ button: UIButton) {
		if isLoadingObject { return } // loadingObject인 상태에서는 중단 (return)

		textManager.cancelScheduledMessage(forType: .contentPlacement)

		let rowHeight = 43
		let popoverSize = CGSize(width: 300, height: rowHeight * VirtualObjectSelectionViewController.COUNT_OBJECTS)
        // object list popup 창 높이, 너비 정의

		let objectViewController = VirtualObjectSelectionViewController(size: popoverSize) // tableview 정의한 class
		objectViewController.delegate = self
		objectViewController.modalPresentationStyle = .popover // model list -> pop over
		objectViewController.popoverPresentationController?.delegate = self
		self.present(objectViewController, animated: true, completion: nil)

		objectViewController.popoverPresentationController?.sourceView = button
		objectViewController.popoverPresentationController?.sourceRect = button.bounds
    }

    // MARK: - Planes

	var planes = [ARPlaneAnchor: Plane]() // dictionary anchor:plane

    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {

		let pos = SCNVector3.positionFromTransform(anchor.transform)
		textManager.showDebugMessage(" \(pos.friendlyString()) 에서 평면 Detect")

		let plane = Plane(anchor, showDebugVisuals)

		planes[anchor] = plane // 해당 anchor(key)에 plane(value) 설정
		node.addChildNode(plane)

		textManager.cancelScheduledMessage(forType: .planeEstimation)
		textManager.showMessage("평면이 인식되었습니다.")
		if !VirtualObjectsManager.shared.isAVirtualObjectPlaced() { // isAVirtualObjectPlaced -> nil이 아닌 배치 object 반환
			textManager.scheduleMessage("Object 배치를 위해 + 버튼을 누르세요.", inSeconds: 7.5, messageType: .contentPlacement)
		}
	}

	func restartPlaneDetection() {
		// configure session
		if let worldSessionConfig = sessionConfig as? ARWorldTrackingConfiguration { // ARWorldTrackingConfiguration 의 sessionConfig로 다운캐스팅
			worldSessionConfig.planeDetection = .horizontal // 수평 planeDetection
			session.run(worldSessionConfig, options: [.resetTracking, .removeExistingAnchors]) // 전에 존재하던 anchor 제거, tracking 초기화
		}

		// reset timer
		if trackingFallbackTimer != nil {
			trackingFallbackTimer!.invalidate()
			trackingFallbackTimer = nil // timer 초기화해준다.
		}

		textManager.scheduleMessage("Object 배치를 위한 평면 찾기", inSeconds: 7.5, messageType: .planeEstimation)
	}

    // MARK: - Focus Square
    var focusSquare: FocusSquare?

    func setupFocusSquare() {
		focusSquare?.isHidden = true // 레이어가 숨겨지는지 여부 -> hide
		focusSquare?.removeFromParentNode()
		focusSquare = FocusSquare()
		sceneView.scene.rootNode.addChildNode(focusSquare!) // 장면 위 Node에 focusSquare 붙인다.

		textManager.scheduleMessage("왼쪽 또는 오른쪽으로 움직여 주세요.", inSeconds: 5.0, messageType: .focusSquare)
    }

	func updateFocusSquare() {
		guard let screenCenter = screenCenter else { return } // nil이면 return, nil이 아닐 시 screenCenter 할당

		let virtualObject = VirtualObjectsManager.shared.getVirtualObjectSelected() // 고른 모델 할당
		if virtualObject != nil && sceneView.isNode(virtualObject!, insideFrustumOf: sceneView.pointOfView!) {
			focusSquare?.hide() // 고른 모델이 존재하고, 오브젝트의 insideFrustumOf가 배치하려는 장면의 pointOfView 안의 node로 존재하면 focussquare을 숨긴다. -> 배치해야 함
		} else {
			focusSquare?.unhide() // 둘중 하나라도 충족하지 않을 시, focusSquare 유지  -> 아직 배치할 준비가 되지 않았음.
		}
		let (worldPos, planeAnchor, _) = worldPositionFromScreenPosition(screenCenter, objectPos: focusSquare?.position)
        // position: SCNVector3?,planeAnchor: ARPlaneAnchor?,hitAPlane: Bool 반환
		if let worldPos = worldPos {
			focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: self.session.currentFrame?.camera) // 해당 값으로 focusSquare 업데이트
			textManager.cancelScheduledMessage(forType: .focusSquare) // 타이머 리셋
		}
	}

	// MARK: - Hit Test Visualization

	var hitTestVisualization: HitTestVisualization? // hitTest 보이게 하는 옵션

	var showHitTestAPIVisualization = UserDefaults.standard.bool(for: .showHitTestAPI) { // 변수 할당 (bool)
		didSet { // 변수 바뀌고 난 직후에 실행
			UserDefaults.standard.set(showHitTestAPIVisualization, for: .showHitTestAPI)
			if showHitTestAPIVisualization {
				hitTestVisualization = HitTestVisualization(sceneView: sceneView) // 활성화
			} else {
				hitTestVisualization = nil // 비활성화
			}
		}
	}

    // MARK: - Debug Visualizations

	@IBOutlet var featurePointCountLabel: UILabel! // Point Cloud size에 보여짐

	func refreshFeaturePoints() {
		guard showDebugVisuals else {
			return
		}

		guard let cloud = session.currentFrame?.rawFeaturePoints else { // 현재 화면의 특징점들을 클라우드에 할당
			return
		}

		DispatchQueue.main.async {
			self.featurePointCountLabel.text = "Features: \(cloud.__count)".uppercased() // 피쳐의 수 rendering
		}
	}

    var showDebugVisuals: Bool = UserDefaults.standard.bool(for: .debugMode) {
        didSet { // 변수가 변한 직후에 실행
			featurePointCountLabel.isHidden = !showDebugVisuals
			debugMessageLabel.isHidden = !showDebugVisuals
			messagePanel.isHidden = !showDebugVisuals
			planes.values.forEach { $0.showDebugVisualization(showDebugVisuals) }
			sceneView.debugOptions = []
			if showDebugVisuals {
				sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
			}
            UserDefaults.standard.set(showDebugVisuals, for: .debugMode)
        }
    }

    func setupDebug() {
		messagePanel.layer.cornerRadius = 3.0 // debug 창 layout
		messagePanel.clipsToBounds = true
    }

    // MARK: - UI Elements and Actions

	@IBOutlet weak var messagePanel: UIView!
	@IBOutlet weak var messageLabel: UILabel!
	@IBOutlet weak var debugMessageLabel: UILabel!

	var textManager: TextManager!

    func setupUIControls() { // message 창 초기화
		textManager = TextManager(viewController: self)
		debugMessageLabel.isHidden = true
		featurePointCountLabel.text = ""
		debugMessageLabel.text = ""
		messageLabel.text = ""
    }

	@IBOutlet weak var restartExperienceButton: UIButton! // 재시작 버튼
	var restartExperienceButtonIsEnabled = true

	@IBAction func restartExperience(_ sender: Any) { // 재시작
		guard restartExperienceButtonIsEnabled, !isLoadingObject else {
			return // 버튼이 활성화 되고, loadingObject가 없어야 return 되지 않는다.
		}

		DispatchQueue.main.async {
			self.restartExperienceButtonIsEnabled = false // 버튼 다시 false
            print("restart")
			self.textManager.cancelAllScheduledMessages()
			self.textManager.dismissPresentedAlert()
			self.textManager.showMessage("새로운 Session을 시작합니다.")
            
            self.initializeNode(view: self.sceneView)


			self.setupFocusSquare() // focusSquare 초기화 및 사용하기 위해 세팅
			self.restartPlaneDetection() // planeDetection 다시 수행
			self.restartExperienceButton.setImage(#imageLiteral(resourceName: "restart"), for: [])

			// Disable Restart button for five seconds in order to give the session enough time to restart.
			DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
				self.restartExperienceButtonIsEnabled = true
			})
		}
	}

	// MARK: - Settings

	@IBOutlet weak var settingsButton: UIButton! // 세팅 선택 칸 보여주는 버튼

	@IBAction func showSettings(_ button: UIButton) { // settingsbutton click -> action
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		guard let settingsViewController = storyboard.instantiateViewController(
			withIdentifier: "settingsViewController") as? SettingsViewController else {
			return
		}

		let barButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSettings))
		settingsViewController.navigationItem.rightBarButtonItem = barButtonItem
		settingsViewController.title = "Options"

		let navigationController = UINavigationController(rootViewController: settingsViewController)
        //popoverPresentationController -> 현재의 뷰 컨트롤러 관리하는 컨트롤러 -> 여기서는 navigationController 관리
		navigationController.modalPresentationStyle = .popover
		navigationController.popoverPresentationController?.delegate = self
		navigationController.preferredContentSize = CGSize(width: sceneView.bounds.size.width - 10,
		                                                   height: sceneView.bounds.size.height) // 크기
		self.present(navigationController, animated: true, completion: nil) // show

		navigationController.popoverPresentationController?.sourceView = settingsButton
		navigationController.popoverPresentationController?.sourceRect = settingsButton.bounds
	}

    @objc
    func dismissSettings() {
		self.dismiss(animated: true, completion: nil) // click done
        print("Done 버튼 클릭.")
		updateSettings() // update
	}

	private func updateSettings() {
		let defaults = UserDefaults.standard

		showDebugVisuals = defaults.bool(for: .debugMode)
		dragOnInfinitePlanesEnabled = defaults.bool(for: .dragOnInfinitePlanes)
		showHitTestAPIVisualization = defaults.bool(for: .showHitTestAPI)

		for (_, plane) in planes {
			plane.updateOcclusionSetting()
		} // 현재 선택된 사항들로 setting을 업데이트함 
	}

	// MARK: - Error handling

	func displayErrorMessage(title: String, message: String, allowRestart: Bool = false) {
		textManager.blurBackground() // error message 띄울 때, blur background

		if allowRestart { // allowRestart -> true
			let restartAction = UIAlertAction(title: "Reset", style: .default) { _ in
				self.textManager.unblurBackground() // blur effect
				self.restartExperience(self)
			}
			textManager.showAlert(title: title, message: message, actions: [restartAction])
		} else { // false
			textManager.showAlert(title: title, message: message, actions: [])
		}
	}
    
    
    // MARK: - Handling

    @IBOutlet weak var HandlingButton : UIButton!
    
    func HandlingPossible(_ touches: Set<UITouch>, with event: UIEvent?) -> Bool {
        
        guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected() else {
            print("HandlingPossible - object nil false")
            return false// object가 nil이어서 할당되지 않으면 return
        }
        
        let touch = touches[touches.index(touches.startIndex, offsetBy: 0)]
        let initialTouchLocation = touch.location(in: sceneView)

        // 초기 터치가 virtualobject를 터치했는지

        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        let results: [SCNHitTestResult] = sceneView.hitTest(initialTouchLocation, options: hitTestOptions)
        for result in results {
            if VirtualObject.isNodePartOfVirtualObject(result.node) {
                object.handle = true
                print(object.handle)
                break
            }
        }
        
        if (object.handle == true) {
            HandlingButton.isHidden = false
            settingsButton.isHidden = true
            addObjectButton.isHidden = true
            restartExperienceButton.isHidden = true
            print("HandlingPossible - true")
            
            return true
        }
        else {
            print("HandlingPossible - handle false")
            return false
        }
    }
    
    @IBAction func HandlingComplete(_ sender: UIButton) {
        guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected() else {
            print("HandlingComplete - object nil false")
            return // object가 nil이어서 할당되지 않으면 return
        }
        HandlingButton.isHidden = true
        settingsButton.isHidden = false
        addObjectButton.isHidden = false
        restartExperienceButton.isHidden = false
        print("HandlingComplete - object handle 다시 false")
        
        print(object.childNodes)
        object.childNodes[1].removeFromParentNode()
        
//        for obj in object.childNodes {
//            obj.removeFromParentNode()
//        }
        
        
        object.handle = false
        print(object.handle)
    }
    
    
    func createBox() -> SCNNode {
        let boxGeometry = SCNBox(width: 0.5, height: 0, length: 0.5, chamferRadius: 0)
        
        let material = SCNMaterial()
        material.isDoubleSided = false
        material.diffuse.contents = UIImage(named: "Models.scnassets/circle.png")
        
        let boxNode = SCNNode(geometry: boxGeometry)
        boxNode.geometry?.materials = [material]
        
        return boxNode
    }
    
}



// MARK: - ARKit / ARSCNView
extension MainViewController {
	func setupScene() {
		sceneView.setUp(viewController: self, session: session) // ScieneView + Extension class -> setup function
		DispatchQueue.main.async {
			self.screenCenter = self.sceneView.bounds.mid // center setting
		}
	}

	func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
		textManager.showTrackingQualityInfo(for: camera.trackingState, autoHide: !self.showDebugVisuals)
        // camera.trackingState -> 위치 추적 품질 (추적 품질이 제한될 경우 가능한 원인 포함)

		switch camera.trackingState {
		case .notAvailable:
			textManager.escalateFeedback(for: camera.trackingState, inSeconds: 5.0)
		case .limited:
				textManager.escalateFeedback(for: camera.trackingState, inSeconds: 10.0)
		case .normal:
			textManager.cancelScheduledMessage(forType: .trackingStateEscalation)
		}
	}

	func session(_ session: ARSession, didFailWithError error: Error) {
		guard let arError = error as? ARError else { return }

		let nsError = error as NSError
		var sessionErrorMsg = "\(nsError.localizedDescription) \(nsError.localizedFailureReason ?? "")"
		if let recoveryOptions = nsError.localizedRecoveryOptions {
			for option in recoveryOptions {
				sessionErrorMsg.append("\(option).")
			}
		}
        // case에 따른 error 다룬다.

		let isRecoverable = (arError.code == .worldTrackingFailed)
		if isRecoverable {
			sessionErrorMsg += "\nSession을 재시작 하거나 어플리케이션을 종료해주세요."
		} else {
			sessionErrorMsg += "\n회복할 수 없는 오류입니다. 어플리케이션을 종료해주세요."
		}

		displayErrorMessage(title: "We're sorry!", message: sessionErrorMsg, allowRestart: isRecoverable)
	}

	func sessionWasInterrupted(_ session: ARSession) { // 잠깐 어플리케이션을 나갔거나 하면 session이 중단된다.
		textManager.blurBackground()
		textManager.showAlert(title: "Session 중단",
		                      message: "중단이 회복된 이후, Session이 재 시작 됩니다.")
	}

	func sessionInterruptionEnded(_ session: ARSession) {
		textManager.unblurBackground()
		session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
		restartExperience(self)
		textManager.showMessage("Session 재시작")
	}
}

// MARK: Gesture Recognized
extension MainViewController {
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected() else {
			return // object가 nil이어서 할당되지 않으면 return
		}
        if HandlingPossible(touches, with: event) == true {
            if currentGesture == nil { // gesture 비어있을 시 새로 시작 할당해주자.
                if object.childNodes.count == 1 {
                    let box = self.createBox()
                    object.addChildNode(box)
                    print(object.childNodes)
                }
                else if object.childNodes.count == 2 {
                    currentGesture = Gesture.startGestureFromTouches(touches, self.sceneView, object)
                }
            } else {
                currentGesture = currentGesture!.updateGestureFromTouches(touches, .touchBegan) // 이미 존재할 경우, update 할당해주자.
            }

            displayVirtualObjectTransform() // Display
        }
	}
    
    //touch moved
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		if !VirtualObjectsManager.shared.isAVirtualObjectPlaced() {
			return
        }
        currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchMoved)

		displayVirtualObjectTransform()
	}

    //touch ended
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		if !VirtualObjectsManager.shared.isAVirtualObjectPlaced() {
			chooseObject(addObjectButton)
			return
		}

		currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchEnded)
	}

    // touch가 취소됨
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		if !VirtualObjectsManager.shared.isAVirtualObjectPlaced() {
			return
		}
		currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchCancelled)
	}
}

// MARK: - UIPopoverPresentationControllerDelegate
extension MainViewController: UIPopoverPresentationControllerDelegate {
	func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return .none
	}

	func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
		updateSettings()
	}
}

// MARK: - VirtualObjectSelectionViewControllerDelegate
extension MainViewController: VirtualObjectSelectionViewControllerDelegate {
	func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, object: VirtualObject) {
		loadVirtualObject(object: object)
	}
    
    
    // init
    func initializeNode(view : ARSCNView) {
        print("-----------------\(view.scene.rootNode.childNodes)")
        
        view.scene.rootNode.childNodes { (node, stop) in
            node.removeFromParentNode()
            return true
        }
    }
    

    // loading
	func loadVirtualObject(object: VirtualObject) { // Virtual Object loading
        // node init
        initializeNode(view: self.sceneView)
        
		// Show progress indicator
		let spinner = UIActivityIndicatorView()
		spinner.center = addObjectButton.center // addObejctButton 안 중간에 spinner bar가 생성된다.
		spinner.bounds.size = CGSize(width: addObjectButton.bounds.width - 5, height: addObjectButton.bounds.height - 5)
		addObjectButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])
		sceneView.addSubview(spinner)
		spinner.startAnimating()
        
        
		DispatchQueue.global().async {
			self.isLoadingObject = true
			object.viewController = self
			VirtualObjectsManager.shared.addVirtualObject(virtualObject: object)
			VirtualObjectsManager.shared.setVirtualObjectSelected(virtualObject: object)

            // light attribute
//            let light = SCNLight()
//            light.type = .directional
//            light.castsShadow = true
//            light.shadowRadius = 20
//            light.shadowSampleCount = 64
//
//            light.shadowColor = UIColor(white: 0, alpha: 0.5)
//            light.shadowMode = .forward
//            let constraint = SCNLookAtConstraint(target: object)
//
//            guard let lightEstimate = self.sceneView.session.currentFrame?.lightEstimate else {
//                return
//            }
//
//            // light node
//            let lightNode = SCNNode()
//            lightNode.light = light
//            lightNode.light?.intensity = lightEstimate.ambientIntensity
//            lightNode.light?.temperature = lightEstimate.ambientColorTemperature
////            lightNode.position = SCNVector3(object.position.x + 10, object.position.y + 30, object.position.z + 30)
//            lightNode.eulerAngles = SCNVector3(45.0,0,0)
//            lightNode.constraints = [constraint]
//            self.sceneView.scene.rootNode.addChildNode(lightNode)
            
            
            
//            let shadowPlane = SCNPlane(width: 10000, height: 10000)
//
//            let material = SCNMaterial()
//            material.isDoubleSided = false
//            material.lightingModel = .shadowOnly // Requires SCNLight shadowMode = .forward and no .omni or .spot lights in the scene or material rendered black
//
//            shadowPlane.materials = [material]
//
//            let shadowPlaneNode = SCNNode(geometry: shadowPlane)
//            shadowPlaneNode.name = object.modelName
//            shadowPlaneNode.eulerAngles.x = -.pi / 2
//            shadowPlaneNode.castsShadow = false
//
//            self.sceneView.scene.rootNode.addChildNode(shadowPlaneNode)
            
            print("Main - loadModel function")
			object.loadModel() // Virtual Object class
            
            
            


			DispatchQueue.main.async {
				if let lastFocusSquarePos = self.focusSquare?.lastPosition { // button을 누를때 저장된 마지막 사각형의 pos -> virtual object 배치
					self.setNewVirtualObjectPosition(lastFocusSquarePos)
				} else {
					self.setNewVirtualObjectPosition(SCNVector3Zero)
				}

				spinner.removeFromSuperview()
                // spinner remove
				// Update the icon of the add object button
				self.isLoadingObject = false
                self.setupFocusSquare()
                let buttonImage = UIImage.composeButtonImage(from: object.thumbImage)
                let pressedButtonImage = UIImage.composeButtonImage(from: object.thumbImage, alpha: 0.3)
                self.addObjectButton.setImage(buttonImage, for: [])
                self.addObjectButton.setImage(pressedButtonImage, for: [.highlighted])
			}
		}
	}
}

// MARK: - ARSCNViewDelegate
extension MainViewController: ARSCNViewDelegate {
	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		refreshFeaturePoints()

		DispatchQueue.main.async {
			self.updateFocusSquare()
			self.hitTestVisualization?.render()

			// If light estimation is enabled, update the intensity of the model's lights and the environment map
//			if let lightEstimate = self.session.currentFrame?.lightEstimate {
//				self.sceneView.enableEnvironmentMapWithIntensity(lightEstimate.ambientIntensity / 100)
////                print(lightEstimate.ambientIntensity / 100)// 조명 업데이트를 사용한 환경 맵 업데이트
//			} else {
//                self.sceneView.enableEnvironmentMapWithIntensity(1) // light Estimate false -> 고정된 조명 값으로 rendering
//			}
		}
	}

    // add
	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
		DispatchQueue.main.async {
			if let planeAnchor = anchor as? ARPlaneAnchor {
				self.addPlane(node: node, anchor: planeAnchor)
				self.checkIfObjectShouldMoveOntoPlane(anchor: planeAnchor) // 반드시 인식된 평면 위에서만 rendering 해야 하는지의 여부 check
			}
		}
	}

    // update
	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
		DispatchQueue.main.async {
			if let planeAnchor = anchor as? ARPlaneAnchor {
				if let plane = self.planes[planeAnchor] {
					plane.update(planeAnchor)
				}
				self.checkIfObjectShouldMoveOntoPlane(anchor: planeAnchor)
			}
		}
	}

    // remove
	func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
		DispatchQueue.main.async {
			if let planeAnchor = anchor as? ARPlaneAnchor, let plane = self.planes.removeValue(forKey: planeAnchor) {
				plane.removeFromParentNode() // 노드에서부터 삭제
			}
		}
	}
}

// MARK: Virtual Object Manipulation
extension MainViewController {
	func displayVirtualObjectTransform() {
		guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected(),
			let cameraTransform = session.currentFrame?.camera.transform else {
			return
		} // camera.transform -> 세계 위치에서의 카메라의 위치와 방향

        
		// Output the current translation, rotation & scale of the virtual object as text.
		let cameraPos = SCNVector3.positionFromTransform(cameraTransform) // cameraTransform에 따른 camera pos 반환
		let vectorToCamera = cameraPos - object.position // object의 위치와의 차 -> 카메라까지의 거리

		let distanceToUser = vectorToCamera.length() // 카메라와 유저 사이 거리

		var angleDegrees = Int(((object.eulerAngles.y) * 180) / Float.pi) % 360 // 오일러각 구해서 카메라의 각도 구한다.
		if angleDegrees < 0 {
			angleDegrees += 360
		}

		let distance = String(format: "%.2f", distanceToUser)
		let scale = String(format: "%.2f", object.scale.x) // distance, scale format
		textManager.showDebugMessage("Distance: \(distance) m\nRotation: \(angleDegrees)°\nScale: \(scale)x")
	}

	func moveVirtualObjectToPosition(_ pos: SCNVector3?, _ instantly: Bool, _ filterPosition: Bool) {

		guard let newPosition = pos else {
			textManager.showMessage("CANNOT PLACE OBJECT\nTry moving left or right.")
			if !VirtualObjectsManager.shared.isAVirtualObjectPlaced() {
				resetVirtualObject()
			}
			return
		}

		if instantly {
			setNewVirtualObjectPosition(newPosition) // -> instantly true
		} else {
			updateVirtualObjectPosition(newPosition, filterPosition) // -> new position
		}
	}

	func worldPositionFromScreenPosition(_ position: CGPoint,
	                                     objectPos: SCNVector3?,
	                                     infinitePlane: Bool = false) -> (position: SCNVector3?,
																		  planeAnchor: ARPlaneAnchor?,
																		  hitAPlane: Bool) {
        // 세계의 위치에 대한 현재 위치를 구한다!
        
		// -------------------------------------------------------------------------------
		// 1.
		let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
        // 해당 장면의 위치에 대한 hitTest를 먼저 수행한다. -> 범위 내에서 anchor가 존재하는 경우
		if let result = planeHitTestResults.first {

			let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform) // 결과에 대한 position(SCNVector3 형식)을 구한다.
			let planeAnchor = result.anchor // 해당 anchor 저장

			// Return immediately - this is the best possible outcome.
//            print("1위 최적의 position 반환")
			return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true) // 최적의 결과
		}

        
		// -------------------------------------------------------------------------------
		// 2.
        
        // 최적의 결과가 나오지 않았을 시, 특징점들을 대상으로 hitTest를 수행한다.
		var featureHitTestPosition: SCNVector3?
		var highQualityFeatureHitTestResult = false

		let highQualityfeatureHitTestResults =
			sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
        // feature points에 대한 hitTest를 수행하여 환경에 대한 정보를 수집한다.

		if !highQualityfeatureHitTestResults.isEmpty {
			let result = highQualityfeatureHitTestResults[0]
			featureHitTestPosition = result.position
			highQualityFeatureHitTestResult = true // feature points에 대한 hitTest 결과가 생성됨
		}

        
		// -------------------------------------------------------------------------------
		// 3.

        // 결과가 또 안나올 경우, 이번에는 무한한 평면에 대한 hitTest를 수행한다.
		if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {
            // infinitePlanesEnabled가 활성화 되 있고 무한한 평면이 존재하며, 위의 결과가 제대로 반환되지 않았을 경우
			let pointOnPlane = objectPos ?? SCNVector3Zero

			let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
			if pointOnInfinitePlane != nil {
//                print("2위 무한한 수평에 대한 position 반환")
				return (pointOnInfinitePlane, nil, true)
			}
		}
        // 추가로 수평의 infinitePlane에 대한 hitTest를 수행하고 해당 결과를 반환한다.

        
		// -------------------------------------------------------------------------------
		// 4.

		if highQualityFeatureHitTestResult {
//            print("3위 특징점 클라우드에 대한 position 반환")
			return (featureHitTestPosition, nil, false)
		} // 만약 featurepoints에 대한 hitTest 결과가 제대로 저장되었을 경우, 이를 반환하고 더 이상 hitTest를 수행하지 않는다.

        
		// -------------------------------------------------------------------------------
		// 5.

		let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position) // 해당 위치에 대한 필터링 되지 않은 Featurepoints들에 대한 hitTest를 수행한다.
		if !unfilteredFeatureHitTestResults.isEmpty {
			let result = unfilteredFeatureHitTestResults[0]
//            print("4위 그저 장면에 대한 position 반환 - 비정확한 최후의 결과 ")
			return (result.position, nil, false)
		}
        // 이는 scene에 feature이 없으면 결과가 0이 된다. 최후의 보루인 셈
		return (nil, nil, false)
	}

    
	func setNewVirtualObjectPosition(_ pos: SCNVector3) {

		guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected(),
			let cameraTransform = session.currentFrame?.camera.transform else {
			return
		}

		recentVirtualObjectDistances.removeAll() // 그 전의 virtualobject distance가 존재할 경우 초기화.

		let cameraWorldPos = SCNVector3.positionFromTransform(cameraTransform) // camera에 대한 position 반환
		var cameraToPosition = pos - cameraWorldPos
		cameraToPosition.setMaximumLength(DEFAULT_DISTANCE_CAMERA_TO_OBJECTS)
        // 입력받은 위치의 벡터 - 카메라의 위치 벡터 = cameraToPosition
		object.position = cameraWorldPos + cameraToPosition // object의 위치 설정

		if object.parent == nil {
			sceneView.scene.rootNode.addChildNode(object) // 배치될 부모 node가 설정되지 않은 경우, 바로 할당해준다.
		}
	}

	func resetVirtualObject() { // 맨 처음 + 버튼때 배치를 위해 object 재설정
		VirtualObjectsManager.shared.resetVirtualObjects()

		addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
		addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
	}

	func updateVirtualObjectPosition(_ pos: SCNVector3, _ filterPosition: Bool) {
		guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected() else {
			return
		}

		guard let cameraTransform = session.currentFrame?.camera.transform else {
			return
		}

		let cameraWorldPos = SCNVector3.positionFromTransform(cameraTransform)
		var cameraToPosition = pos - cameraWorldPos
		cameraToPosition.setMaximumLength(DEFAULT_DISTANCE_CAMERA_TO_OBJECTS)

		let hitTestResultDistance = CGFloat(cameraToPosition.length())

		recentVirtualObjectDistances.append(hitTestResultDistance)
		recentVirtualObjectDistances.keepLast(10) // 10번의 업데이트 동안 카메라와 object간의 평균 거리를 계산함.

		if filterPosition { // filterPosition이 true면, 이 평균 거리를 이용하여 object의 새 위치를 계산한다.
			let averageDistance = recentVirtualObjectDistances.average!

			cameraToPosition.setLength(Float(averageDistance))
			let averagedDistancePos = cameraWorldPos + cameraToPosition

			object.position = averagedDistancePos
		} else {
			object.position = cameraWorldPos + cameraToPosition
		}
	}

	func checkIfObjectShouldMoveOntoPlane(anchor: ARPlaneAnchor) {
		guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected(),
			let planeAnchorNode = sceneView.node(for: anchor) else { // 모델이 선택되어 있고, scene에 node가 존재해야 실행된다.
			return
		}
//        print("평면 위 object 움직임")
		// Get the object's position in the plane's coordinate system.
		let objectPos = planeAnchorNode.convertPosition(object.position, from: object.parent)

		if objectPos.y == 0 {
//            print("물체가 이미 평면 위에 있어요.")
			return; // The object is already on the plane
		}

		// Add 10% tolerance to the corners of the plane.
        
        // 평면 모서리에 10퍼센트의 오차를 추가합니다.
		let tolerance: Float = 0.1

		let minX: Float = anchor.center.x - anchor.extent.x / 2 - anchor.extent.x * tolerance
		let maxX: Float = anchor.center.x + anchor.extent.x / 2 + anchor.extent.x * tolerance
		let minZ: Float = anchor.center.z - anchor.extent.z / 2 - anchor.extent.z * tolerance
		let maxZ: Float = anchor.center.z + anchor.extent.z / 2 + anchor.extent.z * tolerance

		if objectPos.x < minX || objectPos.x > maxX || objectPos.z < minZ || objectPos.z > maxZ {
			return
		}

		// Drop the object onto the plane if it is near it.
		let verticalAllowance: Float = 0.03
		if objectPos.y > -verticalAllowance && objectPos.y < verticalAllowance {
			textManager.showDebugMessage("OBJECT MOVED\n근처에서 지표면이 감지됨.")

			SCNTransaction.begin()
			SCNTransaction.animationDuration = 0.5
			SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
			object.position.y = anchor.transform.columns.3.y
			SCNTransaction.commit()
		}
	}
}
