//
//  ACRelease.swift
//  Crash
//
//  Created by Bill Gestrich on 12/17/19.
//  Copyright © 2019 Bill Gestrich. All rights reserved.
//

public struct ACRelease : Codable {
    
    var id: Int
    var origin : String
    var short_version : String
    var version : String
    var uploaded_at : String
    var enabled: Bool
    var is_external_build : Bool
//      "build": {
//        "branchName": "release/2019-12",
//        "commitHash": "617d06025fdd83d9f71389a18a0092d4cd61ee7e"
//      }

}
