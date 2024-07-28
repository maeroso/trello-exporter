import Foundation
import OSLog
import OpenAPIRuntime

extension Client {
    static var downloadDirectory: URL?

    func downloadCardById(cardId: Components.Schemas.TrelloID) async throws -> URL {
        guard let downloadDirectory = Client.downloadDirectory else {
            throw TrelloAPIError.invalidContentURL
        }
        let directoryURL = URL(
            filePath: cardId,
            directoryHint: .isDirectory,
            relativeTo: downloadDirectory
        )
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let card = try await self.getCard(path: .init(id: cardId)).ok.body.json
        let attachments = try await self.getCardAttachments(path: .init(cardId: cardId)).ok.body.json
        let actions = try await self.getCardActions(path: .init(cardId: cardId)).ok.body.json
        let content = card.toMarkdownDocument(attachments: attachments, actions: actions).format()
        let cardURL = URL(filePath: "\(card.shortLink ?? "Unknown Card ID").md", relativeTo: directoryURL)
        try content.write(
            to: cardURL,
            atomically: true,
            encoding: .utf8
        )

        for attachment in attachments {
            let localURLtoSave = URL(
                filePath: "\(attachment.id ?? "Unknown Attachment ID")_\(attachment.name ?? "Unknown Attachment Name")",
                relativeTo: directoryURL)
            guard let urlString = attachment.url, let url = URL(string: urlString) else {
                throw TrelloAPIError.invalidContentURL
            }
            do {
                try await self.downloadAttachment(at: url, to: localURLtoSave)
            } catch TrelloAPIError.failedToDownloadContent(let httpStatusCode) {
                Logger.shared.warning("Failed to download attachment content: \(httpStatusCode)")
            }
        }
        return directoryURL
    }

    func downloadCardsFromBoard(boardId: Components.Schemas.TrelloID) async throws {
        let cards = try await self.getBoardCards(path: .init(boardId: boardId)).ok.body.json
        for card in cards {
            let cardDirectoryURL = try await self.downloadCardById(cardId: card.id!)
            Logger.shared.debug("Saved card files at \(cardDirectoryURL)")
        }
    }

    func downloadAttachment(at attachmentURL: URL, to savedURL: URL) async throws {
        guard let authCredentials = Client.authCredentials else {
            throw TrelloAPIError.noCredentialsAvailable
        }
        var urlRequest = URLRequest(url: attachmentURL)
        urlRequest.setValue(
            "OAuth oauth_consumer_key=\"\(authCredentials.apiKey)\", oauth_token=\"\(authCredentials.apiToken)\"",
            forHTTPHeaderField: "Authorization")

        let (localURL, response) = try await URLSession.shared.download(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TrelloAPIError.failedToDownloadContent(httpStatusCode: .init(code: 500))
        }
        guard httpResponse.statusCode < 400 else {
            throw TrelloAPIError.failedToDownloadContent(httpStatusCode: .init(code: httpResponse.statusCode))
        }
        if FileManager.default.fileExists(atPath: savedURL.path) {
            try FileManager.default.removeItem(at: savedURL)
        }
        try FileManager.default.moveItem(at: localURL, to: savedURL)
    }
}
