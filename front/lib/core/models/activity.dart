class ActivityUser {
  final String id;
  final String name;
  final String? handle;
  final String? avatarUrl;

  const ActivityUser({required this.id, required this.name, this.handle, this.avatarUrl});

  factory ActivityUser.fromJson(Map<String, dynamic> json) => ActivityUser(
    id:        json['id']       as String,
    name:      json['name']     as String,
    handle:    json['handle']   as String?,
    avatarUrl: json['avatarUrl'] as String?,
  );
}

class ActivityBook {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String? googleBooksId;
  final int? year;

  const ActivityBook({
    required this.id, required this.title, required this.author,
    this.coverUrl, this.googleBooksId, this.year,
  });

  factory ActivityBook.fromJson(Map<String, dynamic> json) => ActivityBook(
    id:            json['id']           as String,
    title:         json['title']        as String,
    author:        json['author']       as String,
    coverUrl:      json['coverUrl']     as String?,
    googleBooksId: json['googleBooksId'] as String?,
    year:          (json['year'] as num?)?.toInt(),
  );
}

class Activity {
  final String id;
  final String type; // book_added | book_finished | book_rated | book_recommended
  final DateTime createdAt;
  final ActivityUser user;
  final ActivityBook? book;

  const Activity({
    required this.id, required this.type, required this.createdAt,
    required this.user, this.book,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    id:        json['id']   as String,
    type:      json['type'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    user:      ActivityUser.fromJson(json['user'] as Map<String, dynamic>),
    book:      json['book'] != null
        ? ActivityBook.fromJson(json['book'] as Map<String, dynamic>)
        : null,
  );

  String get actionLabel {
    switch (type) {
      case 'book_finished':    return 'a fini de lire';
      case 'book_rated':       return 'a noté';
      case 'book_recommended': return 'recommande';
      case 'book_added':
      default:                 return 'a ajouté';
    }
  }

  bool get showAddButton =>
      type == 'book_recommended' || type == 'book_finished' || type == 'book_rated';
}
