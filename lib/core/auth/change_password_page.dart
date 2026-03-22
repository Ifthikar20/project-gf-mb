import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../utils/password_validator.dart';

/// Change Password Page
/// Allows authenticated users to change their password
/// Uses the same purple dark theme as other auth pages
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscurNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _success = false;

  // Theme colors — matching existing auth pages
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color cardBg = Color(0xFF1A1A1A);


  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _success = true;
      });

      // Auto-navigate back after brief delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.pop();
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.code == 'INCORRECT_CURRENT_PASSWORD'
            ? 'The current password you entered is incorrect.'
            : e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _success ? _buildSuccessState() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        ),
        const SizedBox(height: 24),
        Text(
          'Password Changed',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your password has been updated successfully.',
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header icon
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outlined,
                color: primaryPurple,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Update your password',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Error banner
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
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
                    onTap: () => setState(() => _errorMessage = null),
                    child: const Icon(Icons.close, color: Colors.red, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Current password
          _buildLabel('Current Password'),
          const SizedBox(height: 6),
          _buildPasswordField(
            controller: _oldPasswordController,
            hintText: 'Enter current password',
            obscure: _obscureOld,
            onToggle: () => setState(() => _obscureOld = !_obscureOld),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your current password';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // New password
          _buildLabel('New Password'),
          const SizedBox(height: 6),
          _buildPasswordField(
            controller: _newPasswordController,
            hintText: 'Enter new password',
            obscure: _obscurNew,
            onToggle: () => setState(() => _obscurNew = !_obscurNew),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter a new password';
              return PasswordValidator.validate(v);
            },
          ),
          const SizedBox(height: 8),

          // Password requirements checklist
          _buildPasswordRequirements(),
          const SizedBox(height: 20),

          // Confirm password
          _buildLabel('Confirm New Password'),
          const SizedBox(height: 6),
          _buildPasswordField(
            controller: _confirmPasswordController,
            hintText: 'Re-enter new password',
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            validator: (v) {
              if (v != _newPasswordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                disabledBackgroundColor: primaryPurple.withOpacity(0.4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Update Password',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
        prefixIcon: Icon(Icons.lock_outlined, color: Colors.white38, size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.white38,
            size: 18,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: cardBg,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        errorStyle: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    final requirements = PasswordValidator.getRequirements(_newPasswordController.text);

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
}
