import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_bloc.dart';
import '../utils/password_validator.dart';
import '../services/oauth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _showEmailForm = false;
  String? _errorMessage;

  // Purple theme color
  static const Color primaryPurple = Color(0xFF8B5CF6);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  void _onRegister() {
    _clearError();
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthRegisterRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
      ));
    }
  }

  void _signInWithGoogle() {
    // Set up OAuth callbacks
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

  void _signInWithApple() {
    // Set up OAuth callbacks
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
    OAuthService.instance.signInWithApple();
  }

  void _showSocialLoginMessage(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider sign-in coming soon'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2A2A2A),
      ),
    );
  }

  String _parseErrorMessage(String error) {
    if (error.contains('UsernameExistsException') || error.contains('already exists')) {
      return 'An account with this email already exists. Please log in instead.';
    }
    if (error.contains('InvalidPasswordException') || error.contains('Password')) {
      return 'Password must be at least 8 characters with uppercase, lowercase, and numbers.';
    }
    if (error.contains('InvalidParameterException')) {
      return 'Please check your input and try again.';
    }
    if (error.contains('network') || error.contains('Network') || error.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }
    if (error.contains('timeout') || error.contains('Timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (error.length > 100) {
      return 'Registration failed. Please try again.';
    }
    return error;
  }

  @override
  Widget build(BuildContext context) {
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
          context.go('/');
        } else if (state is AuthError) {
          setState(() {
            _errorMessage = _parseErrorMessage(state.message);
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            // ===== TOP SECTION: Backdrop Image =====
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  // Backdrop Image
                  SizedBox.expand(
                    child: Image.asset(
                      'assets/images/sign-up-backgrop.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  
                  // Gradient overlay at bottom for smooth transition
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                          ],
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
                          setState(() {
                            _showEmailForm = false;
                            _errorMessage = null;
                          });
                        } else {
                          context.pop();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // ===== BOTTOM SECTION: Form =====
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.black,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                      
                      // Error message banner
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(
                                    color: Colors.red.shade300,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _clearError,
                                child: const Icon(Icons.close, color: Colors.red, size: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      if (_showEmailForm) 
                        _buildEmailForm() 
                      else 
                        _buildSocialLoginOptions(),
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

  Widget _buildSocialLoginOptions() {
    return Column(
      children: [
        // Email Sign In (Primary)
        _buildSocialButton(
          icon: Icons.email_outlined,
          label: 'Continue with email',
          isPrimary: true,
          onTap: () => setState(() => _showEmailForm = true),
        ),
        const SizedBox(height: 10),
        
        // Google Sign In
        _buildSocialButton(
          icon: Icons.g_mobiledata,
          iconColor: const Color(0xFFDB4437),
          label: 'Continue with Google',
          onTap: _signInWithGoogle,
        ),
        const SizedBox(height: 10),
        
        // Apple Sign In
        _buildSocialButton(
          icon: Icons.apple,
          label: 'Continue with Apple',
          onTap: _signInWithApple,
        ),
        
        const SizedBox(height: 24),
        
        // Already have account
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/login'),
              child: Text(
                'Log in',
                style: GoogleFonts.inter(
                  color: primaryPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor ?? Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name
          _buildTextField(
            controller: _nameController,
            hintText: 'Full name',
            prefixIcon: Icons.person_outline,
            onChanged: (_) => _clearError(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          
          // Email
          _buildTextField(
            controller: _emailController,
            hintText: 'Email address',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            onChanged: (_) => _clearError(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          
          // Password
          _buildTextField(
            controller: _passwordController,
            hintText: 'Password',
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outlined,
            onChanged: (_) {
              _clearError();
              setState(() {});
            },
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white38,
                size: 18,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              return PasswordValidator.validate(value);
            },
          ),
          const SizedBox(height: 6),
          
          // Password requirements checklist
          _buildPasswordRequirements(),
          const SizedBox(height: 10),
          
          // Confirm Password
          _buildTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirm password',
            obscureText: _obscureConfirmPassword,
            prefixIcon: Icons.lock_outlined,
            onChanged: (_) => _clearError(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white38,
                size: 18,
              ),
              onPressed: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Create Account button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: primaryPurple.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Create Account',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Already have account
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/login'),
                  child: Text(
                    'Log in',
                    style: GoogleFonts.inter(
                      color: primaryPurple,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    final requirements = PasswordValidator.getRequirements(_passwordController.text);
    
    return Column(
      children: requirements.map((req) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            Icon(
              req.isMet ? Icons.check_circle : Icons.circle_outlined,
              size: 12,
              color: req.isMet ? Colors.green : Colors.white.withOpacity(0.4),
            ),
            const SizedBox(width: 6),
            Text(
              req.label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: req.isMet ? Colors.green : Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: Colors.white38, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPurple),
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
