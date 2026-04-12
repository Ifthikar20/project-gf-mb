# Food Scanner — Backend Changes Required

## Summary

The Flutter app's food scanner results page has been updated. The backend needs corresponding changes to support new features and fix existing issues.

---

## 1. Remove Wellness Impact from API Response

**Current:** The `/api/food/analyze` endpoint returns a `meal_wellness` object with `overall_score`, `label`, `per_item` scores, `positive_factors`, and `negative_factors`.

**Problem:** The wellness score is often "Unknown" or inaccurate because the Gemini prompt doesn't have enough context to reliably score wellness (it doesn't know the user's dietary goals, allergies, or health conditions).

**Action:** Remove `meal_wellness` from the Gemini prompt and API response. The frontend no longer displays it.

```python
# In food/gemini_client.py — remove from the Gemini prompt:
# - meal_wellness section
# - overall_score
# - positive_factors / negative_factors

# In food/views.py — remove from the response:
# - result['meal_wellness']
```

The `wellnessScore` and `wellnessBreakdownJson` fields still exist in the Flutter `MealLog` Hive model for backward compatibility, but new scans will store 0/null.

---

## 2. Improve Calorie Burn Suggestions

**Current:** The `calorie_burn` array in the response provides activities to burn off the scanned food:
```json
{
  "calorie_burn": [
    {"activity": "Walking", "duration": "90 minutes", "icon": "walking", "steps": 9000},
    {"activity": "Running", "duration": "30 minutes", "icon": "running"}
  ]
}
```

**Needed:** Make the calorie burn suggestions more accurate with real MET calculations:

```python
# Calculate burn durations using real MET values and user's weight
def calculate_burn_suggestions(total_calories, weight_kg=70):
    activities = [
        {"activity": "Walking", "icon": "walking", "met": 3.5},
        {"activity": "Running", "icon": "running", "met": 9.8},
        {"activity": "Cycling", "icon": "cycling", "met": 7.5},
        {"activity": "Swimming", "icon": "swimming", "met": 8.0},
    ]

    suggestions = []
    for act in activities:
        # calories = MET × weight_kg × hours
        hours = total_calories / (act["met"] * weight_kg)
        minutes = round(hours * 60)
        steps = round(minutes * 100) if act["activity"] in ["Walking", "Running"] else None

        suggestions.append({
            "activity": act["activity"],
            "duration": f"{minutes} minutes",
            "icon": act["icon"],
            "steps": steps,
            "calories": total_calories,  # NEW: include target calories
            "detail": f"Burns {total_calories} cal at {act['met']} MET"  # NEW
        })

    return suggestions
```

**New fields to add to each burn suggestion:**
- `calories` (int) — target calories this activity would burn
- `detail` (string) — explanation of the calculation
- `met_value` (float) — the MET value used

If the user's body profile is available, use their actual weight instead of default 70kg.

---

## 3. Persist Food Scan Images with Non-Expiring URLs

**Current:** The `image_url` in the API response is a pre-signed S3 URL that expires after a few hours.

**Problem:** When the user logs out and back in, the local file may be gone and the S3 URL is expired, so the food image disappears.

**Action:** Store food scan images with **permanent (non-expiring) URLs** or at minimum longer expiry (30 days):

### Option A: Public bucket with CloudFront (recommended)
```python
# Upload to a public-read bucket path
s3_key = f"food-scans/{user_id}/{scan_id}.jpg"
# Return CloudFront URL (no expiry)
image_url = f"https://cdn.betterandbliss.app/{s3_key}"
```

### Option B: Long-lived pre-signed URLs
```python
# Generate URL with 30-day expiry instead of hours
url = s3_client.generate_presigned_url(
    'get_object',
    Params={'Bucket': bucket, 'Key': key},
    ExpiresIn=2592000  # 30 days
)
```

### Option C: Re-fetch endpoint
Add an endpoint to regenerate the image URL:
```
GET /api/food/scan/{scan_id}/image
→ Returns fresh pre-signed URL
```

---

## 4. Add Workout Type Mapping for Burn Suggestions

**Current:** The burn suggestions are free-text ("Walking", "90 minutes") with no connection to the workout system.

**Needed:** Include the `workout_type_id` in each burn suggestion so the Flutter app can directly create a workout from it:

```json
{
  "calorie_burn": [
    {
      "activity": "Walking",
      "duration": "90 minutes",
      "duration_minutes": 90,
      "icon": "walking",
      "steps": 9000,
      "calories": 350,
      "workout_type_id": "uuid-of-walking-type",
      "met_value": 3.5
    }
  ]
}
```

This allows the Flutter "Add" button to create a real workout goal linked to a workout type, not just a text label.

---

## 5. No Health Data in Backend

**Reminder:** All health data (steps, heart rate, sleep, etc.) stays on-device. The backend should NOT:
- Receive health metrics from the app
- Store Apple Health data
- Require HealthKit data for any calculations

The only user data the backend has for calorie calculations is the **body profile** (weight/height) via `PUT /api/workouts/body-profile`.

---

## Files Affected on Backend

| File | Change |
|------|--------|
| `food/gemini_client.py` | Remove wellness scoring from Gemini prompt |
| `food/views.py` | Remove `meal_wellness` from response, add `workout_type_id` to burn suggestions |
| `food/serializers.py` | Update response serializer |
| `workouts/models.py` | No changes needed |

## Files Changed on Frontend

| File | Change |
|------|--------|
| `food_scan_sheet.dart` | Better image blur, "Burn It Off" cards with Add button, "Log Meal" button |
| `meal_detail_page.dart` | Removed Wellness Impact section, burn rows with Add button |
| `meal_timeline_card.dart` | Image fallback chain (local → remote → emoji) |
