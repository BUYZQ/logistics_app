import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/core/models/user.dart';

// Feature screens imports
import 'package:logistics_app/features/auth/screens/login_screen.dart';
import 'package:logistics_app/features/orders/screens/orders_list_screen.dart';
import 'package:logistics_app/features/orders/screens/order_detail_screen.dart';
import 'package:logistics_app/features/orders/screens/create_order_screen.dart';
import 'package:logistics_app/features/expeditor/screens/expeditor_home_screen.dart';
import 'package:logistics_app/features/expeditor/screens/order_confirm_screen.dart';
import 'package:logistics_app/features/map/screens/map_screen.dart';
import 'package:logistics_app/features/chat/screens/chat_list_screen.dart';
import 'package:logistics_app/features/chat/screens/chat_screen.dart';
import 'package:logistics_app/features/profile/screens/profile_screen.dart';
import 'package:logistics_app/app/shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = AuthState.isLoggedIn;
      final onLogin = state.matchedLocation == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) {
        return AuthState.currentUser?.role == UserRole.operator
            ? '/orders'
            : '/expeditor';
      }
      return null;
    },
    routes: [
      // ─── Full-screen routes (no bottom nav) ───────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/orders/create',
        builder: (_, __) => const CreateOrderScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/expeditor/confirm/:id',
        builder: (_, state) =>
            OrderConfirmScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/map/:id',
        builder: (_, state) =>
            MapScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) =>
            ChatScreen(roomId: state.pathParameters['id']!),
      ),

      // ─── Shell (bottom nav tabs) ───────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (_, __) => const OrdersListScreen(),
              ),
              GoRoute(
                path: '/expeditor',
                builder: (_, __) => const ExpeditorHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (_, __) => const ChatListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
