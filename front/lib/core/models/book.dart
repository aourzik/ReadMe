// book.dart — modèle Book sans code generation (freezed remplacé par classes manuelles)

enum ReadStatus { reading, read, wishlist }

class Book {
  final String id;
  final String title;
  final String author;
  final int year;
  final int pages;
  final double rating;
  final List<String> tags;
  final String description;
  final String? coverUrl;
  final String? googleBooksId;
  final ReadStatus status;
  final String? lentTo;
  final String? lentToUserId;
  final DateTime? lentSince;
  final DateTime? lentUntil;
  final DateTime? addedAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? userId;
  final bool isFavorite;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.year,
    this.pages = 0,
    this.rating = 0.0,
    this.tags = const [],
    this.description = '',
    this.coverUrl,
    this.googleBooksId,
    this.status = ReadStatus.wishlist,
    this.isFavorite = false,
    this.lentTo,
    this.lentToUserId,
    this.lentSince,
    this.lentUntil,
    this.addedAt,
    this.startedAt,
    this.finishedAt,
    this.userId,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      year: (json['year'] as num).toInt(),
      pages: (json['pages'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      description: json['description'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
      googleBooksId: json['googleBooksId'] as String?,
      status: _parseStatus(json['status'] as String?),
      isFavorite: json['isFavorite'] as bool? ?? false,
      lentTo: json['lentTo'] as String?,
      lentToUserId: json['lentToUserId'] as String?,
      lentSince: json['lentSince'] != null ? DateTime.parse(json['lentSince'] as String) : null,
      lentUntil: json['lentUntil'] != null ? DateTime.parse(json['lentUntil'] as String) : null,
      addedAt: json['addedAt'] != null ? DateTime.parse(json['addedAt'] as String) : null,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
      finishedAt: json['finishedAt'] != null ? DateTime.parse(json['finishedAt'] as String) : null,
      userId: json['userId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'year': year,
      'pages': pages,
      'rating': rating,
      'tags': tags,
      'description': description,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (googleBooksId != null) 'googleBooksId': googleBooksId,
      'status': status.name,
      if (lentTo != null) 'lentTo': lentTo,
      if (addedAt != null) 'addedAt': addedAt!.toIso8601String(),
    };
  }

  Book copyWith({
    String? id, String? title, String? author, int? year, int? pages,
    double? rating, List<String>? tags, String? description, String? coverUrl,
    String? googleBooksId, ReadStatus? status, String? lentTo,
    DateTime? addedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      year: year ?? this.year,
      pages: pages ?? this.pages,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      googleBooksId: googleBooksId ?? this.googleBooksId,
      status: status ?? this.status,
      lentTo: lentTo ?? this.lentTo,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  static ReadStatus _parseStatus(String? s) {
    switch (s) {
      case 'reading': return ReadStatus.reading;
      case 'read':    return ReadStatus.read;
      default:        return ReadStatus.wishlist;
    }
  }
}

// ── Google Books result ──────────────────────────────────────────────────────

class GoogleBookResult {
  final String googleId;
  final String title;
  final String author;
  final int? year;
  final int? pages;
  final String? description;
  final String? coverUrl;
  final List<String> categories;
  final String? isbn;

  const GoogleBookResult({
    required this.googleId,
    required this.title,
    required this.author,
    this.year,
    this.pages,
    this.description,
    this.coverUrl,
    this.categories = const [],
    this.isbn,
  });

  factory GoogleBookResult.fromOpenLibrary(Map<String, dynamic> doc) {
    final authors = doc['author_name'] as List<dynamic>? ?? [];
    final subjects = doc['subject'] as List<dynamic>? ?? [];
    final isbns = doc['isbn'] as List<dynamic>? ?? [];
    final coverId = doc['cover_i'];
    final String? coverUrl = coverId != null
        ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
        : null;
    final isbn13 = isbns.cast<String>().where((s) => s.length == 13).firstOrNull;

    return GoogleBookResult(
      googleId: (doc['key'] as String? ?? '').replaceFirst('/works/', 'OL:'),
      title: doc['title'] as String? ?? 'Titre inconnu',
      author: authors.isNotEmpty ? authors.first as String : 'Auteur inconnu',
      year: doc['first_publish_year'] as int?,
      pages: doc['number_of_pages_median'] as int?,
      description: null,
      coverUrl: coverUrl,
      categories: subjects.take(3).cast<String>().toList(),
      isbn: isbn13,
    );
  }

  factory GoogleBookResult.fromGoogleBooksApi(Map<String, dynamic> json) {
    final info = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    final imageLinks = info['imageLinks'] as Map<String, dynamic>? ?? {};
    final authors = info['authors'] as List<dynamic>? ?? [];
    final cats = info['categories'] as List<dynamic>? ?? [];
    final identifiers = info['industryIdentifiers'] as List<dynamic>? ?? [];

    String? coverUrl = imageLinks['thumbnail'] as String?
        ?? imageLinks['smallThumbnail'] as String?;
    if (coverUrl != null) {
      coverUrl = coverUrl.replaceFirst('http://', 'https://');
    }

    final publishedDate = info['publishedDate'] as String? ?? '';
    final year = int.tryParse(publishedDate.split('-').first);

    final isbn = identifiers
        .cast<Map<String, dynamic>>()
        .where((i) => i['type'] == 'ISBN_13')
        .map((i) => i['identifier'] as String)
        .firstOrNull;

    return GoogleBookResult(
      googleId: json['id'] as String,
      title: info['title'] as String? ?? 'Titre inconnu',
      author: authors.isNotEmpty ? authors.first as String : 'Auteur inconnu',
      year: year,
      pages: info['pageCount'] as int?,
      description: info['description'] as String?,
      coverUrl: coverUrl,
      categories: cats.cast<String>(),
      isbn: isbn,
    );
  }
}
