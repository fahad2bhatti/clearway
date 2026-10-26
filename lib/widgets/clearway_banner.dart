import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

/// Screen ke bottom ka adaptive banner. Ad load na ho to kuch nahi dikhata.
class ClearwayBanner extends StatefulWidget {
  const ClearwayBanner({super.key});

  @override
  State<ClearwayBanner> createState() => _ClearwayBannerState();
}

class _ClearwayBannerState extends State<ClearwayBanner> {
  BannerAd? _ad;
  var _loaded = false;
  int? _requestedWidth;

  @override
  void initState() {
    super.initState();
    AdService.adsReady.addListener(_onAdsReady);
  }

  void _onAdsReady() {
    final width = _requestedWidth;
    if (width != null && _ad == null) _load(width);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (_requestedWidth != width) {
      _requestedWidth = width;
      _load(width);
    }
  }

  Future<void> _load(int width) async {
    if (!AdService.adsReady.value) return;
    // ignore: deprecated_member_use
    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
      MediaQuery.orientationOf(context),
      width,
    );
    if (!mounted || size == null) return;

    final old = _ad;
    setState(() {
      _ad = null;
      _loaded = false;
    });
    old?.dispose();

    late final BannerAd ad;
    ad = BannerAd(
      adUnitId: AdService.bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted || _ad != ad) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (failed, error) {
          debugPrint('Banner failed: ${error.code} ${error.message}');
          failed.dispose();
          if (mounted && _ad == ad) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    AdService.adsReady.removeListener(_onAdsReady);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        height: ad.size.height.toDouble(),
        child: Center(
          child: SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: AdWidget(ad: ad),
          ),
        ),
      ),
    );
  }
}
