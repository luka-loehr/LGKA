/// Data class representing a search result in a PDF document.
class SearchResult {
  /// The page number where the match was found (1-based).
  final int pageNumber;

  /// The text context around the match.
  final String context;

  /// The original search query.
  final String query;

  /// The index of the match within the context string.
  final int matchIndex;

  const SearchResult({
    required this.pageNumber,
    required this.context,
    required this.query,
    required this.matchIndex,
  });

  @override
  String toString() =>
      'SearchResult(page: $pageNumber, query: "$query", matchIndex: $matchIndex)';
}
