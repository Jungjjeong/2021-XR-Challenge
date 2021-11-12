//
//  AirForce.swift
//  ARKitProject
//
//  Created by JungJiyoung on 2021/07/30.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation
import SceneKit


class AirForce: VirtualObject{

    override init() {
        super.init(modelName: "AirForce", fileExtension: "usdz", thumbImageFilename: "vase", title: "AirForce", handle: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
