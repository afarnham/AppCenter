//
//  Crash.swift
//  AppCenter
//
//  Created by Bill Gestrich on 11/21/19.
//  Copyright © 2019 Bill Gestrich. All rights reserved.
//

import Foundation

public struct ACCrashError : Codable {
    
    public let errorId: String
    public let timestamp: Date
    public let deviceName: String
    public let osVersion: String
    public let osType: String
    public let country: String
    public let language: String
    public let userId: String?
    
    enum CodingKeys: String, CodingKey {
            case errorId
            case timestamp
            case deviceName
            case osVersion
            case osType
            case country
            case language
            case userId
    }
    
    public var crashGroupID : String = ""
    public var crashURL : String = ""
    public var appBuild : String = ""
    public var appName : String = ""
    public var appVersion : String = ""
    public var app : ACApp?
}

public struct CrashResponse : Codable {
    var errors: [ACCrashError]
    var nextLink : String?
}
