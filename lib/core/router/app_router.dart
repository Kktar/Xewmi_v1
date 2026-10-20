import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/auth/welcome_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/home/search_screen.dart';
import '../../presentation/screens/event/event_detail_screen.dart';
import '../../presentation/screens/tickets/ticket_selection_screen.dart';
import '../../presentation/screens/payment/payment_screen.dart';
import '../../presentation/screens/tickets/e_ticket_screen.dart';
import '../../presentation/screens/tickets/my_tickets_screen.dart';
import '../../presentation/screens/organizer/organizer_dashboard_screen.dart';
import '../../presentation/screens/scanner/scanner_screen.dart';
import '../../presentation/screens/organizer/generate_ticket_screen.dart';
import '../../presentation/screens/organizer/ticket_ready_screen.dart';
import '../../presentation/screens/organizer/issued_tickets_screen.dart';
import '../../presentation/screens/organizer/create_event_screen.dart';
import '../../presentation/screens/organizer/event_preview_screen.dart';
import '../../presentation/screens/organizer/organizer_kyc_screen.dart';
import '../../presentation/screens/organizer/event_buyers_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/providers/auth_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

bool _requiresAuth(String location) {
  if (location.startsWith('/event/') && location.contains('/tickets')) {
    return true;
  }
  if (location.startsWith('/payment/')) return true;
  if (location.startsWith('/ticket/')) return true;
  if (location == '/my-tickets') return true;
  if (location == '/profile') return true;
  if (location.startsWith('/organizer')) return true;
  return false;
}

bool _isOAuthCallback(Uri uri) {
  final s = uri.toString();
  return uri.scheme == 'io.supabase.flutter' ||
      uri.host == 'login-callback' ||
      s.contains('login-callback') ||
      s.contains('io.supabase.flutter');
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    debugLogDiagnostics: true,

    // Un seul gestionnaire d'erreur (pas de errorBuilder en même temps)
    onException: (context, state, router) {
      router.go('/home');
    },

    redirect: (context, state) {
      final uri = state.uri;
      final loc = state.matchedLocation;
      final full = uri.toString();

      debugPrint('ROUTER REDIRECT: $uri (loc=$loc)');

      if (_isOAuthCallback(uri)) return '/home';
      if (loc == '/' || loc.isEmpty) return '/home';

      final isLoggedIn = authState.valueOrNull != null;
      if (authState.isLoading) return null;

      if (isLoggedIn && (loc == '/welcome' || loc == '/login')) {
        final redirect = uri.queryParameters['redirect'];
        if (redirect != null &&
            redirect.isNotEmpty &&
            !redirect.contains('login-callback') &&
            !redirect.contains('io.supabase')) {
          return redirect;
        }
        return '/home';
      }

      if (!isLoggedIn && _requiresAuth(loc)) {
        return '/login?redirect=${Uri.encodeComponent(full)}';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/login-callback',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          redirectTo: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => SearchScreen(
          initialCategory: state.uri.queryParameters['category'],
        ),
      ),
      GoRoute(
        path: '/event/:id',
        builder: (context, state) => EventDetailScreen(
          eventId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/event/:id/tickets',
        builder: (context, state) => TicketSelectionScreen(
          eventId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/payment/:orderId',
        builder: (context, state) => PaymentScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: '/ticket/:id',
        builder: (context, state) => ETicketScreen(
          ticketId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/my-tickets',
        builder: (context, state) => const MyTicketsScreen(),
      ),
      GoRoute(
        path: '/organizer',
        builder: (context, state) => const OrganizerDashboardScreen(),
      ),
      GoRoute(
        path: '/organizer/scan',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/organizer/generate/:eventId',
        builder: (context, state) => GenerateTicketScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),
      GoRoute(
        path: '/organizer/ticket-ready',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TicketReadyScreen(data: extra ?? {});
        },
      ),
      GoRoute(
        path: '/organizer/issued/:eventId',
        builder: (context, state) => IssuedTicketsScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),
      GoRoute(
        path: '/organizer/create-event',
        builder: (context, state) => const CreateEventScreen(),
      ),
      GoRoute(
        path: '/organizer/preview/:eventId',
        builder: (context, state) => EventPreviewScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),
      GoRoute(
        path: '/organizer/kyc',
        builder: (context, state) => const OrganizerKycScreen(),
      ),
      GoRoute(
        path: '/organizer/event/:eventId/buyers',
        builder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? 'Acheteurs';
          return EventBuyersScreen(
            eventId: state.pathParameters['eventId']!,
            eventTitle: title,
          );
        },
      ),
      GoRoute(path: '/', redirect: (_, __) => '/home'),
      GoRoute(path: '/login-callback', redirect: (_, __) => '/home'),
    ],
  );
});
