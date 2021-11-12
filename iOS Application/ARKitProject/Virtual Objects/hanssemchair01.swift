//
//  hanssemchair01.swift
//  ARKitProject
//
//  Created by JungJiyoung on 2021/08/06.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation


class hanssemchair01: VirtualObject{

    override init() {
        super.init(modelName: "hanssemchair01", fileExtension: "usdz", thumbImageFilename: "vase", title: "hanssemchair01", handle : false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
