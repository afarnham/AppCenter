import AppCenter
import Foundation


if let client = ACRestClient.clientWithHomeDirectoryCredentials() {
    client.startInteractivePrompt()
}


