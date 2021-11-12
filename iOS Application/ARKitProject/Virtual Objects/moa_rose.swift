//
//  moa_rose.swift
//  ARKitProject
//
//  Created by JungJiyoung on 2021/08/06.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation


class moa_rose: VirtualObject{

    override init() {
        super.init(modelName: "moa_rose", fileExtension: "usdz", thumbImageFilename: "vase", title: "moa_rose", handle : false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
