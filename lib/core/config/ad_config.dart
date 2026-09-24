/// Unity Ads configuration.
///
/// Both values come from the Unity dashboard
/// (Unity Cloud → Monetization → Apps → app).
///
/// Verified against your account: Game ID `800379544` belongs to the live Play
/// app `com.vidkwaii.app` ("VidKwaii- Reel Dowloader") and
/// `BP_Rewarded_Android` is its rewarded placement.
///
/// ⚠️  This is a **Unity Ads** account, so the Unity Ads SDK is used. The
///     ironSource/LevelPlay SDK cannot initialise with a Unity Ads Game ID —
///     it answers with HTTP 400 Bad Request.
class AdConfig {
  const AdConfig._();

  /// Unity Ads Game ID (Monetization → Apps → Game ID).
  static const String gameId = '800379544';

  /// Rewarded video placement, as named in the Unity Ads dashboard.
  static const String rewardedPlacementId = 'BP_Rewarded_Android';

  /// When true the SDK serves test ads only. Handy while verifying setup.
  static const bool testMode = false;

  /// Minimum seconds between two impressions. `0` shows an ad on every
  /// download attempt.
  static const int cooldownSeconds = 0;

  /// Upper bound on how long we wait for an ad to report back (completed,
  /// skipped or failed) before giving up on it. Playable and video ads can be
  /// closed in ways that never fire a callback — without this the app would
  /// stay stuck believing an ad is still on screen.
  static const Duration maxShowDuration = Duration(seconds: 150);

  /// How long the download flow waits for an in-flight load before continuing
  /// without an ad.
  static const Duration maxReadyWait = Duration(seconds: 5);

  /// Shows the ad status in the app UI, and opens a status dialog on a
  /// long-press of the home logo. Disabled for production releases.
  static const bool diagnosticsToUi = false;
}
