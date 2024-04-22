import SwiftUI
import Resolver

@main
struct SampleApp: App {
    var body: some Scene {
        WindowGroup {
            // Update the provider you want to test
            MainView(
                provider: Filma24Provider()
            )
        }
    }
}
