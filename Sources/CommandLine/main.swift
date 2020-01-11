import AppCenter
import Foundation

func env() -> ACEnvironment? {
    let envPath = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent(".appCenterSwift.json")

    let decoder = JSONDecoder()
    do {
        let data = try Data(contentsOf: envPath)
        let env = try decoder.decode(ACEnvironment.self, from: data)
        return env
    } catch {
        return nil
    }
}

let envir = env()
ACInteractivePrompt().run(env:envir)

