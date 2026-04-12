# Health Tracking User Guide — Great Feel App

## What Can We Track?

| Data | Source | Requires Apple Watch? |
|------|--------|----------------------|
| Steps | iPhone + Apple Watch | No — iPhone tracks steps on its own |
| Heart Rate | Apple Watch only | Yes |
| Active Calories Burned | iPhone + Apple Watch | No — iPhone estimates from steps |
| Workouts (duration, type) | Apple Watch | Yes |

Your iPhone already tracks **steps** and **active calories** using its built-in motion sensor — no Apple Watch needed. If you have an Apple Watch, you also get **heart rate** and **workout sessions**.

All this data lives in **Apple Health** on your iPhone. Great Feel reads from Apple Health — it never uploads your health data to any server.

---

## How to Connect (First Time)

### Step 1: Open Profile
Tap the **Profile** tab (bottom right of the app).

### Step 2: Find the Apple Health Toggle
Scroll down to the **Apple Health** section. You'll see a toggle with a heart icon.

### Step 3: Turn On the Toggle
Tap the toggle to enable it. iOS will show a **HealthKit permission screen**.

### Step 4: Enable All Categories
On the iOS permission screen, turn on **ALL** of these:
- Steps
- Heart Rate
- Active Energy
- Workouts

Then tap **Allow** (top right corner).

### Step 5: Done!
You'll see a green message: **"Apple Health connected!"**

Go to the **Workouts tab** to see your Health Overview with:
- Steps today
- Heart rate (if you have an Apple Watch)
- Calories burned this week
- Active minutes this week
- Heart rate range (min/avg/max)
- 7-day activity graph
- Heart rate trend (48 hours)

---

## What If I Denied Permissions?

If you tapped **Don't Allow** or turned off categories on the iOS permission screen, the app cannot read your health data. **iOS does not let apps ask again** — you need to enable it manually.

### How to Fix (Re-enable After Denying)

1. Open your iPhone **Settings** app
2. Scroll down and tap **Health**
3. Tap **Data Access & Devices**
4. Find **Great Feel** in the list and tap it
5. Turn on all the categories:
   - Steps
   - Heart Rate
   - Active Energy Burned
   - Workouts
6. Go back to the Great Feel app
7. In **Profile**, toggle Apple Health **off** then **on** again

Your data should now appear in the Workouts tab.

### Can We Still Track Without Permissions?

**No.** Even though your iPhone tracks steps on its own, that data is stored in Apple Health (HealthKit). Without permission, the app cannot read it. The toggle will show a red error message guiding you to Settings.

The app will show **simulated demo data** in the workout graphs so the UI isn't empty, but it won't be your real data until permissions are granted.

---

## How Does the Data Flow?

```
Your iPhone                          Your Apple Watch
  |                                       |
  | steps, active calories                | steps, HR, workouts, calories
  |                                       |
  v                                       v
  +----------- Apple Health (on iPhone) -----------+
  |                                                |
  | All data merged & deduplicated automatically   |
  +------------------------------------------------+
                        |
                        | (read-only, on-device)
                        v
                  Great Feel App
                        |
              +---------+---------+
              |                   |
        Display in UI      Save to Local Cache
        (Workouts tab)     (Hive encrypted box)
                           Never uploaded
```

---

## Where Is My Data Stored?

| What | Where | Uploaded? |
|------|-------|-----------|
| Steps, HR, workouts | Apple Health (iOS) | No |
| Cached health snapshots | Hive encrypted box on device | No |
| Food scan images | Backend (S3) for AI analysis | Yes (images only) |
| Meal logs (calories consumed) | Hive encrypted box on device | No |

**Privacy:** Health data never leaves your phone. It's read from Apple Health and cached locally in an encrypted database. If you turn off the Apple Health toggle, all cached health data is deleted.

---

## Troubleshooting

### "Toggle won't turn on"
- Make sure you're on a real iPhone (not simulator)
- Check Settings > Health > Data Access > Great Feel — enable all categories

### "Steps show 0"
- Make sure you've been carrying your iPhone — it needs movement to count steps
- Check the Apple Health app directly — if it shows 0 steps there, the issue is with the sensor, not our app

### "No heart rate data"
- Heart rate requires an **Apple Watch**
- Make sure your Apple Watch is paired and syncing to your iPhone
- Check Apple Health app > Heart Rate to verify data exists

### "Data looks old / not updating"
- The app refreshes health data when you open the Workouts tab
- Pull down to refresh, or close and reopen the app
- Data is also refreshed each time you launch the app

### "I want to stop sharing health data"
- Go to Profile > Apple Health toggle > turn it OFF
- All cached health data on the app is immediately deleted
- You can also revoke access in Settings > Health > Data Access > Great Feel

---

## For Developers

The health tracking integration is in:
- `lib/core/services/healthkit_service.dart` — reads from HealthKit, caches in Hive
- `lib/features/workouts/presentation/widgets/health_overview_card.dart` — dashboard UI
- `lib/features/workouts/presentation/widgets/heart_rate_monitor_card.dart` — live HR card
- `lib/features/workouts/presentation/widgets/workout_stats_graphs.dart` — graphs
- `lib/features/profile/presentation/pages/profile_page.dart` — toggle in profile

iOS configuration:
- `ios/Runner/Runner.entitlements` — HealthKit capability
- `ios/Runner/Info.plist` — NSHealthShareUsageDescription, NSHealthUpdateUsageDescription
