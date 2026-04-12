# Health Data Architecture — Great Feel App

## Core Principle

**All health data stays on the device. Nothing is sent to the backend.**

Food scan images are uploaded to the backend for AI analysis, but personal health metrics (steps, heart rate, sleep, etc.) are read from Apple Health and cached locally in an encrypted Hive box. They never leave the phone.

---

## What We Track

| Data | Source | Requires Watch? | Stored |
|------|--------|:-:|--------|
| Steps | iPhone + Watch | No | Local (Hive) |
| Active Calories Burned | iPhone + Watch | No | Local (Hive) |
| Heart Rate (live) | Watch only | Yes | Local (Hive) |
| Resting Heart Rate | Watch only | Yes | Local (Hive) |
| Heart Rate Variability (HRV) | Watch only | Yes | Local (Hive) |
| Sleep (hours, quality) | iPhone + Watch | No | Local (Hive) |
| Walking/Running Distance | iPhone + Watch | No | Local (Hive) |
| Flights Climbed | iPhone | No | Local (Hive) |
| Workouts (type, duration) | Watch | Yes | Local (Hive) |
| Calories Consumed (meals) | Food scanner / manual | No | Local (Hive) |
| Food Scan Images | Camera | No | Backend (S3) |

---

## Data Flow

```
Apple Watch / iPhone Sensors
        |
        v
   Apple HealthKit (on-device database)
        |
        v  (read-only via health package)
   HealthKitService
        |
        ├── getStepCount()
        ├── getHeartRateData()
        ├── getSleepMinutes()
        ├── getRestingHeartRate()
        ├── getHRV()
        ├── getDistanceMeters()
        ├── getFlightsClimbed()
        ├── getWorkoutSummaries()
        └── estimateCaloriesFromSteps()
        |
        v
   Hive Encrypted Cache ('health_data' box)
        |
        ├── Home Card (steps, eaten, burned, sleep, distance)
        ├── Health Detail Page (all metrics + graphs)
        └── Workouts Tab (graphs, heart rate card)

   NEVER uploaded to backend
```

---

## Where Each Metric Appears

### Home Page — Wellness Stats Card
Compact card showing today's key numbers. **Tappable** to open full Health Detail page.

| Metric | Display |
|--------|---------|
| Steps | `3.2k Steps` |
| Calories Eaten | `210 Eaten` |
| Calories Burned | `85 Burned` |
| Sleep | `7h 23m Sleep` (if available) |
| Distance | `4.2km Distance` (if available) |
| Net Balance | Bar chart showing eaten vs burned |
| Insight | Actionable tip (e.g. "A 25min walk would cover it") |

### Health Detail Page (tap card to open)
Full-page view with all metrics, graphs, and analysis.

| Section | Contents |
|---------|----------|
| Today's Activity | Steps, Burned, Sleep, Distance, Flights, Eaten — 6-tile grid |
| Heart Health | Resting HR, HRV, Stress level |
| Live Heart Rate | Real-time BPM from Watch (or simulated) |
| Performance | Weekly bar chart, effort ring, HR trend line |
| Privacy Note | "All health data stays on your device" |

### Workouts Tab (Hub Page)
Health Overview card + workout graphs + heart rate monitor + workout history.

---

## Calorie Calculations

### Calories Burned (3-tier fallback)

| Priority | Source | Accuracy |
|----------|--------|----------|
| 1 | Apple Watch `ACTIVE_ENERGY_BURNED` | Highest (uses real HR) |
| 2 | Estimated from steps: `MET(3.5) x weight x (steps/100/60)` | Medium |
| 3 | Backend weekly average / 7 | Low |

### Calories Consumed
Stored locally in Hive (`diet_logs` encrypted box). Sources:
- AI food scanner (image → Gemini Vision → calorie estimate)
- Barcode scanner (product lookup)
- Manual entry

### Net Balance
```
Net = Calories Eaten - Calories Burned
Surplus (positive) → shown in red with exercise suggestion
Deficit (negative) → shown in green with congratulation
```

---

## Apple Health Permission Flow

1. User taps **Connect** on Home card or Workouts tab
2. App calls `Health().configure()` then `Health().requestAuthorization()`
3. iOS shows HealthKit permission dialog (user must turn ON all toggles)
4. On success: read data, cache in Hive, display
5. On failure: show error with link to Settings > Health > Data Access

**Important:** iOS only shows the permission dialog once. If denied, user must go to Settings manually. The `CODE_SIGN_ENTITLEMENTS` must reference `Runner.entitlements` in the Xcode project for HealthKit to work.

---

## Local Storage

| Box Name | Contents | Encrypted |
|----------|----------|:-:|
| `healthkit_prefs` | `authorized`, `enabled` flags | No |
| `health_data` | Steps, HR, sleep, distance, flights, workouts, effort score | No |
| `diet_logs` | Meal logs (calories, macros, images) | Yes (AES) |
| `diet_prefs` | Calorie goal | No |

---

## Backend — What It Does NOT Store

The backend never receives or stores:
- Steps
- Heart rate (resting, live, or HRV)
- Sleep data
- Distance walked
- Flights climbed
- Workout data from Apple Health
- Meal logs (stored locally only)

The backend only handles:
- Food scan image analysis (Gemini Vision)
- Manual workout logging and calorie estimation (MET formula)
- Workout types reference data
- User body profile (weight/height for calorie calculation)

---

## Key Files

| File | Purpose |
|------|---------|
| `lib/core/services/healthkit_service.dart` | All HealthKit reads, caching, permissions |
| `lib/features/wellness_goals/presentation/widgets/wellness_stats_card.dart` | Home card with metrics |
| `lib/features/wellness_goals/presentation/pages/health_detail_page.dart` | Full health detail page |
| `lib/features/workouts/presentation/widgets/health_overview_card.dart` | Workouts tab health card |
| `lib/features/workouts/presentation/widgets/heart_rate_monitor_card.dart` | Live HR card |
| `lib/features/workouts/presentation/widgets/workout_stats_graphs.dart` | Performance graphs |
| `ios/Runner/Runner.entitlements` | HealthKit capability |
| `ios/Runner/Info.plist` | Health usage descriptions |
