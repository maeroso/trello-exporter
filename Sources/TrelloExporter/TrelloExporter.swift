import ArgumentParser
import OSLog
import OpenAPIRuntime

extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(filePath: argument)
    }
}

extension Logger {
    static let shared = Logger()
}

struct Options: ParsableArguments {
    @Option(help: "API Key")
    var apiKey: String

    @Option(help: "API Token")
    var apiToken: String

    @Option(help: "Export directory")
    var exportDirectory: URL
}

@main struct TrelloExporter: AsyncParsableCommand {
    static var configuration: CommandConfiguration = .init(
        commandName: "TrelloExporter", subcommands: [ExportBoardCommand.self, ExportCardCommand.self]
    )
}

struct ExportBoardCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration = .init(commandName: "export-board")

    @Option(help: "ID of the board")
    var boardId: String

    @OptionGroup var options: Options

    func run() async throws {
        Client.authCredentials = (apiKey: options.apiKey, apiToken: options.apiToken)
        Client.downloadDirectory = options.exportDirectory

        let client = try Client()
        Logger.shared.debug("Trello Client created successfully")
        try await client.downloadCardsFromBoard(boardId: boardId)
    }
}

struct ExportCardCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration = .init(commandName: "export-card")

    @Argument(help: "ID of the card")
    var cardId: String

    @OptionGroup var options: Options

    func run() async throws {
        Client.authCredentials = (apiKey: options.apiKey, apiToken: options.apiToken)
        Client.downloadDirectory = options.exportDirectory
        
        let client = try Client()
        Logger.shared.debug("Trello Client created successfully")
        let cardDirectoryURL = try await client.downloadCardById(cardId: cardId)
        Logger.shared.debug("Saved card files at \(cardDirectoryURL)")
    }
}
