import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/book.dart';
import '../models/user.dart';
import '../models/loan.dart';
import '../models/activity.dart';
import '../models/book_club.dart';
import '../models/message.dart';
import '../models/notification.dart';

class ApiService {
  static const _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://readme-back-396x.onrender.com/api',
  );

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // Auth interceptor — injecte le JWT dans chaque requête
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: 'jwt_token');
            // Déclencher une redirection vers login (géré via router)
          }
          handler.next(error);
        },
      ),
    );
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = res.data['token'] as String;
    await _storage.write(key: 'jwt_token', value: token);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    final token = res.data['token'] as String;
    await _storage.write(key: 'jwt_token', value: token);
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }

  // ── Books ─────────────────────────────────────────────────────────────────

  Future<List<Book>> getMyBooks({String? status}) async {
    final params = status != null ? {'status': status} : null;
    final res = await _dio.get('/books', queryParameters: params);
    return (res.data as List).map((b) => Book.fromJson(b)).toList();
  }

  Future<Book> getBook(String id) async {
    final res = await _dio.get('/books/$id');
    return Book.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Book> addBook(Book book) async {
    final res = await _dio.post('/books', data: book.toJson());
    return Book.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Book> updateBook(String id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/books/$id', data: data);
    return Book.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteBook(String id) async {
    await _dio.delete('/books/$id');
  }

  // ── Loans ─────────────────────────────────────────────────────────────────

  Future<List<Loan>> getLoans({String? direction}) async {
    final params = direction != null ? {'direction': direction} : null;
    final res = await _dio.get('/loans', queryParameters: params);
    return (res.data as List).map((l) => Loan.fromJson(l)).toList();
  }

  Future<Loan> createLoan({
    required String bookId,
    required String partnerId,
    DateTime? dueDate,
  }) async {
    final res = await _dio.post('/loans', data: {
      'bookId': bookId,
      'partnerId': partnerId,
      if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
    });
    return Loan.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> returnLoan(String loanId) async {
    await _dio.patch('/loans/$loanId/return');
  }

  Future<void> remindLoan(String loanId) async {
    await _dio.post('/loans/$loanId/remind');
  }

  Future<Loan> borrowBook({
    required String bookId,
    required String giverId,
    DateTime? dueDate,
  }) async {
    final res = await _dio.post('/loans/borrow', data: {
      'bookId': bookId,
      'giverId': giverId,
      if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
    });
    return Loan.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Friends ───────────────────────────────────────────────────────────────

  Future<List<User>> getFriends() async {
    final res = await _dio.get('/friends');
    return (res.data as List).map((u) => User.fromJson(u)).toList();
  }

  Future<List<FriendRequest>> getPendingRequests() async {
    final res = await _dio.get('/friends/requests');
    return (res.data as List).map((r) => FriendRequest.fromJson(r)).toList();
  }

  Future<void> sendFriendRequest(String userId) async {
    await _dio.post('/friends/request', data: {'userId': userId});
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await _dio.patch('/friends/requests/$requestId/accept');
  }

  Future<void> declineFriendRequest(String requestId) async {
    await _dio.patch('/friends/requests/$requestId/decline');
  }

  Future<void> removeFriend(String friendId) async {
    await _dio.delete('/friends/$friendId');
  }

  Future<List<Activity>> getFriendActivity() async {
    final res = await _dio.get('/friends/activity');
    return (res.data as List).map((a) => Activity.fromJson(a)).toList();
  }

  Future<List<Book>> getFriendBooks(String friendId) async {
    final res = await _dio.get('/friends/$friendId/books');
    return (res.data as List).map((b) => Book.fromJson(b)).toList();
  }

  Future<List<User>> searchUsers(String query) async {
    final res = await _dio.get('/users/search', queryParameters: {'q': query});
    return (res.data as List).map((u) => User.fromJson(u)).toList();
  }

  // ── Book Clubs ────────────────────────────────────────────────────────────

  Future<List<BookClub>> getBookClubs() async {
    final res = await _dio.get('/bookclubs');
    return (res.data as List).map((c) => BookClub.fromJson(c)).toList();
  }

  Future<BookClub> getBookClub(String id) async {
    final res = await _dio.get('/bookclubs/$id');
    return BookClub.fromJson(res.data as Map<String, dynamic>);
  }

  Future<BookClub> createBookClub({
    required String name,
    String? theme,
    List<String> memberIds = const [],
  }) async {
    final res = await _dio.post('/bookclubs', data: {
      'name': name,
      if (theme != null) 'theme': theme,
      'memberIds': memberIds,
    });
    return BookClub.fromJson(res.data as Map<String, dynamic>);
  }

  Future<BookClub> updateBookClub(String id, {String? name, String? theme}) async {
    final res = await _dio.patch('/bookclubs/$id', data: {
      if (name != null) 'name': name,
      if (theme != null) 'theme': theme,
    });
    return BookClub.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> addBookClubMembers(String clubId, List<String> userIds) async {
    await _dio.post('/bookclubs/$clubId/members', data: {'userIds': userIds});
  }

  Future<void> removeBookClubMember(String clubId, String userId) async {
    await _dio.delete('/bookclubs/$clubId/members/$userId');
  }

  Future<BookClubMeeting> addBookClubMeeting(String clubId, DateTime date) async {
    final res = await _dio.post('/bookclubs/$clubId/meetings', data: {
      'date': date.toIso8601String(),
    });
    return BookClubMeeting.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteBookClubMeeting(String clubId, String meetingId) async {
    await _dio.delete('/bookclubs/$clubId/meetings/$meetingId');
  }

  // ── Messages ─────────────────────────────────────────────────────────────

  Future<List<Conversation>> getConversations() async {
    final res = await _dio.get('/messages');
    return (res.data as List).map((c) => Conversation.fromJson(c)).toList();
  }

  Future<List<ChatMessage>> getMessages(String partnerId) async {
    final res = await _dio.get('/messages/$partnerId');
    return (res.data as List).map((m) => ChatMessage.fromJson(m)).toList();
  }

  Future<ChatMessage> sendMessage(String partnerId, String content) async {
    final res = await _dio.post('/messages/$partnerId', data: {'content': content});
    return ChatMessage.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<List<AppNotification>> getNotifications() async {
    final res = await _dio.get('/notifications');
    return (res.data as List).map((n) => AppNotification.fromJson(n)).toList();
  }

  Future<int> getUnreadNotifCount() async {
    final res = await _dio.get('/notifications/unread-count');
    return (res.data['count'] as num).toInt();
  }

  Future<void> markNotifRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }

  Future<void> markAllNotifsRead() async {
    await _dio.patch('/notifications/read-all');
  }

  Future<void> acceptLoan(String loanId, {int? dueDays}) async {
    await _dio.patch('/loans/$loanId/accept',
        data: dueDays != null ? {'dueDays': dueDays} : {});
  }

  Future<void> declineLoan(String loanId) async {
    await _dio.patch('/loans/$loanId/decline');
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<User> getMe() async {
    final res = await _dio.get('/users/me');
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _dio.patch('/users/me', data: data);
  }
}

// Singleton provider-accessible
final apiService = ApiService();
