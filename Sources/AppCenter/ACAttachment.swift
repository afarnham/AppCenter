//
//  ACAttachment.swift
//  AppCenter
//
//  Created by Bill Gestrich on 11/22/19.
//  Copyright © 2019 Bill Gestrich. All rights reserved.
//

import Foundation

public struct ACAttachment : Codable {
    
    let appId: String
    let attachmentId: String
    let crashId: String
    let blobLocation: String
    let contentType: String
    let fileName: String?
    let createdTime: Date
    let size: Int

}
