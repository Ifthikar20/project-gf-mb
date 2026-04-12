# Apple In-App Subscription Setup Guide

## Overview

Use Apple's native StoreKit via the `in_app_purchase` Flutter package. No RevenueCat. Subscriptions are managed directly through App Store Connect and validated on your backend.

---

## Step 1: App Store Connect Setup

### 1.1 Create App (if not already done)

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps > + > New App
3. Fill in: Name = "Great Feel", Bundle ID = `com.betterbliss.betterbliss`, SKU = `greatfeel`

### 1.2 Create Subscription Group

1. In your app > Subscriptions > + (Subscription Group)
2. Group name: **"Great Feel Premium"**
3. Add products:

| Product ID | Name | Price | Duration |
|-----------|------|-------|----------|
| `gf_basic_monthly` | Basic Monthly | $4.99 | 1 month |
| `gf_basic_yearly` | Basic Yearly | $39.99 | 1 year |
| `gf_premium_monthly` | Premium Monthly | $9.99 | 1 month |
| `gf_premium_yearly` | Premium Yearly | $79.99 | 1 year |

4. For each product:
   - Set price
   - Add localization (display name + description)
   - Set subscription duration
   - Review screenshot (can be placeholder for now)

### 1.3 Create Sandbox Tester

1. App Store Connect > Users and Access > Sandbox > Testers
2. Create a new tester:
   - Email: use any email (doesn't need to be real)
   - Password: set one you'll remember
   - Country: your country
3. On your iPhone: Settings > App Store > Sandbox Account > sign in with this tester

---

## Step 2: Xcode Configuration

### 2.1 Add In-App Purchase Capability

In `ios/Runner.xcodeproj`:
- Add `com.apple.developer.in-app-payments` to entitlements

Or manually in `Runner.entitlements`:
```xml
<key>com.apple.developer.in-app-payments</key>
<array>
    <string>merchant.com.betterbliss.betterbliss</string>
</array>
```

### 2.2 StoreKit Configuration (for local testing)

Create `ios/Runner/StoreKitConfig.storekit` for Xcode local testing (optional but helpful for development without needing App Store Connect).

---

## Step 3: Flutter Implementation

### 3.1 Add Package

```yaml
# pubspec.yaml
dependencies:
  in_app_purchase: ^3.2.0
```

### 3.2 Service Architecture

```
lib/features/subscription/
├── data/
│   └── services/
│       └── apple_iap_service.dart    ← StoreKit interface
├── presentation/
│   ├── bloc/
│   │   └── subscription_bloc.dart    ← Already exists
│   └── pages/
│       └── subscription_plans_page.dart ← Already exists
```

### 3.3 Flow

```
1. App starts → IAP service initializes → loads available products from Apple
2. User taps "Subscribe" → purchase flow starts → Apple payment sheet appears
3. Apple processes payment → returns receipt
4. App sends receipt to backend for validation
5. Backend validates with Apple → updates user's subscription_tier
6. App refreshes user profile → premium features unlock
```

---

## Step 4: Backend Changes

### 4.1 Apple Receipt Validation Endpoint

```
POST /api/subscriptions/apple/verify
{
    "receipt_data": "<base64 encoded receipt>",
    "product_id": "gf_premium_monthly"
}
```

**Response:**
```json
{
    "success": true,
    "subscription": {
        "tier": "premium",
        "expires_at": "2026-05-01T00:00:00Z",
        "product_id": "gf_premium_monthly",
        "is_trial": false
    }
}
```

### 4.2 Backend Validation Logic

```python
# subscriptions/views.py

import requests

APPLE_VERIFY_URL = "https://buy.itunes.apple.com/verifyReceipt"
APPLE_SANDBOX_URL = "https://sandbox.itunes.apple.com/verifyReceipt"

@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def verify_apple_receipt(request):
    receipt_data = request.data.get('receipt_data')

    # Try production first, fall back to sandbox
    payload = {
        "receipt-data": receipt_data,
        "password": settings.APPLE_SHARED_SECRET,  # From App Store Connect
        "exclude-old-transactions": True,
    }

    resp = requests.post(APPLE_VERIFY_URL, json=payload)
    data = resp.json()

    # Status 21007 = sandbox receipt sent to production
    if data.get('status') == 21007:
        resp = requests.post(APPLE_SANDBOX_URL, json=payload)
        data = resp.json()

    if data.get('status') != 0:
        return Response({'success': False, 'error': 'Invalid receipt'}, status=400)

    # Extract latest subscription info
    latest = data.get('latest_receipt_info', [{}])[-1]
    product_id = latest.get('product_id')
    expires_ms = int(latest.get('expires_date_ms', 0))
    expires_at = datetime.fromtimestamp(expires_ms / 1000, tz=timezone.utc)

    # Determine tier from product_id
    tier = 'premium' if 'premium' in product_id else 'basic'

    # Update user subscription
    user = request.user
    user.subscription_tier = tier
    user.subscription_expires = expires_at
    user.save()

    return Response({
        'success': True,
        'subscription': {
            'tier': tier,
            'expires_at': expires_at.isoformat(),
            'product_id': product_id,
        }
    })
```

### 4.3 App Store Server Notifications (Webhook)

Apple sends notifications for subscription events (renewal, cancellation, refund).

```
POST /api/subscriptions/apple/webhook
```

This handles:
- Auto-renewal success
- Subscription expired
- Refund
- Grace period

---

## Step 5: Sandbox Testing

### How to Test

1. **On your iPhone**: Settings > App Store > Sandbox Account > sign in with your sandbox tester
2. **In the app**: Go to Profile > Membership > Upgrade
3. **Tap a plan** → Apple payment sheet appears with "[Environment: Sandbox]"
4. **Confirm** → sandbox processes instantly (no real charge)
5. **Subscription activates** → app shows premium features

### Sandbox Time Compression

Apple sandbox accelerates subscription durations:

| Real Duration | Sandbox Duration |
|---------------|-----------------|
| 1 week | 3 minutes |
| 1 month | 5 minutes |
| 2 months | 10 minutes |
| 3 months | 15 minutes |
| 6 months | 30 minutes |
| 1 year | 1 hour |

So a monthly subscription renews every 5 minutes in sandbox — perfect for testing renewal logic.

---

## Step 6: What You Need Before Going Live

| Item | Status |
|------|--------|
| Apple Developer Account ($99/year) | You have it (6SP7VHC6XC) |
| App Store Connect app created | Need to create |
| Subscription products configured | Need to create |
| Sandbox tester account | Need to create |
| `in_app_purchase` package in Flutter | Will add |
| Apple receipt validation endpoint | Backend needs to add |
| App Store Server Notifications webhook | Backend needs to add |
| Apple Shared Secret | Get from App Store Connect > App > In-App Purchases > App-Specific Shared Secret |
| Privacy Policy URL | Required for App Store submission |
| App Review | Subscriptions require Apple review before going live |

---

## Files to Create/Modify

### Flutter (this repo)
- `pubspec.yaml` — add `in_app_purchase: ^3.2.0`
- `lib/features/subscription/data/services/apple_iap_service.dart` — new
- `lib/features/subscription/presentation/pages/subscription_plans_page.dart` — update
- `ios/Runner/Runner.entitlements` — add IAP capability

### Backend
- `subscriptions/views.py` — add `verify_apple_receipt` endpoint
- `subscriptions/urls.py` — add route
- `settings.py` — add `APPLE_SHARED_SECRET`
- User model — add `subscription_expires` field if not exists
