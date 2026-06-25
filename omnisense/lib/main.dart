// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait + landscape for tablet support
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // System UI overlay style — dark transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:            Colors.transparent,
    statusBarIconBrightness:   Brightness.light,
    systemNavigationBarColor:  OmniColors.bgDeep,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Firebase
  // TODO: Fill in real values in firebase_options.dart before running.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize FCM service
  final fcmService = FcmService();
  await fcmService.initialize();

  runApp(
    const ProviderScope(
      child: OmniSenseApp(),
    ),
  );
}

// ─── Root App ─────────────────────────────────────────────────────────────────
class OmniSenseApp extends ConsumerWidget {
  const OmniSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title:          'OmniSense Command Center',
      debugShowCheckedModeBanner: false,
      theme:          AppTheme.dark,
      darkTheme:      AppTheme.dark,
      themeMode:      ThemeMode.dark,
      initialRoute:   '/',
      onGenerateRoute: _onGenerateRoute,
      home:           const _AuthGate(),
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
        child:   child,
      ),
      transitionDuration: const Duration(milliseconds: 220),
    );
  }
}

// ─── Auth Gate ────────────────────────────────────────────────────────────────
/// Listens to [authStateProvider] and routes to LoginScreen or DashboardScreen.
/// This is the canonical pattern for Firebase Auth with Riverpod.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      data: (user) {
        if (user != null) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
      loading: () => const _SplashScreen(),
      error:   (_, __) => const LoginScreen(),
    );
  }
}

// ─── Splash Screen ─────────────────────────────────────────────────────────────
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
              width: 72, height: 72,
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
              'INITIALIZING…',
              style: TextStyle(
                color:       OmniColors.textSecondary,
                fontSize:    12,
                letterSpacing: 3.0,
                fontFamily:  'Rajdhani',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
