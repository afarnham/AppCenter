//
//  ACApp.swift
//  AppCenter
//
//  Created by Bill Gestrich on 11/20/19.
//  Copyright © 2019 Bill Gestrich. All rights reserved.
//

import Foundation

public struct ACApp : Codable {
    var id: String
    var app_secret: String
    var description: String?
    public var display_name: String
    var os: String
    var platform: String
    var origin: String
    var icon_url: String?
    var created_at: String
    var updated_at: Date
    var release_type: String?
    
    func name() -> String {
        var name = self.display_name
        name = name.replacingOccurrences(of: " ", with: "-")
        return name
    }

}

public struct AppsResponse : Codable {
    var apps: [ACApp]
}
