import 'package:flutter/foundation.dart' show debugPrint, kReleaseMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob setup. Debug mein hamesha Google ke test ad unit IDs use hoti hain.
class AdService {
  AdService._();

  // Google ka official test banner ID (Android).
  static const _testBannerId = 'ca-app-pub-3940256099942544/6300978111';

  // Release ke liye apni real ID is tarah dein:
  // flutter build appbundle --dart-define=ADMOB_BANNER_ID=ca-app-pub-xxx/yyy
  static const _liveBannerId = String.fromEnvironment('ADMOB_BANNER_ID');

  // Logcat se mila test device ID yahan daal sakte hain (optional).
  static const _testDeviceIds = <String>[];

  static String get bannerUnitId =>
      kReleaseMode && _liveBannerId.isNotEmpty ? _liveBannerId : _testBannerId;

  static Future<void> initialize() async {
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _testDeviceIds),
      );
      await MobileAds.instance.initialize();
    } catch (error) {
      debugPrint('AdMob initialization failed: $error');
    }
  }
}
