# Better & Bliss - Complete API Flow Documentation

## Table of Contents
- [Project Overview](#project-overview)
- [Architecture Overview](#architecture-overview)
- [Authentication System](#authentication-system)
- [Authorization System](#authorization-system)
- [Content Access Flow](#content-access-flow)
- [Streaming Security Flow](#streaming-security-flow)
- [API Endpoints Reference](#api-endpoints-reference)
- [Security Mechanisms](#security-mechanisms)
- [Database Schema](#database-schema)
- [Environment Configuration](#environment-configuration)

---

## Project Overview

**Better & Bliss** is a mental health and wellness platform providing:
- 🎥 **Secure Video/Audio Streaming** with HLS support
- 🧘 **Live Meditation** with real-time breath detection (WebSocket)
- 🔐 **AWS Cognito Authentication** (Email/Password + Google OAuth)
- 🎯 **Subscription-based Access Control** (Free, Basic, Premium)
- 📊 **Analytics & View Tracking**
- 📧 **Newsletter Management**
- ☁️ **CloudFront CDN** with signed URLs

### Tech Stack
- **Backend**: FastAPI (Python 3.9+)
- **Auth**: AWS Cognito (JWT-based)
- **Database**: PostgreSQL (asyncpg)
- **Storage**: AWS S3 + CloudFront CDN
- **Video Processing**: AWS MediaConvert (HLS)
- **Real-time**: WebSockets
- **Monitoring**: Datadog APM

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT (Browser/App)                     │
└─────────────────────────────────────────────────────────────────┘
                                   │
                                   │ HTTPS
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                      FastAPI Backend (Port 8000)                 │
│  ┌──────────────┬──────────────┬──────────────┬──────────────┐  │
│  │ Auth Routes  │ Content Routes│ Streaming   │ Meditation   │  │
│  │ /auth/*      │ /content/*    │ /api/stream*│ /api/med*    │  │
│  └──────────────┴──────────────┴──────────────┴──────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Middleware Layer                             │   │
│  │  - CORS        - Security Headers    - Logging           │   │
│  │  - Auth        - Rate Limiting       - Datadog Tracing   │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                    │                    │                │
                    │                    │                │
                    ▼                    ▼                ▼
        ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐
        │  AWS Cognito     │  │   PostgreSQL     │  │  AWS S3 +    │
        │  User Pool       │  │   Database       │  │  CloudFront  │
        │                  │  │                  │  │              │
        │ - User Auth      │  │ - User Profiles  │  │ - Videos     │
        │ - JWT Tokens     │  │ - Content Data   │  │ - Audio      │
        │ - OAuth (Google) │  │ - Analytics      │  │ - Thumbnails │
        └──────────────────┘  └──────────────────┘  └──────────────┘
```

---

## Authentication System

### 1. User Registration Flow

**Endpoint**: `POST /auth/register`

**Request**:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "full_name": "John Doe",
  "captcha_token": "optional-recaptcha-v3-token"
}
```

**Complete Flow**:

```
┌──────────┐      ┌──────────┐      ┌──────────┐      ┌──────────┐
│ Frontend │      │ Backend  │      │ Cognito  │      │ Database │
└────┬─────┘      └────┬─────┘      └────┬─────┘      └────┬─────┘
     │                 │                 │                 │
     │ POST /register  │                 │                 │
     ├────────────────→│                 │                 │
     │ {email,password}│                 │                 │
     │                 │                 │                 │
     │                 │ 1. Verify CAPTCHA (if enabled)   │
     │                 │────────────────→│                 │
     │                 │                 │                 │
     │                 │ 2. SignUp       │                 │
     │                 │    + SECRET_HASH│                 │
     │                 │────────────────→│                 │
     │                 │                 │                 │
     │                 │ 3. UserSub      │                 │
     │                 │←────────────────│                 │
     │                 │    + Status     │                 │
     │                 │                 │                 │
     │                 │ 4. Auto-confirm (dev mode)       │
     │                 │────────────────→│                 │
     │                 │                 │                 │
     │                 │ 5. INSERT user  │                 │
     │                 │─────────────────────────────────→│
     │                 │    (cognito_sub, email, role)    │
     │                 │                 │                 │
     │                 │ 6. Auto-login (InitiateAuth)     │
     │                 │────────────────→│                 │
     │                 │                 │                 │
     │                 │ 7. JWT Tokens   │                 │
     │                 │←────────────────│                 │
     │                 │    - access_token                │
     │                 │    - refresh_token               │
     │                 │    - id_token                    │
     │                 │                 │                 │
     │ Set-Cookie      │                 │                 │
     │←────────────────│                 │                 │
     │ {access_token,  │                 │                 │
     │  refresh_token} │                 │                 │
     │ + User data     │                 │                 │
     │                 │                 │                 │
```

**Response** (200 OK):
```json
{
  "success": true,
  "user": {
    "id": "cognito-sub-uuid",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "free_user",
    "subscription_tier": "free",
    "permissions": []
  },
  "expires_in": 3600
}
```

**Cookies Set**:
```
Set-Cookie: access_token=eyJhbGc...; HttpOnly; Secure; SameSite=Strict; Path=/
Set-Cookie: refresh_token=eyJhbGc...; HttpOnly; Secure; SameSite=Strict; Path=/
```

**Key Security Features**:
1. **Password Requirements**: Min 8 chars, uppercase, lowercase, number, special char
2. **SECRET_HASH**: HMAC-SHA256(username + client_id, client_secret) → base64
3. **CAPTCHA**: reCAPTCHA v3 with score threshold (if enabled)
4. **Rate Limiting**: Prevents brute force attacks
5. **HttpOnly Cookies**: Prevents XSS token theft

---

### 2. User Login Flow

**Endpoint**: `POST /auth/login`

**Request**:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Complete Flow**:

```
┌──────────┐      ┌──────────┐      ┌──────────┐      ┌──────────┐
│ Frontend │      │ Backend  │      │ Cognito  │      │ Database │
└────┬─────┘      └────┬─────┘      └────┬─────┘      └────┬─────┘
     │                 │                 │                 │
     │ POST /login     │                 │                 │
     ├────────────────→│                 │                 │
     │ {email,password}│                 │                 │
     │                 │                 │                 │
     │                 │ 1. InitiateAuth │                 │
     │                 │    (USER_PASSWORD_AUTH)           │
     │                 │────────────────→│                 │
     │                 │    + SECRET_HASH│                 │
     │                 │                 │                 │
     │                 │ 2. Validate     │                 │
     │                 │    credentials  │                 │
     │                 │                 │                 │
     │                 │ 3. JWT Tokens   │                 │
     │                 │←────────────────│                 │
     │                 │    {access, refresh, id}          │
     │                 │                 │                 │
     │                 │ 4. GetUser      │                 │
     │                 │    (access_token)                 │
     │                 │────────────────→│                 │
     │                 │                 │                 │
     │                 │ 5. User Attrs   │                 │
     │                 │←────────────────│                 │
     │                 │    {sub, email, │                 │
     │                 │     custom:role,│                 │
     │                 │     custom:sub_tier}              │
     │                 │                 │                 │
     │                 │ 6. SELECT user  │                 │
     │                 │─────────────────────────────────→│
     │                 │    WHERE cognito_sub = $1        │
     │                 │                 │                 │
     │                 │ 7. User record  │                 │
     │                 │←─────────────────────────────────│
     │                 │    {id, email, role, sub_tier}   │
     │                 │                 │                 │
     │                 │ 8. UPDATE       │                 │
     │                 │    last_login   │                 │
     │                 │─────────────────────────────────→│
     │                 │                 │                 │
     │ Set-Cookie +    │                 │                 │
     │ User Response   │                 │                 │
     │←────────────────│                 │                 │
     │                 │                 │                 │
```

**Response** (200 OK):
```json
{
  "success": true,
  "user": {
    "id": "cognito-sub-uuid",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "premium_user",
    "subscription_tier": "premium",
    "permissions": ["view_premium_content"]
  },
  "expires_in": 3600
}
```

---

### 3. Google OAuth Flow

**Endpoint**: `GET /auth/google` → `GET /auth/callback`

**Complete Flow**:

```
┌──────────┐   ┌──────────┐   ┌──────────────┐   ┌────────┐   ┌──────────┐
│ Frontend │   │ Backend  │   │   Cognito    │   │ Google │   │ Database │
└────┬─────┘   └────┬─────┘   └──────┬───────┘   └───┬────┘   └────┬─────┘
     │              │                │               │             │
     │ Click        │                │               │             │
     │ "Google Login"                │               │             │
     │              │                │               │             │
     │ GET /auth/google              │               │             │
     ├─────────────→│                │               │             │
     │              │                │               │             │
     │              │ Build OAuth URL│               │             │
     │              │ (Cognito Hosted UI)            │             │
     │              │                │               │             │
     │ 302 Redirect │                │               │             │
     │←─────────────│                │               │             │
     │ Location: https://your-app.auth...amazoncognito.com/       │
     │           oauth2/authorize?                   │             │
     │           client_id=...&                      │             │
     │           response_type=code&                 │             │
     │           identity_provider=Google            │             │
     │              │                │               │             │
     ├──────────────────────────────→│               │             │
     │              │    User sees Cognito login     │             │
     │              │                │               │             │
     │              │                │ Redirect to   │             │
     │              │                │ Google OAuth  │             │
     │              │                ├──────────────→│             │
     │              │                │               │             │
     │              │                │    User logs in to Google   │
     │              │                │               │             │
     │              │                │ Google returns│             │
     │              │                │ authorization │             │
     │              │                │←──────────────│             │
     │              │                │               │             │
     │              │ 302 Redirect   │               │             │
     │              │ to /auth/callback?code=ABC123 │             │
     │←─────────────────────────────│               │             │
     │              │                │               │             │
     │ GET /auth/callback?code=ABC123                │             │
     ├─────────────→│                │               │             │
     │              │                │               │             │
     │              │ POST /oauth2/token             │             │
     │              │ (exchange code for tokens)     │             │
     │              ├───────────────→│               │             │
     │              │                │               │             │
     │              │ Tokens         │               │             │
     │              │←───────────────│               │             │
     │              │ {access, refresh, id}          │             │
     │              │                │               │             │
     │              │ GetUser        │               │             │
     │              ├───────────────→│               │             │
     │              │                │               │             │
     │              │ User Info      │               │             │
     │              │←───────────────│               │             │
     │              │ {sub, email, name}             │             │
     │              │                │               │             │
     │              │ INSERT/UPDATE user             │             │
     │              │───────────────────────────────────────────→│
     │              │ (sync Cognito user to DB)      │             │
     │              │                │               │             │
     │ 302 Redirect │                │               │             │
     │ to /browse   │                │               │             │
     │←─────────────│                │               │             │
     │ (cookies set)│                │               │             │
     │              │                │               │             │
```

**Cognito OAuth URL Structure**:
```
https://your-app.auth.us-east-1.amazoncognito.com/oauth2/authorize?
  client_id=YOUR_CLIENT_ID&
  response_type=code&
  scope=email+openid+profile&
  redirect_uri=https://api.betterandbliss.com/auth/callback&
  identity_provider=Google
```

**Token Exchange Request**:
```http
POST https://your-app.auth.us-east-1.amazoncognito.com/oauth2/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&
client_id=YOUR_CLIENT_ID&
client_secret=YOUR_CLIENT_SECRET&
code=AUTHORIZATION_CODE&
redirect_uri=https://api.betterandbliss.com/auth/callback
```

---

### 4. Token Refresh Flow

**Endpoint**: `POST /auth/refresh`

**Flow**:
```
Frontend                Backend              Cognito
   │                       │                    │
   │ POST /auth/refresh    │                    │
   ├──────────────────────→│                    │
   │ Cookie: refresh_token │                    │
   │                       │                    │
   │                       │ InitiateAuth       │
   │                       │ (REFRESH_TOKEN_AUTH)
   │                       ├───────────────────→│
   │                       │                    │
   │                       │ New Tokens         │
   │                       │←───────────────────│
   │                       │ {access_token,     │
   │                       │  id_token}         │
   │                       │                    │
   │ Set-Cookie            │                    │
   │ (new access_token)    │                    │
   │←──────────────────────│                    │
   │ {success: true}       │                    │
```

**Note**: Refresh tokens do **not** expire and are rotated on use (Cognito default behavior).

---

### 5. Password Reset Flow

**Endpoints**:
- `POST /auth/forgot-password`
- `POST /auth/reset-password`

**Flow**:

```
Frontend            Backend             Cognito             User Email
   │                   │                   │                   │
   │ POST /forgot-password                 │                   │
   ├──────────────────→│                   │                   │
   │ {email}           │                   │                   │
   │                   │                   │                   │
   │                   │ ForgotPassword    │                   │
   │                   ├──────────────────→│                   │
   │                   │                   │                   │
   │                   │                   │ Send 6-digit code │
   │                   │                   ├──────────────────→│
   │                   │                   │                   │
   │                   │ CodeDeliveryDetails                   │
   │                   │←──────────────────│                   │
   │                   │                   │                   │
   │ Generic success   │                   │                   │
   │←──────────────────│                   │                   │
   │ (no email reveal) │                   │                   │
   │                   │                   │                   │
   │                                                           │
   │ User receives email with code: 123456                     │
   │◄──────────────────────────────────────────────────────────│
   │                   │                   │                   │
   │ POST /reset-password                  │                   │
   ├──────────────────→│                   │                   │
   │ {email,           │                   │                   │
   │  code: "123456",  │                   │                   │
   │  new_password}    │                   │                   │
   │                   │                   │                   │
   │                   │ ConfirmForgotPassword                 │
   │                   ├──────────────────→│                   │
   │                   │                   │                   │
   │                   │ Success           │                   │
   │                   │←──────────────────│                   │
   │                   │                   │                   │
   │ Password reset    │                   │                   │
   │←──────────────────│                   │                   │
   │                   │                   │                   │
```

**Security Features**:
- **6-digit code** sent to verified email
- **Code expires** in 1 hour
- **Single-use**: Code invalidated after successful reset
- **Rate limiting**: 5 requests per 15 minutes per IP
- **No email enumeration**: Always returns generic success message
- **Confirmation rate limiting**: 10 attempts per hour per IP+email

---

## Authorization System

### User Roles & Permissions

**Defined in**: `app/auth/models.py`

```python
class UserRole:
    FREE_USER = "free_user"           # Default role
    PREMIUM_USER = "premium_user"     # Paid subscriber
    ADMIN = "admin"                   # Platform admin
    CONTENT_CREATOR = "content_creator"
    MODERATOR = "moderator"

class SubscriptionTier:
    FREE = "free"      # Basic content only
    BASIC = "basic"    # More features, SD quality
    PREMIUM = "premium" # All features, HD quality
```

### Access Control Matrix

| Content Tier | Free User | Basic User | Premium User | Admin |
|--------------|-----------|------------|--------------|-------|
| Free Content | ✅ Yes    | ✅ Yes     | ✅ Yes       | ✅ Yes |
| Basic Content| ❌ No     | ✅ Yes     | ✅ Yes       | ✅ Yes |
| Premium Content| ❌ No   | ❌ No      | ✅ Yes       | ✅ Yes |
| Admin Panel  | ❌ No     | ❌ No      | ❌ No        | ✅ Yes |

### Subscription Tier Limits

**Streaming Quality**:
```python
FREE:
  - Max Bitrate: 2.5 Mbps (480p)
  - Concurrent Streams: 1
  - Quality Options: [360p, 480p]

BASIC:
  - Max Bitrate: 5.0 Mbps (720p)
  - Concurrent Streams: 2
  - Quality Options: [360p, 480p, 720p]

PREMIUM:
  - Max Bitrate: 8.0 Mbps (1080p)
  - Concurrent Streams: 4
  - Quality Options: [360p, 480p, 720p, 1080p]
```

### Authorization Dependency System

**Location**: `app/auth/enhanced_dependencies.py`

```python
# Requires authentication
@router.get("/protected")
async def protected_route(
    user: UserResponse = Depends(get_current_user_simple)
):
    # user is guaranteed to exist
    return {"user_id": user.id}

# Requires authentication + database sync
@router.get("/profile")
async def profile(
    user_data: Dict = Depends(get_current_user_with_db)
):
    # user_data["user"] = Cognito user
    # user_data["db_user"] = Database user record
    return user_data

# Optional authentication
@router.get("/public-or-private")
async def hybrid(
    user_data: Optional[Dict] = Depends(get_optional_user_enhanced)
):
    if user_data:
        # Authenticated - show premium content
        return {"content": "premium"}
    else:
        # Anonymous - show free content
        return {"content": "free"}
```

---

## Content Access Flow

### 1. Browse Content (Mixed Free/Premium)

**Endpoint**: `GET /content/browse?category=mindfulness&limit=20`

**Flow**:

```
┌──────────┐      ┌──────────┐      ┌──────────┐
│ Frontend │      │ Backend  │      │ Database │
└────┬─────┘      └────┬─────┘      └────┬─────┘
     │                 │                 │
     │ GET /content/browse?category=mindfulness
     ├────────────────→│                 │
     │ Cookie: access_token (optional)  │
     │                 │                 │
     │                 │ 1. Extract JWT  │
     │                 │    (if present) │
     │                 │                 │
     │                 │ 2. Get user subscription_tier
     │                 │    - None (anonymous)
     │                 │    - free                        │
     │                 │    - basic                       │
     │                 │    - premium                     │
     │                 │                 │
     │                 │ 3. SELECT content                │
     │                 │    WHERE status = 'published'    │
     │                 │    AND (                         │
     │                 │      access_tier = 'free' OR     │
     │                 │      user_tier >= access_tier    │
     │                 │    )             │
     │                 │─────────────────→│
     │                 │                 │
     │                 │ 4. Content rows │
     │                 │←─────────────────│
     │                 │                 │
     │                 │ 5. Filter based on user tier    │
     │                 │    - Add "locked" flag to premium│
     │                 │      content for free users      │
     │                 │                 │
     │ Content list    │                 │
     │←────────────────│                 │
     │ [{id, title,    │                 │
     │   access_tier,  │                 │
     │   locked: true/false}]            │
     │                 │                 │
```

**Response** (Free User):
```json
{
  "content": [
    {
      "id": "uuid-1",
      "title": "Introduction to Mindfulness",
      "access_tier": "free",
      "locked": false,
      "thumbnail_url": "https://...",
      "duration_seconds": 600,
      "can_access": true
    },
    {
      "id": "uuid-2",
      "title": "Advanced Meditation Techniques",
      "access_tier": "premium",
      "locked": true,
      "thumbnail_url": "https://...",
      "duration_seconds": 1200,
      "can_access": false
    }
  ],
  "user_authenticated": true,
  "premium_available": true
}
```

**Response** (Premium User):
```json
{
  "content": [
    {
      "id": "uuid-1",
      "title": "Introduction to Mindfulness",
      "access_tier": "free",
      "locked": false,
      "can_access": true
    },
    {
      "id": "uuid-2",
      "title": "Advanced Meditation Techniques",
      "access_tier": "premium",
      "locked": false,  // Unlocked for premium user
      "can_access": true
    }
  ],
  "user_authenticated": true,
  "premium_available": true
}
```

---

### 2. View Content Detail

**Endpoint**: `GET /content/detail/{content_id}`

**Flow**:

```
┌──────────┐      ┌──────────┐      ┌──────────┐
│ Frontend │      │ Backend  │      │ Database │
└────┬─────┘      └────┬─────┘      └────┬─────┘
     │                 │                 │
     │ GET /content/detail/uuid-123     │
     ├────────────────→│                 │
     │ Cookie: access_token              │
     │                 │                 │
     │                 │ 1. Validate UUID format
     │                 │    (security: prevent enum)     │
     │                 │                 │
     │                 │ 2. Parse JWT    │
     │                 │    Get user tier│
     │                 │                 │
     │                 │ 3. SELECT content
     │                 │    WHERE id = $1│
     │                 │    AND status = 'published'     │
     │                 │─────────────────→│
     │                 │                 │
     │                 │ 4. Content row  │
     │                 │←─────────────────│
     │                 │                 │
     │                 │ 5. Check access │
     │                 │    IF content.access_tier > user.tier:
     │                 │      locked = true              │
     │                 │      can_stream = false         │
     │                 │    ELSE:        │
     │                 │      locked = false             │
     │                 │      can_stream = true          │
     │                 │                 │
     │ Content detail  │                 │
     │←────────────────│                 │
     │ {id, title,     │                 │
     │  description,   │                 │
     │  access_tier,   │                 │
     │  locked,        │                 │
     │  can_stream}    │                 │
     │                 │                 │
```

**Response** (Premium Content, Free User):
```json
{
  "id": "uuid-123",
  "title": "Advanced Meditation",
  "description": "Deep breathing techniques...",
  "content_type": "video",
  "access_tier": "premium",
  "duration_seconds": 1200,
  "thumbnail_url": "https://...",
  "locked": true,
  "can_stream": false,
  "upgrade_message": "Premium subscription required to access this content"
}
```

**Response** (Premium Content, Premium User):
```json
{
  "id": "uuid-123",
  "title": "Advanced Meditation",
  "description": "Deep breathing techniques...",
  "content_type": "video",
  "access_tier": "premium",
  "duration_seconds": 1200,
  "thumbnail_url": "https://...",
  "locked": false,
  "can_stream": true,
  "is_hls_ready": true
}
```

---

## Streaming Security Flow

### Complete Streaming Flow (Most Important)

**Endpoint**: `GET /api/streaming/content/{content_id}/stream`

This is the **core secure streaming implementation**.

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│ Frontend │   │ Backend  │   │ Database │   │    S3    │   │CloudFront│
└────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘
     │              │              │              │              │
     │ 1. User clicks "Play Video" │              │              │
     │              │              │              │              │
     │ 2. GET /content/detail/{uuid}              │              │
     ├─────────────→│              │              │              │
     │ Cookie: access_token        │              │              │
     │              │              │              │              │
     │              │ 3. Verify JWT│              │              │
     │              │ Get user info│              │              │
     │              │              │              │              │
     │              │ 4. SELECT content           │              │
     │              │ WHERE id = $1│              │              │
     │              ├─────────────→│              │              │
     │              │              │              │              │
     │              │ 5. Content   │              │              │
     │              │←─────────────│              │              │
     │              │ {id, access_tier, s3_keys} │              │
     │              │              │              │              │
     │ 6. Content detail           │              │              │
     │←─────────────│              │              │              │
     │ {id, title, can_stream: true}             │              │
     │              │              │              │              │
     │ 7. User clicks Play         │              │              │
     │              │              │              │              │
     │ 8. GET /api/streaming/content/{uuid}/stream              │
     ├─────────────→│              │              │              │
     │ Cookie: access_token        │              │              │
     │              │              │              │              │
     │              │ 9. Verify JWT│              │              │
     │              │ Get user: {id, tier}        │              │
     │              │              │              │              │
     │              │ 10. Validate UUID           │              │
     │              │              │              │              │
     │              │ 11. SELECT content          │              │
     │              ├─────────────→│              │              │
     │              │              │              │              │
     │              │ 12. Content  │              │              │
     │              │←─────────────│              │              │
     │              │              │              │              │
     │              │ 13. Check subscription_tier │              │
     │              │ IF content.access_tier = 'premium' AND    │
     │              │    user.subscription_tier != 'premium':    │
     │              │      DENY (403 Forbidden)   │              │
     │              │              │              │              │
     │              │ 14. Generate secure token:  │              │
     │              │ expiry = now + 2 hours      │              │
     │              │ md5 = MD5(                  │              │
     │              │   content_id +              │              │
     │              │   expiry +                  │              │
     │              │   user_id +                 │              │
     │              │   STREAMING_SECRET_KEY      │              │
     │              │ )            │              │              │
     │              │              │              │              │
     │              │ 15. Build signed URLs:      │              │
     │              │ https://d123.cloudfront.net/│              │
     │              │ hls/uuid/master.m3u8?       │              │
     │              │   e=1699123456&             │              │
     │              │   md5=abc123def&            │              │
     │              │   uid=user-uuid             │              │
     │              │              │              │              │
     │ 16. Streaming URLs          │              │              │
     │←─────────────│              │              │              │
     │ {hls_master,                │              │              │
     │  hls_720p,                  │              │              │
     │  thumbnail,                 │              │              │
     │  expires_at}│              │              │              │
     │              │              │              │              │
     │ 17. Video Player requests HLS playlist     │              │
     │ GET https://d123.cloudfront.net/hls/uuid/master.m3u8?e=...&md5=...
     ├────────────────────────────────────────────────────────→│
     │              │              │              │              │
     │              │              │    ┌──────────────────────┐│
     │              │              │    │ Lambda@Edge          ││
     │              │              │    │ Validates Token:     ││
     │              │              │    │ 1. Check expiry      ││
     │              │              │    │ 2. Recalculate MD5   ││
     │              │              │    │ 3. Compare hashes    ││
     │              │              │    └──────────────────────┘│
     │              │              │              │              │
     │              │              │              │ 18. Fetch from S3
     │              │              │              │←─────────────│
     │              │              │              │              │
     │              │              │              │ 19. Return file
     │              │              │              ├─────────────→│
     │              │              │              │              │
     │ 20. HLS Playlist (master.m3u8)             │              │
     │◄────────────────────────────────────────────────────────│
     │ #EXTM3U      │              │              │              │
     │ #EXT-X-STREAM-INF:...       │              │              │
     │ 720p.m3u8?e=...&md5=...     │              │              │
     │              │              │              │              │
     │ 21. Request video segments (.ts files)     │              │
     │ GET https://.../720p/segment0001.ts?e=...&md5=...        │
     ├────────────────────────────────────────────────────────→│
     │              │              │              │              │
     │              │              │              │ [Lambda validates]
     │              │              │              │              │
     │ 22. Video chunk             │              │              │
     │◄────────────────────────────────────────────────────────│
     │              │              │              │              │
     │ Video playback starts       │              │              │
     │              │              │              │              │
```

### Token Generation Algorithm

**Location**: `app/services/streaming_service.py`

```python
import hashlib
import time

def generate_secure_token(
    content_id: str,
    user_id: str,
    expiry_minutes: int = 120
) -> dict:
    """
    Generate secure streaming token

    Returns:
        {
            'expiry': 1699123456,
            'md5': 'abc123def...'
        }
    """
    # Calculate expiration timestamp
    expiry_timestamp = int(time.time()) + (expiry_minutes * 60)

    # Build token string
    token_string = f"{content_id}{expiry_timestamp}{user_id}{STREAMING_SECRET_KEY}"

    # Generate MD5 hash
    md5_hash = hashlib.md5(token_string.encode()).hexdigest()

    return {
        'expiry': expiry_timestamp,
        'md5': md5_hash
    }
```

### Token Validation (CloudFront Lambda@Edge)

**Pseudocode** (runs on CloudFront edge):

```javascript
// Lambda@Edge function (CloudFront)
exports.handler = async (event) => {
    const request = event.Records[0].cf.request;
    const queryString = request.querystring;

    // Parse query parameters
    const params = parseQueryString(queryString);
    const { e: expiry, md5: providedMd5, uid: userId } = params;

    // Extract content_id from URI
    const contentId = extractContentIdFromUri(request.uri);

    // 1. Check expiration
    const currentTime = Math.floor(Date.now() / 1000);
    if (currentTime > parseInt(expiry)) {
        return {
            status: '410',
            statusDescription: 'Gone',
            body: 'Streaming URL has expired'
        };
    }

    // 2. Recalculate MD5
    const tokenString = `${contentId}${expiry}${userId}${STREAMING_SECRET_KEY}`;
    const calculatedMd5 = md5(tokenString);

    // 3. Compare hashes
    if (calculatedMd5 !== providedMd5) {
        return {
            status: '403',
            statusDescription: 'Forbidden',
            body: 'Invalid security token'
        };
    }

    // 4. Allow request
    return request;  // Continue to S3
};
```

### URL Security Features

1. **Expiring URLs**: Default 2 hours, configurable via `VIDEO_URL_EXPIRY_MINUTES`
2. **User-bound tokens**: MD5 includes `user_id`, prevents URL sharing
3. **Content-specific**: Each content has unique token
4. **Secret-based**: Uses `STREAMING_SECRET_KEY` (min 32 chars)
5. **UUID-based**: Content IDs are UUIDs (non-enumerable)

---

## API Endpoints Reference

### Authentication Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/auth/register` | No | Register new user |
| POST | `/auth/login` | No | Login with email/password |
| GET | `/auth/me` | Yes | Get current user info |
| GET | `/auth/profile` | Yes | Get detailed profile |
| PUT | `/auth/profile` | Yes | Update user profile |
| POST | `/auth/logout` | Optional | Logout user |
| POST | `/auth/refresh` | Yes (refresh_token) | Refresh access token |
| GET | `/auth/google` | No | Initiate Google OAuth |
| GET | `/auth/callback` | No | OAuth callback handler |
| POST | `/auth/forgot-password` | No | Request password reset code |
| POST | `/auth/reset-password` | No | Reset password with code |
| POST | `/auth/change-password` | Yes | Change password (logged in) |

### Content Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/content/browse` | Optional | Browse content (filtered by tier) |
| GET | `/content/detail/{uuid}` | Optional | Get content details |
| GET | `/content/categories` | No | List all categories |
| GET | `/content/experts` | No | List featured experts |
| GET | `/content/search?q=...` | Optional | Search content |

### Streaming Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/streaming/content/{uuid}/stream` | **Yes** | Get secure streaming URLs |
| GET | `/api/streaming/validate-stream-token` | No | Validate token (CDN use) |

### Meditation Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| WebSocket | `/api/meditation/ws/breath` | Session-based | Real-time breath detection |
| POST | `/api/meditation/sessions/start` | Yes | Start meditation session |
| POST | `/api/meditation/sessions/{id}/complete` | Yes | Complete session |
| GET | `/api/meditation/sessions/{id}/stats` | Yes | Get session stats |
| GET | `/api/meditation/progress` | Yes | Get user progress |

### Analytics Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/analytics/track/view` | Optional | Track video view |
| GET | `/api/analytics/views/{uuid}` | No | Get view count |
| GET | `/api/analytics/summary/{uuid}` | No | Get analytics summary |
| GET | `/api/analytics/trending` | No | Get trending videos |
| GET | `/api/analytics/total-views` | No | Get total platform views |
| GET | `/api/analytics/content/{uuid}/metadata` | No | Get content metadata |

### Newsletter Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/newsletter/subscribe` | No | Subscribe to newsletter |

### System Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/` | No | API root (info) |
| GET | `/health` | No | Health check |
| GET | `/api/docs` | No | Swagger UI |
| GET | `/api/redoc` | No | ReDoc documentation |

---

## Security Mechanisms

### 1. JWT Token Structure

**Access Token** (Cognito-issued):
```json
{
  "sub": "cognito-uuid",           // User ID
  "email": "user@example.com",
  "custom:role": "premium_user",
  "custom:subscription_tier": "premium",
  "custom:permissions": "[]",
  "iat": 1699123456,               // Issued at
  "exp": 1699127056,               // Expires at (15 min)
  "iss": "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_XXXXX",
  "token_use": "access"
}
```

**ID Token** (Cognito-issued):
```json
{
  "sub": "cognito-uuid",
  "email": "user@example.com",
  "name": "John Doe",
  "email_verified": true,
  "iat": 1699123456,
  "exp": 1699127056,
  "token_use": "id"
}
```

### 2. Cookie Security Configuration

**Location**: `app/config.py:118-122`, `app/utils/cookies.py`

```python
# Production cookies
Set-Cookie: access_token=eyJhbG...;
    HttpOnly;                  # Prevents JavaScript access (XSS protection)
    Secure;                    # HTTPS only
    SameSite=Strict;           # CSRF protection
    Partitioned=true;          # Chrome privacy sandbox
    Domain=.betterandbliss.com;# Subdomain sharing
    Path=/;                    # Available on all routes
    Max-Age=900                # 15 minutes (access token)
```

### 3. Secret Hash Calculation (Cognito)

**Why needed**: Cognito requires SECRET_HASH when client has a client secret (confidential client).

**Formula**:
```python
import hmac
import hashlib
import base64

def calculate_secret_hash(username: str, client_id: str, client_secret: str) -> str:
    """
    Calculate Cognito SECRET_HASH

    Formula: HMAC-SHA256(username + client_id, client_secret) → base64
    """
    message = bytes(username + client_id, 'utf-8')
    key = bytes(client_secret, 'utf-8')

    digest = hmac.new(key, message, digestmod=hashlib.sha256).digest()
    secret_hash = base64.b64encode(digest).decode()

    return secret_hash
```

**Used in**:
- Registration (`SignUp`)
- Login (`InitiateAuth`)
- Password reset (`ForgotPassword`, `ConfirmForgotPassword`)
- Token refresh (uses `client_id` as username)

### 4. Rate Limiting

**Configuration** (`.env`):
```env
# Default rate limits (if enabled)
RATE_LIMIT_REGISTER=5/15min         # 5 registrations per 15 minutes
RATE_LIMIT_LOGIN=10/5min            # 10 login attempts per 5 minutes
RATE_LIMIT_PASSWORD_RESET=5/15min  # 5 reset requests per 15 minutes
RATE_LIMIT_API=100/1min             # 100 API calls per minute
```

**Implementation**: Redis-backed (optional) or in-memory fallback.

### 5. CAPTCHA Protection

**When enabled** (`.env`):
```env
ENABLE_CAPTCHA=true
RECAPTCHA_SECRET_KEY=your-recaptcha-secret
RECAPTCHA_MIN_SCORE=0.5    # reCAPTCHA v3 score threshold
```

**Protected endpoints**:
- `/auth/register` - Prevents bot registrations
- `/auth/login` - Prevents credential stuffing
- `/auth/forgot-password` - Prevents enumeration attacks

### 6. Input Validation

**UUID Validation** (prevents enumeration):
```python
import uuid

def validate_uuid(content_id: str) -> bool:
    try:
        uuid.UUID(content_id)
        return True
    except (ValueError, AttributeError):
        return False

# Usage
if not validate_uuid(content_id):
    raise HTTPException(status_code=400, detail="Invalid ID format")
```

**SQL Injection Prevention**: All queries use parameterized statements (asyncpg):
```python
# ✅ SAFE (parameterized)
await conn.fetchrow("SELECT * FROM users WHERE id = $1", user_id)

# ❌ DANGEROUS (never do this)
await conn.fetchrow(f"SELECT * FROM users WHERE id = '{user_id}'")
```

### 7. CORS Configuration

**Location**: `app/middleware/cors.py`

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=[settings.frontend_url],  # Only allow configured frontend
    allow_credentials=True,                 # Allow cookies
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["Set-Cookie"]
)
```

### 8. Security Headers

**Location**: `app/middleware/security_headers.py`

```python
# Added to all responses
headers = {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "X-XSS-Protection": "1; mode=block",
    "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
    "Content-Security-Policy": "default-src 'self'"
}
```

---

## Database Schema

### Core Tables

#### `users`
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cognito_sub TEXT UNIQUE NOT NULL,         -- Cognito user ID
    email TEXT UNIQUE NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'free_user',
    subscription_tier TEXT NOT NULL DEFAULT 'free',
    status TEXT NOT NULL DEFAULT 'active',    -- active, suspended, deleted
    last_login TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_cognito_sub ON users(cognito_sub);
CREATE INDEX idx_users_email ON users(email);
```

#### `content`
```sql
CREATE TABLE content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    content_type TEXT NOT NULL,               -- 'video', 'audio'
    access_tier TEXT NOT NULL DEFAULT 'free', -- 'free', 'basic', 'premium'
    status TEXT NOT NULL DEFAULT 'draft',     -- 'draft', 'published', 'archived'

    -- Category and expert
    category_id UUID REFERENCES categories(id),
    expert_id UUID REFERENCES experts(id),
    series_id UUID REFERENCES content_series(id),
    episode_number INTEGER,

    -- Media files
    s3_key_video_720p TEXT,
    s3_key_video_1080p TEXT,
    s3_key_audio TEXT,
    s3_key_thumbnail TEXT,
    s3_key_poster TEXT,

    -- HLS streaming
    is_hls_ready BOOLEAN DEFAULT false,
    hls_playlist_url TEXT,
    hls_conversion_status TEXT,               -- 'pending', 'processing', 'completed', 'failed'

    -- Audio streaming
    s3_key_audio_hls TEXT,
    is_audio_hls_ready BOOLEAN DEFAULT false,
    audio_hls_playlist_url TEXT,

    -- Metadata
    duration_seconds INTEGER,
    video_duration_seconds INTEGER,
    audio_bitrate INTEGER,
    featured BOOLEAN DEFAULT false,
    trending BOOLEAN DEFAULT false,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_content_status ON content(status);
CREATE INDEX idx_content_access_tier ON content(access_tier);
CREATE INDEX idx_content_category ON content(category_id);
```

#### `meditation_sessions`
```sql
CREATE TABLE meditation_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    content_id UUID REFERENCES content(id),   -- NULL for free practice
    session_type TEXT NOT NULL,               -- 'guided', 'free_practice'

    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP,
    duration_seconds INTEGER,
    completed BOOLEAN DEFAULT false,

    -- Breath metrics
    total_breaths INTEGER DEFAULT 0,
    avg_breath_duration DECIMAL(5,2),         -- Average seconds per breath
    breath_consistency_score DECIMAL(3,2),    -- 0.00 to 1.00
    inhale_exhale_ratio DECIMAL(3,2),         -- Ratio of inhale to exhale
    quality_score DECIMAL(3,2),               -- Overall quality 0.00 to 1.00

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_meditation_user ON meditation_sessions(user_id);
CREATE INDEX idx_meditation_started ON meditation_sessions(started_at);
```

#### `breath_events`
```sql
CREATE TABLE breath_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES meditation_sessions(id) ON DELETE CASCADE,

    event_type TEXT NOT NULL,                 -- 'inhaling', 'exhaling', 'holding', 'idle'
    timestamp TIMESTAMP NOT NULL,
    duration_ms INTEGER,                      -- Duration of this breath phase

    -- Audio features
    volume_rms DECIMAL(5,4),                  -- Root Mean Square (volume)
    spectral_centroid DECIMAL(8,2),           -- Frequency in Hz
    confidence_score DECIMAL(3,2),            -- 0.00 to 1.00

    -- Metrics
    breath_number INTEGER,
    is_consistent BOOLEAN,
    deviation_from_target DECIMAL(3,2),       -- Deviation from target duration

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_breath_session ON breath_events(session_id);
CREATE INDEX idx_breath_timestamp ON breath_events(timestamp);
```

#### `video_analytics`
```sql
CREATE TABLE video_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID NOT NULL REFERENCES content(id),
    user_id UUID REFERENCES users(id),        -- NULL for anonymous
    session_id TEXT,                          -- Frontend session ID

    viewed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    watch_duration INTEGER,                   -- How long user watched (seconds)

    -- User agent info
    ip_address INET,
    user_agent TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_analytics_content ON video_analytics(content_id);
CREATE INDEX idx_analytics_user ON video_analytics(user_id);
CREATE INDEX idx_analytics_viewed_at ON video_analytics(viewed_at);
```

#### `newsletter_subscribers`
```sql
CREATE TABLE newsletter_subscribers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    source TEXT,                              -- 'homepage', 'blog', etc.
    status TEXT NOT NULL DEFAULT 'active',    -- 'active', 'unsubscribed'
    client_ip INET,

    subscribed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    unsubscribed_at TIMESTAMP,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_newsletter_email ON newsletter_subscribers(email);
CREATE INDEX idx_newsletter_status ON newsletter_subscribers(status);
```

---

## Environment Configuration

### Required Environment Variables

```bash
# ==================================================================
# AWS COGNITO AUTHENTICATION (REQUIRED)
# ==================================================================
AWS_REGION=us-east-1
COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxx
COGNITO_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxx
COGNITO_DOMAIN=your-app.auth.us-east-1.amazoncognito.com

# ==================================================================
# DATABASE (REQUIRED)
# ==================================================================
DATABASE_URL=postgresql://user:password@host:5432/dbname

# ==================================================================
# APPLICATION (REQUIRED)
# ==================================================================
FRONTEND_URL=http://localhost:5173
BACKEND_URL=http://localhost:8000
JWT_SECRET_KEY=your-jwt-secret-key-change-in-production
ENVIRONMENT=development

# ==================================================================
# EMAIL - AWS SES (REQUIRED)
# ==================================================================
FROM_EMAIL=noreply@betterandbliss.com
SUPPORT_EMAIL=support@betterandbliss.com
SES_CONFIGURATION_SET=

# ==================================================================
# STREAMING SECURITY (CRITICAL FOR PRODUCTION)
# ==================================================================
# Generate with: python -c "import secrets; print(secrets.token_urlsafe(48))"
STREAMING_SECRET_KEY=CHANGE-THIS-TO-A-SECURE-RANDOM-STRING-MIN-32-CHARS

# CloudFront CDN
CLOUDFRONT_DOMAIN=d1234567890abc.cloudfront.net
VIDEO_BUCKET_NAME=betterbliss-videos-production
S3_REGION=us-east-1

# URL Expiry
VIDEO_URL_EXPIRY_MINUTES=120      # 2 hours
AUDIO_URL_EXPIRY_MINUTES=120
THUMBNAIL_URL_EXPIRY_HOURS=24

# Streaming Features
ENABLE_STREAMING_TOKEN_VALIDATION=false  # Set true if Lambda@Edge configured
ENABLE_GEO_RESTRICTION=false
ALLOWED_COUNTRIES=                       # Comma-separated country codes
```

### Optional Environment Variables

```bash
# ==================================================================
# DATADOG MONITORING (RECOMMENDED)
# ==================================================================
DD_API_KEY=your-datadog-api-key
DD_SITE=datadoghq.com
DD_SERVICE=betterbliss-auth
DD_ENV=production
DD_VERSION=1.0.0
DD_TRACE_ENABLED=true
DD_LOGS_ENABLED=true

# ==================================================================
# SECURITY (OPTIONAL BUT RECOMMENDED)
# ==================================================================
# CAPTCHA
ENABLE_CAPTCHA=true
RECAPTCHA_SECRET_KEY=your-recaptcha-secret-key
RECAPTCHA_MIN_SCORE=0.5

# API Encryption (AES-256-GCM)
ENABLE_API_ENCRYPTION=false
API_ENCRYPTION_KEY=
API_HMAC_KEY=

# ==================================================================
# COOKIE SETTINGS
# ==================================================================
COOKIE_SAMESITE=strict
COOKIE_HTTPONLY=true
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7
COOKIE_DOMAIN=                    # Auto-detected in production

# ==================================================================
# AWS CREDENTIALS (if not using IAM roles)
# ==================================================================
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1

# ==================================================================
# MEDIACONVERT (for video processing)
# ==================================================================
MEDIACONVERT_ENDPOINT=
MEDIACONVERT_ROLE=
MEDIACONVERT_QUEUE=
```

### Generating Secure Keys

```bash
# Streaming Secret Key (minimum 32 characters)
python -c "import secrets; print(secrets.token_urlsafe(48))"

# JWT Secret Key
python -c "import secrets; print(secrets.token_hex(32))"

# API Encryption Key (256-bit)
python -c "import secrets; print(secrets.token_urlsafe(32))"

# API HMAC Key
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

---

## Quick Start Guide

### 1. Setup Environment

```bash
# Clone repository
git clone <repo-url>
cd betterbliss-auth

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy environment template
cp .env.example .env

# Edit .env with your AWS credentials
nano .env
```

### 2. Configure AWS Cognito

1. **Create User Pool**:
   - Go to AWS Cognito Console
   - Create User Pool
   - Enable email as username
   - Add custom attributes: `role`, `subscription_tier`, `permissions`

2. **Create App Client**:
   - Add app client with secret
   - Enable `USER_PASSWORD_AUTH` flow
   - Configure OAuth (for Google login)

3. **Setup Google OAuth** (optional):
   - Add Google as identity provider
   - Configure callback URL: `https://your-backend.com/auth/callback`

### 3. Setup Database

```bash
# Create database
createdb betterbliss

# Run migrations
python -m app.database.migrations
```

### 4. Run Application

```bash
# Development
uvicorn app.main:app --reload --port 8000

# Production
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

### 5. Test API

```bash
# Health check
curl http://localhost:8000/health

# Register user
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!",
    "full_name": "Test User"
  }'

# Login
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!"
  }' \
  -c cookies.txt

# Get current user
curl http://localhost:8000/auth/me \
  -b cookies.txt
```

---

## Troubleshooting

### Common Issues

**1. "Invalid SECRET_HASH" error**:
```bash
# Ensure you're calculating SECRET_HASH correctly
# Formula: HMAC-SHA256(username + client_id, client_secret) → base64
# Username should be the email address
```

**2. CORS errors**:
```bash
# Check FRONTEND_URL in .env matches your frontend origin
# Example: FRONTEND_URL=http://localhost:3000
```

**3. "Streaming URL expired"**:
```bash
# URLs expire after VIDEO_URL_EXPIRY_MINUTES (default: 120)
# Request new streaming URLs from /api/streaming/content/{uuid}/stream
```

**4. Database connection failed**:
```bash
# Verify DATABASE_URL format
# postgresql://username:password@host:port/database
```

**5. Cognito authentication failed**:
```bash
# Verify all Cognito settings in .env
# Check AWS region matches user pool region
# Ensure COGNITO_CLIENT_SECRET is correct
```

---

## Security Best Practices

### Production Checklist

- [ ] **Generate secure random keys** for `STREAMING_SECRET_KEY`, `JWT_SECRET_KEY`
- [ ] **Enable HTTPS** (required for cookies with `Secure` flag)
- [ ] **Set `ENVIRONMENT=production`** in .env
- [ ] **Configure CORS** with specific frontend domain (not `*`)
- [ ] **Enable Datadog monitoring** (`DD_API_KEY`, `DD_TRACE_ENABLED=true`)
- [ ] **Use IAM roles** instead of hardcoded AWS credentials
- [ ] **Enable CAPTCHA** to prevent bot attacks
- [ ] **Set strong password policy** in Cognito
- [ ] **Configure rate limiting** to prevent abuse
- [ ] **Use database SSL** (`DB_SSL_MODE=require`)
- [ ] **Review CloudFront Lambda@Edge** for token validation
- [ ] **Setup AWS CloudWatch alarms** for errors
- [ ] **Enable database backups** (automated snapshots)
- [ ] **Use secrets manager** (AWS Secrets Manager or similar)
- [ ] **Implement IP allowlisting** for admin endpoints

---

## Support & Documentation

- **API Documentation**: http://localhost:8000/api/docs (Swagger UI)
- **Alternative Docs**: http://localhost:8000/api/redoc (ReDoc)
- **Health Check**: http://localhost:8000/health
- **Meditation API Reference**: See `MEDITATION_API_REFERENCE.md`
- **Frontend Integration**: See `FRONTEND_IMPLEMENTATION_GUIDE.md`

---

**Last Updated**: 2025-11-05
**Version**: 2.0.0
**Maintained by**: Better & Bliss Development Team
