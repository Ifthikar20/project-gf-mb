# Suggestion Badge — Backend Integration Guide

## Overview

The **Suggestion Badge** is a context-aware system that shows actionable cards when the app needs user input. The backend collates all user data and returns a prioritized list of suggestions.

---

## API Endpoints

### Fetch Suggestions

```
GET /api/suggestions/
Authorization: Token <user_token>
```

**Response:**

```json
{
  "suggestions": [
    {
      "id": "daily_checkin",
      "type": "checkin",
      "priority": 1,
      "title": "Daily Check-In",
      "subtitle": "How are you feeling today?",
      "icon": "favorite",
      "color": "#F59E0B",
      "action_target": "/checkin",
      "reason": "You haven't checked in today",
      "expires_at": "2026-03-23T00:00:00Z"
    }
  ]
}
```

### Dismiss a Suggestion

```
POST /api/suggestions/dismiss/
Authorization: Token <user_token>

{ "suggestion_id": "morning_breathe_20260322" }
```

---

## Django Models

```python
class SuggestionRule(models.Model):
    """Admin-configurable rule that triggers a suggestion."""
    name        = models.CharField(max_length=100)     # "morning_breathing"
    title       = models.CharField(max_length=200)
    subtitle    = models.CharField(max_length=300)
    icon        = models.CharField(max_length=50)      # Flutter icon name
    color       = models.CharField(max_length=7)       # "#F97316"
    action_target = models.CharField(max_length=200)   # "/breathing-exercise"
    priority    = models.IntegerField(default=5)       # Lower = higher priority
    conditions  = models.JSONField(default=dict)       # Rule conditions (see below)
    is_active   = models.BooleanField(default=True)

class UserSuggestionDismissal(models.Model):
    """Tracks dismissed suggestions per user per day."""
    user          = models.ForeignKey('auth.User', on_delete=models.CASCADE)
    suggestion_id = models.CharField(max_length=200)
    dismissed_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'suggestion_id')
```

---

## Data Sources the Engine Reads

| Source | Model / Table | What It Checks |
|--------|--------------|----------------|
| **Check-Ins** | `WellnessCheckIn` | Did the user check in today? |
| **Workouts** | `WorkoutLog` | Logged today? Last intensity? Hours since last? |
| **Heart Rate** | `HealthData` | Any reading ≥ 120 BPM today? |
| **Water Intake** | `WaterLog` | Total ml today < 1000 after noon? |
| **Meals** | `MealLog` | Any food logged today? High caffeine? |
| **Dismissals** | `UserSuggestionDismissal` | Already dismissed this suggestion today? |
| **Time** | User's timezone | What time is it for the user? |

---

## Engine Logic

```python
# suggestions/engine.py

def get_suggestions(user) -> list[dict]:
    now = timezone.now()
    local_time = now.astimezone(ZoneInfo(user.profile.timezone or 'UTC'))
    hour = local_time.hour
    today = local_time.date()

    # 1. Load today's dismissals
    dismissed = set(
        UserSuggestionDismissal.objects
        .filter(user=user, dismissed_at__date=today)
        .values_list('suggestion_id', flat=True)
    )

    suggestions = []

    # 2. Check-In (if not done today)
    if not WellnessCheckIn.objects.filter(user=user, date=today).exists():
        if 'daily_checkin' not in dismissed:
            suggestions.append({
                'id': 'daily_checkin',
                'priority': 1,
                'title': 'Daily Check-In',
                'subtitle': 'How are you feeling today?',
                'icon': 'favorite',
                'color': '#F59E0B',
                'action_target': '/checkin',
            })

    # 3. Morning Breathing (5AM–10AM)
    if 5 <= hour < 10:
        bid = f'morning_breathe_{today}'
        if bid not in dismissed:
            suggestions.append({
                'id': bid,
                'priority': 2,
                'title': 'Morning Breathing',
                'subtitle': 'Start your day with calm focus',
                'icon': 'wb_sunny',
                'color': '#F97316',
                'action_target': '/breathing-exercise',
            })

    # 4. Night Breathing (8PM–12AM)
    if hour >= 20 or hour < 1:
        bid = f'night_breathe_{today}'
        if bid not in dismissed:
            suggestions.append({
                'id': bid,
                'priority': 2,
                'title': 'Night Breathing',
                'subtitle': 'Wind down before sleep',
                'icon': 'nightlight_round',
                'color': '#8B5CF6',
                'action_target': '/breathing-exercise',
            })

    # 5. High Heart Rate → Calm Breathing
    high_hr = HealthData.objects.filter(
        user=user, metric='heart_rate',
        value__gte=120, timestamp__date=today
    ).exists()

    if high_hr and f'calm_breathe_{today}' not in dismissed:
        suggestions.append({
            'id': f'calm_breathe_{today}',
            'priority': 1,
            'title': 'Calm Breathing',
            'subtitle': 'High heart rate detected — take a moment',
            'icon': 'air',
            'color': '#EF4444',
            'action_target': '/breathing-exercise',
        })

    # 6. Log Workout (if not done today)
    if not WorkoutLog.objects.filter(user=user, date=today).exists():
        if 'workout' not in dismissed:
            suggestions.append({
                'id': 'workout',
                'priority': 3,
                'title': 'Log Workout',
                'subtitle': 'No workout logged today',
                'icon': 'fitness_center',
                'color': '#22C55E',
                'action_target': '/workout',
            })

    # 7. Post-Workout Recovery
    last = WorkoutLog.objects.filter(user=user).order_by('-timestamp').first()
    if last:
        hrs = (now - last.timestamp).total_seconds() / 3600
        if 12 < hrs < 48 and last.intensity == 'high':
            rid = f'recovery_{last.id}'
            if rid not in dismissed:
                suggestions.append({
                    'id': rid,
                    'priority': 3,
                    'title': 'Recovery Stretch',
                    'subtitle': f'Recover after {last.name}',
                    'icon': 'self_improvement',
                    'color': '#06B6D4',
                    'action_target': '/breathing-exercise',
                })

    # 8. Hydration (low water after noon)
    water = WaterLog.objects.filter(
        user=user, date=today
    ).aggregate(total=Sum('ml'))['total'] or 0

    if water < 1000 and hour >= 12 and 'hydration' not in dismissed:
        suggestions.append({
            'id': 'hydration',
            'priority': 2,
            'title': 'Stay Hydrated',
            'subtitle': f'Only {water}ml — aim for 2000ml',
            'icon': 'water_drop',
            'color': '#3B82F6',
            'action_target': '/water',
        })

    suggestions.sort(key=lambda s: s['priority'])
    return suggestions
```

---

## Data Flow

```
App opens → GET /api/suggestions/
                  ↓
          Suggestion Engine
                  ↓
    ┌─────────────────────────────┐
    │ Read check-ins    (today?)  │
    │ Read workouts  (today/last) │
    │ Read heart rate  (≥120?)    │
    │ Read water log   (<1L?)     │
    │ Read meals       (logged?)  │
    │ Read dismissals  (today)    │
    │ Read user timezone + clock  │
    └─────────────────────────────┘
                  ↓
    Filter dismissed → Sort by priority
                  ↓
    Return JSON → App caches in Hive
                  ↓
    User taps → Navigate + POST dismiss
```

---

## When Each Suggestion Shows

| Time Window | Possible Suggestions |
|-------------|---------------------|
| 5AM – 10AM | Morning breathing, check-in, workout |
| 10AM – 8PM | Check-in, workout, hydration, recovery |
| 8PM – 12AM | Night breathing, check-in |
| Any time | Calm breathing (if high HR), recovery (12–48h post-workout) |

---

## Frontend Integration

The Flutter `SuggestionBadge` widget at:
```
lib/features/wellness_goals/presentation/widgets/suggestion_badge.dart
```

Currently runs locally. To switch to backend-powered:

1. Call `GET /api/suggestions/` on app open
2. Cache response in Hive for offline access
3. On dismiss/complete → `POST /api/suggestions/dismiss/`
4. On pull-to-refresh → re-fetch from backend
