# Magic Echoes — Claude Rules

## Localization

**Every screen and widget** that displays user-facing text **MUST** use `AppLocalizations`. No hardcoded UI strings allowed. **Portuguese-BR (`pt_BR`) is always the default locale.**

### Getting the loc instance (mandatory in every screen)
```dart
final loc = AppLocalizations.of(context)!;
```

### Adding new strings
1. Add the key to `lib/l10n/app_pt.arb` first (source of truth — pt_BR is default)
2. Mirror the key in `lib/l10n/app_en.arb` with the English equivalent
3. Run `flutter gen-l10n` to regenerate `app_localizations.dart`

### Strings with parameters
Use ARB placeholders — never string interpolation for sentences:
```json
"welcomeUser": "Olá, {name}!",
"@welcomeUser": { "placeholders": { "name": { "type": "String" } } }
```

### Dates & numbers
Always pass the current locale — never hardcode formats:
```dart
final locale = Localizations.localeOf(context).toString();
DateFormat.yMMMd(locale).format(date)
NumberFormat.decimalPattern(locale).format(number)
```

### Forbidden
- `Text('Any hardcoded string')`
- `SnackBar(content: Text('Error occurred'))`
- `'${date.day}/${date.month}/${date.year}'`
- Adding a key only to `app_en.arb` without `app_pt.arb`

### Reference
- ARB files: `magic_echoes/lib/l10n/`
- Generated class: `lib/l10n/app_localizations.dart`
- l10n config: `magic_echoes/l10n.yaml`

---

## Share Feature

When implementing or modifying any feature that involves sharing a Story, **ALWAYS** use the unified `SharePreviewScreen`. **NEVER** implement direct native sharing (`Share.share`) or custom share dialogs for stories.

### Implementation
1. **Entry Point**: Call the static method `SharePreviewScreen.show(BuildContext context, Story story)`.
2. **Deep Link Format**: `https://magicechoes.app/story/<story_id>` — handled internally by `SharePreviewScreen`.
3. **Deep Link Logic**: Must open the story details screen in-app or redirect to app store/web preview if not installed.

### UI/UX: Preview-First Pattern
1. User taps "Share" icon/button.
2. App displays the `SharePreviewScreen` modal with:
   - **Card**: Story Cover Image (16:9), Story Title (Headline style), Story Description (2 lines max), Author Name, "Magic Echoes" App Badge
   - **Actions**: Copy Link (copies deep link) and Share (captures card as PNG + shares via native sheet with deep link text)

### Forbidden
- Calling `SharePlus.share()` directly from a Story Detail or Completion screen
- Sharing only the text link without the visual preview card
- Creating disparate share designs for different screens

### Reference
- Strategy Doc: `docs/09_SHARE.md`
- Widget: `lib/core/widgets/share_preview_screen.dart`
