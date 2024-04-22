import Foundation
import SwiftUI
import Resolver

public struct SearchView: View {
    @State private var mediaContent: [MediaContent] = []
    private let provider: Provider
    @State private var searchText = ""

    private var gridItems: [GridItem] {
        [GridItem(.adaptive(minimum: 180), spacing: 5)]
    }
    public init(provider: Provider) {
        self.provider = provider
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItems) {
                ForEach(mediaContent, id: \.self) { media in
                    VStack {
                        NavigationLink(value: media) {
                            AsyncImage(
                                url: media.posterURL,
                                content: { image in
                                    image.resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 90)
                                },
                                placeholder: {
                                    ProgressView()
                                }
                            )            }
                        Text(media.title)
                    }
                }
            }.navigationDestination(for: MediaContent.self) { media in
                if media.type == .movie {
                    MoviesDetailsView(url: media.webURL, provider: provider)
                } else {
                    TVShowDetailsView(url: media.webURL, provider: provider)
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer)
            .onChange(of: searchText) { _ in
                executeSearch()
            }
        }
    }

    private func executeSearch() {
        // Perform your search request here using the searchText value
        // and update the searchResults array with the fetched results
        Task { @MainActor in
            self.mediaContent = try await provider.search(keyword: searchText, page: 1)
        }
    }
}
