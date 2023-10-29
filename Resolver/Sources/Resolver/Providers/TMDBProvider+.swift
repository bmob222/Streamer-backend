import Foundation
import struct TMDb.Movie
import struct TMDb.TVSeries

extension TMDBProvider {
    public func convert(_ movie: TMDb.Movie) -> MediaContent? {
        let url = URL(staticString: "https://api.themoviedb.org/3/movie/").appendingPathComponent(movie.id)
        guard let posterURL = imagesConfiguration?.posterURL(for: movie.posterPath) else {
            return nil
        }
        return MediaContent(title: movie.title,
                            webURL: url,
                            posterURL: posterURL,
                            type: .movie,
                            provider: self.type)
        
    }
    
    public func convert(_ tvseries: TVSeries) -> MediaContent? {
        let url = URL(staticString: "https://api.themoviedb.org/3/tv/").appendingPathComponent(tvseries.id)
        guard let posterURL = imagesConfiguration?.posterURL(for: tvseries.posterPath) else {
            return nil
        }
        return MediaContent(title: tvseries.name,
                            webURL: url,
                            posterURL: posterURL,
                            type: .tvShow,
                            provider: self.type)
    }
}
