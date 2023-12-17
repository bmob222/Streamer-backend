# Resolver

Resolver is a Swift package that handles all the core logic of the Streamer iOS and tvOS apps. It's responsible for parsing the website's HTML to output a raw URL that can be used to play the media content.

## Common terms:

- Provider: A website that contains movies or TV shows like 123moviesfree.so

- Media Content: Any content that contains playable material. It can be a movie or a TV show. 

- Source: 3rd party websites that host the video content like streamtape.com

- Stream: Contains information about playable content. It contains raw URL and headers used to play this content on any player.  

- Resolver: A piece of code that converts a source "URL from a provider" to a stream "URL used to play content on any player".

## Installation

- Clone the repo.  

- Open `Resolver/SampleApp/SampleApp.xcodeproj` in Xcode 15.

- Run the project.

- You should see a sample app running the playground that shows content from one provider. The provider is defined in `SampleApp.swift`.

## Writing your own provider  

- Open `Resolver/SampleApp/SampleApp.xcodeproj` in Xcode 15.

- Browse the `Resolver` package to `ResolverSources/Resolver/Providers`.   

- Open `Provider.swift` and add a new case to the `ProviderType` enum with the provider name e.g `case xyz`.

- Create a new file with the provider name in the providers folder e.g `XYZProvider.swift`.   

- Create a new struct that conforms to the `Provider` protocol e.g:  

```swift 
struct XYZProvider: Provider {

  var type: ProviderType = .xyz
  
  // Name of the website
  var title: String = "XYZProvider"  
  
  // Emoji for the website language
  var language: String = "🇺🇸" 
  
  // Description of the content on the website
  var subtitle: String = "English content"

  // The base URL for the website
  var baseURL: URL = URL(string:"https://xyz.com")!  
  
  // The base URL that contains all the movie listings
  var moviesURL: URL = URL(string:"https://xyz.com/movies")!

  // The base URL that contains all the TV show listings
  var tvShowsURL: URL = URL(string:"https://xyz.com/tvshows")!  
  
  func latestMovies(page: Int) async throws -> [MediaContent] {
    // Write code to request and parse a specific page for movie listing  
    return []
  }

  func latestTVShows(page: Int) async throws -> [MediaContent] {  
    // Write code to request and parse a specific page for a TV show listing
  }

  func fetchMovieDetails(for url: URL) async throws -> Movie {
    // Write code to request and parse specific movie details 
  }

  func fetchTVShowDetails(for url: URL) async throws -> TVshow { 
    // Write code to request and parse specific tv show details
  }  

  func search(keyword: String, page: Int) async throws -> [MediaContent] {  
    // Write code to request and parse a search query for this website
  }

}
```
- You can always check the older providers for guidance  

- You can write a test case in the resolver tests target to verify your implementation or you can use the playground to check the output  

## Writing your own resolver

- Open `Resolver/SampleApp/SampleApp.xcodeproj` in Xcode 15  

- Browse the `Resolver` package to `ResolverSources/Resolver/Resolvers/Hosts`  

- Create a new file with the resolver name in the resolvers folder e.g `XYZResolver.swift`  

- Create a new struct that conforms to the `Resolver` protocol e.g:

```swift
struct XYZResolver: Resolver {

  // List of domains supported by this resolver
  static var domains: [String] = [""]

  // Request and parse the URL to generate streams. Some resolvers can generate multiple streams for multiple qualities  
  func getMediaURL(url: URL) async throws -> [Stream] {

  } 
}
```

- Open `Resolver.swift` and add your resolver to `HostsResolver.resolvers` array   

- You can always check the older resolvers for guidance  

- You can write a test case in the resolver tests target to verify your implementation or you can use the playground to check the output
