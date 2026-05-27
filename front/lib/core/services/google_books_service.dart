import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/book.dart';

class GoogleBooksService {
  static const _googleBaseUrl = 'https://www.googleapis.com/books/v1';
  static const _openLibraryUrl = 'https://openlibrary.org';
  static const _apiKey = String.fromEnvironment('GOOGLE_BOOKS_API_KEY', defaultValue: '');

  Future<List<GoogleBookResult>> search(String query, {int maxResults = 15}) async {
    if (query.trim().isEmpty) return [];

    // Use Google Books only if an API key is configured
    if (_apiKey.isNotEmpty) {
      try {
        final results = await _searchGoogleBooks(query, maxResults);
        if (results.isNotEmpty) return results;
      } catch (_) {}
    }

    // Open Library: free, no key, great French coverage
    return _searchOpenLibrary(query, maxResults);
  }

  Future<List<GoogleBookResult>> _searchGoogleBooks(String query, int maxResults) async {
    final uri = Uri.parse('$_googleBaseUrl/volumes').replace(queryParameters: {
      'q': query,
      'maxResults': maxResults.toString(),
      'printType': 'books',
      'key': _apiKey,
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final data = json.decode(res.body) as Map<String, dynamic>;
    if (data.containsKey('error')) return [];
    final items = data['items'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>().map(GoogleBookResult.fromGoogleBooksApi).toList();
  }

  Future<List<GoogleBookResult>> _searchOpenLibrary(String query, int maxResults) async {
    final uri = Uri.parse('$_openLibraryUrl/search.json').replace(queryParameters: {
      'q': query,
      'limit': maxResults.toString(),
      'fields': 'key,title,author_name,first_publish_year,number_of_pages_median,cover_i,subject,isbn',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final data = json.decode(res.body) as Map<String, dynamic>;
    final docs = data['docs'] as List<dynamic>? ?? [];
    return docs.cast<Map<String, dynamic>>().map(GoogleBookResult.fromOpenLibrary).toList();
  }

  Future<GoogleBookResult?> getById(String googleId) async {
    if (_apiKey.isNotEmpty) {
      final uri = Uri.parse('$_googleBaseUrl/volumes/$googleId')
          .replace(queryParameters: {'key': _apiKey});
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        if (!data.containsKey('error')) return GoogleBookResult.fromGoogleBooksApi(data);
      }
    }
    return null;
  }

  Future<List<GoogleBookResult>> searchByIsbn(String isbn) => search('isbn:$isbn');

  Future<List<GoogleBookResult>> getSuggestions({int limit = 20}) async {
    // Mix of popular French subjects for variety
    const subjects = ['roman_francais', 'litterature_francaise', 'bestsellers'];
    final subject = subjects[DateTime.now().second % subjects.length];
    try {
      final uri = Uri.parse('$_openLibraryUrl/subjects/$subject.json')
          .replace(queryParameters: {'limit': limit.toString()});
      final res = await http.get(uri);
      if (res.statusCode != 200) return _fallbackSuggestions();
      final data = json.decode(res.body) as Map<String, dynamic>;
      final works = data['works'] as List<dynamic>? ?? [];
      return works.cast<Map<String, dynamic>>().map((w) {
        final authors = w['authors'] as List<dynamic>? ?? [];
        final coverId = w['cover_id'] as int?;
        final String? coverUrl = coverId != null
            ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
            : null;
        return GoogleBookResult(
          googleId: 'OL:${w['key'] ?? ''}',
          title: w['title'] as String? ?? 'Titre inconnu',
          author: authors.isNotEmpty
              ? (authors.first as Map<String, dynamic>)['name'] as String? ?? 'Auteur inconnu'
              : 'Auteur inconnu',
          year: (w['first_publish_year'] as int?),
          coverUrl: coverUrl,
        );
      }).where((b) => b.title != 'Titre inconnu').toList();
    } catch (_) {
      return _fallbackSuggestions();
    }
  }

  Future<List<GoogleBookResult>> _fallbackSuggestions() =>
      _searchOpenLibrary('roman francais contemporain', 15);
}

final googleBooksService = GoogleBooksService();
