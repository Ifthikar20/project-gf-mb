# Nutrition Breakdown — Backend Changes for Vitamins & Minerals

## Current State

The food scanner (Gemini Vision) currently returns these nutrients per detected food item:

| Nutrient | Field | Unit | Status |
|----------|-------|------|--------|
| Calories | `calories` | kcal | Working |
| Protein | `protein_g` | grams | Working |
| Carbs | `carbs_g` | grams | Working |
| Fat | `fat_g` | grams | Working |
| Sugar | `sugar_g` | grams | Working |
| Fiber | `fiber_g` | grams | Working |
| Sodium | `sodium_mg` | mg | Working |
| Caffeine | `caffeine_mg` | mg | Working |

## What's Needed

Add these additional micronutrients to the Gemini prompt and API response:

### Vitamins

| Nutrient | Field | Unit | Daily Value |
|----------|-------|------|-------------|
| Vitamin A | `vitamin_a_mcg` | mcg | 900 mcg |
| Vitamin C | `vitamin_c_mg` | mg | 90 mg |
| Vitamin D | `vitamin_d_mcg` | mcg | 20 mcg |
| Vitamin E | `vitamin_e_mg` | mg | 15 mg |
| Vitamin K | `vitamin_k_mcg` | mcg | 120 mcg |
| Vitamin B12 | `vitamin_b12_mcg` | mcg | 2.4 mcg |
| Folate (B9) | `folate_mcg` | mcg | 400 mcg |

### Minerals

| Nutrient | Field | Unit | Daily Value |
|----------|-------|------|-------------|
| Iron | `iron_mg` | mg | 18 mg |
| Calcium | `calcium_mg` | mg | 1300 mg |
| Potassium | `potassium_mg` | mg | 2600 mg |
| Magnesium | `magnesium_mg` | mg | 420 mg |
| Zinc | `zinc_mg` | mg | 11 mg |

### Other

| Nutrient | Field | Unit | Daily Value |
|----------|-------|------|-------------|
| Cholesterol | `cholesterol_mg` | mg | 300 mg |
| Saturated Fat | `saturated_fat_g` | grams | 20 g |
| Trans Fat | `trans_fat_g` | grams | 0 g (avoid) |

---

## Gemini Prompt Changes

In `food/gemini_client.py`, update the prompt to request additional nutrients:

```python
# Add to the Gemini prompt (inside the JSON schema for each item):

"vitamins": {
    "vitamin_a_mcg": 150,
    "vitamin_c_mg": 12,
    "vitamin_d_mcg": 0,
    "vitamin_e_mg": 1.5,
    "vitamin_k_mcg": 20,
    "vitamin_b12_mcg": 0.5,
    "folate_mcg": 40
},
"minerals": {
    "iron_mg": 2.5,
    "calcium_mg": 50,
    "potassium_mg": 300,
    "magnesium_mg": 30,
    "zinc_mg": 1.2
},
"cholesterol_mg": 45,
"saturated_fat_g": 5,
"trans_fat_g": 0
```

### Full Updated Item Schema for Gemini:

```json
{
    "name": "Chicken Breast",
    "calories": 165,
    "protein_g": 31,
    "carbs_g": 0,
    "fat_g": 3.6,
    "sugar_g": 0,
    "fiber_g": 0,
    "sodium_mg": 74,
    "caffeine_mg": 0,
    "cholesterol_mg": 85,
    "saturated_fat_g": 1,
    "trans_fat_g": 0,
    "vitamins": {
        "vitamin_a_mcg": 6,
        "vitamin_c_mg": 0,
        "vitamin_d_mcg": 0.1,
        "vitamin_e_mg": 0.3,
        "vitamin_k_mcg": 0,
        "vitamin_b12_mcg": 0.3,
        "folate_mcg": 4
    },
    "minerals": {
        "iron_mg": 1,
        "calcium_mg": 15,
        "potassium_mg": 256,
        "magnesium_mg": 29,
        "zinc_mg": 0.9
    },
    "confidence": 0.92,
    "type": "solid"
}
```

---

## API Response Changes

The `/api/food/analyze` response should include the new fields nested under each item. No changes to the top-level response structure.

```json
{
    "success": true,
    "items": [
        {
            "name": "Grilled Chicken Salad",
            "calories": 350,
            "protein_g": 35,
            "carbs_g": 20,
            "fat_g": 15,
            "sugar_g": 5,
            "fiber_g": 8,
            "sodium_mg": 450,
            "caffeine_mg": 0,
            "cholesterol_mg": 95,
            "saturated_fat_g": 3,
            "trans_fat_g": 0,
            "vitamins": {
                "vitamin_a_mcg": 350,
                "vitamin_c_mg": 25,
                "vitamin_d_mcg": 0,
                "vitamin_k_mcg": 80
            },
            "minerals": {
                "iron_mg": 3,
                "calcium_mg": 120,
                "potassium_mg": 650,
                "magnesium_mg": 45
            },
            "warnings": [...],
            "benefits": [...],
            "calorie_burn": [...]
        }
    ]
}
```

---

## Flutter Changes Needed (After Backend Update)

1. **Update `DetectedFoodItem` model** (`food_scan_result.dart`):
   - Add vitamin/mineral fields
   - Parse from JSON

2. **Update `MealLog` model** (`diet_models.dart`):
   - Add HiveFields for new nutrients
   - Run `flutter pub run build_runner build` to regenerate adapters

3. **Update Nutrition Breakdown widget** on Calories page:
   - Add vitamin/mineral rows with progress bars against daily values

4. **Update Food Summary page**:
   - Show vitamins/minerals in the detail section

---

## Priority

Phase 1 (now — already working):
- Protein, Carbs, Fat, Sugar, Fiber, Sodium, Caffeine

Phase 2 (backend update needed):
- Cholesterol, Saturated Fat, Trans Fat
- Vitamins A, C, D, B12
- Iron, Calcium, Potassium

Phase 3 (nice to have):
- Remaining vitamins (E, K, Folate)
- Remaining minerals (Magnesium, Zinc)

---

## Notes

- Gemini Vision can estimate vitamins/minerals from food images with moderate accuracy
- For packaged foods (barcode scan), use the product database which has exact values
- All nutrition data is stored locally on the device (Hive) — nothing uploaded to backend except the food image for analysis
- Daily values are based on FDA 2020-2025 Dietary Guidelines for adults
