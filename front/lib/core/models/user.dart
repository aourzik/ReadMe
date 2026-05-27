// user.dart — modèle User sans code generation

class User {
  final String id;
  final String name;
  final String email;
  final String? handle;
  final String? avatarUrl;
  final int bookCount;
  final int friendCount;
  final List<String> favoriteGenres;
  final String? location;
  final int? readingGoal;
  final int? booksReadThisYear;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.handle,
    this.avatarUrl,
    this.bookCount = 0,
    this.friendCount = 0,
    this.favoriteGenres = const [],
    this.location,
    this.readingGoal,
    this.booksReadThisYear,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      handle: json['handle'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bookCount: (json['bookCount'] as num?)?.toInt() ?? 0,
      friendCount: (json['friendCount'] as num?)?.toInt() ?? 0,
      favoriteGenres: (json['favoriteGenres'] as List<dynamic>?)?.cast<String>() ?? [],
      location: json['location'] as String?,
      readingGoal: (json['readingGoal'] as num?)?.toInt(),
      booksReadThisYear: (json['booksReadThisYear'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    if (handle != null) 'handle': handle,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    'bookCount': bookCount,
    'friendCount': friendCount,
    'favoriteGenres': favoriteGenres,
    if (location != null) 'location': location,
    if (readingGoal != null) 'readingGoal': readingGoal,
    if (booksReadThisYear != null) 'booksReadThisYear': booksReadThisYear,
  };
}

class FriendRequest {
  final String id;
  final User sender;
  final DateTime sentAt;
  final String status;

  const FriendRequest({
    required this.id,
    required this.sender,
    required this.sentAt,
    this.status = 'pending',
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      sender: User.fromJson(json['sender'] as Map<String, dynamic>),
      sentAt: DateTime.parse(json['sentAt'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }
}
