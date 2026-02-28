import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Notification preferences state
  bool _dailyReminders = true;
  bool _meditationReminders = true;
  bool _workoutReminders = false;
  bool _weeklyProgress = true;
  bool _newContent = true;
  bool _goalAlerts = true;
  bool _communityUpdates = false;

  TimeOfDay _morningReminderTime = const TimeOfDay(hour: 7, minute: 30);
  TimeOfDay _eveningReminderTime = const TimeOfDay(hour: 20, minute: 0);

  // Demo notifications data
  final List<_NotificationItem> _notifications = [
    _NotificationItem(
      icon: Icons.self_improvement_rounded,
      iconColor: Color(0xFF8B5CF6),
      title: 'Time to meditate ',
      body: 'Your daily 10-minute calm session is waiting for you.',
      time: '2 min ago',
      isRead: false,
      category: 'Meditation',
    ),
    _NotificationItem(
      icon: Icons.local_fire_department_rounded,
      iconColor: Color(0xFFFF6B35),
      title: '3-day streak! ',
      body: 'Keep it up! You\'ve meditated 3 days in a row.',
      time: '1 hr ago',
      isRead: false,
      category: 'Achievement',
    ),
    _NotificationItem(
      icon: Icons.fitness_center_rounded,
      iconColor: Color(0xFF4ECDC4),
      title: 'Workout reminder',
      body: 'Don\'t forget your afternoon movement session.',
      time: '3 hr ago',
      isRead: true,
      category: 'Workout',
    ),
    _NotificationItem(
      icon: Icons.star_rounded,
      iconColor: Color(0xFFFFB800),
      title: 'New content available ',
      body: 'Check out the new "Deep Sleep" audio series — perfect for tonight.',
      time: 'Yesterday',
      isRead: true,
      category: 'Content',
    ),
    _NotificationItem(
      icon: Icons.bar_chart_rounded,
      iconColor: Color(0xFF059669),
      title: 'Weekly Progress Report',
      body: 'You completed 5 of 7 wellness goals this week. Great work!',
      time: '2 days ago',
      isRead: true,
      category: 'Progress',
    ),
    _NotificationItem(
      icon: Icons.favorite_rounded,
      iconColor: Color(0xFFEC4899),
      title: 'Mindfulness tip',
      body: 'Try the 4-7-8 breathing technique to reduce stress instantly.',
      time: '3 days ago',
      isRead: true,
      category: 'Tip',
    ),
    _NotificationItem(
      icon: Icons.emoji_events_rounded,
      iconColor: Color(0xFFFFB800),
      title: 'Goal achieved! ',
      body: 'You\'ve completed your "Meditate 7 days" challenge.',
      time: '5 days ago',
      isRead: true,
      category: 'Achievement',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        final isVintage = themeState.isVintage;
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final primaryColor = ThemeColors.primary(mode);
        final borderColor = isVintage
            ? ThemeColors.vintageBorder
            : Colors.white.withOpacity(0.08);

        return Scaffold(
          backgroundColor: bgColor,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                backgroundColor: bgColor,
                elevation: 0,
                floating: true,
                pinned: true,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: textColor, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  'Notifications',
                  style: isVintage
                      ? GoogleFonts.playfairDisplay(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)
                      : GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        for (var n in _notifications) {
                          n.isRead = true;
                        }
                      });
                    },
                    child: Text(
                      'Mark all read',
                      style: GoogleFonts.lora(
                          color: primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  labelColor: isVintage ? Colors.black : Colors.white,
                  unselectedLabelColor: textSecondary,
                  indicatorColor: primaryColor,
                  indicatorWeight: 2,
                  labelStyle: GoogleFonts.lora(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  unselectedLabelStyle:
                      GoogleFonts.lora(fontSize: 14),
                  tabs: const [
                    Tab(text: 'Activity'),
                    Tab(text: 'Preferences'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildActivityTab(
                    bgColor, surfaceColor, textColor, textSecondary,
                    isVintage, borderColor),
                _buildPreferencesTab(
                    bgColor, surfaceColor, textColor, textSecondary,
                    isVintage, borderColor, primaryColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityTab(
    Color bgColor,
    Color surfaceColor,
    Color textColor,
    Color textSecondary,
    bool isVintage,
    Color borderColor,
  ) {
    final unread = _notifications.where((n) => !n.isRead).length;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (unread > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              'New ($unread)',
              style: GoogleFonts.lora(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5),
            ),
          ),
        ..._notifications.where((n) => !n.isRead).map((n) =>
            _buildNotificationTile(n, surfaceColor, textColor, textSecondary,
                isVintage, borderColor)),
        if (_notifications.any((n) => n.isRead))
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              'Earlier',
              style: GoogleFonts.lora(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5),
            ),
          ),
        ..._notifications.where((n) => n.isRead).map((n) =>
            _buildNotificationTile(n, surfaceColor, textColor, textSecondary,
                isVintage, borderColor)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildNotificationTile(
    _NotificationItem item,
    Color surfaceColor,
    Color textColor,
    Color textSecondary,
    bool isVintage,
    Color borderColor,
  ) {
    return GestureDetector(
      onTap: () => setState(() => item.isRead = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead
              ? surfaceColor
              : item.iconColor.withOpacity(isVintage ? 0.05 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead
                ? borderColor
                : item.iconColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.lora(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: item.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item.iconColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    style: GoogleFonts.lora(
                        color: textSecondary, fontSize: 12.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.time,
                    style: GoogleFonts.lora(
                        color: textSecondary.withOpacity(0.6),
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesTab(
    Color bgColor,
    Color surfaceColor,
    Color textColor,
    Color textSecondary,
    bool isVintage,
    Color borderColor,
    Color primaryColor,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // Reminder times
        _buildSectionHeader('Daily Reminders', textSecondary),
        const SizedBox(height: 8),
        _buildTimeCard(
          'Morning Reminder',
          'Start your day with mindfulness',
          Icons.wb_sunny_rounded,
          const Color(0xFFFFB800),
          _morningReminderTime,
          _dailyReminders,
          surfaceColor, textColor, textSecondary, borderColor, isVintage,
          onToggle: (v) => setState(() => _dailyReminders = v),
          onTapTime: () async {
            final t = await showTimePicker(
                context: context, initialTime: _morningReminderTime);
            if (t != null) setState(() => _morningReminderTime = t);
          },
        ),
        const SizedBox(height: 10),
        _buildTimeCard(
          'Evening Wind-Down',
          'Relax and reflect before bed',
          Icons.nightlight_round,
          const Color(0xFF8B5CF6),
          _eveningReminderTime,
          _meditationReminders,
          surfaceColor, textColor, textSecondary, borderColor, isVintage,
          onToggle: (v) => setState(() => _meditationReminders = v),
          onTapTime: () async {
            final t = await showTimePicker(
                context: context, initialTime: _eveningReminderTime);
            if (t != null) setState(() => _eveningReminderTime = t);
          },
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Activity Alerts', textSecondary),
        const SizedBox(height: 8),
        _buildToggleCard(
          'Workout Reminders',
          'Get reminded to move your body',
          Icons.fitness_center_rounded,
          const Color(0xFF4ECDC4),
          _workoutReminders,
          surfaceColor, textColor, textSecondary, borderColor, isVintage,
          onToggle: (v) => setState(() => _workoutReminders = v),
        ),
        const SizedBox(height: 10),
        _buildToggleCard(
          'Goal Alerts',
          'Stay on track with your wellness goals',
          Icons.flag_rounded,
          const Color(0xFF059669),
          _goalAlerts,
          surfaceColor, textColor, textSecondary, borderColor, isVintage,
          onToggle: (v) => setState(() => _goalAlerts = v),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Updates & Tips', textSecondary),
        const SizedBox(height: 8),
        _buildToggleCard(
          'Weekly Progress',
          'A summary of your weekly achievements',
          Icons.bar_chart_rounded,
          const Color(0xFFFF6B35),
          _weeklyProgress,
          surfaceColor, textColor, textSecondary, borderColor, isVintage,
          onToggle: (v) => setState(() => _weeklyProgress = v),
        ),
        const SizedBox(height: 10),
        _buildToggleCard(
          'New Content',
          'Be first to know about new meditations & videos',
          Icons.auto_awesome_rounded,
          const Color(0xFFEC4899),
          _newContent,
          surfaceColor, textColor, textSecondary, borderColor, isVintage,
          onToggle: (v) => setState(() => _newContent = v),
        ),
        const SizedBox(height: 10),
        _buildToggleCard(
          'Community Updates',
          'Challenges and community milestones',
          Icons.people_rounded,
          const Color(0xFF448AFF),
          _communityUpdates,
          surfaceColor, textColor, textSecondary, borderColor, isVintage,
          onToggle: (v) => setState(() => _communityUpdates = v),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color textSecondary) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.lora(
          color: textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2),
    );
  }

  Widget _buildTimeCard(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    TimeOfDay time,
    bool enabled,
    Color surfaceColor,
    Color textColor,
    Color textSecondary,
    Color borderColor,
    bool isVintage, {
    required ValueChanged<bool> onToggle,
    required VoidCallback onTapTime,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.lora(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: GoogleFonts.lora(
                            color: textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Switch.adaptive(
                value: enabled,
                onChanged: onToggle,
                activeColor: iconColor,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onTapTime,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Reminder time',
                        style: GoogleFonts.lora(
                            color: textSecondary, fontSize: 13)),
                    Text(
                      time.format(context),
                      style: GoogleFonts.lora(
                          color: iconColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleCard(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    bool enabled,
    Color surfaceColor,
    Color textColor,
    Color textSecondary,
    Color borderColor,
    bool isVintage, {
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.lora(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: GoogleFonts.lora(
                        color: textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onToggle,
            activeColor: iconColor,
          ),
        ],
      ),
    );
  }
}

class _NotificationItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
  bool isRead;
  final String category;

  _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.category,
  });
}
