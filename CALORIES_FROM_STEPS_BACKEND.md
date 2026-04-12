# Calories Burned From Steps — Backend Implementation Guide

## Current State

### What Already Works

| Source | Method | Where |
|--------|--------|-------|
| Apple Watch active calories | `ACTIVE_ENERGY_BURNED` from HealthKit | Frontend only (local) |
| Manual workout calories | MET formula via `POST /api/workouts/estimate` | Backend |
| Logged workout calories | Stored in `workout_logs` table | Backend |
| Weekly calorie totals | `GET /api/workouts/stats` | Backend |

### What's Missing

There is no way to calculate **calories burned from steps** on the backend. If the user doesn't have an Apple Watch (no `ACTIVE_ENERGY_BURNED` data), and hasn't logged a manual workout, their "Burned" number stays 0 — even if they walked 8,000 steps.

---

## Proposed Solution

### Option A: Frontend Estimation (No Backend Changes)

Calculate calories from steps locally using a standard formula:

```
calories = steps × 0.04  (average person, ~70kg)
```

Or more accurately with body weight:

```
calories = steps × stride_length_m × weight_kg × 0.0005
```

Where `stride_length_m ≈ 0.762` for average adult.

**Simplified:**
```
calories_from_steps = steps × weight_kg × 0.0000385
```

Example: 10,000 steps × 70kg = ~27 cal (this is the NET additional calories above BMR)

**Note:** The more commonly cited "100 cal per mile" (~2,000 steps) gives:
```
calories_from_steps = steps × 0.05  (rough estimate)
```

**Pros:** No backend changes needed, instant.
**Cons:** Not personalized without weight, less accurate.

### Option B: Backend Endpoint (Recommended)

Add a new endpoint that calculates calories from steps using the user's body profile.

#### New Endpoint: `POST /api/workouts/calories-from-steps`

**Request:**
```json
{
  "steps": 8432,
  "date": "2026-03-31"
}
```

**Response:**
```json
{
  "success": true,
  "estimate": {
    "steps": 8432,
    "calories_burned": 336,
    "distance_km": 6.3,
    "active_minutes": 84,
    "formula": "steps × stride × weight × 0.0005",
    "weight_kg": 75.0,
    "note": "Estimated from step count using body profile"
  }
}
```

#### Backend Logic (Django)

```python
# workouts/views.py

@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def calories_from_steps(request):
    steps = request.data.get('steps', 0)

    # Get user's body profile for weight
    try:
        profile = BodyProfile.objects.get(user=request.user)
        weight_kg = float(profile.weight_kg)
    except BodyProfile.DoesNotExist:
        weight_kg = 70.0  # default

    # Calculation
    # Average stride length: 0.762m (adjustable by height if available)
    stride_m = 0.762
    if hasattr(profile, 'height_cm') and profile.height_cm:
        # Stride ≈ height × 0.415 for walking
        stride_m = float(profile.height_cm) / 100 * 0.415

    distance_km = (steps * stride_m) / 1000

    # MET for walking ≈ 3.5 (moderate pace)
    # Calories = MET × weight_kg × hours
    active_minutes = steps / 100  # ~100 steps per minute walking
    hours = active_minutes / 60
    calories = 3.5 * weight_kg * hours

    return Response({
        'success': True,
        'estimate': {
            'steps': steps,
            'calories_burned': round(calories),
            'distance_km': round(distance_km, 1),
            'active_minutes': round(active_minutes),
            'formula': 'MET(3.5) × weight × hours',
            'weight_kg': weight_kg,
        }
    })
```

#### URL Config

```python
# workouts/urls.py
path('calories-from-steps', views.calories_from_steps, name='calories-from-steps'),
```

---

## Frontend Integration

### With Option A (local estimation):

In `healthkit_service.dart`, add:

```dart
/// Estimate calories burned from steps (no backend needed)
/// Uses MET 3.5 for walking, 100 steps/min average pace
static int estimateCaloriesFromSteps(int steps, {double weightKg = 70.0}) {
  final activeMinutes = steps / 100;
  final hours = activeMinutes / 60;
  final calories = 3.5 * weightKg * hours;
  return calories.round();
}
```

### With Option B (backend call):

In `workout_service.dart`, add:

```dart
Future<int> getCaloriesFromSteps(int steps) async {
  final response = await _api.post('/api/workouts/calories-from-steps', data: {
    'steps': steps,
  });
  return response.data['estimate']['calories_burned'] ?? 0;
}
```

---

## Formula Reference

| Method | Formula | Accuracy |
|--------|---------|----------|
| Rough estimate | `steps × 0.05` | Low — ignores weight |
| Weight-based | `steps × weight_kg × 0.0000385` | Medium |
| MET-based (recommended) | `MET(3.5) × weight_kg × (steps/100/60)` | High |
| HealthKit (gold standard) | `ACTIVE_ENERGY_BURNED` from Apple Watch | Highest — uses real HR |

## Priority

The HealthKit `ACTIVE_ENERGY_BURNED` is always the most accurate because Apple Watch uses real heart rate data. The step-based estimation should be a **fallback** for when:
- User doesn't have an Apple Watch
- HealthKit permissions aren't granted
- Active energy data isn't available

---

## Decision

For now: **use Option A (frontend estimation)** as a fallback when HealthKit active calories are 0 but steps > 0. This gives immediate results with no backend work. The backend endpoint can be added later for cross-device consistency.
