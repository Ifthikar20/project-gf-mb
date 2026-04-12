import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _mealReminders = true;
  bool _workoutReminders = true;
  bool _goalProgress = true;
  bool _weeklyReport = false;
  bool _newContent = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final box = await Hive.openBox('notification_prefs');
    if (mounted) {
      setState(() {
        _mealReminders = box.get('meal_reminders', defaultValue: true) as bool;
        _workoutReminders = box.get('workout_reminders', defaultValue: true) as bool;
        _goalProgress = box.get('goal_progress', defaultValue: true) as bool;
        _weeklyReport = box.get('weekly_report', defaultValue: false) as bool;
        _newContent = box.get('new_content', defaultValue: true) as bool;
      });
    }
  }

  Future<void> _save(String key, bool value) async {
    final box = await Hive.openBox('notification_prefs');
    await box.put(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final bg = ThemeColors.background(mode);
        final text = ThemeColors.textPrimary(mode);
        final subtle = ThemeColors.textSecondary(mode);
        final surface = ThemeColors.surface(mode);
        final border = themeState.isLight ? const Color(0xFFE8E8EC) : const Color(0xFF2A2A2A);
        final primary = ThemeColors.primary(mode);

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: text, size: 20), onPressed: () => Navigator.pop(context)),
            title: Text('Notifications', style: GoogleFonts.inter(color: text, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _section('Reminders', [
                _toggle('Meal reminders', 'Remind you to log meals', Icons.restaurant_rounded, _mealReminders, (v) {
                  setState(() => _mealReminders = v);
                  _save('meal_reminders', v);
                }, surface, text, subtle, border, primary),
                _toggle('Workout reminders', 'Encourage daily movement', Icons.fitness_center_rounded, _workoutReminders, (v) {
                  setState(() => _workoutReminders = v);
                  _save('workout_reminders', v);
                }, surface, text, subtle, border, primary),
              ], text),
              const SizedBox(height: 24),
              _section('Updates', [
                _toggle('Goal progress', 'Notify when goals are near completion', Icons.emoji_events_rounded, _goalProgress, (v) {
                  setState(() => _goalProgress = v);
                  _save('goal_progress', v);
                }, surface, text, subtle, border, primary),
                _toggle('Weekly report', 'Summary of your week every Sunday', Icons.bar_chart_rounded, _weeklyReport, (v) {
                  setState(() => _weeklyReport = v);
                  _save('weekly_report', v);
                }, surface, text, subtle, border, primary),
                _toggle('New content', 'When new videos or audio are added', Icons.new_releases_rounded, _newContent, (v) {
                  setState(() => _newContent = v);
                  _save('new_content', v);
                }, surface, text, subtle, border, primary),
              ], text),
            ],
          ),
        );
      },
    );
  }

  Widget _section(String title, List<Widget> children, Color text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _toggle(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged,
      Color surface, Color text, Color subtle, Color border, Color primary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: subtle, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: text)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: subtle)),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged, activeColor: primary),
        ],
      ),
    );
  }
}
