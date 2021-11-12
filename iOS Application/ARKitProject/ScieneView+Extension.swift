// MARK: - View setting


import ARKit
import Foundation


extension ARSCNView {
	func setUp(viewController: MainViewController, session: ARSession) {
		delegate = viewController
		self.session = session
		antialiasingMode = .multisampling4X // view의 장면을 rendering하는데 필요한 antialiasingMode
        autoenablesDefaultLighting = true
		automaticallyUpdatesLighting = true
		preferredFramesPerSecond = 60 // view가 장면을 rendering하는데 사용하는 애니메이션 frame rate(second)
		contentScaleFactor = 1.3 // content의 축적 비율
    }
}
