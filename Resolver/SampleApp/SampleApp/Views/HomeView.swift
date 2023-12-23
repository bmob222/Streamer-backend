import Foundation
import SwiftUI
import Resolver

public struct HomeView: View {
    private let mediaContentSections: [MediaContentSection]
    private let provider: Provider

    private var gridItems: [GridItem] {
        [GridItem(.adaptive(minimum: 180), spacing: 5)]
    }
    public init(mediaContentSections: [MediaContentSection], provider: Provider) {
        self.mediaContentSections = mediaContentSections
        self.provider = provider
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItems) {

                ForEach(mediaContentSections, id: \.self) { section in
                    Section(header: Text(section.title).font(.title3)) {

                        ForEach(section.media, id: \.self) { media in
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
                    }.padding(.horizontal)

                }
            }.navigationDestination(for: MediaContent.self) { media in
                if media.type == .movie {
                    MoviesDetailsView(url: media.webURL, provider: provider)
                } else {
                    TVShowDetailsView(url: media.webURL, provider: provider)
                }
            }
        }
    }

}
