import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/library/screens/library_screen.dart';
import '../features/book_detail/screens/book_detail_screen.dart';
import '../features/add_book/screens/add_book_screen.dart';
import '../features/social/screens/friends_screen.dart';
import '../features/social/screens/friend_library_screen.dart';
import '../features/social/screens/add_friend_screen.dart';
import '../features/social/screens/create_book_club_screen.dart';
import '../features/social/screens/book_club_detail_screen.dart';
import '../features/messaging/screens/messages_screen.dart';
import '../features/messaging/screens/chat_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/loans/screens/loans_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import 'widgets/main_shell.dart';
import 'services/api_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) async {
      final isAuth = await apiService.isAuthenticated();
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/welcome' || loc == '/login' ||
          loc == '/register' || loc == '/onboarding';

      if (!isAuth && !isAuthRoute) return '/welcome';
      if (isAuth && isAuthRoute) return '/library';
      return null;
    },
    routes: [
      // ── Auth ──
      GoRoute(path: '/welcome',    builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: '/login',      builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register',   builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),

      // ── Full-screen detail pages (pas de nav bar) ──
      GoRoute(path: '/library/add',           builder: (c, s) => const AddBookScreen()),
      GoRoute(path: '/library/book/:id',      builder: (c, s) => BookDetailScreen(bookId: s.pathParameters['id']!)),
      GoRoute(path: '/friends/add',           builder: (c, s) => const AddFriendScreen()),
      GoRoute(path: '/friends/bookclub/new',  builder: (c, s) => const CreateBookClubScreen()),
      GoRoute(path: '/friends/bookclub/:id',  builder: (c, s) => BookClubDetailScreen(clubId: s.pathParameters['id']!)),
      GoRoute(path: '/friends/:userId',       builder: (c, s) => FriendLibraryScreen(userId: s.pathParameters['userId']!)),
      GoRoute(path: '/notifications',          builder: (c, s) => const NotificationsScreen()),
      GoRoute(path: '/messages',              builder: (c, s) => const MessagesScreen()),
      GoRoute(path: '/messages/:partnerId',   builder: (c, s) => ChatScreen(
        partnerId:   s.pathParameters['partnerId']!,
        partnerName: s.extra as String? ?? '',
      )),

      // ── Main shell (bottom tab bar) ──
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/library',  builder: (c, s) => const LibraryScreen()),
          GoRoute(path: '/friends',  builder: (c, s) => const FriendsScreen()),
          GoRoute(path: '/loans',    builder: (c, s) => const LoansScreen()),
          GoRoute(path: '/profile',  builder: (c, s) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
