import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/config/app_theme.dart';
import 'core/l10n/app_localizations.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/pending_screen.dart';
import 'features/auth/screens/setup_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/workout/screens/workout_screen.dart';
import 'features/workout/screens/session_screen.dart';
import 'features/nutrition/screens/nutrition_screen.dart';
import 'features/attendance/screens/attendance_screen.dart';
import 'features/progress/screens/progress_screen.dart';
import 'features/chat/screens/chat_list_screen.dart';
import 'features/chat/screens/chat_room_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/admin/screens/admin_screen.dart';
import 'features/subscription/screens/subscription_screen.dart';
import 'features/subscription/screens/payment_screen.dart';
import 'features/update/screens/update_screen.dart';
import 'models/version_model.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/version_provider.dart';
import 'widgets/common/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final versionState = ref.watch(versionProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (ctx, state) {
      final path = state.uri.toString();

      // ── Version check (highest priority) ──────────────────
      // While loading version, don't redirect yet
      if (versionState.isLoading) return null;

      // If forced update or unsupported — block everything except /update
      if (versionState.isBlocked) {
        if (path == '/update') return null;
        return '/update';
      }

      // Allow leaving /update once no longer blocked
      if (path == '/update' && !versionState.isBlocked) {
        return '/home';
      }

      // ── Auth check ─────────────────────────────────────────
      if (authState.isLoading) return null;
      final user = authState.valueOrNull;

      if (user == null) {
        if (path.startsWith('/auth')) return null;
        return '/auth/login';
      }
      if (user.status == 'pending' || user.status == 'rejected') {
        return '/auth/pending';
      }
      if (path.startsWith('/auth')) return '/home';

      return null;
    },
    routes: [
      // ── Update screen (outside shell — fullscreen) ─────────
      GoRoute(
        path: '/update',
        builder: (_, __) => const UpdateScreen(),
      ),

      // ── Auth screens ───────────────────────────────────────
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/auth/pending', builder: (_, __) => const PendingScreen()),
      GoRoute(path: '/auth/setup', builder: (_, __) => const SetupScreen()),

      // ── Main shell (bottom nav) ────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/workout', builder: (_, __) => const WorkoutScreen()),
          GoRoute(path: '/nutrition', builder: (_, __) => const NutritionScreen()),
          GoRoute(path: '/attendance', builder: (_, __) => const AttendanceScreen()),
          GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
          GoRoute(path: '/chat', builder: (_, __) => const ChatListScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
          GoRoute(path: '/subscription', builder: (_, __) => const SubscriptionScreen()),
        ],
      ),

      // ── Detail screens (outside shell) ────────────────────
      GoRoute(
        path: '/workout/session',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SessionScreen(
            sessionName: extra['sessionName'] as String? ?? '',
            programId: extra['programId'] as String? ?? 'UL',
          );
        },
      ),
      GoRoute(
        path: '/chat/room',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ChatRoomScreen(
            roomId: extra['roomId'] as String? ?? 'general',
            roomName: extra['roomName'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/subscription/pay',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PaymentScreen(planId: extra['planId'] as String? ?? 'light');
        },
      ),
    ],
  );
});

class ToBestApp extends ConsumerWidget {
  const ToBestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TO Best',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(settings.accentColor),
      darkTheme: AppTheme.darkTheme(settings.accentColor),
      themeMode: settings.themeMode,
      routerConfig: router,
      locale: settings.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (ctx, child) => Directionality(
        textDirection: settings.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
    );
  }
}
