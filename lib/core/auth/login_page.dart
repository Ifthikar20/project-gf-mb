import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_bloc.dart';
import '../services/oauth_service.dart';
import '../navigation/app_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  static const _purple = Color(0xFF8B5CF6);
  static const _dark = Color(0xFF1A1A1A);
  static const _grey = Color(0xFF6B7280);
  static const _fieldBg = Color(0xFFF3F4F6);
  static const _fieldBorder = Color(0xFFE5E7EB);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _login() {
    _clearError();
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthLoginRequested(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      ));
    }
  }

  void _googleSignIn() {
    OAuthService.instance.onAuthSuccess = (user) =>
        context.read<AuthBloc>().add(AuthUserChanged(user));
    OAuthService.instance.onAuthError = (e) =>
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e), backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
    OAuthService.instance.signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthLoading) {
          setState(() { _loading = true; _error = null; });
        } else {
          setState(() => _loading = false);
        }
        if (state is AuthAuthenticated) ctx.go(AppRouter.home);
        if (state is AuthNeedsOnboarding) ctx.go(AppRouter.onboarding);
        if (state is AuthError) setState(() => _error = state.message);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Logo + Welcome (flexible height) ──
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        // Logo
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: _purple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.self_improvement_rounded,
                            size: 36,
                            color: _purple,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Welcome back',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _dark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to continue your practice',
                          style: GoogleFonts.inter(fontSize: 15, color: _grey),
                        ),
                        const Spacer(),

                        // ── Form ──
                        Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Error banner
                              if (_error != null)
                                _buildError(_error!),

                              // Email
                              _field(
                                controller: _emailCtrl,
                                focusNode: _emailFocus,
                                hint: 'Email address',
                                icon: Icons.email_outlined,
                                keyboard: TextInputType.emailAddress,
                                action: TextInputAction.next,
                                onSubmit: (_) => _passwordFocus.requestFocus(),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Enter your email';
                                  if (!v.contains('@')) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Password
                              _field(
                                controller: _passwordCtrl,
                                focusNode: _passwordFocus,
                                hint: 'Password',
                                icon: Icons.lock_outlined,
                                obscure: _obscure,
                                action: TextInputAction.done,
                                onSubmit: (_) => _login(),
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: _grey, size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Enter your password';
                                  if (v.length < 8) return 'At least 8 characters';
                                  return null;
                                },
                              ),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => context.push('/forgot-password'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: GoogleFonts.inter(
                                      color: _purple, fontSize: 13, fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Login button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _purple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22, height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2,
                                          ),
                                        )
                                      : Text('Log in',
                                          style: GoogleFonts.inter(
                                            fontSize: 16, fontWeight: FontWeight.w600,
                                          )),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Divider
                              Row(
                                children: [
                                  const Expanded(child: Divider(color: _fieldBorder)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('or',
                                        style: GoogleFonts.inter(color: _grey, fontSize: 13)),
                                  ),
                                  const Expanded(child: Divider(color: _fieldBorder)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Google
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: _googleSignIn,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _dark,
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: _fieldBorder, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20, height: 20,
                                        child: CustomPaint(painter: GoogleLogoPainter()),
                                      ),
                                      const SizedBox(width: 12),
                                      Text('Continue with Google',
                                          style: GoogleFonts.inter(
                                            fontSize: 15, fontWeight: FontWeight.w500,
                                            color: _dark,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Sign up
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Don't have an account? ",
                                      style: GoogleFonts.inter(color: _grey, fontSize: 14)),
                                  GestureDetector(
                                    onTap: () => context.push('/register'),
                                    child: Text('Sign up',
                                        style: GoogleFonts.inter(
                                          color: _purple, fontSize: 14, fontWeight: FontWeight.w600,
                                        )),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Error banner ──
  Widget _buildError(String msg) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: GoogleFonts.inter(color: Colors.red.shade700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── Styled text field ──
  Widget _field({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
    TextInputAction? action,
    ValueChanged<String>? onSubmit,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboard,
      obscureText: obscure,
      textInputAction: action,
      onFieldSubmitted: onSubmit,
      onChanged: (_) => _clearError(),
      style: GoogleFonts.inter(color: _dark, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: _grey, fontSize: 15),
        prefixIcon: Icon(icon, color: _grey, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: _fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _purple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }
}

/// Google "G" logo painter
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);
    final r = w * 0.45;
    final sw = w * 0.18;

    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;

    p.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -0.4, 1.3, false, p);

    p.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 0.9, 1.0, false, p);

    p.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 1.9, 0.9, false, p);

    p.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 2.8, 1.0, false, p);

    p
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(w * 0.5, h * 0.38, w * 0.5, h * 0.24), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
