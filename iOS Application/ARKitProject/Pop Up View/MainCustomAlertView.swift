//
//  MainCustomAlertView.swift
//  ARKitProject
//
//  Created by JungJiyoung on 2021/08/09.
//  Copyright © 2021 Apple. All rights reserved.
//


// MARK: - POPUP controller

import UIKit

final class MainCustomAlertView: UIViewController {
    
    @IBOutlet var popUpView : UIView!
    @IBOutlet weak var dismissButton : UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        popUpView.layer.cornerRadius = 15
        popUpView.layer.masksToBounds = true
    }
    
    @IBAction func didTapDismissButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
