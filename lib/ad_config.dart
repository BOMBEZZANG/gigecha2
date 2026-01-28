import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'ad_helper.dart';
import 'ad_state.dart';

bool adsRemovedGlobal = false;

class MyBannerAd extends StatefulWidget {
  @override
  _MyBannerAdState createState() => _MyBannerAdState();
}

class _MyBannerAdState extends State<MyBannerAd> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    print('[MyBannerAd] _loadBannerAd called, adsRemovedGlobal: $adsRemovedGlobal');
    // Check global variable first for immediate state
    if (!adsRemovedGlobal) {
      _bannerAd = BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        size: AdSize.banner,
        request: AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            print('[MyBannerAd] Banner ad loaded successfully');
            if (mounted) setState(() {});
          },
          onAdFailedToLoad: (ad, error) {
            print('[MyBannerAd] Banner ad failed to load: ${error.code} - ${error.message}');
            ad.dispose();
            _bannerAd = null;
          },
          onAdOpened: (ad) => print('[MyBannerAd] Banner ad opened'),
          onAdClosed: (ad) => print('[MyBannerAd] Banner ad closed'),
        ),
      )..load();
      print('[MyBannerAd] Banner ad load() called');
    } else {
      print('[MyBannerAd] Ads removed, skipping banner load');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Provider to reactively listen to ad state changes
    final adState = Provider.of<AdState>(context);

    if (adState.adsRemoved || adsRemovedGlobal || _bannerAd == null) {
      // 광고 제거 구매 상태이면 아무것도 반환하지 않음
      return SizedBox.shrink();
    }
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}