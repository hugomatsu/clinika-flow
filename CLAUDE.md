# Clinika Flow — Claude Rules

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
- ARB files: `lib/l10n/`
- Generated class: `lib/l10n/app_localizations.dart`
- l10n config: `l10n.yaml`
