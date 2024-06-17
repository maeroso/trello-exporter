# TrelloExporter
TrelloExporter is a tool that exports Trello cards to Markdown files.

## Getting Started
To get started with TrelloExporter, you need to have Swift 5.10 installed on your machine.

1. Clone the repository:
```sh
git clone https://github.com/yourusername/TrelloExporter.git
cd TrelloExporter
```
2. Build/Run the project:
```sh
swift run TrelloExporter
```

## Usage
You can use TrelloExporter to export a Trello card to a Markdown file. Here's an example of how to do this:
```sh
swift run TrelloExporter export-card cardshortlink --api-key yourapikey --api-token yourapitoken --export-directory ./exported/
```
Replace cardshortlink, yourapikey, and yourapitoken with your Trello card ID, API key, and API token respectively.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
This project is licensed under the MIT License - see the LICENSE.md file for details