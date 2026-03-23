# Suggestion Badge — Flutter Integration Guide

## Overview

The suggestion badges appear as a **horizontal icon row** on the home page — just like the existing quick-action icons, but **only showing what the backend suggests** instead of hardcoding all icons.

```
Before (hardcoded):       After (backend-driven):
┌──┬──┬──┬──┬──┬──┐       ┌──┬──┬──┐
│❤️│☀️│💪│🧘│💧│🍽│       │❤️│💪│🍽│  ← only 3 shown today
└──┴──┴──┴──┴──┴──┘       └──┴──┴──┘
  Always 6 icons            Only what's relevant
```

## API Endpoints

```
GET  /api/suggestions/           → Fetch suggestions for current user
POST /api/suggestions/dismiss/   → Dismiss a suggestion
```

## Flutter Widget: `SuggestionBadge`

**File:** `lib/features/wellness_goals/presentation/widgets/suggestion_badge.dart`

### How it works:

1. **App opens** → `GET /api/suggestions/` → cache in Hive → show icons
2. **Offline** → load from Hive cache → if empty, evaluate locally
3. **Tap icon** → navigate to `action_target` → auto-dismiss
4. **Long-press icon** → bottom sheet with subtitle + reason + "Let's go" button
5. **All done** → row hidden (`SizedBox.shrink()`)

### Icon & Color Mapping

Icons and colors come as strings from the API and are parsed in the widget:

```dart
IconData _mapIcon(String name) → Maps 'favorite' → Icons.favorite_rounded
Color _parseColor(String hex) → Parses '#F59E0B' → Color(0xFFF59E0B)
```

### Priority Styling

| Priority | Style |
|----------|-------|
| 1 (urgent) | 54×54 icon, bold border, bold label |
| 2-3 (normal) | 52×52 icon, subtle border |

### What Shows When

| Time | Possible Icons |
|------|---------------|
| 5AM–10AM | ❤️ Check-In, ☀️ Morning Breathe, 💪 Workout |
| 10AM–8PM | ❤️ Check-In, 💪 Workout, 💧 Hydration, 🍽 Scan Meal |
| 8PM–12AM | ❤️ Check-In, 🌙 Night Breathe |
| After workout | 🧘 Recovery Stretch |
| High HR | ❗ Calm Breathing (priority 1) |

### Offline Behavior

```
App opens (online)  → GET /api/suggestions/ → cache in Hive → show icons
App opens (offline) → load from Hive cache  → show cached icons
Dismiss (online)    → remove icon + POST dismiss
Dismiss (offline)   → remove icon + store in Hive
```

### Date-Scoped IDs

Some IDs include the date (e.g., `morning_breathe_2026-03-22`):
- Dismissing hides it **today only**
- Reappears **tomorrow** with a new ID
- IDs without dates (e.g., `daily_checkin`) reset daily on backend
