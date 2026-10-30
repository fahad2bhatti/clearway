/// Small built-in English/Urdu string set for the game UI.
final class ClearwayStrings {
  const ClearwayStrings(this.language);

  final String language;
  bool get _ur => language == 'ur';

  // Helper method for digit formatting
  String _digits(int value) => value.toString();

  // Welcome Screen
  String get welcomeTitle => _ur ? 'خوش آمدید' : 'Welcome';
  String get welcomeMessage => _ur ? 'اپنا نام درج کریں اور شرائط و ضوابط قبول کریں۔' : 'Enter your username and accept the terms and conditions.';
  String get username => _ur ? 'صارف نام' : 'Username';
  String get usernameHint => _ur ? '3 سے 15 حرفوں کا نام' : '3-15 characters';
  String get usernameRequired => _ur ? 'صارف نام ضروری ہے' : 'Username is required';
  String get usernameLength => _ur ? 'صارف نام 3 سے 15 حرفوں کا ہونا چاہیے' : 'Username must be 3-15 characters';
  String get usernameInvalidChars => _ur ? 'صرف حروف، اعداد اور انڈر سکرول کی اجازت ہے' : 'Only letters, numbers, and underscores allowed';
  String get usernameError => _ur ? 'صارف نام درج کرنے میں خرابی' : 'Error setting username';
  String get continueButton => _ur ? 'جاری رکھیں' : 'Continue';

  // Settings Strings
  String get accountDeleted => _ur ? 'اکاؤنٹ حذف ہو گیا' : 'Account deleted';
  String get accountDeleteFailed => _ur ? 'اکاؤنٹ حذف نہیں ہو سکا۔ دوبارہ کوشش کریں۔' : 'Account deletion failed. Please retry.';
  String get cancel => _ur ? 'منسوخ' : 'Cancel';
  String get confirm => _ur ? 'تصدیق کریں' : 'Confirm';
  String get rateUnavailable => _ur ? 'ریٹنگ ابھی دستیاب نہیں۔' : 'Rating is not available yet.';
  String get feedbackEmpty => _ur ? 'رائے خالی نہیں ہو سکتی۔' : 'Feedback cannot be empty.';
  String get feedbackSent => _ur ? 'رائے بھیج دی گئی۔' : 'Feedback sent.';
  String get feedbackUnavailable => _ur ? 'رائے بھیجنے کے لیے آن لائن کنکشن درکار ہے۔' : 'An online connection is required to send feedback.';
  String get sendFeedback => _ur ? 'رائے بھیجیں' : 'Send Feedback';
  String get feedbackPrompt => _ur ? 'اپنی رائے لکھیں' : 'Write your feedback';

  // Shop Strings
  String get shopTitle => _ur ? 'دکان' : 'Shop';
  String get shopCoins => _ur ? 'سکے اور اشارے' : 'Coins and hints';
  String get shopAds => _ur ? 'روزانہ اشتہاری انعامات' : 'Daily ad offers';
  String get shopRemoveAds => _ur ? 'اشتہارات ہٹائیں' : 'Remove Ads';
  String get shopSkins => _ur ? 'تیر کی کھالیں' : 'Arrow skins';
  String get unlockAt80 => _ur ? 'لیول ۸۰ پر کھلے گا' : 'Unlocks at level 80';
  String get selected => _ur ? 'منتخب' : 'Selected';
  String get select => _ur ? 'منتخب کریں' : 'Select';
  String get skinUnlocked => _ur ? 'نیا اسکن مفت کھل گیا!' : 'New skin unlocked for free!';
  String get skinPurchased => _ur ? 'اسکن خرید لیا گیا' : 'Skin purchased';
  String get insufficientCoins => _ur ? 'سکے کم ہیں' : 'Not enough coins';

  String shopOfferTitle(String id) => _ur ? switch (id) {
    'hint-pack' => '۲ اشارے',
    'undo-pack' => '۳ واپسی کے مواقع',
    'ad-coins' => '+۳۰ سکے',
    'classic' => 'کلاسک',
    'sunset' => 'غروب آفتاب',
    'remove-ads' => 'اشتہارات ہٹائیں',
    _ => id,
  } : switch (id) {
    'hint-pack' => '2 hints',
    'undo-pack' => '3 undos',
    'ad-coins' => '+30 coins',
    'classic' => 'Classic',
    'sunset' => 'Sunset',
    'remove-ads' => 'Remove Ads',
    _ => id,
  };

  String shopOfferDescription(String id) => _ur ? switch (id) {
    'hint-pack' => 'ابھی نکلنے والی سواری دیکھیں',
    'undo-pack' => 'آخری نکلی سواری واپس لائیں',
    'ad-coins' => 'انعامی اشتہار دیکھیں',
    'classic' => 'اصل Clearway تیر کا انداز',
    'sunset' => 'صرف UI اور ملکیت کی تیاری؛ مرحلہ ۷ میں آئے گا',
    'remove-ads' => 'ایک بار کی خریداری',
    _ => '',
  } : switch (id) {
    'hint-pack' => 'Find a vehicle that can leave now',
    'undo-pack' => 'Bring back your last cleared vehicle',
    'ad-coins' => 'Watch a rewarded ad',
    'classic' => 'The original Clearway arrow style',
    'sunset' => 'UI and ownership wiring only; arrives in Phase 7',
    'remove-ads' => 'One-time purchase',
    _ => '',
  };

  String freeCoinsLeft(int remaining) => _ur ? '$remaining باقی ہیں' : '$remaining remaining';
  String get comingSoon => _ur ? 'جلد آ رہا ہے' : 'Coming soon';
  String get watchAd => _ur ? 'مختصر اشتہار دیکھیں' : 'Watch a short ad';

  // Game Strings
  String get wayClear => _ur ? 'راستہ صاف' : 'Way clear';
  String get allVehiclesOut => _ur ? 'تمام سواریاں باہر' : 'All vehicles out';
  String get hintAdded => _ur ? 'اشارہ شامل' : 'Hint added';
  String get undoAdded => _ur ? 'واپسی شامل' : 'Undo added';
  String get cloudError => _ur ? 'کلاؤڈ آپریشن میں خرابی' : 'Cloud operation error';
  String get notNow => _ur ? 'ابھی نہیں' : 'Not now';
  String get watchAdDouble => _ur ? 'دوبارہ اشتہار دیکھیں' : 'Watch ad again';
  String get rewardDoubled => _ur ? 'انعام دگنا ہو گیا!' : 'Reward doubled!';
  String get backToHome => _ur ? 'گھر واپس' : 'Back to home';
  String get nextLevel => _ur ? 'اگلا لیول' : 'Next level';
  String get replay => _ur ? 'پلی' : 'Replay';
  String get tryAgain => _ur ? 'دوبارہ کوشش کریں' : 'Try again';
  String get home => _ur ? 'گھر' : 'Home';
  String get takeABreak => _ur ? 'راستہ صاف کرنے کے لیے تھک گئے؟' : 'Take a break?';
  String get pauseMessage => _ur ? 'پاوس' : 'Paused';
  String get keepPlaying => _ur ? 'کھیلنا جاری رکھیں' : 'Keep playing';
  String get restartLevel => _ur ? 'لیول دوبارہ شروع کریں' : 'Restart level';
  String vehiclesRemaining(int remaining) => _ur ? 'باقی سواریاں: ${_digits(remaining)}' : 'Vehicles remaining: ${_digits(remaining)}';

  String firstDepartureTip() => _ur ? 'اس سواری کو چھوئیں جس کا راستہ صاف ہے۔' : 'Tap the bus whose road ahead is already clear.';
  String blockedVehicleTip() => _ur ? 'پہلے وہ سواری ہٹائیں جو راستہ روک رہی ہے۔' : 'Clear the bus blocking another bus’s exit.';
  String orderTip() => _ur ? 'چال چلنے سے پہلے محفوظ ترتیب دیکھیں۔' : 'Look for the safe order before moving.';
  String bossShapeTip() => _ur ? 'باس لیول کا انداز دیکھیں۔' : 'Look at the boss level shape.';
  String breatherTip() => _ur ? 'بھاری لیول سے تھک گئے؟' : 'Tired of heavy levels?';
  String bigBoardTip() => _ur ? 'بڑے بورڈ کے لیے پین اور زوم کریں۔' : 'Pan and zoom for big boards.';
  String get rushHour => _ur ? 'رش آور' : 'RUSH HOUR';
  String get dailyLabel => _ur ? 'روزانہ' : 'DAILY';
  String levelNumber(int number) => _ur ? 'لیول ${_digits(number)}' : 'Level ${_digits(number)}';
  String get bossLevel => _ur ? 'باس لیول' : 'Boss Level';
  String levelTitle(int level) => _ur ? 'لیول ${_digits(level)}' : 'Level ${_digits(level)}';
  String hintCount(int count) => _ur ? '${_digits(count)} اشارے' : '$count hints';
  String undoCount(int count) => _ur ? '${_digits(count)} واپسیاں' : '$count undos';
  String get zoomLocked => _ur ? 'زوم لک ہوا ہے' : 'Zoom locked';
  String get lockZoom => _ur ? 'زوم لکائیں' : 'Lock zoom';
  String get letsGo => _ur ? 'جائیں' : 'Let’s go';
  String get coneBlocked => _ur ? 'کونے سے روک دیا گیا' : 'Blocked by cone';
  String get gateBlocked => _ur ? 'گیت سے روک دیا گیا' : 'Blocked by gate';
  String get convoyBlocked => _ur ? 'کنوے سے روک دیا گیا' : 'Blocked by convoy';
  String get blockedByVehicle => _ur ? 'سواری سے روک دیا گیا' : 'Blocked by vehicle';
  String adForHint() => _ur ? 'اشارے ختم ہو گئے۔ مختصر اشتہار دیکھ کر 1 اشارہ پائیں؟' : 'Out of hints. Watch a short ad to get 1 hint?';
  String adForUndo() => _ur ? 'واپسی کے موقع ختم۔ مختصر اشتہار دیکھ کر 1 موقع پائیں؟' : 'No undos left. Watch a short ad to get 1 undo?';
  String retryMessage() => _ur ? 'دوبارہ کوشش کریں' : 'Retry';
  String reviveShort(int cost) => _ur ? 'لیفز: $cost سکے' : 'Lives: $cost coins';
  String watchAdRevive(int cost) => _ur ? 'مختصر اشتہار دیکھ کر $cost سکے سے ایک لیفز حاصل کریں' : 'Watch a short ad to get $cost coins for a life';
  String reviveLabel(int cost) => _ur ? 'لیفز حاصل کریں ($cost سکے)' : 'Get a life ($cost coins)';

  // Home Screen
  String get synced => _ur ? 'سنک' : 'Synced';
  String get syncing => _ur ? 'سنک کر رہا ہے' : 'Syncing';
  String get offline => _ur ? 'آف لائن' : 'Offline';
  String get cloudUnavailable => _ur ? 'کلاؤڈ دستیاب نہیں' : 'Cloud unavailable';
  String get homeDescription => _ur ? 'تیر کو چھو کر بورڈ سے باہر نکالیں۔ صحیح ترتیب تلاش کریں۔' : 'Tap an arrow to slide it off the board. Find the right order, then clear the way.';
  String get startDriving => _ur ? 'کھیلنا شروع کریں' : 'Play';
  String get level => _ur ? 'لیول' : 'LEVEL';
  String get dailyCalendar => _ur ? 'روزانہ کیلنڈر' : 'Daily calendar';
  String dailyGift() => _ur ? 'روزانہ انعام' : 'Daily gift';
  String get yardShop => _ur ? 'دکان' : 'Shop';
  String giftClaimed() => _ur ? 'انعام حاصل' : 'Claimed';
  String get chooseYard => _ur ? 'لیول منتخب کریں' : 'Choose a level';

  // Notification Strings
  String get notificationPermissionTitle => _ur ? 'یاد دہانیاں آن کریں؟' : 'Turn on reminders?';
  String get notificationPermissionMessage => _ur ? 'ہم صرف زیر التوا لیول اور روزانہ چیلنج کی یاد دہانی بھیجیں گے۔ آپ یہ اختیار کبھی بھی ترتیبات میں بند کر سکتے ہیں۔' : 'We will only remind you about an unfinished level and the daily challenge. You can turn reminders off anytime in Settings.';
  String get notificationPermissionNotNow => _ur ? 'ابھی نہیں' : 'Not now';
  String get notificationPermissionEnable => _ur ? 'یاد دہانیاں آن کریں' : 'Turn on reminders';
  String get notificationChannelName => _ur ? 'Clearway یاد دہانیاں' : 'Clearway reminders';
  String get notificationChannelDescription => _ur ? 'زیر التوا لیول اور روزانہ چیلنج کی اختیاری یاد دہانیاں۔' : 'Optional reminders for unfinished levels and daily challenges.';
  String get midLevelReminderTitle => _ur ? 'آپ کا لیول ابھی باقی ہے' : 'Your level is waiting';
  String get midLevelReminderBody => _ur ? 'واپس آئیں اور اپنا لیول مکمل کریں۔' : 'Come back and finish your level.';
  String get dailyReminderTitle => _ur ? 'روزانہ چیلنج تیار ہے' : 'Daily challenge ready';
  String get dailyReminderBody => _ur ? 'آج کا چیلنج مکمل کرنے کے لیے واپس آئیں۔' : 'Come back for today’s challenge.';

  // Achievement and Mission Strings
  String achievementName(String id) => _ur ? switch (id) {
    'clear-10-no-hints' => 'اشارے کے بغیر ۱۰ لیول',
    'clear-boss' => 'باس لیول صاف کریں',
    'daily-streak-7' => '۷ دن کا سلسلہ',
    'reach-level-80' => 'لیول ۸۰ تک پہنچیں',
    _ => id,
  } : switch (id) {
    'clear-10-no-hints' => 'Clear 10 levels without hints',
    'clear-boss' => 'Clear a boss level',
    'daily-streak-7' => 'Reach a 7-day streak',
    'reach-level-80' => 'Reach level 80',
    _ => id,
  };

  String missionName(String id) => _ur ? (id.contains('clear-levels') ? 'لیول مکمل کریں' : id.contains('no-hints') ? 'اشارے کے بغیر مکمل کریں' : 'باس لیول صاف کریں') : (id.contains('clear-levels') ? 'Complete levels' : id.contains('no-hints') ? 'Clear without hints' : 'Clear a boss level');

  String progressLabel(int value, int target) => _ur ? '${_digits(value)} / ${_digits(target)}' : '$value / $target';
  String coinsReward(int coins) => _ur ? '+🪙${_digits(coins)}' : '+🪙$coins';
  String achievementComplete() => _ur ? 'کامیابی مکمل!' : 'Achievement complete!';
  String missionComplete() => _ur ? 'مشن مکمل!' : 'Mission complete!';
  String dailyWithStreak(int days) => _ur ? '$days دن کا سلسلہ' : '$days day streak';
  String newPuzzleIn(String countdown) => _ur ? 'نیا چیلنج $countdown میں' : 'New puzzle in $countdown';

  // Chapter Strings
  String chapterLabel(int number) => _ur ? 'مرحلہ $number' : 'Chapter $number';
  String chapterLevels(int chapter) => _ur ? 'مرحلہ $chapter: لیول' : 'Chapter $chapter: Levels';
  String chapterBoard(int chapter) => _ur ? 'مرحلہ $chapter: بورڈ' : 'Chapter $chapter: Board';
  String chapterBoss(int chapter) => _ur ? 'مرحلہ $chapter: باس' : 'Chapter $chapter: Boss';

  // Link and Error Strings
  String get linkError => _ur ? 'لینک کھولنے میں کامیابی نہیں ہوئی' : 'Failed to open link';
  String get linkPrivacy => _ur ? 'لینک نہیں کھل سکا۔' : 'Could not open the link.';

  // Terms and Conditions
  String get termsGateTitle => _ur ? 'کھیلنے سے پہلے' : 'Before you play';
  String get termsGateBody => _ur ? 'Clearway کھیلنے کے لیے براہ کرم شرائط و ضوابط اور رازداری کی پالیسی پڑھ کر قبول کریں۔' : 'Please read and accept the Terms & Conditions and the Privacy Policy to play Clearway.';
  String get termsGateCheckbox => _ur ? 'شرائط و ضوابط اور رازداری کی پالیسی پڑھ لی ہیں اور میں ان سے متفق ہوں۔' : 'I have read and accept the Terms & Conditions and the Privacy Policy.';
  String get termsGateContinue => _ur ? 'قبول کریں اور جاری رکھیں' : 'Accept and continue';

  // Settings
  String get settings => _ur ? 'ترتیبات' : 'Settings';
  String get settingsAccount => _ur ? 'اکاؤنٹ' : 'Account';
  String get linkedAccount => _ur ? 'اکاؤنٹ لنک ہے' : 'Account linked';
  String get anonymousAccount => _ur ? 'گمنام اکاؤنٹ' : 'Anonymous account';
  String get linkAccount => _ur ? 'پیش رفت محفوظ کرنے کے لیے اکاؤنٹ لنک کریں' : 'Link account to save your progress';
  String get accountActionUnavailable => _ur ? 'اکاؤنٹ لنک کرنے کا عمل اگلے مرحلے میں دستیاب ہوگا۔ آپ کی مقامی پیش رفت محفوظ ہے۔' : 'Account linking will be available in a later phase. Your local progress remains safe.';
  String get logout => _ur ? 'لاگ آؤٹ' : 'Logout';
  String get deleteAccount => _ur ? 'اکاؤنٹ حذف کریں' : 'Delete Account';
  String get logoutConfirm => _ur ? 'کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟' : 'Are you sure you want to log out?';
  String get deleteAccountConfirm => _ur ? 'یہ کارروائی واپس نہیں ہو سکتی۔ اکاؤنٹ اور اس سے منسلک آن لائن ڈیٹا حذف ہو جائے گا۔' : 'This cannot be undone. Your account and associated online data will be deleted.';

  // Additional Settings
  String get sound => _ur ? 'آواز' : 'Sound effects';
  String get music => _ur ? 'موسیقی' : 'Music';
  String get haptics => _ur ? 'وائبریشن' : 'Haptics';
  String get notifications => _ur ? 'یاد دہانیاں' : 'Notifications';
  String get languageLabel => _ur ? 'زبان' : 'Language';
  String get appVersion => _ur ? 'ایپ ورژن' : 'App version';
}