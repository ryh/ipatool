//
//  Search.swift
//  IPATool
//
//  Created by Majd Alfhaily on 22.05.21.
//

import ArgumentParser
import Foundation
import Networking
import StoreAPI
import SwiftyTextTable

struct Search: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        return .init(abstract: "Search for iOS apps available on the App Store.")
    }

    @Argument(help: "The term to search for.")
    private var term: String

    @Option(name: [.short, .long], help: "The maximum amount of search results to retrieve.")
    private var limit: Int = 5

    @Option(
        name: [.customShort("c"), .customLong("country")],
        help: "The two-letter (ISO 3166-1 alpha-2) country code for the iTunes Store."
    )
    private var countryCode: String = "US"

    @Option(name: [.short, .long], help: "The device family to limit the search query to.")
    private var deviceFamily: DeviceFamily = .phone

    @Option(name: [.long], help: "The log level.")
    private var logLevel: LogLevel = .info
    
    lazy var logger = ConsoleLogger(level: logLevel)
}

extension Search {
    mutating func results(with term: String) async -> [iTunesResponse.Result] {
        logger.log("Creating HTTP client...", level: .debug)
        let httpClient = HTTPClient(session: URLSession.shared)

        logger.log("Creating iTunes client...", level: .debug)
        let itunesClient = iTunesClient(httpClient: httpClient)

        logger.log("Searching for '\(term)' using the '\(countryCode)' store front...", level: .info)

        do {
            let results = try await itunesClient.search(
                term: term,
                limit: limit,
                countryCode: countryCode,
                deviceFamily: deviceFamily
            )

            guard !results.isEmpty else {
                logger.log("No results found.", level: .error)
                _exit(1)
            }

            return results
        } catch {
            logger.log("\(error)", level: .debug)
            logger.log("An unknown error has occurred.", level: .error)
            _exit(1)
        }
    }
    
    mutating func run() async throws {
        // Search the iTunes store
        let results = await results(with: term)
        var table = printTable(style: .none)
        // Compile output
        let _ = results
            .enumerated()
            .map({
                table.addRow(values:[$1.identifier, $1.name, $1.bundleIdentifier, $1.version, $1.url.components(separatedBy: "?")[0]])
                return "\($1.identifier). \($1.name): \($1.bundleIdentifier) (\($1.version))."
                })
            .joined(separator: "\n")
        //TODO: user define style?
        print(table.render())

    }
}
public func printTable(style:TextTableStyle = .none) -> TextTable {
    let c1 = TextTableColumn(header: "id", color:.green)
    let c2 = TextTableColumn(header: "name", color:.blue)
    let c3 = TextTableColumn(header: "bundleIdentifier", color:.green)
    let c4 = TextTableColumn(header: "version", color:.blue)
    let c5 = TextTableColumn(header: "url", color:.blue)
    let table = TextTable(columns: [c1, c2, c3, c4, c5],style: style)
    return table
  }