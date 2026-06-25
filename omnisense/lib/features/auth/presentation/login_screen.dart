// lib/features/auth/presentation/login_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnisense/core/theme/app_theme.dart';
import 'package:omnisense/features/auth/data/auth_repository.dart';
import 'package:omnisense/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey     = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  bool  _obscure     = true;
  String? _errorMsg;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _errorMsg = null);

    try {
      await ref.read(authNotifierProvider.notifier).signIn(
            email:    _emailCtrl.text,
            password: _passCtrl.text,
          );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMsg = AuthRepository.errorMessage(e));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMsg = 'An unexpected error occurred.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authNotifierProvider);
    final isLoading = authAsync.isLoading;

    return Scaffold(
      backgroundColor: OmniColors.bgDeep,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // ── Background Grid ─────────────────────────────────────────────
            Positioned.fill(child: _GridBackground()),

            // ── Content ─────────────────────────────────────────────────────
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: OmniColors.neonGreen, width: 1.5,
                          ),
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
                      Text(
                        'OMNISENSE',
                        style: GoogleFonts.rajdhani(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: OmniColors.textPrimary,
                          letterSpacing: 6.0,
                        ),
                      ),
                      Text(
                        'COMMAND CENTER',
                        style: GoogleFonts.rajdhani(
                          fontSize: 13,
                          color: OmniColors.neonGreen,
                          letterSpacing: 5.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RESTRICTED ACCESS — AUTHORIZED PERSONNEL ONLY',
                        style: GoogleFonts.rajdhani(
                          fontSize: 10,
                          color: OmniColors.textDisabled,
                          letterSpacing: 2.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // ── Login Card ────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color:  OmniColors.bgCard,
                          border: Border.all(color: OmniColors.bgBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'ADMIN AUTHENTICATION',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: OmniColors.textSecondary,
                                  letterSpacing: 2.5,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Email
                              TextFormField(
                                controller:   _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.inter(
                                  color: OmniColors.textPrimary, fontSize: 14,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Admin Email',
                                  prefixIcon: Icon(Icons.alternate_email, size: 18),
                                ),
                                validator: (v) =>
                                    (v == null || !v.contains('@'))
                                        ? 'Enter a valid email address'
                                        : null,
                              ),
                              const SizedBox(height: 14),

                              // Password
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                style: GoogleFonts.inter(
                                  color: OmniColors.textPrimary, fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.length < 6)
                                        ? 'Password must be 6+ characters'
                                        : null,
                                onFieldSubmitted: (_) => _submit(),
                              ),

                              // Error message
                              if (_errorMsg != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: OmniColors.crimsonRed.withAlpha(20),
                                    border: Border.all(
                                      color: OmniColors.crimsonRed.withAlpha(80),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_outlined,
                                        color: OmniColors.crimsonRed, size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMsg!,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: OmniColors.crimsonRed,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 22),

                              // Sign In Button
                              SizedBox(
                                height: 48,
                                child: FilledButton(
                                  onPressed: isLoading ? null : _submit,
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20, height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: OmniColors.bgDeep,
                                          ),
                                        )
                                      : Text(
                                          'AUTHENTICATE',
                                          style: GoogleFonts.rajdhani(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 3.0,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'OmniSense Edge Gateway v3.2  ·  Firebase Auth',
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          color: OmniColors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Background Grid Painter ──────────────────────────────────────────────────
class _GridBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
