import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_bloc.dart';
import '../services/auth_service.dart';
import '../theme/theme_bloc.dart';
import '../theme/app_theme.dart';

/// Account Settings Page
/// Allows users to edit their display name, view account info,
/// and delete their account with confirmation
class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isSavingName = false;
  bool _isDeletingAccount = false;
  String? _nameError;
  String? _successMessage;

  // Theme colors
  static const Color primaryPurple = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    // Pre-fill with current user's name
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _nameController.text = authState.user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Name cannot be empty');
      return;
    }

    setState(() {
      _isSavingName = true;
      _nameError = null;
      _successMessage = null;
    });

    try {
      final updatedUser = await AuthService.instance.updateProfile(
        displayName: name,
      );

      if (!mounted) return;

      // Update auth state with new user data
      context.read<AuthBloc>().add(AuthUserChanged(updatedUser));

      setState(() {
        _isSavingName = false;
        _isEditingName = false;
        _successMessage = 'Name updated successfully';
      });

      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _successMessage = null);
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSavingName = false;
        _nameError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSavingName = false;
        _nameError = 'Failed to update name. Please try again.';
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Account',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This action is permanent and cannot be undone. All your data, preferences, and watch history will be lost.\n\nAre you sure you want to delete your account?',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAccount();
            },
            child: Text(
              'Delete Account',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeletingAccount = true);

    try {
      await AuthService.instance.deleteAccount();

      if (!mounted) return;

      // Trigger logout in auth bloc (clears state)
      context.read<AuthBloc>().add(AuthLogoutRequested());
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete account. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isVintage = themeState.isVintage;
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final errorColor = ThemeColors.error(mode);

        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final user = authState is AuthAuthenticated ? authState.user : null;

            return Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: bgColor,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  'Account',
                  style: isVintage
                      ? GoogleFonts.playfairDisplay(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        )
                      : GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                ),
                centerTitle: true,
              ),
              body: user == null
                  ? Center(
                      child: Text(
                        'Please log in to view account settings.',
                        style: TextStyle(color: textSecondary),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Success message
                          if (_successMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _successMessage!,
                                    style: GoogleFonts.inter(
                                      color: Colors.green,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // ─── Profile Avatar ─────────────────────
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryPurple,
                                        primaryPurple.withOpacity(0.6),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (user.displayName?.isNotEmpty == true
                                              ? user.displayName![0]
                                              : user.email[0])
                                          .toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Subscription badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: user.isPremium
                                        ? Colors.amber.withOpacity(0.15)
                                        : surfaceColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: user.isPremium
                                          ? Colors.amber.withOpacity(0.4)
                                          : textSecondary.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        user.isPremium
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 14,
                                        color: user.isPremium
                                            ? Colors.amber
                                            : textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        user.subscriptionTier
                                                .substring(0, 1)
                                                .toUpperCase() +
                                            user.subscriptionTier.substring(1) +
                                            ' Plan',
                                        style: GoogleFonts.inter(
                                          color: user.isPremium
                                              ? Colors.amber
                                              : textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ─── Display Name Section ───────────────
                          _buildSectionHeader('Display Name', textColor, isVintage),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isEditingName
                                    ? primaryPurple.withOpacity(0.5)
                                    : textSecondary.withOpacity(0.15),
                              ),
                            ),
                            child: _isEditingName
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        controller: _nameController,
                                        autofocus: true,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 15,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Enter your name',
                                          hintStyle: TextStyle(
                                            color: textSecondary.withOpacity(0.5),
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                      if (_nameError != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          _nameError!,
                                          style: TextStyle(
                                            color: errorColor,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: _isSavingName
                                                ? null
                                                : () {
                                                    _nameController.text =
                                                        user.displayName ?? '';
                                                    setState(() {
                                                      _isEditingName = false;
                                                      _nameError = null;
                                                    });
                                                  },
                                            child: Text(
                                              'Cancel',
                                              style: GoogleFonts.inter(
                                                color: textSecondary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed:
                                                _isSavingName ? null : _saveName,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryPurple,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 10,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              elevation: 0,
                                              minimumSize: Size.zero,
                                            ),
                                            child: _isSavingName
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : Text(
                                                    'Save',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user.displayName ?? 'Not set',
                                          style: TextStyle(
                                            color: user.displayName != null
                                                ? textColor
                                                : textSecondary,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            setState(() => _isEditingName = true),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primaryPurple.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            'Edit',
                                            style: GoogleFonts.inter(
                                              color: primaryPurple,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 24),

                          // ─── Email Section ─────────────────────
                          _buildSectionHeader('Email', textColor, isVintage),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: textSecondary.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  color: textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  user.email,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ─── Account Info ──────────────────────
                          _buildSectionHeader(
                              'Account Info', textColor, isVintage),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: textSecondary.withOpacity(0.15),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  'Member Since',
                                  _formatDate(user.createdAt),
                                  textColor,
                                  textSecondary,
                                ),
                                Divider(
                                  color: textSecondary.withOpacity(0.1),
                                  height: 24,
                                ),
                                _buildInfoRow(
                                  'Account Status',
                                  user.isActive ? 'Active' : 'Inactive',
                                  textColor,
                                  user.isActive ? Colors.green : errorColor,
                                ),
                                Divider(
                                  color: textSecondary.withOpacity(0.1),
                                  height: 24,
                                ),
                                _buildInfoRow(
                                  'Account ID',
                                  user.id.length > 8
                                      ? '${user.id.substring(0, 8)}…'
                                      : user.id,
                                  textColor,
                                  textSecondary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // ─── Danger Zone ───────────────────────
                          _buildSectionHeader(
                              'Danger Zone', errorColor, isVintage),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap:
                                _isDeletingAccount ? null : _showDeleteConfirmation,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: errorColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: errorColor.withOpacity(0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_forever,
                                    color: errorColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Delete Account',
                                          style: TextStyle(
                                            color: errorColor,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Permanently remove your account and all data',
                                          style: TextStyle(
                                            color: errorColor.withOpacity(0.7),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_isDeletingAccount)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: errorColor,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.chevron_right,
                                      color: errorColor.withOpacity(0.5),
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color color, bool isVintage) {
    return Text(
      title,
      style: isVintage
          ? GoogleFonts.playfairDisplay(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            )
          : GoogleFonts.poppins(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: labelColor.withOpacity(0.7), fontSize: 13),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Unknown';
    try {
      final date = DateTime.parse(isoDate);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
