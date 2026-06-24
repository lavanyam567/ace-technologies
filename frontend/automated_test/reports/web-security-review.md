# Web Security Review

- Technology Detected: Flutter web + Supabase auth client
- Security Score: 72/100
- Risk Rating: Low Risk
- Critical Findings: 0
- High Findings: 0
- Medium Findings: 0
- Low Findings: 14

## Findings

### WEB-001. OAuth redirect falls back to the active browser origin
- Severity: Low
- Category: Session Management
- Evidence: `lib/core/config/app_config.dart:15`
- Description: The frontend derives the OAuth redirect from `Uri.base.origin` when `APP_REDIRECT_URL` is empty, which increases the chance of inconsistent redirect handling across preview or alternate hostnames.
- Recommendation: Require an explicit redirect URL per environment and reject runtime fallbacks for production builds.

```text
static String get oauthRedirectUrl =>
      appRedirectUrl.isNotEmpty ? appRedirectUrl : Uri.base.origin;
```

### WEB-002. Client auth state has no application-level idle timeout
- Severity: Low
- Category: Session Management
- Evidence: `lib/features/providers/auth_provider.dart:11`
- Description: The auth provider listens for Supabase session changes but does not enforce an additional inactivity timeout or forced reauthentication window in the app layer.
- Recommendation: Add client-side idle tracking and a reauthentication policy for sensitive account actions.

```text
AuthProvider() : super(AuthState.fromSession(_client.auth.currentSession)) {
    _authSubscription = _client.auth.onAuthStateChange.listen((event) {
      final nextState = AuthState.fromSession(event.session);
```

### WEB-003. Login email validation only checks for the @ character
- Severity: Low
- Category: Input Validation
- Evidence: `lib/features/account/screens/login_screen.dart:88`
- Description: The login form performs minimal email validation, which makes malformed addresses easier to submit and leaves normalization entirely to the backend.
- Recommendation: Use a stricter email validator and normalize whitespace before submission.

```text
if (value.isEmpty) return 'Email is required';
                        if (!value.contains('@')) return 'Enter valid email';
                        return null;
```

### WEB-004. Signup password policy is limited to six characters
- Severity: Low
- Category: Authentication
- Evidence: `lib/features/account/screens/signup_screen.dart:132`
- Description: The signup screen accepts passwords with a minimum length of six characters, matching the current backend minimum but leaving room for stronger credential requirements.
- Recommendation: Raise the minimum length and add composition or breached-password checks.

```text
if (value.isEmpty) return 'Password is required';
                    if (value.length < 6) {
                      return 'Password must be 6+ characters';
```

### WEB-005. Signup collects phone numbers before linked privacy terms are implemented
- Severity: Low
- Category: Privacy
- Evidence: `lib/features/account/screens/signup_screen.dart:179`
- Description: The signup flow collects phone data while the Terms and Privacy links are placeholders, reducing user visibility into how personal data is handled.
- Recommendation: Publish real Terms and Privacy routes before collecting optional contact data.

```text
child: GestureDetector(
                        onTap: () {},
                        child: RichText(
```

### WEB-006. Auth error strings are surfaced directly to the UI
- Severity: Low
- Category: Error Handling
- Evidence: `lib/features/account/screens/login_screen.dart:277`
- Description: Both login and signup screens rewrite and display raw auth exception messages, which can expose backend wording that is useful for account enumeration or debugging.
- Recommendation: Map backend failures to a smaller set of user-safe messages and log detailed causes separately.

```text
return error
        .replaceFirst('AuthException(message: ', '')
        .replaceFirst(')', '');
```

### WEB-007. Role values are trusted from user metadata on the client
- Severity: Low
- Category: Authorization
- Evidence: `lib/features/providers/auth_provider.dart:217`
- Description: The frontend derives role information from user metadata when building auth state, so UI-level admin gating depends on claims that should still be treated as advisory on the client.
- Recommendation: Use server-verified role checks for privileged actions and avoid relying on UI-only role state.

```text
profileImageUrl: metadata['avatar_url'] as String?,
      role: metadata['role'] as String? ?? 'customer',
      userEmail: user.email,
```

### WEB-008. No Content Security Policy is declared in the web shell
- Severity: Low
- Category: Browser Security
- Evidence: `web/index.html:1`
- Description: The web entry page does not define a CSP, leaving script and frame controls to default browser behavior.
- Recommendation: Add a restrictive CSP that explicitly allows only required script, connect, frame, and image origins.

```text
No Content-Security-Policy meta tag found in the <head> block.
```

### WEB-009. No anti-framing policy is declared in the web shell
- Severity: Low
- Category: Browser Security
- Evidence: `web/index.html:1`
- Description: The page head does not publish a frame-ancestors or equivalent anti-clickjacking directive.
- Recommendation: Set `frame-ancestors` in CSP and add a server-side `X-Frame-Options` header where hosting allows it.

```text
No frame-ancestors directive or anti-framing meta/header surrogate found.
```

### WEB-010. Third-party scripts load without integrity metadata
- Severity: Low
- Category: Browser Security
- Evidence: `web/index.html:84`
- Description: The app shell imports Razorpay checkout and the Noupe embed directly from remote domains without subresource integrity attributes.
- Recommendation: Add integrity and crossorigin attributes where supported, or proxy the scripts through a controlled asset pipeline.

```text
<script src="https://checkout.razorpay.com/v1/checkout.js"></script>
  <script src="https://www.noupe.com/embed/019eb7726a167d818eb5a0adccad28d97996.js"></script>
```

### WEB-011. No referrer policy is defined for the web entry page
- Severity: Low
- Category: Browser Security
- Evidence: `web/index.html:1`
- Description: The web shell does not publish a referrer policy, so browser defaults decide how much URL context is forwarded to third-party destinations.
- Recommendation: Set a conservative `Referrer-Policy` such as `strict-origin-when-cross-origin` or stricter.

```text
No Referrer-Policy meta tag found in the HTML head.
```

### WEB-012. No permissions policy is defined for browser features
- Severity: Low
- Category: Browser Security
- Evidence: `web/index.html:1`
- Description: The web shell does not restrict access to browser capabilities such as camera, microphone, geolocation, or payment-related APIs.
- Recommendation: Add a Permissions-Policy header or meta configuration to disable unused browser features.

```text
No Permissions-Policy control found in the HTML head.
```

### WEB-013. shared_preferences remains in the dependency set despite sensitive account flows
- Severity: Low
- Category: Dependency Review
- Evidence: `pubspec.yaml:43`
- Description: The frontend includes `shared_preferences`, which is commonly backed by browser storage on web builds and deserves explicit review when account and profile data are in scope.
- Recommendation: Document allowed storage use cases and remove the package if it is not required for this build.

```text
  shared_preferences: ^2.2.3
```

### WEB-014. Embedded web content support expands the client attack surface
- Severity: Low
- Category: Dependency Review
- Evidence: `pubspec.yaml:46`
- Description: The frontend ships with `webview_flutter`, which broadens the runtime surface for remote content if the package is used beyond tightly controlled flows.
- Recommendation: Keep embedded web content isolated, audited, and disabled where it is not essential.

```text
  webview_flutter: ^4.13.0
```
