import Foundation
import SwiftUI
import Resolver

public struct MainView: View {
    @State private var homeMediaContentSection: [MediaContentSection] = []
    @State private var tvMediaContent: [MediaContent] = []
    @State private var moviesMediaContent: [MediaContent] = []
    private let provider: Provider

    public init(provider: Provider) {
        self.provider = provider
    }

    public var body: some View {

        TabView {
            NavigationStack {
                HomeView(mediaContentSections: homeMediaContentSection, provider: provider)
                    .navigationTitle("Home")
            } .tabItem {
                Text("Home")
            }
            NavigationStack {
                ListingView(mediaContent: tvMediaContent, provider: provider)
                    .navigationTitle("TV shows")
            } .tabItem {
                Text("TV shows")
            }

            NavigationStack {
                ListingView(mediaContent: moviesMediaContent, provider: provider)
                    .navigationTitle("Movies")
            }.tabItem {
                Text("Movies")
            }
        }
        .task(refreshTask)

    }
    @Sendable
    private func refreshTask() {
        Task {
            self.homeMediaContentSection = try await provider.home()
            self.tvMediaContent = try await provider.latestTVShows(page: 1)
            self.moviesMediaContent = try await provider.latestMovies(page: 1)
        }
    }

}
