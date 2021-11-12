//
//  SizeMeasurementView.swift
//  ARKitProject
//
//  Created by JungJiyoung on 2021/08/03.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation
import ARKit
import UIKit

// MARK: - Size Measurement

class SizeMeasurementView : UIViewController, ARSessionDelegate, ARSCNViewDelegate {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var addBtn : UIButton!
    var screenCenter: CGPoint?
    var boxNode: SCNNode?
    let session = ARSession() // ar scene의 고유 런타임 인스턴스 관리


    
    var doteNodes = [SCNNode]()
    var textNode = SCNNode()
    var lineNode = SCNNode()
    var progressDot = SCNNode()
    
//    let midPosition : SCNVector3
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.session.delegate = self
        sceneView.autoenablesDefaultLighting = true
        print("SizeMeasurementView")
//        setupFocusSquare()
//        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        
        let scene = SCNScene()

        let boxNode = createBox()
        scene.rootNode.addChildNode(boxNode)
        self.boxNode = boxNode

        //------------------------------------
        // Set the view's delegate
        sceneView.delegate = self
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    // MARK: - CreateBox
    
    
    func createBox() -> SCNNode {
        let boxGeometry = SCNBox(width: 0.2, height: 0, length: 0.2, chamferRadius: 0)
        
        let material = SCNMaterial()
        material.isDoubleSided = false
//        material.locksAmbientWithDiffuse = false
        material.fresnelExponent = 0.0
        material.diffuse.contents = UIImage(named: "Models.scnassets/focus.png")
//        material.specular.contents = UIColor(white: 0.8, alpha: 1.0) // 빛반사
        
        let boxNode = SCNNode(geometry: boxGeometry)
        boxNode.geometry?.materials = [material]
        
        return boxNode
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.addCoaching()
//        let configuration = ARWorldTrackingConfiguration()
//        configuration.planeDetection = [.horizontal, .vertical]
//        sceneView.session.run(configuration)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        sceneView.session.run(configuration)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true 
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
        session.pause() // session 멈춘다.
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
    }
    

    
    
    // MARK: - addButton Click
    
    @IBAction func addAnchor(_ button : UIButton) {
        
        if doteNodes.count == 3 {
            for dot in doteNodes{
                dot.removeFromParentNode()
            }
            textNode.removeFromParentNode()
            lineNode.removeFromParentNode()
            textNode = SCNNode()
            lineNode = SCNNode()
            doteNodes = [SCNNode]()
        }
        // 클릭하면 화면 중앙의 앵커가 저장 -> addDot로 연결
        ExistPlanes()
    }
    
    func ExistPlanes() {
        let results = sceneView.raycastQuery(from: view.center, allowing: ARRaycastQuery.Target.estimatedPlane, alignment: .any)
        
        if let hitRes = results {
            let rayCast = sceneView.session.raycast(hitRes)
            
            guard let ray = rayCast.first else { return }
            addDot(at: ray)
        }
    }
    

    
    
    // MARK: - Add dot

    func addDot(at hitResult: ARRaycastResult) {
        let sphereScene = SCNSphere(radius: 0.006)
        
        let material = SCNMaterial()
        
//        material.locksAmbientWithDiffuse = false
        material.diffuse.contents = UIColor.white
        sphereScene.materials = [material]
        
        let node = SCNNode()
        
        node.position = SCNVector3(
            hitResult.worldTransform.columns.3.x,
            hitResult.worldTransform.columns.3.y + sphereScene.boundingSphere.radius,
            hitResult.worldTransform.columns.3.z
        )
        
        node.geometry = sphereScene
        
        sceneView.scene.rootNode.addChildNode(node)
        
        doteNodes.append(node)

        print(doteNodes.count)
        if doteNodes.count == 1 {
            let buttonImage = UIImage(named: "go")
            self.addBtn.setImage(buttonImage, for: [])
            let node2 = SCNNode(geometry: sphereScene)
            sceneView.scene.rootNode.addChildNode(node2)
            doteNodes.append(node2)
        }
        else if doteNodes.count == 3{
            calculate()
            doteNodes[1].removeFromParentNode()
            sceneView.scene.rootNode.addChildNode(lineBetweenNodes(positionA: doteNodes[0].position, positionB: doteNodes[2].position, inScene: self.sceneView.scene))
            let buttonImage = UIImage(named: "add")
            self.addBtn.setImage(buttonImage, for: [])
        }
    }
    
    
    // MARK: - Draw lines
    
    func lineBetweenNodes(positionA: SCNVector3, positionB: SCNVector3, inScene: SCNScene) -> SCNNode {
        let vector = SCNVector3(positionA.x - positionB.x, positionA.y - positionB.y, positionA.z - positionB.z)
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        let midPosition = SCNVector3 (x:(positionA.x + positionB.x) / 2, y:(positionA.y + positionB.y) / 2, z:(positionA.z + positionB.z) / 2)

        let lineGeometry = SCNCylinder()
        lineGeometry.radius = 0.0025
        lineGeometry.height = CGFloat(distance)
        lineGeometry.radialSegmentCount = 5
        lineGeometry.firstMaterial!.diffuse.contents = UIColor.white

        lineNode = SCNNode(geometry: lineGeometry)
        lineNode.position = midPosition
        lineNode.look (at: positionB, up: inScene.rootNode.worldUp, localFront: lineNode.worldUp)
        return lineNode
    }
    
    
    
    // MARK: - Calculate distance

    func calculate() {
        let start = doteNodes[0]
        let end = doteNodes[2]
        
        print(start.position)
        print(end.position)
        
        let distance = sqrt(pow(start.position.x-end.position.x, 2) +
                                pow(start.position.y-end.position.y, 2) +
                                pow(start.position.z-end.position.z, 2))
        
        let midPosition = SCNVector3 (x:(start.position.x + end.position.x) / 2, y:(start.position.y + end.position.y) / 2, z:(start.position.z + end.position.z) / 2)

        sceneView.scene.rootNode.addChildNode(updateText(text: "\(round(abs(distance)*1000)/10) cm", atPosition: midPosition))
    }
    
    
    
    
    // MARK: - update TextNode

    func updateText(text: String, atPosition position: SCNVector3) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.black
        
        
        textNode = SCNNode(geometry: textGeometry)
        
        textNode.scale = SCNVector3(0.002, 0.002, 0.002)
        
        
        let minVec = textNode.boundingBox.min
        let maxVec = textNode.boundingBox.max
        let bound = SCNVector3Make(maxVec.x - minVec.x,
                                   maxVec.y - minVec.y,
                                   maxVec.z - minVec.z);

        let plane = SCNPlane(width: CGFloat(bound.x + 4.5),
                             height: CGFloat(bound.y + 4.5))
        plane.cornerRadius = 4
        plane.firstMaterial?.diffuse.contents = UIColor.white

        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(CGFloat( minVec.x) + CGFloat(bound.x) / 2 ,
                                        CGFloat( minVec.y) + CGFloat(bound.y) / 2 ,
                                        CGFloat( minVec.z - 0.01))

//        textNode.look (at: position, up: sceneView.scene.rootNode.worldUp, localFront: lineNode.worldUp)

        textNode.position = SCNVector3(position.x, position.y , position.z)
        textNode.addChildNode(planeNode)
        
        return textNode

//        textNode.addChildNode(planeNode)
//
//
//        sceneView.scene.rootNode.addChildNode(textNode)
    }
    
    
    
    // MARK: - initialize Button

    @IBOutlet weak var trashBtn : UIButton!
    
    @IBAction func initialize (_ button: UIButton) {
        for dot in doteNodes{
            dot.removeFromParentNode()
        }
        textNode.removeFromParentNode()
        lineNode.removeFromParentNode()
        textNode = SCNNode()
        lineNode = SCNNode()
        doteNodes = [SCNNode]()
    }
    
    
    
    
    // MARK: - Renderer
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform // 변화
        
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33) // 방향
        let location = SCNVector3(transform.m41, transform.m42, transform.m43) // 위치
        
        let currentPositionOfCamera = SizeMeasurementView.plus(left: orientation , right: location)
        
//        SCNTransaction.begin()
        if let boxNode = self.boxNode{
            boxNode.position = currentPositionOfCamera
        }
        
        if self.doteNodes.count == 2{
            doteNodes[1].position = currentPositionOfCamera
        }

        self.updateScaleFromCameraForNodes(doteNodes, fromPointOfView: pointOfView, useScaling: true)
        self.updateScaleFromCameraForLine(lineNode, fromPointOfView: pointOfView, useScaling: true)
        self.updateScaleFromCameraForText(textNode, fromPointOfView: pointOfView, useScaling: true)
//        textNode.simdScale = SIMD3(repeating: 0.0005)
        textNode.eulerAngles.x = (sceneView.pointOfView?.eulerAngles.x)!
        textNode.eulerAngles.y = (sceneView.pointOfView?.eulerAngles.y)!
//        textNode.eulerAngles.z = (sceneView.pointOfView?.eulerAngles.z)!


        
    }
    
    
    static func plus (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
    }
    
    
    
    // MARK: - Update Scale

    func updateScaleFromCameraForNodes(_ nodes: [SCNNode], fromPointOfView pointOfView: SCNNode, useScaling: Bool) {
        nodes.forEach { (node) in
            //1. Get The Current Position Of The Node
            let positionOfNode = SCNVector3ToGLKVector3(node.worldPosition)
            //2. Get The Current Position Of The Camera
            let positionOfCamera = SCNVector3ToGLKVector3(pointOfView.worldPosition)
            //3. Calculate The Distance From The Node To The Camera
            let distanceBetweenNodeAndCamera = GLKVector3Distance(positionOfNode, positionOfCamera)

            let a = distanceBetweenNodeAndCamera * 2
            if(useScaling) {
                node.simdScale = simd_float3(a,a,a)
            }
        }
        SCNTransaction.flush()
    }
    
    
    
    func updateScaleFromCameraForLine(_ node: SCNNode, fromPointOfView pointOfView: SCNNode, useScaling: Bool) {
        //1. Get The Current Position Of The Node
        let positionOfNode = SCNVector3ToGLKVector3(node.worldPosition)
        //2. Get The Current Position Of The Camera
        let positionOfCamera = SCNVector3ToGLKVector3(pointOfView.worldPosition)
        //3. Calculate The Distance From The Node To The Camera
        let distanceBetweenNodeAndCamera = GLKVector3Distance(positionOfNode, positionOfCamera)

        let a = distanceBetweenNodeAndCamera * 2
        if(useScaling) {
            node.simdScale = simd_float3(a,1,a)
        }
        SCNTransaction.flush()
    }
    
    
    func updateScaleFromCameraForText(_ node: SCNNode, fromPointOfView pointOfView: SCNNode, useScaling: Bool) {
        //1. Get The Current Position Of The Node
        let positionOfNode = SCNVector3ToGLKVector3(node.worldPosition)
        //2. Get The Current Position Of The Camera
        let positionOfCamera = SCNVector3ToGLKVector3(pointOfView.worldPosition)
        //3. Calculate The Distance From The Node To The Camera
        let distanceBetweenNodeAndCamera = GLKVector3Distance(positionOfNode, positionOfCamera)
        
        
        let a = distanceBetweenNodeAndCamera * 1.5
        if(useScaling) {
//            node.simdScale = simd_float3(a,1,a)
            print(node)
            node.scale = SCNVector3(a * 0.003, a * 0.003, a * 0.003)
//            for i in node.childNodes {
//                i.scale = SCNVector3(a, a, a)
//            }
        }
        SCNTransaction.flush()
    }
}


    // MARK: - Coaching overlay view


extension SizeMeasurementView : ARCoachingOverlayViewDelegate {
    func addCoaching() {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.delegate = self
        coachingOverlay.session = sceneView.session
        coachingOverlay.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(coachingOverlay)
        
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.goal = .horizontalPlane
    }
    
    
}
