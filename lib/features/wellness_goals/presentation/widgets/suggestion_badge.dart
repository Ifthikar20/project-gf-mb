import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/config/secure_config.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../workouts/presentation/pages/workout_check_page.dart';
import '../../data/models/wellness_checkin_model.dart';
import '../pages/wellness_checkin_page.dart';

/// Suggestion Badge — circular icon row, backend-driven.
/// Shows only icons the backend suggests, hides when nothing is pending.
class SuggestionBadge extends StatefulWidget {
  const SuggestionBadge({super.key});

  @override
  State<SuggestionBadge> createState() => SuggestionBadgeState();
}

class SuggestionBadgeState extends State<SuggestionBadge> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void refresh() => _load();

  String get _todayKey {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  // ── Load ──

  Future<void> _load() async {
    // Try backend first
    try {
      final api = ApiClient.instance;
      if (api.hasToken) {
        final res = await api.get('/api/suggestions/');
        if (res.statusCode == 200) {
          final data = res.data as Map<String, dynamic>;
          final list = (data['suggestions'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              [];
          final box = await Hive.openBox('smart_suggestions', encryptionCipher: HiveAesCipher(await SecureConfig.getHiveEncryptionKey()));
          await box.put('cached', jsonEncode(list));
          if (mounted) setState(() { _suggestions = list; _loading = false; });
          return;
        }
      }
    } catch (_) {}

    // Offline: cache → local fallback
    await _loadCached();
    if (_suggestions.isEmpty) await _evaluateLocal();
  }

  Future<void> _loadCached() async {
    try {
      final box = await Hive.openBox('smart_suggestions', encryptionCipher: HiveAesCipher(await SecureConfig.getHiveEncryptionKey()));
      final raw = box.get('cached') as String?;
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final now = DateTime.now();
        list.removeWhere((s) {
          final exp = s['expires_at'] as String?;
          if (exp == null) return false;
          try { return DateTime.parse(exp).isBefore(now); } catch (_) { return false; }
        });
        if (mounted) setState(() { _suggestions = list; _loading = false; });
      }
    } catch (_) {}
  }

  Future<void> _evaluateLocal() async {
    final s = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final h = now.hour;

    try {
      final box = await Hive.openBox('smart_suggestions', encryptionCipher: HiveAesCipher(await SecureConfig.getHiveEncryptionKey()));

      // Check-in
      final keyList = await SecureConfig.instance.getEncryptionKey();
      final cipher = HiveAesCipher(Uint8List.fromList(keyList));
      final ci = await Hive.openBox<WellnessCheckInModel>('wellness_checkins',
          encryptionCipher: cipher);
      if (ci.get(_todayKey) == null) {
        s.add({'id':'daily_checkin','type':'checkin','priority':1,'title':'Check In','icon':'favorite','color':'#F59E0B','action_target':'/checkin','subtitle':'How are you feeling today?','reason':"You haven't checked in today"});
      }

      // Morning breathing
      if (h >= 5 && h < 10 && box.get('morning_breathe_$_todayKey') != true) {
        s.add({'id':'morning_breathe_$_todayKey','type':'breathing','priority':2,'title':'Breathe','icon':'wb_sunny','color':'#F97316','action_target':'/breathing-exercise','subtitle':'Start your day with calm focus','reason':'Morning breathing practice'});
      }

      // Night breathing
      if ((h >= 20 || h < 1) && box.get('night_breathe_$_todayKey') != true) {
        s.add({'id':'night_breathe_$_todayKey','type':'breathing','priority':2,'title':'Breathe','icon':'nightlight_round','color':'#8B5CF6','action_target':'/breathing-exercise','subtitle':'Wind down before sleep','reason':'Evening breathing practice'});
      }

      // High HR
      final fb = await Hive.openBox('workout_feedback', encryptionCipher: HiveAesCipher(await SecureConfig.getHiveEncryptionKey()));
      if (fb.get('high_heart_rate_today') == true && box.get('calm_breathe_$_todayKey') != true) {
        s.add({'id':'calm_breathe_$_todayKey','type':'breathing','priority':1,'title':'Calm','icon':'air','color':'#EF4444','action_target':'/breathing-exercise','subtitle':'High heart rate detected','reason':'Take a moment to breathe'});
      }

      // Workout
      final ld = fb.get('last_workout_date') as String?;
      bool wt = false;
      if (ld != null) { try { final d = DateTime.parse(ld); wt = d.year==now.year&&d.month==now.month&&d.day==now.day; } catch (_) {} }
      if (!wt) {
        s.add({'id':'workout','type':'workout','priority':3,'title':'Workout','icon':'fitness_center','color':'#22C55E','action_target':'/workout','subtitle':'No workout logged today','reason':'Stay consistent'});
      }
    } catch (_) {}

    s.sort((a, b) => (a['priority'] as int? ?? 5).compareTo(b['priority'] as int? ?? 5));
    if (mounted) setState(() { _suggestions = s; _loading = false; });
  }

  // ── Dismiss ──

  Future<void> _dismiss(String id) async {
    setState(() => _suggestions.removeWhere((s) => s['id'] == id));
    try {
      final box = await Hive.openBox('smart_suggestions', encryptionCipher: HiveAesCipher(await SecureConfig.getHiveEncryptionKey()));
      await box.put(id, true);
      final raw = box.get('cached') as String?;
      if (raw != null) {
        final list = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        list.removeWhere((s) => s['id'] == id);
        await box.put('cached', jsonEncode(list));
      }
    } catch (_) {}
    try { if (ApiClient.instance.hasToken) ApiClient.instance.post('/api/suggestions/dismiss/', data: {'suggestion_id': id}); } catch (_) {}
  }

  // ── Tap: navigate ──

  void _onTap(Map<String, dynamic> s) {
    final target = s['action_target'] as String? ?? '';
    final id = s['id'] as String? ?? '';
    if (target == '/checkin') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WellnessCheckInPage())).then((_) => refresh());
      return;
    }
    if (target == '/workout') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkoutCheckPage())).then((_) => refresh());
      return;
    }
    if (target == '/breathing-exercise') { _dismiss(id); context.push(AppRouter.breathingExercise); return; }
    if (target.isNotEmpty) { _dismiss(id); context.push(target); }
  }

  // ── Long-press: detail sheet ──

  void _showDetail(Map<String, dynamic> s) {
    final dk = Theme.of(context).brightness == Brightness.dark;
    final c = _parseColor(s['color'] as String? ?? '#8B5CF6');

    showModalBottomSheet(
      context: context,
      backgroundColor: dk ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.withValues(alpha: dk ? 0.15 : 0.08),
              ),
              child: Icon(_mapIcon(s['icon'] as String? ?? ''), color: c, size: 28),
            ),
            const SizedBox(height: 14),
            Text(s['title'] as String? ?? '',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700,
                    color: dk ? Colors.white : Colors.black)),
            const SizedBox(height: 4),
            Text(s['subtitle'] as String? ?? '',
                style: GoogleFonts.inter(fontSize: 14, color: dk ? Colors.white54 : Colors.black45),
                textAlign: TextAlign.center),
            if ((s['reason'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(s['reason'] as String,
                  style: GoogleFonts.inter(fontSize: 12, color: dk ? Colors.white30 : Colors.black26),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); _onTap(s); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: c,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('Let\'s go', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  static IconData _mapIcon(String name) {
    const m = {
      'favorite': Icons.favorite_rounded,
      'wb_sunny': Icons.wb_sunny_rounded,
      'nightlight_round': Icons.nightlight_round,
      'air': Icons.air_rounded,
      'fitness_center': Icons.fitness_center_rounded,
      'self_improvement': Icons.self_improvement_rounded,
      'water_drop': Icons.water_drop_rounded,
      'restaurant': Icons.restaurant_rounded,
      'local_fire_department': Icons.local_fire_department_rounded,
    };
    return m[name] ?? Icons.auto_awesome_rounded;
  }

  static Color _parseColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); }
    catch (_) { return const Color(0xFF8B5CF6); }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    if (_loading || _suggestions.isEmpty) return const SizedBox.shrink();

    final dk = Theme.of(context).brightness == Brightness.dark;
    final labelColor = dk ? Colors.white70 : Colors.black54;

    return SizedBox(
      height: 86,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _suggestions.length,
        itemBuilder: (context, i) {
          final s = _suggestions[i];
          final icon = _mapIcon(s['icon'] as String? ?? '');
          final color = _parseColor(s['color'] as String? ?? '#8B5CF6');
          final label = s['title'] as String? ?? '';
          final priority = s['priority'] as int? ?? 5;
          final isUrgent = priority == 1;

          return GestureDetector(
            onTap: () => _onTap(s),
            onLongPress: () => _showDetail(s),
            child: Container(
              width: 62,
              margin: const EdgeInsets.only(right: 6),
              child: Column(
                children: [
                  // Circle icon
                  Container(
                    width: isUrgent ? 54 : 52,
                    height: isUrgent ? 54 : 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: dk ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withValues(alpha: isUrgent ? 0.35 : 0.12),
                        width: isUrgent ? 1.5 : 1.0,
                      ),
                    ),
                    child: Icon(icon, color: color, size: isUrgent ? 28 : 26),
                  ),
                  const SizedBox(height: 8),
                  // Label
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: labelColor,
                      fontSize: 11,
                      fontWeight: isUrgent ? FontWeight.w600 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
