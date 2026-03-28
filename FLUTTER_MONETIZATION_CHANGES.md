# Flutter UI — Monetization Integration Changes

> This document explains every Flutter-side change made to integrate the new **Subscriptions**, **Creator Marketplace**, and **Live Coaching** backend APIs. Written for the backend team so you understand exactly how the app calls your endpoints, what it expects back, and where each piece lives.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [API Endpoints Mapping](#2-api-endpoints-mapping)
3. [Services Layer (HTTP Calls)](#3-services-layer-http-calls)
4. [State Management (BLoCs)](#4-state-management-blocs)
5. [Screens & User Flows](#5-screens--user-flows)
6. [Profile Page Changes](#6-profile-page-changes)
7. [Explore Page Changes](#7-explore-page-changes)
8. [Routing](#8-routing)
9. [Dependencies Added](#9-dependencies-added)
10. [What the App Does NOT Do Yet](#10-what-the-app-does-not-do-yet)
11. [File Inventory](#11-file-inventory)

---

## 1. Architecture Overview

Every feature follows the same pattern the app already uses:

```
Backend API
    ↓
Service (Dio HTTP calls, response parsing, error extraction)
    ↓
BLoC (state machine: Events → States)
    ↓
Page (UI reads BLoC state, dispatches events)
```

All HTTP requests go through `ApiClient` (singleton Dio instance) which automatically attaches:
- `Authorization: Token <user-token>` header
- `X-Client-Id: <app-key>` header
- `Content-Type: application/json`

Every service expects the backend's standard envelope:
```json
{ "success": true, "data": { ... } }
```
or on error:
```json
{ "success": false, "error": { "code": "ERROR_CODE", "message": "..." } }
```

---

## 2. API Endpoints Mapping

All endpoints are defined in `lib/core/config/api_endpoints.dart`. Here is exactly what the Flutter app calls:

### Subscriptions

| What the app calls | HTTP | Backend endpoint |
|---|---|---|
| `ApiEndpoints.subscriptionCheckout` | POST | `/api/subscriptions/checkout/` |
| `ApiEndpoints.subscriptionPortal` | POST | `/api/subscriptions/portal/` |
| `ApiEndpoints.subscriptionStatus` | GET | `/api/subscriptions/status/` |

### Marketplace

| What the app calls | HTTP | Backend endpoint |
|---|---|---|
| `ApiEndpoints.marketplacePrograms` | GET | `/api/marketplace/programs/` |
| `ApiEndpoints.marketplaceProgramDetail(id)` | GET | `/api/marketplace/programs/<uuid>/` |
| `ApiEndpoints.marketplaceProgramPurchase(id)` | POST | `/api/marketplace/programs/<uuid>/purchase/` |
| `ApiEndpoints.marketplaceProgramContent(id)` | GET | `/api/marketplace/programs/<uuid>/content/` |
| `ApiEndpoints.marketplacePurchases` | GET | `/api/marketplace/purchases/` |

### Coaching

| What the app calls | HTTP | Backend endpoint |
|---|---|---|
| `ApiEndpoints.coaches` | GET | `/api/coaching/coaches/` |
| `ApiEndpoints.coachDetail(id)` | GET | `/api/coaching/coaches/<uuid>/` |
| `ApiEndpoints.coachBookingUrl(id)` | GET | `/api/coaching/coaches/<uuid>/booking-url/` |
| `ApiEndpoints.coachingSessions` | GET | `/api/coaching/sessions/` |
| `ApiEndpoints.coachingSessionJoin(id)` | POST | `/api/coaching/sessions/<uuid>/join/` |
| `ApiEndpoints.coachingSessionCancel(id)` | POST | `/api/coaching/sessions/<uuid>/cancel/` |

---

## 3. Services Layer (HTTP Calls)

Each service is a singleton that uses `ApiClient.instance` for all requests. Here is exactly what each method sends and what it reads from the response.

### 3.1 SubscriptionService (`lib/core/services/subscription_service.dart`)

**`createCheckout(String tier)`**
- Sends: `POST /api/subscriptions/checkout/` with body `{"tier": "basic"}` or `{"tier": "premium"}`
- Reads: `response.data['checkout_url']` and `response.data['session_id']`
- The app opens `checkout_url` in the device's external browser via `url_launcher`
- After the user returns from Stripe, the app calls `getStatus()` to refresh the tier

**`openPortal()`**
- Sends: `POST /api/subscriptions/portal/` with no body
- Reads: `response.data['portal_url']`
- Opens `portal_url` in external browser

**`getStatus()`**
- Sends: `GET /api/subscriptions/status/`
- Reads: `response.data['subscription']` and parses into a `SubscriptionStatus` model with fields: `tier`, `status`, `current_period_end`, `stripe_subscription_id`
- Called on app launch (BLoC is created with `LoadSubscriptionStatus` event in `main.dart`), after checkout returns, and after portal returns

### 3.2 MarketplaceService (`lib/core/services/marketplace_service.dart`)

**`getPrograms({categoryId, creatorId, search})`**
- Sends: `GET /api/marketplace/programs/` with optional query params `?category=<uuid>&creator=<uuid>&search=<string>`
- Reads: `response.data['programs']` as a List, maps each to `MarketplaceProgram`
- Fields the app uses from each program: `id`, `title`, `slug`, `description`, `cover_image_url`, `price`, `creator.id`, `creator.display_name`, `creator.avatar_url`, `category.id`, `category.name`, `content_count`, `purchase_count`, `is_purchased`

**`getProgramDetail(String programId)`**
- Sends: `GET /api/marketplace/programs/<uuid>/`
- Reads: `response.data['program']` (falls back to `response.data` if no wrapper)
- Same fields as list item

**`purchaseProgram(String programId)`**
- Sends: `POST /api/marketplace/programs/<uuid>/purchase/` with no body
- Reads: `response.data['client_secret']`, `response.data['payment_intent_id']`, `response.data['amount']`, `response.data['currency']`
- The app currently shows a placeholder SnackBar — full `flutter_stripe` payment sheet integration is stubbed

**`getProgramContent(String programId)`**
- Sends: `GET /api/marketplace/programs/<uuid>/content/`
- Reads: `response.data['content_items']` as a List
- Fields used: `id`, `title`, `content_type` ("video" or "article"), `thumbnail_url`, `duration_seconds`
- Only called when `is_purchased == true`

**`getMyPurchases()`**
- Sends: `GET /api/marketplace/purchases/`
- Reads: `response.data['purchases']` as a List
- Fields used: `id`, `program.id`, `program.title`, `program.cover_image_url`, `amount`, `status`, `purchased_at`

### 3.3 CoachingService (`lib/core/services/coaching_service.dart`)

**`getCoaches({specialty, maxPrice})`**
- Sends: `GET /api/coaching/coaches/` with optional `?specialty=<string>&max_price=<decimal>`
- Reads: `response.data['coaches']` as a List
- Fields used: `id`, `expert.id`, `expert.name`, `expert.avatar_url`, `expert.title`, `hourly_rate`, `discounted_rate` (nullable), `premium_discount_percent`, `bio`, `specialties` (List of strings), `is_accepting_clients`, `has_calcom`

**`getCoachDetail(String coachId)`**
- Sends: `GET /api/coaching/coaches/<uuid>/`
- Reads: `response.data['coach']` (falls back to `response.data`)

**`getBookingUrl(String coachId)`**
- Sends: `GET /api/coaching/coaches/<uuid>/booking-url/`
- Reads: `response.data['booking_url']`, `response.data['embed_url']`, `response.data['coach']`
- The app opens `booking_url` in external browser via `url_launcher`

**`getSessions({role})`**
- Sends: `GET /api/coaching/sessions/?role=client` (default) or `?role=coach`
- Reads: `response.data['sessions']` as a List
- Fields used: `id`, `coach.id`, `coach.name`, `coach.avatar_url`, `client_id`, `scheduled_at` (ISO datetime string), `duration_minutes`, `status`, `amount`, `discount_applied`, `notes`, `created_at`
- The app splits sessions into "Upcoming" (`pending_payment`, `confirmed`, `in_progress`) and "Past" (`completed`, `cancelled_by_client`, `cancelled_by_coach`, `no_show`)

**`joinSession(String sessionId)`**
- Sends: `POST /api/coaching/sessions/<uuid>/join/` with no body
- Reads: `response.data['token']`, `response.data['livekit_url']`, `response.data['room_name']`, `response.data['role']`, `response.data['session']`
- Currently shows a placeholder SnackBar — full `livekit_client` integration is stubbed

**`cancelSession(String sessionId, {reason})`**
- Sends: `POST /api/coaching/sessions/<uuid>/cancel/` with optional body `{"reason": "..."}`
- Reads: `response.data['status']`, `response.data['refund_amount']`, `response.data['hours_until_session']`
- Before calling, the app shows a dialog with the refund policy (calculated client-side from `scheduled_at`)

---

## 4. State Management (BLoCs)

Each BLoC translates user actions (Events) into UI states (States). The backend only needs to care about **when** the app calls which endpoint — that's documented here.

### 4.1 SubscriptionBloc

| Event | What happens | API called |
|---|---|---|
| `LoadSubscriptionStatus` | Fired on app launch in `main.dart` | `GET /api/subscriptions/status/` |
| `CreateCheckout(tier)` | User taps "Get Started" on a plan card | `POST /api/subscriptions/checkout/` |
| `OpenBillingPortal` | User taps "Manage" on their current plan | `POST /api/subscriptions/portal/` |
| `RefreshSubscription` | After returning from Stripe browser | `GET /api/subscriptions/status/` |

The `lastStatus` property caches the latest `SubscriptionStatus` so the profile page can read the tier without re-fetching.

### 4.2 MarketplaceBloc

| Event | What happens | API called |
|---|---|---|
| `LoadPrograms({category, search})` | Marketplace page opens, or user searches | `GET /api/marketplace/programs/` |
| `LoadProgramDetail(programId)` | User taps a program card | `GET /api/marketplace/programs/<id>/` + `GET .../content/` if purchased |
| `PurchaseProgram(programId)` | User taps "Buy Now" | `POST /api/marketplace/programs/<id>/purchase/` |
| `LoadProgramContent(programId)` | User taps "View Content" on a purchased program | `GET /api/marketplace/programs/<id>/` + `GET .../content/` |
| `LoadMyPurchases` | User opens "My Purchases" page | `GET /api/marketplace/purchases/` |

### 4.3 CoachingBloc

| Event | What happens | API called |
|---|---|---|
| `LoadCoaches({specialty, maxPrice})` | Coaches page opens, or Explore page loads | `GET /api/coaching/coaches/` |
| `LoadCoachDetail(coachId)` | User taps a coach card | `GET /api/coaching/coaches/<id>/` |
| `GetBookingUrl(coachId)` | User taps "Book a Session" on coach detail | `GET /api/coaching/coaches/<id>/booking-url/` |
| `LoadSessions({role})` | Sessions page opens | `GET /api/coaching/sessions/` |
| `JoinSession(sessionId)` | User taps "Join Video" on an in-progress session | `POST /api/coaching/sessions/<id>/join/` |
| `CancelSession(sessionId, reason)` | User confirms cancellation dialog | `POST /api/coaching/sessions/<id>/cancel/` |

---

## 5. Screens & User Flows

### 5.1 Subscription Plans (`/subscription-plans`)

**Flow:**
1. User navigates from profile page "Upgrade" / "Manage" button
2. Page fires `LoadSubscriptionStatus` to get current tier
3. Displays three plan cards: Free ($0), Basic ($9.99), Premium ($19.99)
4. Current plan shows a green "Current" badge; other plans show "Get Started"
5. If user is on free → taps a paid plan → `POST /api/subscriptions/checkout/` → opens Stripe Checkout URL in external browser
6. If user is already subscribed → taps another plan → `POST /api/subscriptions/portal/` → opens Stripe billing portal
7. On return to app → `GET /api/subscriptions/status/` to refresh

### 5.2 Marketplace Browse (`/marketplace`)

**Flow:**
1. Shows a search bar at top — submitting fires `GET /api/marketplace/programs/?search=<query>`
2. Programs listed as vertical cards with cover image, category badge, title, creator name, price, lesson count, purchase count
3. Programs with `is_purchased: true` show a green "Purchased" badge
4. Top-right shopping bag icon navigates to My Purchases page
5. Tapping a card navigates to program detail

### 5.3 Program Detail (`/marketplace-detail?id=<uuid>`)

**Flow:**
1. Fires `GET /api/marketplace/programs/<uuid>/`
2. If `is_purchased == true`, also fires `GET /api/marketplace/programs/<uuid>/content/`
3. Shows cover image, category, title, creator avatar+name, stats (lessons, students), full description
4. Bottom bar: if not purchased → shows price + "Buy Now" button; if purchased → shows "View Content" button
5. "Buy Now" fires `POST /api/marketplace/programs/<uuid>/purchase/` — returns `client_secret` for Stripe payment sheet (currently stubbed)

### 5.4 My Purchases (`/my-purchases`)

**Flow:**
1. Fires `GET /api/marketplace/purchases/`
2. Lists purchases with thumbnail, title, amount
3. Tapping navigates to program detail page

### 5.5 Coaches Browse (`/coaches`)

**Flow:**
1. Fires `GET /api/coaching/coaches/`
2. Lists coaches as cards with avatar, name, title, specialties (chips), price
3. If `discounted_rate` is not null → shows original price with strikethrough + discounted price in green + "Premium" badge
4. If `has_calcom == true && is_accepting_clients == true` → shows "Book" button; otherwise shows "Coming soon"
5. Top-right calendar icon navigates to My Sessions page
6. Tapping a card navigates to coach detail

### 5.6 Coach Detail (`/coach-detail?id=<uuid>`)

**Flow:**
1. Fires `GET /api/coaching/coaches/<uuid>/`
2. Shows avatar, name, title, price card (with discount if applicable), bio, specialties as chips
3. Bottom bar: if `has_calcom && is_accepting_clients` → "Book a Session" button; otherwise → "Scheduling coming soon"
4. "Book a Session" fires `GET /api/coaching/coaches/<uuid>/booking-url/` → opens `booking_url` in external browser (Cal.com)

### 5.7 Coaching Sessions (`/coaching-sessions`)

**Flow:**
1. Fires `GET /api/coaching/sessions/?role=client`
2. Two tabs: "Upcoming" and "Past" — sessions are split client-side based on `status`
3. Each card shows: coach avatar+name, status badge (color-coded), date, time, duration, amount, discount badge if applicable
4. Action buttons per status:
   - `pending_payment` → "Complete Payment" (Stripe stub)
   - `confirmed` → "Cancel" (opens refund dialog → `POST .../cancel/`)
   - `in_progress` → "Join Video" (`POST .../join/` → LiveKit stub)
5. Cancel dialog calculates refund tier client-side: 24+ hrs = full, 2-24 hrs = 50%, <2 hrs = none — then calls backend which returns actual `refund_amount`

---

## 6. Profile Page Changes

The static "Free Plan" membership card was replaced with a **dynamic card** that reads from `SubscriptionBloc.lastStatus`:

| Tier | Card gradient | Icon | Description | Button |
|---|---|---|---|---|
| `free` | Dark gray | Star | "Limited access to content" | "Upgrade" → navigates to `/subscription-plans` |
| `basic` | Blue | Premium badge | "720p streaming, food scanner, 1 coaching session/mo" | "Manage" → navigates to `/subscription-plans` |
| `premium` | Purple | Premium badge | "Full HD, wearable sync, unlimited coaching" | "Manage" → navigates to `/subscription-plans` |

Below the membership card, two new quick-access tiles were added:
- **Marketplace** (amber storefront icon) → navigates to `/marketplace`
- **Live Coaching** (purple video camera icon) → navigates to `/coaches`

---

## 7. Explore Page Changes

Two new horizontal scrollable sections were added to the "Explore" tab (between "Trending" and "Wellness Audio"):

### Live Coaching Section
- Header: "Live Coaching" with "See All" link → `/coaches`
- Fires `LoadCoaches` event on page load
- Shows coach cards (160px wide) with: avatar circle, name, title, green live indicator dot, hourly rate (green if discounted)
- Tapping a card → `/coach-detail?id=<uuid>`

### Programs Section
- Header: "Programs" with "Browse All" link → `/marketplace`
- Fires `LoadPrograms` event on page load
- Shows program cards (200px wide) with: cover image, price badge overlay, "Owned" badge if purchased, title, creator + lesson count
- Tapping a card → `/marketplace-detail?id=<uuid>`

---

## 8. Routing

New routes registered in `lib/core/navigation/app_router.dart`:

| Route path | Page | Query params |
|---|---|---|
| `/subscription-plans` | `SubscriptionPlansPage` | none |
| `/marketplace` | `MarketplacePage` | none |
| `/marketplace-detail` | `ProgramDetailPage` | `?id=<uuid>` |
| `/my-purchases` | `MyPurchasesPage` | none |
| `/coaches` | `CoachesPage` | none |
| `/coach-detail` | `CoachDetailPage` | `?id=<uuid>` |
| `/coaching-sessions` | `CoachingSessionsPage` | none |

All routes are protected (require authentication via the existing GoRouter auth guard).

---

## 9. Dependencies Added

| Package | Version | Why |
|---|---|---|
| `url_launcher` | ^6.2.1 | Opens Stripe Checkout URLs, Stripe billing portal, and Cal.com booking URLs in the device's external browser |

**Not added yet (future):**
- `flutter_stripe` — for native payment sheet (program purchases). Currently stubbed with SnackBar.
- `livekit_client` — for 1:1 video sessions. Currently stubbed with SnackBar.

---

## 10. What the App Does NOT Do Yet

These are intentional stubs. The backend endpoints exist and the app calls them, but the native SDK integration is pending:

| Feature | What happens now | What's needed |
|---|---|---|
| **Stripe Payment Sheet** (program purchase) | App calls `POST .../purchase/`, gets `client_secret`, shows a SnackBar placeholder | Integrate `flutter_stripe` SDK, call `Stripe.instance.initPaymentSheet()` with the `client_secret`, then `presentPaymentSheet()` |
| **LiveKit Video Session** | App calls `POST .../join/`, gets `token` + `livekit_url`, shows a SnackBar placeholder | Integrate `livekit_client` SDK, call `room.connect(livekitUrl, token)`, build video UI with `VideoTrackRenderer` |
| **Deep Link Handling** for `betterbliss://subscription/success` and `betterbliss://subscription/cancel` | Not wired yet | Add deep link listeners in `OAuthService` or a new handler to detect these URLs and refresh subscription status |
| **Stripe Checkout in WebView** | Opens in external browser | Could use `webview_flutter` for in-app experience |
| **Cal.com Booking Completion Detection** | Opens in external browser, no callback | Could use WebView with URL matching to detect `booking-confirmed` redirect |
| **Pull-to-Refresh on Sessions** | Not implemented | Add `RefreshIndicator` that re-dispatches `LoadSessions` |

---

## 11. File Inventory

### New files (13)

```
lib/core/services/
├── subscription_service.dart      — HTTP calls for subscriptions
├── marketplace_service.dart       — HTTP calls + models for marketplace
└── coaching_service.dart          — HTTP calls + models for coaching

lib/features/subscription/
└── presentation/
    ├── bloc/subscription_bloc.dart     — Events, States, BLoC
    └── pages/subscription_plans_page.dart — Plan selection UI

lib/features/marketplace/
└── presentation/
    ├── bloc/marketplace_bloc.dart      — Events, States, BLoC
    └── pages/
        ├── marketplace_page.dart       — Browse programs
        ├── program_detail_page.dart    — Program detail + content
        └── my_purchases_page.dart      — Purchase history

lib/features/coaching/
└── presentation/
    ├── bloc/coaching_bloc.dart         — Events, States, BLoC
    └── pages/
        ├── coaches_page.dart           — Browse coaches
        ├── coach_detail_page.dart      — Coach profile + booking
        └── coaching_sessions_page.dart — Upcoming/past sessions
```

### Modified files (5)

| File | What changed |
|---|---|
| `lib/core/config/api_endpoints.dart` | Replaced old subscription endpoints with new ones; added marketplace and coaching endpoint definitions |
| `lib/core/navigation/app_router.dart` | Added 7 new route definitions and their imports |
| `lib/main.dart` | Registered `SubscriptionBloc`, `MarketplaceBloc`, `CoachingBloc` in `MultiBlocProvider`; `SubscriptionBloc` fires `LoadSubscriptionStatus` on creation |
| `lib/features/profile/presentation/pages/profile_page.dart` | Replaced static "Free Plan" card with dynamic membership card + added Marketplace/Coaching quick-access tiles |
| `lib/features/explore/presentation/pages/explore_for_you_page.dart` | Added "Live Coaching" and "Programs" horizontal sections with coach and program cards |
| `pubspec.yaml` | Added `url_launcher: ^6.2.1` |
