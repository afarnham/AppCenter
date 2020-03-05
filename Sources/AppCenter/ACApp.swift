//
//  ACApp.swift
//  AppCenter
//
//  Created by Bill Gestrich on 11/20/19.
//  Copyright © 2019 Bill Gestrich. All rights reserved.
//

import Foundation

public struct ACApp : Codable {
    public var id: String
    public var app_secret: String
    var description: String?
    public var display_name: String
    public var name: String
    public var os: String
    public var platform: String
    public var origin: String
    public var icon_url: String?
    public var created_at: String
    public var updated_at: Date
    public var release_type: String?
    
    public func name() -> String {
        var name = self.display_name
        name = name.replacingOccurrences(of: " ", with: "-")
        return name
    }

}

public struct AppsResponse : Codable {
    var apps: [ACApp]
}
