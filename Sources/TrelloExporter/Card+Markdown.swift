import Foundation
import Markdown
import OpenAPIRuntime

extension Components.Schemas.Card {
    private func MarkdownInfoTable() -> Markdown.Table {
        let now = Date.now.ISO8601Format()
        let labels =
            self.labels?.sorted(by: { a, b in
                guard let aName = a.name, let bName = b.name else {
                    return false
                }
                return aName.lexicographicallyPrecedes(bName)
            }).flatMap {
                [$0.toMarkdownText(), SoftBreak()]
            } ?? [Text("Unlabeled")]
        return Table(
            columnAlignments: [.left],
            header: .init([
                Table.Cell(Text("Card ID")), Table.Cell(Text("Labels")), Table.Cell(Text("Exported At")),
            ]),
            body: .init([
                Table.Row([
                    Table.Cell(Text(self.shortLink ?? "Unknown")),
                    Table.Cell(labels),
                    Table.Cell(Text(now)),
                ])
            ])
        )
    }

    func toMarkdownDocument(
        attachments: [Components.Schemas.Attachment],
        actions: [Components.Schemas.Action]
    ) -> Markdown.Document {
        guard let desc = self.desc else {
            return Markdown.Document(
                Heading(level: 1, Text(self.name ?? "Empty Card Name")),
                self.MarkdownInfoTable(),
                Paragraph(Text("No description provided"))
            )
        }

        let description = Markdown.Document(parsing: desc)
        var imageLinkRewriter = ImageLinkRewriter(
            urlMapping: attachments.reduce(into: [:]) { result, attachment in
                guard
                    let source = attachment.url,
                    let id = attachment.id,
                    let name = attachment.name
                else {
                    return
                }
                result[source] = "\(id)_\(name)"
            }
        )

        guard let newDescriptionDocument = imageLinkRewriter.visit(description) as? Markdown.Document else {
            return Markdown.Document(
                Heading(level: 1, Text(self.name ?? "Empty Card Name")),
                self.MarkdownInfoTable(),
                description
            )
        }

        let filteredActions = actions.sorted {
            guard let aDate = $0.date, let bDate = $1.date else {
                return false
            }
            return aDate > bDate
        }.filter { action in
            guard let _ = action.data?.text else {
                return false
            }
            return action._type == "commentCard"
        }

        let blockQuotes = filteredActions.map { action -> BlockQuote in
            let textContent = action.data?.text ?? "No comment provided"
            return BlockQuote(
                Paragraph(
                    Text(textContent)
                )
            )
        }

        let markdownInfoTable = self.MarkdownInfoTable()
        var contents: [any BlockMarkup] = [
            Heading(level: 1, Text(self.name ?? "Empty Card Name")),
            markdownInfoTable,
            newDescriptionDocument,
            ThematicBreak(),
            Heading(level: 2, Text("Comments")),
        ]
        contents.append(contentsOf: blockQuotes)
        return Document(contents)
    }
}

struct ImageLinkRewriter: MarkupRewriter {
    let urlMapping: [String: String]
    func visitImage(_ image: Image) -> (any Markup)? {
        guard let source = image.source, source.starts(with: "https://trello.com") else {
            return image
        }
        guard let newURL = self.urlMapping[source] else {
            return image
        }
        return Image(source: newURL, title: image.title)
    }
}

extension Components.Schemas.Label {
    func toMarkdownText() -> Markdown.InlineMarkup {
        Text(self.name ?? "Label ID: \(self.id ?? "Unknown")")
    }
}
