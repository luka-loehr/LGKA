# LGKA - Digital Substitution Plan Lessing-Gymnasium Karlsruhe

A Flutter mobile application for accessing digital substitution plans of Lessing-Gymnasium Karlsruhe. This app provides students and teachers with an easy way to view schedule changes and announcements.

## Features

- User authentication (with fixed credentials)
- View digital substitution plan for today and tomorrow
- PDF download from the official school website
- Extraction of metadata from PDFs (weekday, update date)
- Caching of downloaded plans for offline access
- Dark design theme
- Haptic feedback for interactions
- Welcome screen for first-time users

## Technical Details

- Developed with Flutter
- Uses Riverpod for state management
- Go Router for navigation
- PDF processing with `syncfusion_flutter_pdf`
- HTTPS requests with `http`
- File opening with `open_filex`
- Package information retrieval with `package_info_plus`
- Path management with `path_provider`

## Getting Started

### Prerequisites

- Flutter SDK (version ^3.8.0)
- Dart SDK (latest stable)
- Android Studio or VS Code with Flutter extensions

### Installation

1. Clone the repository:
    ```
    git clone https://github.com/YourUsername/LGKA.git
    ```
    *Note: Replace YourUsername with your GitHub username.*

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run the app:
    ```
    flutter run
    ```

## Privacy

The protection of your data is important to me. The app does not collect, store, or process any personal data. For more information, please see my [privacy policy](https://luka-loehr.github.io/LGKA/privacy.html).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
