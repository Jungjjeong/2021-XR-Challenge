//
//  fender_stratocaster.swift
//  ARKitProject
//
//  Created by JungJiyoung on 2021/07/30.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation
class fender_stratocaster: VirtualObject{

    override init() {
        super.init(modelName: "fender_stratocaster", fileExtension: "usdz", thumbImageFilename: "vase", title: "fender_stratocaster", handle : false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
