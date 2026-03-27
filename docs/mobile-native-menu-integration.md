# Noralooks — Native Mobile App: Bottom Tab Bar Integration Guide

## Overview

The Noralooks storefront is a Rails web application rendered inside a Hotwire Native web view (WKWebView on iOS, WebView on Android). The web app already has a mobile bottom navigation bar, but when loaded inside the native app, the **web bottom nav is automatically hidden** by the server. The native app must render its own **native bottom tab bar** to replace it.

This document covers every scenario and implementation detail needed to build the native tab bar with a live cart badge.

---

## 1. Architecture

```
┌─────────────────────────────────┐
│         Native App Shell        │
│  ┌───────────────────────────┐  │
│  │                           │  │
│  │     WKWebView / WebView   │  │
│  │   (Renders Rails pages)   │  │
│  │                           │  │
│  │   padding-bottom: 70px    │  │
│  │   (server adds this for   │  │
│  │    Hotwire user-agent)    │  │
│  │                           │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │   Native Bottom Tab Bar   │  │
│  │  Home Search Cart Orders  │  │
│  │                  Account  │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

### How the server detects the native app

The server checks the User-Agent header for the string `"Hotwire"`. When detected:

- The web bottom nav bar is **completely hidden** (not rendered in DOM visibility)
- The `<body>` main content gets `padding-bottom: 70px` to make room for the native tab bar
- Viewport is locked: `maximum-scale=1, user-scalable=no`
- Long-press context menus and text selection are disabled on links, images, and buttons

**CRITICAL**: Your app's User-Agent string MUST contain `"Hotwire"` for this to work. Hotwire Native libraries do this by default. Verify by logging `navigator.userAgent` in the web view.

---

## 2. User-Agent Requirement

### iOS (Swift)
Hotwire Native for iOS automatically appends `"Hotwire Native iOS"` to the User-Agent. If you are using a custom WKWebView, ensure your User-Agent contains the substring `"Hotwire"`.

### Android (Kotlin)
Hotwire Native for Android automatically appends `"Hotwire Native Android"` to the User-Agent. If you are using a custom WebView, set it manually:

```kotlin
webView.settings.userAgentString = webView.settings.userAgentString + " Hotwire Native Android"
```

### Verification
Load any page and check that:
1. The web bottom nav bar (Search, Cart, Home, Orders, Account) is NOT visible
2. The page content has bottom padding (approx 70px gap at the bottom)

If the web nav is still showing, your User-Agent is not being detected. Debug by hitting any page and checking the server logs for the User-Agent string.

---

## 3. API Endpoints

Base URL: Your app's domain (e.g., `https://noralooks.com`)

### 3.1 GET /api/mobile/navigation

Returns the tab bar configuration and pages where the native menu should be hidden.

**Authentication**: None required. Public endpoint. No CSRF token needed.

**Request**:
```
GET /api/mobile/navigation
Cookie: <session cookie from web view> (optional but recommended — needed for correct Account tab URL)
```

**Response** (200 OK):
```json
{
  "tabs": [
    { "name": "Home",    "path": "https://noralooks.com/" },
    { "name": "Search",  "path": "https://noralooks.com/products" },
    { "name": "Cart",    "path": "https://noralooks.com/cart" },
    { "name": "Orders",  "path": "https://noralooks.com/orders" },
    { "name": "Account", "path": "https://noralooks.com/account" }
  ],
  "hide_native_menu_patterns": [
    { "path": "/products/*", "description": "Product detail pages" },
    { "path": "/cart",       "description": "Cart page" },
    { "path": "/checkout",   "description": "Checkout pages" }
  ]
}
```

**Notes on the Account tab**:
- If the user is **logged in** (session cookie present with valid session): `path` = `/account`
- If the user is **not logged in**: `path` = `/login`
- The native app should re-fetch this endpoint after login/logout to get the updated Account URL, OR simply always navigate to `/account` and let the server redirect to `/login` if needed (the web app handles this redirect automatically)

**When to call this endpoint**:
- Once on app launch to build the tab bar
- After login or logout (to update the Account tab URL)
- Optionally cache the response and refresh periodically

### 3.2 GET /api/mobile/cart_count

Returns the current cart item count for the badge on the Cart tab.

**Authentication**: None required. Uses the session cookie from the web view's cookie jar.

**Request**:
```
GET /api/mobile/cart_count
Cookie: <session cookie from web view>
```

**Response** (200 OK):
```json
{
  "count": 3
}
```

**How sessions work (important)**:
- The web view maintains a cookie jar automatically
- When a guest user adds items to cart, the server stores a `cart_token` in the session cookie
- When a logged-in user has a cart, it's tied to their `customer_id` in the session
- As long as you make API calls using the **same cookie jar** as the web view, the server resolves the correct cart automatically
- Guest carts persist across sessions via the cookie — no login required

**When to call this endpoint**:
- On app launch (initial badge count)
- On each tab switch (as a fallback sync mechanism)
- As a fallback if the JavaScript bridge message is missed

---

## 4. Hiding the Native Tab Bar on Specific Pages

The `hide_native_menu_patterns` array from the navigation API tells you which pages should NOT show the native tab bar. The native app must observe the current URL in the web view and hide/show the tab bar accordingly.

### Patterns to match

| Pattern | Matches | Examples |
|---------|---------|----------|
| `/products/*` | Any URL starting with `/products/` followed by a slug | `/products/gold-ring`, `/products/silver-necklace` |
| `/cart` | Exact match on the cart page | `/cart` |
| `/checkout` | Any URL starting with `/checkout` | `/checkout`, `/checkout/confirm` |

### Implementation

#### iOS (Swift)
```swift
// In your Turbo Navigator / WKNavigationDelegate
func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    guard let url = webView.url else { return }
    let path = url.path

    let shouldHideTabBar = path.hasPrefix("/products/") ||
                           path == "/cart" ||
                           path.hasPrefix("/checkout")

    setTabBarHidden(shouldHideTabBar, animated: true)
}
```

#### Android (Kotlin)
```kotlin
// In your TurboSessionNavHostFragment or WebViewClient
override fun onPageFinished(view: WebView, url: String) {
    val path = Uri.parse(url).path ?: ""

    val shouldHide = path.startsWith("/products/") ||
                     path == "/cart" ||
                     path.startsWith("/checkout")

    bottomNavigationView.isVisible = !shouldHide
}
```

### Why these pages hide the tab bar
- **Product detail pages** (`/products/*`): These have their own sticky "Add to Cart" bar at the bottom — the tab bar would overlap and conflict with it
- **Cart page** (`/cart`): Has a sticky checkout button at the bottom
- **Checkout pages** (`/checkout`, `/checkout/confirm`): Full-screen checkout flow — no distractions, user should complete the purchase

### Transition behavior
- When navigating FROM a tab-bar-visible page TO a hidden page: animate the tab bar sliding down/fading out
- When navigating BACK to a tab-bar-visible page: animate the tab bar sliding up/fading in
- Keep the transition smooth (200-300ms) to avoid jarring UX

---

## 5. Cart Badge — Real-Time Updates via JavaScript Bridge

When items are added, updated, or removed from the cart, the Rails server sends a Turbo Stream response that injects a `<script>` tag into the web view. This script posts a message to the native app with the updated cart count.

### 5.1 iOS — WKScriptMessageHandler

**Register the message handler** on the web view's user content controller:

```swift
class CartCountHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: CartBadgeDelegate?

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let count = message.body as? Int else { return }
        DispatchQueue.main.async {
            self.delegate?.updateCartBadge(count: count)
        }
    }
}

// During web view setup:
let handler = CartCountHandler()
handler.delegate = self
webView.configuration.userContentController.add(handler, name: "cartCount")
```

**The JavaScript that fires** (injected by the server via Turbo Stream):
```javascript
window.webkit.messageHandlers.cartCount.postMessage(3);
```

**Important**: The message handler name MUST be exactly `"cartCount"` (camelCase). This is hardcoded on the server side.

### 5.2 Android — JavascriptInterface

**Register the JavaScript interface** on the WebView:

```kotlin
class NativeAndroidBridge {
    var onCartCountUpdate: ((Int) -> Unit)? = null

    @JavascriptInterface
    fun updateCartCount(count: Int) {
        onCartCountUpdate?.invoke(count)
    }
}

// During web view setup:
val bridge = NativeAndroidBridge()
bridge.onCartCountUpdate = { count ->
    runOnUiThread {
        updateCartBadge(count)
    }
}
webView.addJavascriptInterface(bridge, "NoralooksAndroid")
```

**The JavaScript that fires** (injected by the server via Turbo Stream):
```javascript
window.NoralooksAndroid.updateCartCount(3);
```

**Important**: The interface name MUST be exactly `"NoralooksAndroid"` and the method MUST be exactly `updateCartCount(int)`. These are hardcoded on the server side.

### 5.3 When the bridge fires

The JavaScript bridge message is sent on EVERY cart mutation:

| User Action | Trigger |
|-------------|---------|
| Add item to cart (from product page, product card, etc.) | Turbo Stream response from `POST /cart/add/:variant_id` |
| Increase/decrease item quantity (from cart page) | Turbo Stream response from `PATCH /cart/update/:variant_id` |
| Remove item from cart (from cart page) | Turbo Stream response from `DELETE /cart/remove/:variant_id` |
| Clear entire cart | Full page redirect (no bridge message — use fallback) |

### 5.4 Fallback: When the bridge might NOT fire

There are edge cases where the JavaScript bridge message may not reach the native app:

| Scenario | Why | Fallback |
|----------|-----|----------|
| Cart cleared via "Clear Cart" button | Uses full page redirect, not Turbo Stream | Poll `/api/mobile/cart_count` on page load |
| Coupon applied/removed | Does not change item count, but triggers redirect | No action needed — count unchanged |
| User logs in (guest cart merges with account cart) | Login is a full page redirect | Poll `/api/mobile/cart_count` after login completes |
| User logs out | Session changes, cart may change | Poll `/api/mobile/cart_count` after logout completes |
| App returns from background | Web view may have been suspended | Poll `/api/mobile/cart_count` on `applicationDidBecomeActive` (iOS) / `onResume` (Android) |
| Web view process terminated (iOS low memory) | WKWebView content process killed | Poll `/api/mobile/cart_count` when web view reloads |
| Checkout completed (order placed) | Cart is converted, count goes to 0 | Poll `/api/mobile/cart_count` after navigation to order confirmation page |

**Recommended fallback strategy**: Call `GET /api/mobile/cart_count` on every full page navigation (when the web view fires `didFinish` / `onPageFinished`). This ensures the badge is always accurate even if a bridge message was missed. The endpoint is lightweight.

---

## 6. Tab Bar Badge Display Rules

| Count | Badge Display |
|-------|---------------|
| `0` | No badge (hide badge completely) |
| `1-99` | Show the number |
| `100+` | Show `"99+"` |

---

## 7. Session & Cookie Management

### How it works
The web view (WKWebView / WebView) automatically manages cookies like a browser. The Rails server uses a session cookie to track:

- **Guest users**: `cart_token` stored in session — identifies the guest cart
- **Logged-in users**: `customer_id` stored in session — identifies the customer and their cart

### Cookie sharing between web view and native API calls

**CRITICAL**: When making API calls (`/api/mobile/navigation`, `/api/mobile/cart_count`) from native code, you MUST use the same cookie jar as the web view. Otherwise the server won't know which cart or customer to look up.

#### iOS
```swift
// WKWebView shares cookies with URLSession via WKWebsiteDataStore
// If using the default data store, URLSession.shared can access the same cookies.
// If using a non-persistent data store, you need to manually extract cookies.

// To make API calls with the web view's cookies:
let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
cookieStore.getAllCookies { cookies in
    let cookieHeader = cookies
        .filter { $0.domain.contains("noralooks.com") }
        .map { "\($0.name)=\($0.value)" }
        .joined(separator: "; ")

    var request = URLRequest(url: URL(string: "https://noralooks.com/api/mobile/cart_count")!)
    request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")

    URLSession.shared.dataTask(with: request) { data, _, _ in
        // Parse JSON response
    }.resume()
}
```

#### Android
```kotlin
// CookieManager is shared between WebView and HttpURLConnection
val cookieManager = CookieManager.getInstance()
val cookies = cookieManager.getCookie("https://noralooks.com")

val connection = URL("https://noralooks.com/api/mobile/cart_count").openConnection() as HttpURLConnection
connection.setRequestProperty("Cookie", cookies)
// Read response...
```

### What happens on login/logout

| Event | What happens to the cart | Action needed |
|-------|-------------------------|---------------|
| Guest adds items, then logs in | Guest cart is **automatically merged** into the customer's cart by the server | Re-fetch cart count — it may have changed |
| Logged-in user logs out | Session is destroyed, customer cart is disassociated | Re-fetch cart count (will be 0 or a new guest cart) |
| Guest user on fresh install | New session cookie created on first page load, guest cart created on first "Add to Cart" | No action needed — cookie jar handles it |

---

## 8. Tab Bar Navigation Behavior

### Tab tap behavior

| Tab | URL to load | Notes |
|-----|-------------|-------|
| Home | `/` | Root page |
| Search | `/products` | Products listing with search |
| Cart | `/cart` | Cart page — tab bar will HIDE on this page |
| Orders | `/orders` | Requires login — server redirects to `/login` if not logged in |
| Account | `/account` | Requires login — server redirects to `/login` if not logged in |

### When user taps the already-active tab
- Scroll the web view to top
- Do NOT reload the page (avoid unnecessary network requests)

### When user taps a different tab
- Navigate the web view to that tab's URL
- Let Turbo/Hotwire handle the navigation naturally (use Turbo visit, not a full page load)

### Deep linking from tab bar
Always navigate the web view — do NOT open an external browser. The session cookies only exist in the web view's cookie jar.

---

## 9. App Lifecycle Events

### App launch sequence

```
1. Initialize web view with Hotwire Native (ensures "Hotwire" in User-Agent)
2. Register JavaScript bridge handlers:
   - iOS: WKScriptMessageHandler named "cartCount"
   - Android: JavascriptInterface named "NoralooksAndroid"
3. Load the home page: GET /
4. Fetch tab configuration: GET /api/mobile/navigation
5. Build native tab bar from response
6. Fetch initial cart count: GET /api/mobile/cart_count
7. Display badge on Cart tab
```

### App returns from background

```
1. Check if web view content is still alive (iOS may have killed the process)
2. If web view is alive: call GET /api/mobile/cart_count to refresh badge
3. If web view was killed: reload current page, re-register bridge handlers, fetch cart count
```

### Login detected

How to detect: observe URL changes in the web view. After a `POST /login`, the server redirects to `/` or the return URL. You can detect login by:
- Observing navigation to `/` after being on `/login`
- OR injecting JavaScript to check if a session exists after each navigation

```
1. Re-fetch GET /api/mobile/navigation (Account tab URL changes)
2. Re-fetch GET /api/mobile/cart_count (cart may have merged)
3. Update tab bar and badge
```

### Logout detected

How to detect: observe navigation to `/login` after `DELETE /logout`

```
1. Re-fetch GET /api/mobile/navigation (Account tab URL changes to /login)
2. Re-fetch GET /api/mobile/cart_count (cart count resets)
3. Update tab bar and badge
```

### Order completed (checkout success)

How to detect: observe navigation to `/orders/:order_number` from `/checkout`

```
1. Cart is now empty — update badge to 0
2. OR fetch GET /api/mobile/cart_count to confirm
```

---

## 10. Error Handling

| Error | Handling |
|-------|----------|
| `/api/mobile/navigation` fails | Use hardcoded fallback tabs: Home(/), Search(/products), Cart(/cart), Orders(/orders), Account(/account) |
| `/api/mobile/cart_count` fails | Keep showing the last known count. Retry on next page load |
| JavaScript bridge message not received | Fallback: poll `/api/mobile/cart_count` on `didFinish`/`onPageFinished` |
| Web view loses cookies (e.g., cleared by OS) | User will appear logged out. Cart starts fresh. This is expected browser-like behavior |
| Network error while loading a tab | Show native error/retry UI. Do not crash or show blank screen |

---

## 11. Testing Checklist

### Tab bar visibility
- [ ] Tab bar shows on Home page
- [ ] Tab bar shows on Search/Products page
- [ ] Tab bar shows on Orders page
- [ ] Tab bar shows on Account page
- [ ] Tab bar HIDES on Product detail page (e.g., `/products/gold-ring`)
- [ ] Tab bar HIDES on Cart page (`/cart`)
- [ ] Tab bar HIDES on Checkout page (`/checkout`)
- [ ] Tab bar HIDES on Checkout confirm page (`/checkout/confirm`)
- [ ] Tab bar reappears when navigating back from a hidden page
- [ ] Web bottom nav bar is NOT visible on any page (server hides it)

### Cart badge
- [ ] Badge shows correct count on app launch
- [ ] Badge updates in real-time when adding item from product page
- [ ] Badge updates in real-time when adding item from product card (listing page)
- [ ] Badge updates when increasing quantity on cart page
- [ ] Badge updates when decreasing quantity on cart page
- [ ] Badge updates when removing item on cart page
- [ ] Badge disappears when cart becomes empty
- [ ] Badge resets after completing checkout
- [ ] Badge updates after login (guest cart merge)
- [ ] Badge updates after logout
- [ ] Badge refreshes when app returns from background

### Session/cookies
- [ ] Guest user can add items to cart, close app, reopen — cart persists
- [ ] Guest user logs in — guest cart items appear in their account cart
- [ ] Logged-in user logs out and back in — cart items persist
- [ ] API calls (`/api/mobile/cart_count`) return correct count for both guest and logged-in users

### Navigation
- [ ] All 5 tabs navigate to correct pages
- [ ] Tapping active tab scrolls to top (does not reload)
- [ ] Orders tab redirects to login if not logged in
- [ ] Account tab redirects to login if not logged in
- [ ] No pages open in external browser — everything stays in web view

---

## 12. Summary of Server-Side Contracts

| Contract | Value | Where defined |
|----------|-------|---------------|
| User-Agent detection string | `"Hotwire"` (substring match) | `application.html.erb` |
| Navigation API | `GET /api/mobile/navigation` | `Api::MobileController#navigation` |
| Cart count API | `GET /api/mobile/cart_count` | `Api::MobileController#cart_count` |
| iOS bridge handler name | `"cartCount"` | `shared/_native_cart_count_bridge.html.erb`, `carts_controller.rb` |
| Android interface name | `"NoralooksAndroid"` | `shared/_native_cart_count_bridge.html.erb`, `carts_controller.rb` |
| Android method name | `updateCartCount(int)` | `shared/_native_cart_count_bridge.html.erb`, `carts_controller.rb` |
| Web content bottom padding | `70px` | `application.html.erb` (inline style for Hotwire) |
| CSRF protection | Disabled for `/api/*` | `Api::MobileController` (`skip_forgery_protection`) |
