//
//  InteractivePrompt.swift
//  AppCenter
//
//  Created by Bill Gestrich on 11/22/19.
//  Copyright © 2019 Bill Gestrich. All rights reserved.
//

import Foundation
import swift_utilities

public class ACInteractivePrompt{
    
    public init() {
        
    }
    
    public func run (env: ACEnvironment?) {
        
        var orgName : String?
        var token : String?
        if let env = env {
            orgName = env.orgName
            token = env.token
        } else {
            promptForText(title:"Enter org name: ")
            promptForText(title:"Enter token: ")
        }


        let client = ACRestClient(ownerName: orgName!, token: token!)

        let apps = client.getApps().sorted { (app1, app2) -> Bool in
            let compareResult = app1.display_name.compare(app2.display_name)
            if compareResult == .orderedAscending {
                return true
            } else {
                return false
            }
        }


        let selectedAppIndex = promptForSelection(title: "Select App:", options: apps.map({ (model) -> String in
            return model.display_name
        }))
        
        let selectedApp = apps[selectedAppIndex]
        
        let appActionIndex = promptForSelection(title: "Select:", options:["Releases", "Error Groups"])

        if appActionIndex == 0 {
            let releases = client.getReleases(app: selectedApp)
            let releaseIndex = promptForSelection(title: "Select Release:", options: releases.map({ (release) -> String in
                return release.short_version + " " + release.version
            }))
            print("Selected \(releaseIndex)")
            self.promptForCrashOptions(client:client, app: selectedApp, release: releases[releaseIndex])
            
        } else {
            self.promptForCrashOptions(client:client, app: selectedApp, release: nil)
        }
    }
    
    func promptForCrashOptions(client: ACRestClient,app: ACApp, release: ACRelease?) {
        let crashGroups = client.getCrashGroups(app: app, release:release, nextLink: nil)
        let crashGroupIndex = promptForSelection(title: "Select Group:", options: crashGroups.map({ (group) -> String in
            return group.exceptionMessage ?? ""
        }))

        let crashGroup = crashGroups[crashGroupIndex]

        let crashes = client.getCrashes(app: app, errorGroup: crashGroup)
        let crashIndex = promptForSelection(title: "Select Error:", options: crashes.map({ (crash) -> String in
            return crash.timestamp.description
        }))

        let crash = crashes[crashIndex]

        let crashActionsIndex = promptForSelection(title: "Download Crash Info:", options:["Download Crash Report", "Attachments"])

        if crashActionsIndex == 0 {
            let text = client.getCrashText(app: app, crash: crash)!
            print(text)
        } else {
            let attachments = client.getAttachments(crash: crash)
            if let firstAttachment = attachments.first {
                if let attachmentText = client.getAttachmentText(app: app, crash: crash, attachment: firstAttachment) {
                    print(attachmentText)
                } else {
                    print("Failure getting attachment text")
                }
                
            } else {
                print("No attachments")
            }

        }
    }
    
    func promptForSelection(title: String, options: [String]) -> Int {
        print("\n\(title)")
        
        var promptString = ""
        var x = 0
        for option in options {
            promptString = promptString.appendingFormat("\n%u:  %@", x, option)
            x += 1
        }
        
        promptString = promptString.appendingFormat("\n\nEnter selection: ")
        print(promptString, separator:" ", terminator:"")
        let response = readLine()
        return Int(response!)!
    }
}
