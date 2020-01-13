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
    
    public func run (client: ACRestClient) {

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
            var releases = client.getReleases(app: selectedApp)
            releases.sort { (release1, release2) -> Bool in
                guard let release1AsNum =  Int(release1.version) else {
                    return true
                }
                guard let release2AsNum =  Int(release2.version) else {
                    return true
                }
                
                return release1AsNum < release2AsNum
            }
            let releaseIndex = promptForSelection(title: "Select Release:", options: releases.map({ (release) -> String in
                return release.short_version + " " + release.version
            }))
            self.promptForReleaseOptions(client:client, app: selectedApp, release: releases[releaseIndex])
            
        } else {
            let crashGroups = client.getCrashGroups(app: selectedApp, release:nil, nextLink: nil)
            self.promptForGroupSelection(client:client, app: selectedApp, release: nil, crashGroups: crashGroups)
        }
    }
    
    func promptForReleaseOptions(client: ACRestClient,app: ACApp, release: ACRelease?) {
        let releaseActionIndex = promptForSelection(title: "Select:", options:["Search", "Error Groups"])

        if releaseActionIndex == 0 {
            let crashGroups = client.searchErrorGroups(app: app, methodName: "mainThreadLocked:seconds:", release: release)
            self.promptForGroupSelection(client:client, app: app, release: release, crashGroups: crashGroups)
        } else {
            let crashGroups = client.getCrashGroups(app: app, release:release, nextLink: nil)
            self.promptForGroupSelection(client:client, app: app, release: release, crashGroups: crashGroups)
        }
    }
    
    func promptForGroupSelection(client: ACRestClient,app: ACApp, release: ACRelease?, crashGroups: [ACCrashErrorGroup]) {
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
}
