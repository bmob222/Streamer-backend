import SwiftUI
import Resolver

@main
struct SampleApp: App {
    var body: some Scene {
        WindowGroup {
            // Update the provider you want to test
            MainView(provider: ProviderType.init(config: .init(id: "flixHQ", locale: "en_en", title: "FlixHQ", emoji: "", iconURL: .init(string: "http://google.com")!, type: .local)).provider)
        }
    }
}
