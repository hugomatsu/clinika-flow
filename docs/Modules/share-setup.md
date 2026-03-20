# Share Module — Flutter Project

Reusable guide for implementing the **preview-first sharing pattern** in a Flutter project. Covers the branded preview card widget, image capture, native sharing, deep linking (Android App Links + iOS Universal Links + Firebase Hosting), and localization strings.

---

## Architecture Overview

```
User taps Share
      │
      ▼
SharePreviewScreen.show(context, story)   ← modal bottom sheet
      │
      ├─ Preview Card (RepaintBoundary)   ← branded image, 16:9 cover + metadata
      │
      ├─ "Copy Link" button               ← copies deep link to clipboard
      │
      └─ "Share" button                   ← captures card as PNG → native share sheet
                                              (text-only fallback on web)
```

Deep link format: `https://<your-domain>/story/<story_id>`

When the link is opened:
- **App installed** → GoRouter catches `/story/:id` → opens `StoryDetailScreen`
- **App not installed** → Firebase Hosting serves Flutter web build (SPA rewrite)

---

## 1. Packages

In `pubspec.yaml`:

```yaml
dependencies:
  share_plus: ^12.0.1       # native share sheet + file sharing
  path_provider: ^2.1.5     # temp directory for PNG file
```

Run `flutter pub get`.

---

## 2. The `SharePreviewScreen` Widget

Create `lib/core/widgets/share_preview_screen.dart`:

```dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';   // your Story model
import 'package:your_app/l10n/app_localizations.dart';

class SharePreviewScreen extends StatefulWidget {
  final Story story;
  const SharePreviewScreen({super.key, required this.story});

  /// Entry point — always use this, never push directly.
  static Future<void> show(BuildContext context, Story story) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SharePreviewScreen(story: story),
    );
  }

  @override
  State<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends State<SharePreviewScreen> {
  final GlobalKey _previewKey = GlobalKey();
  bool _isProcessing = false;

  // ← Replace with your domain
  String get _deepLink => 'https://your-domain.web.app/story/${widget.story.id}';

  Future<Uint8List?> _capturePreview() async {
    try {
      final boundary = _previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing preview: $e');
      return null;
    }
  }

  Future<void> _copyLink() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await Clipboard.setData(ClipboardData(text: _deepLink));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.shareLinkCopied),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareStory() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final imageBytes = await _capturePreview();
      final shareText =
          '${AppLocalizations.of(context)!.checkOutStory(widget.story.title)}\n\n'
          '${widget.story.description}\n\n'
          '🔗 $_deepLink';

      if (imageBytes != null && !kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/share_preview.png');
        await file.writeAsBytes(imageBytes);
        await SharePlus.instance.share(
          ShareParams(
            text: shareText,
            files: [XFile(file.path, mimeType: 'image/png')],
          ),
        );
      } else {
        // Web or capture failure — text only
        await SharePlus.instance.share(ShareParams(text: shareText));
      }
    } catch (e) {
      debugPrint('Share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.shareFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                AppLocalizations.of(context)!.shareStory,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // The card that gets captured as a PNG
              RepaintBoundary(
                key: _previewKey,
                child: _SharePreviewCard(story: widget.story, deepLink: _deepLink),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _copyLink,
                      icon: const Icon(Icons.copy),
                      label: Text(AppLocalizations.of(context)!.copyLink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _shareStory,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.share),
                      label: Text(AppLocalizations.of(context)!.shareAction),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### The Preview Card

The card is a private widget inside the same file. It renders the branded image that is captured by `RepaintBoundary`:

```dart
class _SharePreviewCard extends StatelessWidget {
  final Story story;
  final String deepLink;
  const _SharePreviewCard({required this.story, required this.deepLink});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B4EFF), Color(0xFF9B7EFF)],  // brand colours
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 16:9 cover image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: story.coverImageUrl != null
                ? Image.network(story.coverImageUrl!, fit: BoxFit.cover)
                : Container(color: Colors.white12),
          ),
          // Title, description, author, app badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(story.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(story.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                     style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (story.authorName.isNotEmpty) ...[
                      const Icon(Icons.person, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(story.authorName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                    const Spacer(),
                    // App badge — update the name to your app
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 12, color: Colors.amber),
                          SizedBox(width: 4),
                          Text('Your App Name', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 3. Usage

Call the static entry point from any screen:

```dart
// Story detail or completion screen
IconButton(
  icon: const Icon(Icons.share),
  onPressed: () => SharePreviewScreen.show(context, story),
),
```

**Never** call `SharePlus.share()` directly from story screens — always go through `SharePreviewScreen.show()`.

---

## 4. Deep Linking — Android App Links

### `AndroidManifest.xml`

Inside the `<activity>` tag, add an `intent-filter` with `autoVerify="true"`:

```xml
<!-- Deep link / App Links for shared story URLs -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="https"
        android:host="your-domain.web.app"
        android:pathPrefix="/story/" />
</intent-filter>
```

`autoVerify="true"` tells Android to verify ownership by fetching `/.well-known/assetlinks.json` from your domain. Without it, Android shows a disambiguation dialog every time.

### `web/.well-known/assetlinks.json`

```json
[
    {
        "relation": ["delegate_permission/common.handle_all_urls"],
        "target": {
            "namespace": "android_app",
            "package_name": "com.yourcompany.your_app",
            "sha256_cert_fingerprints": [
                "YOUR_SHA256_RELEASE_FINGERPRINT_HERE"
            ]
        }
    }
]
```

**Get your SHA-256 fingerprint:**
```bash
# Debug keystore
keytool -exportcert -alias androiddebugkey \
  -keystore ~/.android/debug.keystore \
  -storepass android | openssl sha256 -hex

# Release keystore
keytool -exportcert -alias YOUR_ALIAS \
  -keystore path/to/release.keystore \
  -storepass YOUR_PASSWORD | openssl sha256 -hex
```

> Add both debug and release SHA-256 fingerprints to cover all build types.

---

## 5. Deep Linking — iOS Universal Links

### `ios/Runner/Info.plist`

Add `FlutterDeepLinkingEnabled` to enable GoRouter to handle incoming URLs:

```xml
<key>FlutterDeepLinkingEnabled</key>
<true/>
```

> No `Associated Domains` entitlement is needed when using Firebase Hosting as the domain, because GoRouter's deep link handling via `FlutterDeepLinkingEnabled` handles the routing internally.

### `web/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "YOUR_TEAM_ID.com.yourcompany.your_app",
        "paths": ["/story/*"]
      }
    ]
  }
}
```

Replace `YOUR_TEAM_ID` with your 10-character Apple Developer Team ID (found at [developer.apple.com](https://developer.apple.com) → Account → Membership).

---

## 6. Firebase Hosting — Serving the Well-Known Files

The `/.well-known/` files must be served with `Content-Type: application/json` and must NOT be caught by the SPA rewrite. Configure `firebase.json` inside your Flutter project directory:

```json
{
    "hosting": {
        "public": "build/web",
        "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
        "rewrites": [
            {
                "source": "**",
                "destination": "/index.html"
            }
        ],
        "headers": [
            {
                "source": "/.well-known/assetlinks.json",
                "headers": [{"key": "Content-Type", "value": "application/json"}]
            },
            {
                "source": "/.well-known/apple-app-site-association",
                "headers": [{"key": "Content-Type", "value": "application/json"}]
            }
        ]
    }
}
```

The `headers` rules take priority over `rewrites`, so the files are served as-is (not redirected to `index.html`).

Deploy:
```bash
cd <flutter_project>
flutter build web
firebase deploy --only hosting
```

---

## 7. GoRouter — Handling the Deep Link

In your router, define the story route so it's accessible at the deep link path:

```dart
GoRouter(
  // ... other config ...
  routes: [
    // Deep link target: /story/:id
    GoRoute(
      path: '/story/:id',
      builder: (context, state) {
        final storyId = state.pathParameters['id']!;
        return StoryDetailScreen(storyId: storyId);
      },
    ),
  ],
)
```

### Auth Guard with Deep Link Preservation

If your app requires authentication, preserve the deep link destination so users land on the correct screen after signing in:

```dart
redirect: (context, state) {
  final isLoggedIn = /* check auth state */;
  final isOnAuth = state.matchedLocation == '/auth';

  if (!isLoggedIn && !isOnAuth) {
    // Preserve destination for redirect after login
    final from = Uri.encodeComponent(state.uri.toString());
    return '/auth?from=$from';
  }
  if (isLoggedIn && isOnAuth) {
    // Redirect to original destination or home
    final from = state.uri.queryParameters['from'];
    return from != null ? Uri.decodeComponent(from) : '/home';
  }
  return null;
},
```

---

## 8. Localization Strings

Add to `lib/l10n/app_pt.arb` (source of truth):

```json
"shareStory": "Compartilhar História",
"@shareStory": {},

"shareLinkCopied": "Link copiado!",
"@shareLinkCopied": {},

"copyLink": "Copiar Link",
"@copyLink": {},

"shareAction": "Compartilhar",
"@shareAction": {},

"shareFailed": "Erro ao compartilhar. Tente novamente.",
"@shareFailed": {},

"checkOutStory": "Confira a história \"{title}\" no Magic Echoes!",
"@checkOutStory": {
    "placeholders": {
        "title": {"type": "String"}
    }
}
```

Mirror in `lib/l10n/app_en.arb`:

```json
"shareStory": "Share Story",
"@shareStory": {},

"shareLinkCopied": "Link copied!",
"@shareLinkCopied": {},

"copyLink": "Copy Link",
"@copyLink": {},

"shareAction": "Share",
"@shareAction": {},

"shareFailed": "Failed to share. Please try again.",
"@shareFailed": {},

"checkOutStory": "Check out \"{title}\" on Magic Echoes!",
"@checkOutStory": {
    "placeholders": {
        "title": {"type": "String"}
    }
}
```

Run `flutter gen-l10n` to regenerate `app_localizations.dart`.

---

## 9. What to Commit vs. Keep Out of Git

| File | Committed | Reason |
|---|---|---|
| `lib/core/widgets/share_preview_screen.dart` | ✅ Yes | App source code |
| `web/.well-known/assetlinks.json` | ✅ Yes | Must be deployed with web build |
| `web/.well-known/apple-app-site-association` | ✅ Yes | Must be deployed with web build |
| `firebase.json` (hosting config) | ✅ Yes | Deployment config, not sensitive |

The SHA-256 fingerprint in `assetlinks.json` is the certificate fingerprint of your signing key — it is safe to commit. It does not expose the private key.

---

## Quick-Start Checklist for a New Project

```
[ ] Add share_plus and path_provider to pubspec.yaml
[ ] Create lib/core/widgets/share_preview_screen.dart
    [ ] Update _deepLink to point to your domain/route
    [ ] Update app badge name in _SharePreviewCard
[ ] Add localization strings to app_pt.arb and app_en.arb
[ ] Run flutter gen-l10n
[ ] Add GoRoute for /story/:id (or your entity path)
[ ] Wire up auth guard to preserve deep link destination
[ ] Add intent-filter with autoVerify="true" to AndroidManifest.xml
    [ ] Update android:host and android:pathPrefix
[ ] Add FlutterDeepLinkingEnabled to ios/Runner/Info.plist
[ ] Create web/.well-known/assetlinks.json
    [ ] Fill in package_name and sha256_cert_fingerprints
[ ] Create web/.well-known/apple-app-site-association
    [ ] Fill in YOUR_TEAM_ID and bundle ID
[ ] Configure firebase.json with headers for .well-known files
[ ] Deploy: flutter build web && firebase deploy --only hosting
[ ] Test Android: adb shell am start -a android.intent.action.VIEW -d "https://your-domain/story/test123"
[ ] Test iOS: xcrun simctl openurl booted "https://your-domain/story/test123"
```
