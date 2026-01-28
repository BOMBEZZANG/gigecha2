import 'dart:io';

class AdHelper {
  // Banner Ad - using test ID (provide production ID if needed)
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test ID - replace with production if available
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Interstitial Ad
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-2598779635969436/9696046015'; // Production
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Rewarded Ad
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-2598779635969436/5292916517'; // Production
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // App Open Ad
  static String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-2598779635969436/3979834843'; // Production
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2598779635969436/2114262130';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
