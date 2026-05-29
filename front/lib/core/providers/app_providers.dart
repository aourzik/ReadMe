import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../models/loan.dart';
import '../models/notification.dart';
import '../services/api_service.dart';

final booksProvider = FutureProvider<List<Book>>((ref) => apiService.getMyBooks());

final loansProvider = FutureProvider<List<Loan>>((ref) => apiService.getLoans());

final borrowedLoansProvider = FutureProvider<List<Loan>>(
  (ref) => apiService.getLoans(direction: 'in'),
);

final unreadNotifCountProvider = FutureProvider<int>(
  (ref) => apiService.getUnreadNotifCount(),
);

final notificationsProvider = FutureProvider<List<AppNotification>>(
  (ref) => apiService.getNotifications(),
);
