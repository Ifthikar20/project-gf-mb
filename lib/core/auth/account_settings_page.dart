import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_bloc.dart';
import '../services/auth_service.dart';
import '../theme/theme_bloc.dart';
import '../theme/app_theme.dart';

/// Account Settings Page — modern hero-header profile design
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

  static const _accent = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
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

  // ─── Logic (unchanged) ─────────────────────────────────────────
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
      final updatedUser =
          await AuthService.instance.updateProfile(displayName: name);
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthUserChanged(updatedUser));
      setState(() {
        _isSavingName = false;
        _isEditingName = false;
        _successMessage = 'Name updated successfully';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _successMessage = null);
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSavingName = false;
        _nameError = e.message;
      });
    } catch (_) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text(
          'This action is permanent and cannot be undone. All your data will be lost.\n\nAre you sure?',
          style: GoogleFonts.inter(
              color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAccount();
            },
            child: Text('Delete Account',
                style: GoogleFonts.inter(
                    color: Colors.red, fontWeight: FontWeight.w600)),
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
      context.read<AuthBloc>().add(AuthLogoutRequested());
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to delete account. Please try again.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ─── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final dk = !themeState.isLight;
        final bg = ThemeColors.background(mode);
        final card = ThemeColors.surface(mode);
        final txt = ThemeColors.textPrimary(mode);
        final sub = ThemeColors.textSecondary(mode);
        final err = ThemeColors.error(mode);
        final bdr = dk
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06);

        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final user =
                authState is AuthAuthenticated ? authState.user : null;

            return Scaffold(
              backgroundColor: bg,
              body: user == null
                  ? Center(
                      child: Text('Please log in.',
                          style: TextStyle(color: sub)))
                  : CustomScrollView(
                      slivers: [
                        // ─── Hero header with image ──────────
                        SliverAppBar(
                          expandedHeight: 260,
                          pinned: true,
                          backgroundColor: bg,
                          leading: GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                          flexibleSpace: FlexibleSpaceBar(
                            background: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Background image
                                Image.asset(
                                  'assets/images/bk-1.png',
                                  fit: BoxFit.cover,
                                ),
                                // Gradient overlay
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        bg.withValues(alpha: 0.3),
                                        bg,
                                      ],
                                      stops: const [0.0, 0.6, 1.0],
                                    ),
                                  ),
                                ),
                                // Avatar + name overlay
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Column(
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: bg, width: 4),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF8B5CF6),
                                              Color(0xFFA78BFA),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _accent.withValues(alpha: 0.4),
                                              blurRadius: 20,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            (user.displayName
                                                        ?.isNotEmpty ==
                                                    true
                                                ? user.displayName![0]
                                                : user.email[0])
                                                .toUpperCase(),
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 36,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      // Name
                                      Text(
                                        user.displayName ??
                                            user.email.split('@')[0],
                                        style: GoogleFonts.inter(
                                          color: txt,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Email
                                      Text(user.email,
                                          style: GoogleFonts.inter(
                                              color: sub, fontSize: 13)),
                                      const SizedBox(height: 8),
                                      // Plan badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: user.isPremium
                                              ? Colors.amber
                                                  .withValues(alpha: 0.15)
                                              : card,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: user.isPremium
                                                ? Colors.amber
                                                    .withValues(alpha: 0.4)
                                                : bdr,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              user.isPremium
                                                  ? Icons.star_rounded
                                                  : Icons.star_border_rounded,
                                              size: 14,
                                              color: user.isPremium
                                                  ? Colors.amber
                                                  : sub,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${user.subscriptionTier[0].toUpperCase()}${user.subscriptionTier.substring(1)} Plan',
                                              style: GoogleFonts.inter(
                                                color: user.isPremium
                                                    ? Colors.amber
                                                    : sub,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ─── Body ────────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Success toast
                                if (_successMessage != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      border: Border.all(
                                          color: Colors.green
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Colors.green, size: 18),
                                        const SizedBox(width: 8),
                                        Text(_successMessage!,
                                            style: GoogleFonts.inter(
                                                color: Colors.green,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // ─── Settings list ─────────────
                                _tile(
                                  icon: Icons.person_outline_rounded,
                                  label: 'Display Name',
                                  value: user.displayName ?? 'Not set',
                                  trailing: _isEditingName
                                      ? null
                                      : _editButton(() => setState(
                                          () => _isEditingName = true)),
                                  card: card,
                                  bdr: bdr,
                                  txt: txt,
                                  sub: sub,
                                  expandedChild: _isEditingName
                                      ? _nameEditor(user, txt, sub, err)
                                      : null,
                                ),
                                const SizedBox(height: 10),

                                _tile(
                                  icon: Icons.email_outlined,
                                  label: 'Email',
                                  value: user.email,
                                  card: card,
                                  bdr: bdr,
                                  txt: txt,
                                  sub: sub,
                                ),
                                const SizedBox(height: 10),

                                _tile(
                                  icon: Icons.calendar_today_rounded,
                                  label: 'Member Since',
                                  value: _formatDate(user.createdAt),
                                  card: card,
                                  bdr: bdr,
                                  txt: txt,
                                  sub: sub,
                                ),
                                const SizedBox(height: 10),

                                _tile(
                                  icon: Icons.verified_outlined,
                                  label: 'Account Status',
                                  value:
                                      user.isActive ? 'Active' : 'Inactive',
                                  valueColor: user.isActive
                                      ? const Color(0xFF22C55E)
                                      : err,
                                  card: card,
                                  bdr: bdr,
                                  txt: txt,
                                  sub: sub,
                                ),
                                const SizedBox(height: 10),

                                _tile(
                                  icon: Icons.fingerprint_rounded,
                                  label: 'Account ID',
                                  value: user.id.length > 8
                                      ? '${user.id.substring(0, 8)}…'
                                      : user.id,
                                  card: card,
                                  bdr: bdr,
                                  txt: txt,
                                  sub: sub,
                                ),

                                const SizedBox(height: 36),

                                // ─── Danger zone ───────────────
                                Text('Danger Zone',
                                    style: GoogleFonts.inter(
                                        color: err,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: _isDeletingAccount
                                      ? null
                                      : _showDeleteConfirmation,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: err.withValues(alpha: 0.06),
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      border: Border.all(
                                          color:
                                              err.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_forever_rounded,
                                            color: err, size: 22),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Delete Account',
                                                  style: GoogleFonts.inter(
                                                      color: err,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Permanently remove your account and all data',
                                                style: GoogleFonts.inter(
                                                    color: err.withValues(
                                                        alpha: 0.6),
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (_isDeletingAccount)
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child:
                                                CircularProgressIndicator(
                                              color: err,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        else
                                          Icon(Icons.chevron_right_rounded,
                                              color: err.withValues(
                                                  alpha: 0.5),
                                              size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  // ─── Helper widgets ────────────────────────────────────────────

  Widget _tile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    Widget? trailing,
    Widget? expandedChild,
    required Color card,
    required Color bdr,
    required Color txt,
    required Color sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdr),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.inter(
                            color: sub,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: GoogleFonts.inter(
                          color: valueColor ?? txt,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          if (expandedChild != null) ...[
            const SizedBox(height: 12),
            expandedChild,
          ],
        ],
      ),
    );
  }

  Widget _editButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('Edit',
            style: GoogleFonts.inter(
                color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _nameEditor(dynamic user, Color txt, Color sub, Color err) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          autofocus: true,
          style: TextStyle(color: txt, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: sub.withValues(alpha: 0.5)),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (_nameError != null) ...[
          const SizedBox(height: 6),
          Text(_nameError!, style: TextStyle(color: err, fontSize: 11)),
        ],
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _isSavingName
                  ? null
                  : () {
                      _nameController.text = user.displayName ?? '';
                      setState(() {
                        _isEditingName = false;
                        _nameError = null;
                      });
                    },
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: sub, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSavingName ? null : _saveName,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                minimumSize: Size.zero,
              ),
              child: _isSavingName
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Save',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Unknown';
    try {
      final date = DateTime.parse(isoDate);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
