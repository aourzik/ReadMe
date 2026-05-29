class BookClubMember {
  final String id;
  final String name;
  final String? handle;
  final String? avatarUrl;
  final DateTime joinedAt;

  const BookClubMember({
    required this.id, required this.name, required this.joinedAt,
    this.handle, this.avatarUrl,
  });

  factory BookClubMember.fromJson(Map<String, dynamic> json) => BookClubMember(
    id:        json['id']       as String,
    name:      json['name']     as String,
    handle:    json['handle']   as String?,
    avatarUrl: json['avatarUrl'] as String?,
    joinedAt:  DateTime.parse(json['joinedAt'] as String),
  );
}

class BookClubMeeting {
  final String id;
  final DateTime date;

  const BookClubMeeting({required this.id, required this.date});

  factory BookClubMeeting.fromJson(Map<String, dynamic> json) => BookClubMeeting(
    id:   json['id']   as String,
    date: DateTime.parse(json['date'] as String),
  );
}

class BookClubCreatedBy {
  final String id;
  final String name;
  final String? handle;

  const BookClubCreatedBy({required this.id, required this.name, this.handle});

  factory BookClubCreatedBy.fromJson(Map<String, dynamic> json) => BookClubCreatedBy(
    id:     json['id']     as String,
    name:   json['name']   as String,
    handle: json['handle'] as String?,
  );
}

class BookClub {
  final String id;
  final String name;
  final String? theme;
  final DateTime createdAt;
  final BookClubCreatedBy createdBy;
  final List<BookClubMember> members;
  final List<BookClubMeeting> meetings;

  const BookClub({
    required this.id, required this.name, required this.createdAt,
    required this.createdBy, required this.members, required this.meetings,
    this.theme,
  });

  factory BookClub.fromJson(Map<String, dynamic> json) => BookClub(
    id:        json['id']    as String,
    name:      json['name']  as String,
    theme:     json['theme'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    createdBy: BookClubCreatedBy.fromJson(json['createdBy'] as Map<String, dynamic>),
    members:   (json['members'] as List).map((m) => BookClubMember.fromJson(m)).toList(),
    meetings:  (json['meetings'] as List).map((m) => BookClubMeeting.fromJson(m)).toList(),
  );
}
