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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Theme colors
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color greyText = Color(0xFF6B7280);
  static const Color inputBg = Color(0xFFF3F4F6);
  static const Color inputBorder = Color(0xFFE5E7EB);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  void _onLogin() {
    _clearError();
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthLoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
    }
  }

  void _signInWithGoogle() {
    OAuthService.instance.onAuthSuccess = (user) {
      context.read<AuthBloc>().add(AuthUserChanged(user));
    };
    OAuthService.instance.onAuthError = (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    };
    OAuthService.instance.signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          setState(() {
            _isLoading = true;
            _errorMessage = null;
          });
        } else {
          setState(() => _isLoading = false);
        }

        if (state is AuthAuthenticated) {
          context.go(AppRouter.home);
        } else if (state is AuthNeedsOnboarding) {
          context.go(AppRouter.onboarding);
        } else if (state is AuthError) {
          setState(() => _errorMessage = state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // ── Top Section: Logo + Welcome ──
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // App icon / logo
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: primaryPurple.withOpacity(0.08),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.self_improvement_rounded,
                                        size: 36,
                                        color: primaryPurple,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Welcome back',
                                    style: GoogleFonts.inter(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: darkText,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Sign in to continue your practice',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      color: greyText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Form Section ──
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(28, 0, 28, 20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Error message
                                  if (_errorMessage != null)
                                    Container(
                                      width: double.infinity,
                                      margin:
                                          const EdgeInsets.only(bottom: 14),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.red.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline,
                                              color: Colors.red.shade400,
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: GoogleFonts.inter(
                                                color: Colors.red.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Email field
                                  _buildTextField(
                                    controller: _emailController,
                                    focusNode: _emailFocus,
                                    hintText: 'Email address',
                                    keyboardType:
                                        TextInputType.emailAddress,
                                    prefixIcon: Icons.email_outlined,
                                    textInputAction:
                                        TextInputAction.next,
                                    onFieldSubmitted: (_) {
                                      _passwordFocus.requestFocus();
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  // Password field
                                  _buildTextField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocus,
                                    hintText: 'Password',
                                    obscureText: _obscurePassword,
                                    prefixIcon: Icons.lock_outlined,
                                    textInputAction:
                                        TextInputAction.done,
                                    onFieldSubmitted: (_) => _onLogin(),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons
                                                .visibility_off_outlined
                                            : Icons
                                                .visibility_outlined,
                                        color: greyText,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscurePassword =
                                              !_obscurePassword),
                                    ),
                                  ),

                                  // Forgot password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () =>
                                          context.push('/forgot-password'),
                                      style: TextButton.styleFrom(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 0,
                                                vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize
                                                .shrinkWrap,
                                      ),
                                      child: Text(
                                        'Forgot Password?',
                                        style: GoogleFonts.inter(
                                          color: primaryPurple,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
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
                                      onPressed:
                                          _isLoading ? null : _onLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryPurple,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              'Log in',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Divider
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                            color: inputBorder,
                                            thickness: 1),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16),
                                        child: Text(
                                          'or',
                                          style: GoogleFonts.inter(
                                            color: greyText,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                            color: inputBorder,
                                            thickness: 1),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Google button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: OutlinedButton(
                                      onPressed: _signInWithGoogle,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: darkText,
                                        backgroundColor: Colors.white,
                                        side: BorderSide(
                                            color: inputBorder,
                                            width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CustomPaint(
                                              painter:
                                                  GoogleLogoPainter(),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Continue with Google',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight:
                                                  FontWeight.w500,
                                              color: darkText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // Sign up link
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Don't have an account? ",
                                        style: GoogleFonts.inter(
                                          color: greyText,
                                          fontSize: 14,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            context.push('/register'),
                                        child: Text(
                                          'Sign up',
                                          style: GoogleFonts.inter(
                                            color: primaryPurple,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: (_) => _clearError(),
      style: GoogleFonts.inter(color: darkText, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(color: greyText, fontSize: 15),
        prefixIcon: Icon(prefixIcon, color: greyText, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: primaryPurple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (hintText.contains('Email')) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!value.contains('@')) return 'Please enter a valid email';
        } else if (hintText.contains('Password')) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          if (value.length < 8) {
            return 'Password must be at least 8 characters';
          }
        }
        return null;
      },
    );
  }
}

/// Custom painter for Google "G" logo
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);
    final double radius = w * 0.45;
    final double strokeWidth = w * 0.18;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.4,
      1.3,
      false,
      paint,
    );

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.9,
      1.0,
      false,
      paint,
    );

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.9,
      0.9,
      false,
      paint,
    );

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.8,
      1.0,
      false,
      paint,
    );

    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.5, h * 0.38, w * 0.5, h * 0.24),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
