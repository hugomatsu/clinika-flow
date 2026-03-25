/// Build-time constants injected via --dart-define.
/// Pass these when building:
///   --dart-define=APP_VERSION=1.0.0
///   --dart-define=BUILD_NUMBER=10
///   --dart-define=BUILD_DATE=2026-03-24 14:30
const kAppVersion =
    String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
const kBuildNumber =
    String.fromEnvironment('BUILD_NUMBER', defaultValue: '10');
const kBuildDate =
    String.fromEnvironment('BUILD_DATE', defaultValue: '—');
