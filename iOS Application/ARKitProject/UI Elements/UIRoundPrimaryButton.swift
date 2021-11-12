//
// MARK: - Button design
//  ARKitProject
//
//  Created by JungJiyoung on 2021/07/19.
//  Copyright © 2021 Apple. All rights reserved.
//


import Foundation
import UIKit

class UIRoundPrimaryButton: UIButton{
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.layer.cornerRadius = 10.0;
        self.backgroundColor = UIColor(red: 0.917, green: 0.715, blue: 0, alpha: 1)
        

//        let layer1 = CAGradientLayer()
//        layer1.colors = [
//          UIColor(red: 1, green: 1, blue: 1, alpha: 0.65).cgColor,
//          UIColor(red: 1, green: 0.262, blue: 0.262, alpha: 0.65).cgColor
//        ]
//
//        layer1.locations = [0, 0.99]
//        layer1.startPoint = CGPoint(x: 0.25, y: 0.5)
//        layer1.endPoint = CGPoint(x: 0.75, y: 0.5)
//        layer1.transform = CATransform3DMakeAffineTransform(CGAffineTransform(a: 1, b: 0, c: 0, d: 27.85, tx: 0, ty: -13.43))
//        layer1.bounds = self.bounds.insetBy(dx: -0.5*self.bounds.size.width, dy: -0.5*self.bounds.size.height)
//        layer1.position = self.center
//        self.layer.addSublayer(layer1)


    }
}
