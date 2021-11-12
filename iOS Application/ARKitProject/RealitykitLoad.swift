//
//  RealitykitLoad.swift
//  ARKitProject
//
//  Created by JungJiyoung on 2021/08/09.
//  Copyright © 2021 Apple. All rights reserved.
//

import ARKit
import UIKit
import RealityKit


class RealitykitLoad : UIViewController {
    @IBOutlet var arview: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overlayCoachingView()
        setupARView()
        
    }
    
    // MARK: - file loading code

    @IBOutlet weak var usdzButton: UIButton!

    @IBAction func usdzFileLoad(_ button: UIButton) {
        
        print("-------------------------------spinner activate-------------------------------")
        let spinner = UIActivityIndicatorView()
        spinner.center = usdzButton.center
        spinner.bounds.size = CGSize(width: usdzButton.bounds.width - 5, height: usdzButton.bounds.height - 5)
        usdzButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])
        arview.addSubview(spinner)
        spinner.startAnimating()
        
        
        
        print("-------------------------------download function-------------------------------")
        let url = URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/stratocaster/fender_stratocaster.usdz")
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationUrl = documentsUrl.appendingPathComponent(url!.lastPathComponent)
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        
        
        let downloadTask = session.downloadTask(with: request, completionHandler: {
            (location:URL?, response:URLResponse?, error:Error?) -> Void in
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: destinationUrl.path) {
                try! fileManager.removeItem(atPath: destinationUrl.path)
            }
            try! fileManager.moveItem(atPath: location!.path, toPath: destinationUrl.path)
            DispatchQueue.main.async { [self] in
                do {
                    let object = try Entity.load(contentsOf: destinationUrl) // It is work
                    object.name = "TEAPOT"
                    object.generateCollisionShapes(recursive: true)
                    

                    let anchor = AnchorEntity(plane: .horizontal, minimumBounds:[0.2,0.2])
                    anchor.addChild(object)
                    arview.scene.addAnchor(anchor)
                    
                    
//                    arview.installGestures([.all], for: object as! Entity & HasCollision)
//                    arview.debugOptions = .showPhysics
                    
                    print("-------------------------------spinner deactivate-------------------------------")
                    spinner.removeFromSuperview()
                    self.usdzButton.setImage(#imageLiteral(resourceName: "add"), for: [])
                    self.usdzButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
                }
                catch {
                    print("Fail load entity: \(error.localizedDescription)")
                }
            }
        })
        
        
        print("-------------------------------downloadTask resume-------------------------------")
        downloadTask.resume()
        
    }
    
    
    // MARK: - OverlayCoaching View

    func overlayCoachingView() {
        let coachingView = ARCoachingOverlayView(frame: CGRect(x:0,y:0, width: arview.frame.width, height: arview.frame.height))
        
        coachingView.session = arview.session
        coachingView.activatesAutomatically = true
        coachingView.goal = .horizontalPlane
        
        view.addSubview(coachingView)
    }
    
    
    // MARK: - Debug message viewer

    func setupARView() {
        arview.automaticallyConfigureSession = false
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        arview.session.run(configuration)
    }
}
