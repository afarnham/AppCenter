//
//  ACRestClient.swift
//  AppCenter
//
//  Created by Bill Gestrich on 11/19/19.
//  Copyright © 2019 Bill Gestrich. All rights reserved.
//

import Foundation
import swift_utilities

public class ACRestClient: RestClient {
    
    let ownerName : String
    static let appListBaseURLPart = "apps"
    
    public init(ownerName: String, token: String){
        self.ownerName = ownerName
        super.init(baseURL: "https://api.appcenter.ms/v0.1/")
        self.headers = ["X-API-Token":token]
    }
    
    public func synchronousData(relativeURL: String, completionBlock:@escaping ((Data) -> Void), errorBlock:(@escaping (RestClientError) -> Void)){
            
        let semaphore = DispatchSemaphore(value: 0)

        self.getData(relativeURL: relativeURL, completionBlock: { (data) in
            completionBlock(data)
            semaphore.signal()
        }) { (error) in
            errorBlock(error)
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
    }
    
    func appBaseURL() -> String {
        return ACRestClient.appBaseURL(ownerName: self.ownerName)
    }
    
    static func appBaseURL(ownerName: String) -> String {
        return "\(ACRestClient.appListBaseURLPart)/\(ownerName)"
    }
    
    func appURL(app : ACApp) -> String {
        return appBaseURL().appending("/\(app.name())")
    }
    
    func errorGroupURL(app: ACApp) -> String {
        return appURL(app: app).appending("/errors/errorGroups")
    }
    
    func crashesURL(app: ACApp, errorGroupId: String) -> String {
        return errorGroupURL(app: app).appending("/\(errorGroupId)/errors")
    }
    
    func appsWebURL() -> String {
        return "https://appcenter.ms/orgs/\(ownerName)/apps"
    }
    
    public func getApps() -> [ACApp] {
        
        var apps = [ACApp]()
        synchronousData(relativeURL: ACRestClient.appListBaseURLPart, completionBlock: { (json) in
            let decoder = self.jsonDecoder()
            
            do {
                
                apps = try decoder.decode([ACApp].self, from: json)
            } catch (let deserializationErorr){
                //errorBlock(.deserialization(error))
                print("deserialization error \(deserializationErorr)")
            }
        }) { (error) in
            print(error)
        }

        return apps
        
    }
    
    public func appForAppTitle(appTitle : String) -> ACApp?{
        let apps = self.getApps()
        for app in apps{
            if app.display_name == appTitle{
                return app
            }
        }
        print("Could not find app " + appTitle)
        return nil
    }
    
    public func getReleases(app: ACApp) -> [ACRelease] {
        
        var releases = [ACRelease]()
        
        let url : String? = appURL(app: app).appending("/releases")
        
        synchronousData(relativeURL: url!, completionBlock: { (json) in
            let decoder = self.jsonDecoder()
            
            do {
                releases = try decoder.decode([ACRelease].self, from: json)
            } catch (let deserializationErorr){
                //errorBlock(.deserialization(error))
                print("deserialization error \(deserializationErorr)")
            }
        }) { (error) in
            print(error)
        }
        
        return releases
        
    }
    
    //TODO: This will probably not work as expected if you pass both a release and a nextLink.
    public func getCrashGroups(app: ACApp, release:(ACRelease?), nextLink: String?) -> [ACCrashErrorGroup] {
        
        var errorGroups = [ACCrashErrorGroup]()
        var url = self.errorGroupURL(app: app)
        if let nextLink = nextLink {
            let token = nextLink.getPartAfter(toSearch: "?")
            url = url.appending("?\(token)")
        }
        
        if let release = release {
            if url.contains("?") {
                url = url.appending("&")
            } else {
                url = url.appending("?")
            }
            
            url = url.appending("version=\(release.short_version)&app_build=\(release.version)")
        }
        
        synchronousData(relativeURL: url, completionBlock: { (json) in
            let decoder = self.jsonDecoder()

            do {
                
                let errorGroupResponse = try decoder.decode(ErrorGroupsResponse.self, from: json)
                errorGroups += errorGroupResponse.errorGroups
                if let nextLinkFromResponse = errorGroupResponse.nextLink {
                    //TODO: Recursion is a bad idea here due to stack overflow with lots of results. Use iteration instead.
                    errorGroups += self.getCrashGroups(app: app, release:release, nextLink: nextLinkFromResponse)
                }
            } catch (let deserializationErorr){
                //errorBlock(.deserialization(error))
                print("deserialization error \(deserializationErorr)")
            }
        }) { (error) in
            print(error)
        }

        return errorGroups
        
    }
    
    //AppCenter doens't seem to offer a search that can both accept an oData arg and specify a release.
    //Adding the release or build to the oData arg causes the API call to fail.
    //It may be possible to use the a query string "?q=" instead of oData (not in addition, that fails too).
    //So for now this just searches for all methods and filters out the results for a particular release.
    public func searchErrorGroups(app : ACApp, methodName : String, release: ACRelease?) -> [ACCrashErrorGroup] {
        let oData = "exceptionMethod eq '" + methodName + "'";
        var groups = self.searchErrorGroups(app: app, oData: oData, nextLink: nil)
        if let release = release {
            groups = groups.filter { (group) -> Bool in
                return group.appVersion == release.short_version && group.appBuild == release.version
            }
        }
        
        return groups
    }
    
    //TODO: This method is almost identical to another in here.
    public func searchErrorGroups(app : ACApp, oData : String,  nextLink: String?) -> [ACCrashErrorGroup] {
        var errorGroups = [ACCrashErrorGroup]()
        
        let safeOData = oData.addingPercentEncodingForURLQueryValue()
        var url = self.appURL(app: app) + "/errors/errorGroups/search?filter=" + safeOData + "&top=10000"

        if let nextLink = nextLink {
            let token = nextLink.getPartAfter(toSearch: "?")
            url = url.appending("?\(token)")
        }

        synchronousData(relativeURL: url, completionBlock: { (json) in
            let decoder = self.jsonDecoder()
            
            do {
                
                let errorGroupResponse = try decoder.decode(ErrorGroupsResponse.self, from: json)
                errorGroups += errorGroupResponse.errorGroups
                if let nextLinkFromResponse = errorGroupResponse.nextLink {
                    errorGroups += self.getCrashGroups(app: app, release:nil, nextLink: nextLinkFromResponse)
                }
            } catch (let deserializationErorr){
                //errorBlock(.deserialization(error))
                print("deserialization error \(deserializationErorr)")
            }
        }) { (error) in
            print(error)
        }

        return errorGroups
        
        
    }
    
    public func getCrashes(app: ACApp, errorGroup: ACCrashErrorGroup) -> [ACCrashError] {
        
        var crashes = [ACCrashError]()
        var url : String? = crashesURL(app: app, errorGroupId: errorGroup.errorGroupId)
        
        while url != nil {
            
            var nextLink: String?
            synchronousData(relativeURL: url!, completionBlock: { (json) in
                let decoder = self.jsonDecoder()
                
                do {
                    
                    let crashesResponse = try decoder.decode(CrashResponse.self, from: json)
                    crashes += crashesResponse.errors
                    print(crashesResponse)
                    if let nextLinkFromResponse = crashesResponse.nextLink {
                        nextLink = nextLinkFromResponse
                    }
                } catch (let deserializationErorr){
                    //errorBlock(.deserialization(error))
                    print("deserialization error \(deserializationErorr)")
                }
            }) { (error) in
                print(error)
            }
            
            if let nextLink = nextLink {
                url = crashesURL(app: app, errorGroupId: errorGroup.errorGroupId)
                let token = nextLink.getPartAfter(toSearch: "?")
                url = url!.appending("?\(token)")
            } else {
                url = nil
            }
        }
        
        var crashWithURLs = [ACCrashError]()
        for crash in crashes {
            var crashCopy = crash
            crashCopy.crashGroupID = errorGroup.errorGroupId
            //https://appcenter.ms/orgs/<org>/apps/<app name>/crashes/errors/1532991759u/reports/2518293128619999999-79c5964a-0cb3-4dac-9cf2-21f048e3bcb5/raw
            crashCopy.crashURL = self.appsWebURL().appending("/\(app.name())/crashes/errors/\(errorGroup.errorGroupId)/reports/\(crash.errorId)/raw")
            crashCopy.appName = app.display_name
            crashCopy.appBuild = errorGroup.appBuild
            crashCopy.appVersion = errorGroup.appVersion
            crashCopy.app = app
            crashWithURLs.append(crashCopy)
        }

        return crashWithURLs

    }
    
    public func getCrashText(app : ACApp, crash : ACCrashError) -> String? {

        let url = self.crashesURL(app: app, errorGroupId: crash.crashGroupID) + "/" + crash.errorId +  "/download?format=text"
        var text : String?
        synchronousData(relativeURL: url, completionBlock: { (data) in
            text = String.init(data: data, encoding: .utf8)
        }) { (error) in
            print(error)
        }

        return text
    }
    
    //curl -H "X-API-Token: <token>" "https://api.appcenter.ms/v0.1/apps/<org>/<app name>/errors/2518282636709999999-ac65d33e-277f-4954-8e3b-741cd6c42e4a/attachments"
    public func getAttachments(crash: ACCrashError) -> [ACAttachment] {
        var attachments = [ACAttachment]()
        let url = self.appURL(app: crash.app!).appending("/errors/\(crash.errorId)/attachments")

        synchronousData(relativeURL: url, completionBlock: { (json) in
            let decoder = self.jsonDecoder()

            do {
                attachments = try decoder.decode([ACAttachment].self, from: json)
            } catch (let deserializationErorr){
                //errorBlock(.deserialization(error))
                print("deserialization error \(deserializationErorr)")
            }
        }) { (error) in
            print(error)
        }

        return attachments

    }
    

    
    public func getAttachmentText(app : ACApp, crash : ACCrashError, attachment : ACAttachment) -> String? {
        
        let url = self.appURL(app: app).appending("/errors/\(crash.errorId)/attachments/\(attachment.attachmentId)/text")
        var text : String?
        synchronousData(relativeURL: url, completionBlock: { (data) in
            let decoder = self.jsonDecoder()
            do {
                let dict = try decoder.decode(Dictionary<String,String>.self, from: data)
                if let optText = dict["content"] {
                    text = optText
                }
            } catch (let deserializationErorr){
                //errorBlock(.deserialization(error))
                print("deserialization error \(deserializationErorr)")
            }

        }) { (error) in
            print(error)
        }
        
        return text
    }
    
    func jsonDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        enum DateError: String, Error {
            case invalidDate
        }
        
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            throw DateError.invalidDate
        })
        return decoder
    }
    
//    curl -H "X-API-Token: <token>" "https://api.appcenter.ms/v0.1/apps/<org>/<app name>/errors/2518282636709999999-ac65d33e-277f-4954-8e3b-741cd6c42e4a/attachments/b27fcaac-95a2-4adb-ab51-9dfff1c03948/text"

}
