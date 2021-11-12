//
//  FirstViewController.swift
//  ARKitProject
//
//  Created by 저스트비버 on 2021/10/12.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

class FirstViewController: UIViewController {
    
    @IBOutlet weak var firstView : UIView!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var subView : UIView!
    @IBOutlet weak var arButton: UIButton!
    @IBOutlet weak var threedButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subView.layer.cornerRadius = 20
        subView.layer.shadowOffset = CGSize(width: 0, height: 8)
        subView.layer.shadowOpacity = 0.5
        subView.layer.shadowRadius = 5
        
        arButton.setGradient(color1: UIColor(red: 0.917, green: 0.715, blue: 0, alpha: 1), color2: UIColor(red: 0.9098, green: 0.5451, blue: 0, alpha: 1.0))
        threedButton.setGradient(color1: UIColor(red: 0.917, green: 0.715, blue: 0, alpha: 1), color2: UIColor(red: 0.9098, green: 0.5451, blue: 0, alpha: 1.0))
        arButton.roundedButton()
        threedButton.roundedButton()
        
        arButton.setTitle("AR Viewer", for: .normal)
        threedButton.setTitle("3D Viewer", for: .normal)
        
        arButton.setTitleColor(UIColor.white, for: .normal)
        threedButton.setTitleColor(UIColor.white, for: .normal)
        
        arButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.bold)
        threedButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.bold)
        
        self.view.addSubview(self.subView)
        self.view.addSubview(self.image)
        self.view.addSubview(self.arButton)
        self.view.addSubview(self.threedButton)
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)

        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    @IBAction func onClick_3D(_ sender: Any) {
            guard let threedurl = URL(string: "http://210.94.185.38:8080/3D/test.html") else { return }
            let safariVC = SFSafariViewController(url: threedurl)
            present(safariVC, animated: true, completion: nil)
        }
    
}

extension UIButton{
    func roundedButton(){
        clipsToBounds = true //뷰의 테두리 기준으로 짤리게 된다.
        layer.cornerRadius = 20 //얼만큼 둥글게
//        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
        
    func setGradient(color1:UIColor,color2:UIColor){
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [color1.cgColor,color2.cgColor]
        gradient.locations = [0.0 , 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradient.frame = bounds
        layer.addSublayer(gradient)
    }
    
}

