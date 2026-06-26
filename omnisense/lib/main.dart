// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omnisense/core/theme/app_theme.dart';
import 'package:omnisense/features/analytics/presentation/analytics_screen.dart';
import 'package:omnisense/features/auth/presentation/login_screen.dart';
import 'package:omnisense/features/auth/providers/auth_provider.dart';
import 'package:omnisense/features/dashboard/presentation/dashboard_screen.dart';
import 'package:omnisense/features/registry/presentation/registry_screen.dart';
import 'package:omnisense/firebase_options.dart';
import 'package:omnisense/shared/services/fcm_service.dart';

/// Mandatory Top-Level Background Message Handler for Firebase Cloud Messaging.
/// This must remain a top-level function to execute safely in an isolated background thread.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Custom processing logic for your "Unknown Entity" alarms can be executed here
}

void main() async {
  // Ensure the framework engine is fully attached before running native calls
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce structural orientation optimization for hardware displays and tablets
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Apply visual layer optimizations across system status navigation interfaces
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: OmniColors.bgDeep,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  try {
    // Initialize the main Firebase instance using your generated configuration map
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Register background cloud messaging channels
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Bootstrap local notification routines and channels
    final fcmService = FcmService();
    await fcmService.initialize();
  } catch (error) {
    debugPrint("Critical System Boot Failure: $error");
  }

  runApp(
    const ProviderScope(
      child: OmniSenseApp(),
    ),
  );
}

// ─── Root App Configuration ───────────────────────────────────────────────────
class OmniSenseApp extends ConsumerWidget {
  const OmniSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'OmniSense Command Center',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
      home: const _AuthGate(),
    );
  }

  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return _slide(const LoginScreen());
      case '/dashboard':
        return _slide(const DashboardScreen());
      case '/registry':
        return _slide(const RegistryScreen());
      case '/analytics':
        return _slide(const AnalyticsScreen());
      default:
        return null;
    }
  }

  static PageRoute<dynamic> _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 220),
    );
  }
}

// ─── Role-Based Authentication Gate ───────────────────────────────────────────
/// Evaluates credentials and verifies explicit admin role clearances
/// before rendering primary secure workspace dashboards.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        
        // Secondary Role Verification Sequence
        // Ensures standard accounts cannot bypass entry to the hardware panel
        final adminAsync = ref.watch(adminRoleProvider);
        
        return adminAsync.when(
          data: (isAdmin) => isAdmin ? const DashboardScreen() : const LoginScreen(),
          loading: () => const _SplashScreen(),
          error: (_, __) => const LoginScreen(),
        );
      },
      loading: () => const _SplashScreen(),
      error: (_, __) => const LoginScreen(),
    );
  }
}

// ─── Hardware Themed Splash Sequence ──────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OmniColors.bgDeep,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                border: Border.all(color: OmniColors.neonGreen, width: 1.5),
                borderRadius: BorderRadius.circular(16),
                color: OmniColors.neonGreen.withAlpha(15),
              ),
              child: const Icon(
                Icons.security,
                color: OmniColors.neonGreen,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              strokeWidth: 2,
              color: OmniColors.neonGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              'INITIALIZING APP LAYER…',
              style: TextStyle(
                color: OmniColors.textSecondary,
                fontSize: 12,
                letterSpacing: 3.0,
                fontFamily: 'Rajdhani',
              ),
            ),
          ],
        ),
      ),
    );
  }
}