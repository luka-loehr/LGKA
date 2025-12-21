# Lessing Gymnasium News Scraper

A Dart web scraper that extracts news events from the Lessing Gymnasium Karlsruhe website.

## Features

Extracts the following information from each news event:
- **Title** - The headline of the news article
- **Author** - Who wrote the article (from "Geschrieben von" field)
- **Description** - The article content/excerpt
- **Created Date** - When the article was published (from "Erstellt:" field)
- **Views** - Number of views (from "Zugriffe:" field)
- **URL** - Direct link to the full article

## How to Run

Since this is part of a Flutter project, the dependencies are already configured in `pubspec.yaml`.

### 1. Make sure dependencies are installed:
```bash
flutter pub get
```

### 2. Run the scraper:
```bash
dart run lessing_scraper.dart
```

## Output

The scraper will:
1. Fetch all news events from https://lessing-gymnasium-karlsruhe.de/cm3/index.php/neues
2. Display a formatted list of all events
3. Output the data in JSON format

## Code Structure

- `NewsEvent` class: Data model for news events
- `extractNewsEvents()`: Main scraping function that parses the HTML
- `printEvents()`: Pretty prints the extracted events

## HTML Structure

The scraper looks for:
- `.blog-item` divs containing individual news articles
- `h2 a` elements for titles and URLs
- `.createdby` elements for author information
- `.create` elements for creation dates
- `.hits` elements for view counts
- `.item-content p` elements for descriptions

## Dependencies

- `http` ^1.6.0 - For making HTTP requests
- `html` ^0.15.4 - For parsing HTML content

Both are already included in the project's `pubspec.yaml`.
