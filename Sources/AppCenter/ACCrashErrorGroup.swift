//
//  ACErrorGroup.swift
//  AppCenter
//
//  Created by Bill Gestrich on 11/21/19.
//  Copyright © 2019 Bill Gestrich. All rights reserved.
//

import Foundation

public struct ACCrashErrorGroup : Codable {
    
    let errorGroupId: String
    let appVersion: String
    let appBuild: String
    let count: Int
    let deviceCount: Int
    
    //Would like to convert to Date but this is throwing error decoding.
//    let formatter = DateFormatter.init()
//    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'" //2019-11-22T01:01:36Z
    let firstOccurrence: Date
    let lastOccurrence: Date
    let exceptionType: String
    let exceptionMessage: String?
    let exceptionClassMethod: Bool
    let exceptionAppCode: Bool
    let hidden: Bool = false
    let state: String

}

public struct ErrorGroupsResponse : Codable {
    var errorGroups: [ACCrashErrorGroup]
    var nextLink : String?
}
