import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/coaching_service.dart';
import '../bloc/coaching_bloc.dart';

class CoachingSessionsPage extends StatefulWidget {
  const CoachingSessionsPage({super.key});

  @override
  State<CoachingSessionsPage> createState() => _CoachingSessionsPageState();
}

class _CoachingSessionsPageState extends State<CoachingSessionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<CoachingBloc>().add(const LoadSessions());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isLight = themeState.isLight;
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final primaryColor = ThemeColors.primary(mode);
        final borderColor = ThemeColors.border(mode);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'My Sessions',
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: primaryColor,
              indicatorWeight: 2,
              labelColor: textColor,
              unselectedLabelColor: textSecondary,
              labelStyle: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
            ),
          ),
          body: BlocConsumer<CoachingBloc, CoachingState>(
            listener: (context, state) {
              if (state is CoachingSessionCancelled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Session cancelled. Refund: \$${state.refundAmount}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                context.read<CoachingBloc>().add(const LoadSessions());
              }
              if (state is CoachingSessionJoined) {
                // In a real app, navigate to LiveKit video room
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Video session ready (LiveKit integration required)'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              if (state is CoachingError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is CoachingLoading) {
                return Center(
                  child: CircularProgressIndicator(
                      color: primaryColor, strokeWidth: 2),
                );
              }
              if (state is CoachingSessionsLoaded) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSessionList(
                      sessions: state.upcoming,
                      emptyMessage: 'No upcoming sessions',
                      emptyIcon: Icons.event_available_outlined,
                      isLight: isLight,
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      textSecondary: textSecondary,
                      primaryColor: primaryColor,
                      borderColor: borderColor,
                    ),
                    _buildSessionList(
                      sessions: state.past,
                      emptyMessage: 'No past sessions',
                      emptyIcon: Icons.history,
                      isLight: isLight,
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      textSecondary: textSecondary,
                      primaryColor: primaryColor,
                      borderColor: borderColor,
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildSessionList({
    required List<CoachingSession> sessions,
    required String emptyMessage,
    required IconData emptyIcon,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color primaryColor,
    required Color borderColor,
  }) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, color: textSecondary, size: 48),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style:
                    GoogleFonts.inter(color: textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: sessions.length,
      itemBuilder: (context, index) => _buildSessionCard(
        session: sessions[index],
        isLight: isLight,
        surfaceColor: surfaceColor,
        textColor: textColor,
        textSecondary: textSecondary,
        primaryColor: primaryColor,
        borderColor: borderColor,
      ),
    );
  }

  Widget _buildSessionCard({
    required CoachingSession session,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color primaryColor,
    required Color borderColor,
  }) {
    final scheduledDt = session.scheduledDateTime;
    final dateStr = scheduledDt != null
        ? DateFormat('MMM d, yyyy').format(scheduledDt)
        : 'TBD';
    final timeStr = scheduledDt != null
        ? DateFormat('h:mm a').format(scheduledDt)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coach + status
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primaryColor.withOpacity(0.15),
                backgroundImage: session.coach?.avatarUrl != null
                    ? CachedNetworkImageProvider(session.coach!.avatarUrl!)
                    : null,
                child: session.coach?.avatarUrl == null
                    ? Text(
                        (session.coach?.name ?? 'C')[0],
                        style: GoogleFonts.inter(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  session.coach?.name ?? 'Coach',
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildStatusBadge(session.status, primaryColor),
            ],
          ),
          const SizedBox(height: 12),
          // Date / time / duration
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  color: textSecondary, size: 14),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: GoogleFonts.inter(color: textSecondary, fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, color: textSecondary, size: 14),
              const SizedBox(width: 6),
              Text(
                '$timeStr (${session.durationMinutes} min)',
                style: GoogleFonts.inter(color: textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Amount
          Row(
            children: [
              Text(
                '\$${session.amount}',
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (session.discountApplied) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Discount applied',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF22C55E),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Action buttons
          const SizedBox(height: 12),
          _buildActionButton(session, primaryColor, textColor, textSecondary),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color primaryColor) {
    Color badgeColor;
    String label;
    switch (status) {
      case 'pending_payment':
        badgeColor = Colors.orange;
        label = 'Payment Needed';
        break;
      case 'confirmed':
        badgeColor = const Color(0xFF22C55E);
        label = 'Confirmed';
        break;
      case 'in_progress':
        badgeColor = primaryColor;
        label = 'In Progress';
        break;
      case 'completed':
        badgeColor = Colors.grey;
        label = 'Completed';
        break;
      case 'cancelled_by_client':
      case 'cancelled_by_coach':
        badgeColor = Colors.red;
        label = status == 'cancelled_by_coach' ? 'Coach Cancelled' : 'Cancelled';
        break;
      case 'no_show':
        badgeColor = Colors.red.shade300;
        label = 'Missed';
        break;
      default:
        badgeColor = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    CoachingSession session,
    Color primaryColor,
    Color textColor,
    Color textSecondary,
  ) {
    switch (session.status) {
      case 'in_progress':
        return _actionButton(
          label: 'Join Video',
          icon: Icons.videocam_outlined,
          color: primaryColor,
          onTap: () => context
              .read<CoachingBloc>()
              .add(JoinSession(sessionId: session.id)),
        );
      case 'confirmed':
        return Row(
          children: [
            Expanded(
              child: _actionButton(
                label: 'Cancel',
                icon: Icons.close,
                color: Colors.red,
                onTap: () => _showCancelDialog(session),
              ),
            ),
          ],
        );
      case 'pending_payment':
        return _actionButton(
          label: 'Complete Payment',
          icon: Icons.payment_outlined,
          color: Colors.orange,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment flow (Stripe integration)'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(CoachingSession session) {
    final hoursUntil = session.scheduledDateTime != null
        ? session.scheduledDateTime!.difference(DateTime.now()).inHours
        : 0;

    String refundText;
    if (hoursUntil >= 24) {
      refundText = 'You will receive a full refund.';
    } else if (hoursUntil >= 2) {
      refundText = 'You will receive a 50% refund.';
    } else {
      refundText = 'No refund available (less than 2 hours before session).';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Session?'),
        content: Text(
          'Are you sure you want to cancel this session?\n\n$refundText',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<CoachingBloc>()
                  .add(CancelSession(sessionId: session.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Session'),
          ),
        ],
      ),
    );
  }
}
