# Health Data Architecture — Great Feel App

## Overview

This document explains how health data (calories consumed, steps, Apple Watch data, calorie burn targets) flows through the app, and where each type of data is stored.

### Design Principle

- **Food images** are sent to the backend for AI analysis (Gemini Vision) — this requires server-side processing.
- **Personal health data** (steps, heart rate, calories burned, meal logs) stays **strictly on-device**. This is an intentional privacy decision — we do not upload personal health metrics to the backend.

---

## 1. Calorie Consumption (Food/Diet Tracking)

### How It Works

1. User scans food with their camera
2. Image is uploaded to the backend (S3 pre-signed URL)
3. Backend runs **Google Gemini 2.5 Flash Vision** to detect food items, estimate calories/macros
4. Results returned to the app include:
   - Per-item calories, protein, carbs, fat, sugar, fiber, sodium, caffeine
   - Wellness score (-100 to +100)
   - **Calorie burn suggestions** (activities needed to burn what was consumed)
   - Warnings (allergens, high sugar) and benefits (high protein, fiber)
5. User confirms and logs the meal

### Where It's Stored

| Data | Location | Details |
|------|----------|---------|
| Meal logs | **Local (Hive, encrypted)** | `diet_logs` box, AES encrypted |
| Food scan images | **Backend (S3)** | Uploaded during scan, pre-signed URL stored locally |
| Daily calorie goal | **Local (hardcoded)** | Default 2000 cal/day in `DailyNutritionSummary` |

**Key:** Meal logs are **frontend-only**. They never sync to the backend. The backend only processes the food scan — the actual meal log stays on your device.

### Calorie Goal Tracking

- `DailyNutritionSummary` computes:
  - `totalCalories` — sum of all logged meals for the day
  - `caloriesRemaining` — goal minus consumed
  - `calorieProgress` — ratio (clamped 0–1.5)
- Nutrition charts available for 7-day, 14-day, and 30-day ranges

### Key Files

- `lib/features/diet/data/models/diet_models.dart` — MealLog, MealType, DailyNutritionSummary
- `lib/features/diet/data/datasources/diet_local_datasource.dart` — Hive storage/retrieval
- `lib/features/diet/presentation/bloc/diet_bloc.dart` — State management

---

## 2. Apple Watch / HealthKit Data (Steps, Heart Rate, Workouts)

### What Data Is Read from Apple Health

| Data Type | HealthKit Type | How It's Used |
|-----------|---------------|---------------|
| Steps | `STEPS` | Daily step count |
| Heart Rate | `HEART_RATE` | BPM over time (2-day window) |
| Active Calories | `ACTIVE_ENERGY_BURNED` | Daily active burn |
| Workouts | `WORKOUT` | Duration, calories, workout type |

### How It Works

1. User grants HealthKit permission via `HealthConsentPage`
2. App reads data directly from the device's HealthKit store
3. Data is displayed in `WorkoutStatsGraphs` (weekly bar charts, heart rate graph)
4. An **Effort Score** (0.0–1.0) is computed:
   - 60% weight: workout minutes vs 150 min/week target
   - 40% weight: active calories vs 2000 cal/week target

### Where It's Stored

| Data | Location | Details |
|------|----------|---------|
| HealthKit data | **Device (Apple Health)** | Read-only, never uploaded |
| Permission status | **Local (Hive)** | `healthkit_prefs` box |
| Displayed metrics | **In-memory only** | Fetched fresh on each screen load |

**Key:** HealthKit data stays 100% on-device. The app reads it but **never uploads it to the backend**. As the consent screen states: *"Data stays on device, never uploaded."*

### Optional Backend Sync

There are API endpoints for syncing workouts to the backend if the user chooses:
- `POST /api/workouts/log/apple-health` — sync a single workout
- `POST /api/workouts/log/apple-health/batch` — batch sync up to 50 workouts

This is opt-in and separate from the automatic HealthKit reads.

### Fallback Behavior

If HealthKit is unavailable (e.g., on simulator or permission denied), the app shows **simulated demo data** with a "Demo Data" badge.

### Key Files

- `lib/core/services/healthkit_service.dart` — HealthKit reads, permissions, effort score
- `ios/Runner/Runner.entitlements` — HealthKit capability
- `ios/Runner/Info.plist` — HealthKit usage descriptions

---

## 3. Calories Needed to Burn

### Current Implementation

The app does **not** have a traditional BMR/TDEE calorie deficit calculator. Instead, it uses two approaches:

#### A. Food Scan Burn Suggestions

When you scan food, the backend returns **calorie burn suggestions** — activities and durations needed to burn off what you just ate. This comes from the Gemini Vision response.

#### B. MET-Based Workout Calorie Estimation

When logging workouts, calories burned are calculated using the METs formula:

```
calories_burned = MET_value x weight_kg x duration_minutes / 60
```

- **MET values** are provided by the backend per workout type (via `/api/workouts/types`)
- **Body weight** is required (stored on backend via `/api/workouts/body-profile`)
- **Estimation endpoint:** `POST /api/workouts/estimate`

#### C. Weekly Workout Goals

Users can set weekly targets for:
- `calories_burned` — target calories/week
- `active_minutes` — target minutes/week
- `workout_count` — target workouts/week

Progress is tracked on the backend via `/api/workouts/goals`.

### What's Missing

- No BMR (Basal Metabolic Rate) calculation — would need age, sex, activity level
- No TDEE (Total Daily Energy Expenditure) calculation
- No explicit calorie deficit view (consumed minus burned)
- Calorie goal is hardcoded at 2000 cal/day — no per-user customization

---

## 4. Local vs Backend — Complete Summary

### Stored Locally (Frontend)

| Data | Storage Method | Encrypted |
|------|---------------|-----------|
| Meal logs (calories, macros) | Hive (`diet_logs`) | Yes (AES) |
| Wellness goals (video completion, streaks) | Hive (`wellness_goals`) | Yes |
| Meditation journal entries | Hive | Yes |
| HealthKit permission status | Hive (`healthkit_prefs`) | No |
| Auth token | FlutterSecureStorage (iOS Keychain) | Yes |
| Recently viewed items | Hive | No |

### Stored on Backend

| Data | API Endpoint | Notes |
|------|-------------|-------|
| User account & auth | `/auth/*` | Token-based auth |
| Body profile (weight/height) | `/api/workouts/body-profile` | Required for calorie estimation |
| Manual workout logs | `/api/workouts/log/manual` | Synced immediately |
| Workout history & stats | `/api/workouts/history`, `/api/workouts/stats` | Read from backend |
| Workout goals & progress | `/api/workouts/goals` | Weekly targets |
| Food scan images | S3 (pre-signed URL) | Uploaded during scan |
| Food scan analysis | Gemini Vision (via backend) | Processed server-side, results returned to app |

### Stored on Device (Apple)

| Data | Location | Access |
|------|----------|--------|
| Steps, heart rate, workouts | Apple HealthKit | Read-only by the app |

---

## 5. Data Flow Diagram

```
Apple Watch / iPhone Sensors
        |
        v
   Apple HealthKit (on-device)
        |
        v  (read-only)
   HealthKitService ──> WorkoutStatsGraphs (display only)
                    ──> Effort Score calculation (in-memory)
                    ──> Optional: sync to backend via /api/workouts/log/apple-health

   Camera
        |
        v
   Food Scan ──> Backend (S3 + Gemini Vision) ──> Results returned
        |
        v
   DietBloc ──> Hive (encrypted local storage) ──> Nutrition charts/summaries

   Manual Workout
        |
        v
   WorkoutService ──> Backend API ──> Stored server-side
```

---

## 6. iOS Permissions Required

| Permission | Purpose |
|-----------|---------|
| `com.apple.developer.healthkit` | Read steps, heart rate, workouts, active calories |
| `NSHealthShareUsageDescription` | "Great Feel reads your workout, heart rate, and activity data..." |
| `NSHealthUpdateUsageDescription` | "Great Feel can save your workout sessions to Apple Health..." |
| `NSCameraUsageDescription` | Food scanning |
| `NSPhotoLibraryUsageDescription` | Select food images for scanning |
