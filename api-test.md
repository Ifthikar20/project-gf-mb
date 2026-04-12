# BetterBliss Auth API Reference

Base URL: `https://api.betterandbliss.com`

All endpoints require the following header:

```
X-Client-Id: <your-client-id>
Content-Type: application/json
```

---

## Login

### `POST /auth/login`

**Request:**

```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Success (200):**

```json
{
  "success": true,
  "user": {
    "id": "ab9239d2-c58f-4071-9948-7ed3e58058e9",
    "email": "user@example.com",
    "display_name": "John Doe",
    "avatar_url": null,
    "role": "free_user",
    "subscription_tier": "free",
    "status": "active",
    "share_food_data_with_coach": false,
    "created_at": "2026-03-30T04:11:51.424507+00:00",
    "updated_at": "2026-03-30T04:27:25.348288+00:00"
  },
  "token": "b6a5e07e9d6d31b26f1dbe340311aa227d4174ee",
  "expires_in": 604800,
  "onboarding_completed": false
}
```

**After login, use the token for all authenticated requests:**

```
Authorization: Token b6a5e07e9d6d31b26f1dbe340311aa227d4174ee
```

**UI Logic:**
- Store `token` securely (e.g. Flutter secure storage)
- If `onboarding_completed` is `false`, redirect to onboarding flow
- Store `user` object for profile display

**Error — Invalid credentials (401):**

```json
{
  "success": false,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Invalid email or password",
    "hint": "Double-check your email and password"
  }
}
```

**Error — Account disabled (403):**

```json
{
  "success": false,
  "error": {
    "code": "ACCOUNT_DISABLED",
    "message": "This account has been deactivated"
  }
}
```

**Error — Missing client ID (403):**

```json
{
  "success": false,
  "error": {
    "code": "MISSING_CLIENT_ID",
    "message": "X-Client-Id header is required."
  }
}
```

**Error — Rate limited (429):**

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMITED",
    "message": "Too many requests. Please try again later."
  }
}
```

---

## Register

### `POST /auth/register`

**Request:**

```json
{
  "email": "newuser@example.com",
  "password": "SecurePass123!",
  "display_name": "Jane Doe"
}
```

**Success (201):**

```json
{
  "success": true,
  "user": {
    "id": "237cd8c6-9614-419b-a6d2-39f7de41562f",
    "email": "newuser@example.com",
    "display_name": "Jane Doe",
    "avatar_url": null,
    "role": "free_user",
    "subscription_tier": "free",
    "status": "active",
    "share_food_data_with_coach": false,
    "created_at": "2026-03-30T05:00:00.000000+00:00",
    "updated_at": "2026-03-30T05:00:00.000000+00:00"
  },
  "token": "a1b2c3d4e5f6...",
  "expires_in": 604800,
  "onboarding_completed": false
}
```

User is auto-logged in after registration. Same response shape as login.

---

## Logout

### `POST /auth/logout`

**Headers:**

```
Authorization: Token <token>
X-Client-Id: <your-client-id>
```

**Request body:** none

**Success (200):**

```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

## Get Current User

### `GET /auth/me`

**Headers:**

```
Authorization: Token <token>
X-Client-Id: <your-client-id>
```

**Success (200):**

```json
{
  "success": true,
  "user": {
    "id": "ab9239d2-c58f-4071-9948-7ed3e58058e9",
    "email": "user@example.com",
    "display_name": "John Doe",
    "avatar_url": null,
    "role": "free_user",
    "subscription_tier": "free",
    "status": "active",
    "share_food_data_with_coach": false,
    "created_at": "2026-03-30T04:11:51.424507+00:00",
    "updated_at": "2026-03-30T04:27:25.348288+00:00"
  }
}
```

**Error — Not authenticated (403):**

```json
{
  "detail": "Authentication credentials were not provided."
}
```

---

## Forgot Password Flow

### Step 1: Request OTP

### `POST /auth/forgot-password`

**Request:**

```json
{
  "email": "user@example.com"
}
```

**Response (200 — always, prevents email enumeration):**

```json
{
  "success": true,
  "message": "If an account exists, a reset code has been generated"
}
```

**UI Logic:**
- Show "Check your email for the reset code"
- Navigate to OTP input screen
- 60-second cooldown before allowing resend

---

### Step 2: Verify OTP

### `POST /auth/verify-reset-otp`

**Request:**

```json
{
  "email": "user@example.com",
  "otp_code": "978784"
}
```

**Success (200):**

```json
{
  "success": true,
  "reset_token": "tMbNZO2dUQ-2CDzXaWy5oQimjKyi-O82HmsOHJ6vhW8",
  "expires_in": 300,
  "message": "Code verified. Use the reset token to set your new password."
}
```

**UI Logic:**
- Store `reset_token` in memory (do NOT persist to disk)
- Navigate to "Set new password" screen immediately
- Token expires in 5 minutes

**Error — Expired OTP (400):**

```json
{
  "success": false,
  "error": {
    "code": "OTP_EXPIRED",
    "message": "Reset code has expired. Please request a new one."
  }
}
```

**Error — Wrong OTP (400):**

```json
{
  "success": false,
  "error": {
    "code": "INVALID_OTP",
    "message": "Incorrect reset code. 2 attempts remaining."
  }
}
```

**Error — Too many attempts (429):**

```json
{
  "success": false,
  "error": {
    "code": "TOO_MANY_ATTEMPTS",
    "message": "Too many failed attempts. Please request a new code."
  }
}
```

---

### Step 3: Reset Password

### `POST /auth/reset-password`

**Request:**

```json
{
  "reset_token": "tMbNZO2dUQ-2CDzXaWy5oQimjKyi-O82HmsOHJ6vhW8",
  "new_password": "NewSecure456!"
}
```

**Success (200):**

```json
{
  "success": true,
  "message": "Password has been reset successfully. Please log in with your new password."
}
```

**UI Logic:**
- Show success message
- Navigate to login screen
- All existing sessions are invalidated (user must log in again on all devices)

**Error — Invalid/expired token (400):**

```json
{
  "success": false,
  "error": {
    "code": "INVALID_TOKEN",
    "message": "Reset token is invalid or has expired. Please start over."
  }
}
```

**Error — Weak password (400):**

```json
{
  "success": false,
  "error": {
    "code": "WEAK_PASSWORD",
    "message": "This password is too common.",
    "field": "new_password"
  }
}
```

---

## Change Password (Authenticated)

### `POST /auth/change-password`

**Headers:**

```
Authorization: Token <token>
X-Client-Id: <your-client-id>
```

**Request:**

```json
{
  "current_password": "OldPass123!",
  "new_password": "NewPass456!"
}
```

**Success (200):**

```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

**Error — Wrong current password (400):**

```json
{
  "success": false,
  "error": {
    "code": "INCORRECT_CURRENT_PASSWORD",
    "message": "Current password is incorrect"
  }
}
```

---

## Password Requirements

- Minimum 8 characters
- Cannot be too similar to your email or display name
- Cannot be a commonly used password (e.g. "password123")
- Cannot be entirely numeric

---

## Rate Limits

| Scope | Limit |
|-------|-------|
| Auth endpoints (`/auth/*`) | 10 requests/minute per IP |
| All other endpoints | 60 requests/minute per IP |
| OTP resend cooldown | 60 seconds per email |
| OTP verification attempts | 3 per OTP code |

---

## Timings

| Item | Duration |
|------|----------|
| OTP code validity | 10 minutes |
| Reset token validity | 5 minutes |
| Auth token (Bearer) | 7 days |
| OTP resend cooldown | 60 seconds |
