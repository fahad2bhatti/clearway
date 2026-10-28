import 'dart:async';

import 'package:flutter/foundation.dart'
    show ValueNotifier, debugPrint, kReleaseMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob: banner, interstitial (har 5 level) aur rewarded ads.
/// Debug mein hamesha Google ke test ad unit IDs use hoti hain.
class AdService {
  AdService._();

  // Google ke official test IDs (Android).
  static const _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  // Release ke liye real IDs:
  // flutter build appbundle --dart-define=ADMOB_BANNER_ID=ca-app-pub-xxx/aaa
  //   --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-xxx/bbb
  //   --dart-define=ADMOB_REWARDED_ID=ca-app-pub-xxx/ccc
  // Default mein real IDs hain, taake --dart-define bhoolne par bhi release
  // build mein test IDs na lagein. Debug mein hamesha test IDs chalti hain.
  static const _liveBannerId = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: 'ca-app-pub-8397637614188934/5851587236',
  );
  static const _liveInterstitialId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-8397637614188934/7108828584',
  );
  static const _liveRewardedId = String.fromEnvironment(
    'ADMOB_REWARDED_ID',
    defaultValue: 'ca-app-pub-8397637614188934/5739820870',
  );

  // Logcat se mila test device ID yahan daal sakte hain (optional).
  static const _testDeviceIds = <String>[];

  /// Itne level jeetne ke baad ek interstitial.
  static const levelsPerInterstitial = 5;

  /// Do interstitials ke darmiyan kam az kam itna waqfa.
  static const interstitialCooldown = Duration(seconds: 60);

  static String _pick(String live, String test) =>
      kReleaseMode && live.isNotEmpty ? live : test;

  static String get bannerUnitId => _pick(_liveBannerId, _testBannerId);
  static String get interstitialUnitId =>
      _pick(_liveInterstitialId, _testInterstitialId);
  static String get rewardedUnitId => _pick(_liveRewardedId, _testRewardedId);

  static var _initialized = false;

  /// True once consent is settled and the SDK is ready; banners wait for it.
  static final adsReady = ValueNotifier<bool>(false);
  static InterstitialAd? _interstitial;
  static RewardedAd? _rewarded;
  static var _loadingInterstitial = false;
  static var _loadingRewarded = false;
  static var _levelsSinceAd = 0;
  static DateTime? _lastInterstitial;

  static Future<void> initialize() async {
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _testDeviceIds),
      );
      await _gatherConsent();
      if (!await ConsentInformation.instance.canRequestAds()) {
        debugPrint('Ads off: consent abhi nahi mila.');
        return;
      }
      await MobileAds.instance.initialize();
      _initialized = true;
      adsReady.value = true;
      preload();
    } catch (error) {
      debugPrint('AdMob initialization failed: $error');
    }
  }

  /// Google UMP consent: EEA/UK mein form dikhata hai, baqi jagah foran khatam.
  /// Form AdMob console ke "Privacy & messaging" mein banta hai.
  static Future<void> _gatherConsent() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          if (error != null) debugPrint('Consent form: ${error.message}');
          if (!done.isCompleted) done.complete();
        });
      },
      (FormError error) {
        debugPrint('Consent info: ${error.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future.timeout(const Duration(seconds: 90), onTimeout: () {});
  }

  /// Interstitial aur rewarded dono pehle se load kar leta hai.
  static void preload() {
    _loadInterstitial();
    _loadRewarded();
  }

  static void _loadInterstitial() {
    if (!_initialized || _interstitial != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          debugPrint('Interstitial failed: ${error.code} ${error.message}');
        },
      ),
    );
  }

  static void _loadRewarded() {
    if (!_initialized || _rewarded != null || _loadingRewarded) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewarded = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
          debugPrint('Rewarded failed: ${error.code} ${error.message}');
        },
      ),
    );
  }

  /// Har jeete hue level par ek bar call karein.
  static void registerLevelCleared() => _levelsSinceAd++;

  /// 5 level poore hone par (aur cooldown guzarne par) interstitial dikhata
  /// hai. Ad band hone tak wait karta hai.
  static Future<void> maybeShowInterstitial() async {
    if (_levelsSinceAd < levelsPerInterstitial) return;
    final last = _lastInterstitial;
    if (last != null &&
        DateTime.now().difference(last) < interstitialCooldown) {
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    _levelsSinceAd = 0;
    _lastInterstitial = DateTime.now();
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial show failed: ${error.message}');
        ad.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete();
      },
    );
    try {
      await ad.show();
    } catch (error) {
      debugPrint('Interstitial show error: $error');
      if (!done.isCompleted) done.complete();
    }
    await done.future;
  }

  /// Rewarded ad dikhata hai. Sirf tab true deta hai jab user ne ad poora
  /// dekh kar reward kamaya.
  static Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    _rewarded = null;
    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded show failed: ${error.message}');
        ad.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete(false);
      },
    );
    try {
      await ad.show(onUserEarnedReward: (ad, reward) => earned = true);
    } catch (error) {
      debugPrint('Rewarded show error: $error');
      if (!done.isCompleted) done.complete(false);
    }
    return done.future;
  }
}
