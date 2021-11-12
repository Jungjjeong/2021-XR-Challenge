//
//  ProgressViewController.swift
//  ARKitProject
//
//  Created by JungJiyoung on 2021/08/09.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class ProgressViewController: UIViewController {
    
    @IBOutlet weak var cancleBtn : UIButton!
    @IBOutlet var popUpView: UIView!
    @IBOutlet weak var progress : UIProgressView!
    
    var isRunning = false
    var progressBarTimer: Timer!
    
    @IBAction func cancle(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progress.progress = 0.0
        
        popUpView.layer.cornerRadius = 15
        popUpView.layer.masksToBounds = true
        // Do any additional setup after loading the view.
        
        if(isRunning) {
            progressBarTimer.invalidate()
        }
        else {
            progress.progress = 0.0
            progressBarTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ProgressViewController.updateProgressView),userInfo: nil, repeats: true)
        }
        isRunning = !isRunning
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {

        progress.progress = 1.0
        progress.setProgress(1.0, animated: true)
        progressBarTimer.invalidate()
        isRunning = false
        
        super.viewWillDisappear(true)
    }
    
//    func setProgress100() {
//        DispatchQueue.main.async { [self] in
//            progress.progress = 100
//            progress.setProgress(progress.progress, animated: true)
//
//            self.dismiss(animated: true, completion: nil)
//        }
//
//    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @objc func updateProgressView() {
        progress.progress += Float(CGFloat(progressBarTimer.timeInterval/20))
        progress.setProgress(progress.progress, animated: true)
        print(progress.progress)
        if(progress.progress == 1.0)
        {
            progressBarTimer.invalidate()
            isRunning = false
        }
    }
}

