import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_bloc.dart';
import '../utils/password_validator.dart';
import '../services/oauth_service.dart';
import '../navigation/app_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _showEmailForm = false;
  String? _error;

  static const _purple = Color(0xFF8B5CF6);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _register() {
    _clearError();
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthRegisterRequested(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _nameCtrl.text.trim(),
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

  void _appleSignIn() {
    OAuthService.instance.onAuthSuccess = (user) =>
        context.read<AuthBloc>().add(AuthUserChanged(user));
    OAuthService.instance.onAuthError = (e) =>
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e), backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
    OAuthService.instance.signInWithApple();
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
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // ── Top: Backdrop image ──
              if (!_showEmailForm || MediaQuery.of(context).viewInsets.bottom == 0)
                Expanded(
                  flex: _showEmailForm ? 1 : 2,
                  child: Stack(
                    children: [
                      SizedBox.expand(
                        child: Image.asset(
                          'assets/images/sign-up-backgrop.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Gradient fade
                      Positioned(
                        bottom: 0, left: 0, right: 0, height: 60,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black],
                            ),
                          ),
                        ),
                      ),
                      // Back button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 8,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                          onPressed: () {
                            if (_showEmailForm) {
                              setState(() { _showEmailForm = false; _error = null; });
                            } else {
                              context.pop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Bottom: Form ──
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: Column(
                    children: [
                      // Title
                      Text(
                        _showEmailForm ? 'Create your account' : 'Sign up to start\nyour journey',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Error
                      if (_error != null) ...[
                        _buildError(_error!),
                        const SizedBox(height: 12),
                      ],

                      if (_showEmailForm)
                        _buildEmailForm()
                      else
                        _buildSocialOptions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Social login buttons ──
  Widget _buildSocialOptions() {
    return Column(
      children: [
        _socialBtn(
          icon: Icons.email_outlined,
          label: 'Continue with email',
          primary: true,
          onTap: () => setState(() => _showEmailForm = true),
        ),
        const SizedBox(height: 10),
        _socialBtn(
          icon: Icons.g_mobiledata,
          iconColor: const Color(0xFFDB4437),
          label: 'Continue with Google',
          onTap: _googleSignIn,
        ),
        const SizedBox(height: 10),
        _socialBtn(
          icon: Icons.apple,
          label: 'Continue with Apple',
          onTap: _appleSignIn,
        ),
        const SizedBox(height: 24),
        _loginLink(),
      ],
    );
  }

  Widget _socialBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    bool primary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: primary
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor ?? Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
    );
  }

  // ── Email registration form ──
  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          _field(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            hint: 'Full name',
            icon: Icons.person_outline,
            action: TextInputAction.next,
            onSubmit: (_) => _emailFocus.requestFocus(),
            validator: (v) => (v == null || v.isEmpty) ? 'Enter your name' : null,
          ),
          const SizedBox(height: 10),

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
              if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 10),

          // Password
          _field(
            controller: _passwordCtrl,
            focusNode: _passwordFocus,
            hint: 'Password',
            icon: Icons.lock_outlined,
            obscure: _obscure,
            action: TextInputAction.next,
            onSubmit: (_) => _confirmFocus.requestFocus(),
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.white38, size: 18,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            onChanged: (_) { _clearError(); setState(() {}); },
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a password';
              return PasswordValidator.validate(v);
            },
          ),
          const SizedBox(height: 6),
          _buildPasswordReqs(),
          const SizedBox(height: 10),

          // Confirm password
          _field(
            controller: _confirmCtrl,
            focusNode: _confirmFocus,
            hint: 'Confirm password',
            icon: Icons.lock_outlined,
            obscure: _obscureConfirm,
            action: TextInputAction.done,
            onSubmit: (_) => _register(),
            suffix: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                color: Colors.white38, size: 18,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) => v != _passwordCtrl.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 16),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _purple.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Create Account',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          _loginLink(),
        ],
      ),
    );
  }

  // ── Password requirements ──
  Widget _buildPasswordReqs() {
    final reqs = PasswordValidator.getRequirements(_passwordCtrl.text);
    return Column(
      children: reqs.map((r) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            Icon(
              r.isMet ? Icons.check_circle : Icons.circle_outlined,
              size: 12,
              color: r.isMet ? Colors.green : Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 6),
            Text(r.label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: r.isMet ? Colors.green : Colors.white.withValues(alpha: 0.4),
                )),
          ],
        ),
      )).toList(),
    );
  }

  // ── Error banner ──
  Widget _buildError(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: GoogleFonts.inter(color: Colors.red.shade300, fontSize: 12)),
          ),
          GestureDetector(
            onTap: _clearError,
            child: const Icon(Icons.close, color: Colors.red, size: 16),
          ),
        ],
      ),
    );
  }

  // ── Login link ──
  Widget _loginLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Already have an account? ',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 13,
              )),
          GestureDetector(
            onTap: () => context.push('/login'),
            child: Text('Log in',
                style: GoogleFonts.inter(
                  color: _purple, fontSize: 13, fontWeight: FontWeight.w600,
                )),
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
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboard,
      obscureText: obscure,
      textInputAction: action,
      onFieldSubmitted: onSubmit,
      onChanged: onChanged ?? (_) => _clearError(),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _purple),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        errorStyle: const TextStyle(fontSize: 10),
      ),
    );
  }
}
