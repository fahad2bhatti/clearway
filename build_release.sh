#!/usr/bin/env bash
set -e
flutter build appbundle --release \
  --dart-define=ADMOB_BANNER_ID=ca-app-pub-8397637614188934/5851587236 \
  --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-8397637614188934/7108828584 \
  --dart-define=ADMOB_REWARDED_ID=ca-app-pub-8397637614188934/5739820870
echo "Ready: build/app/outputs/bundle/release/app-release.aab"
