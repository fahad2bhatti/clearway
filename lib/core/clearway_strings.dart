/// Small built-in English/Urdu string set for the game UI.
final class ClearwayStrings {
  const ClearwayStrings(this.language);

  final String language;
  bool get _ur => language == 'ur';

  String get tagline => _ur ? 'راستہ صاف کریں۔' : 'Clear the path.';
  String get homeHeadline =>
      _ur ? 'ہر تیر کے لیے راستہ ہے۔' : 'Every arrow\nhas a way out.';
  String get homeDescription => _ur
      ? 'تیر کو چھو کر بورڈ سے باہر نکالیں۔ صحیح ترتیب تلاش کریں۔'
      : 'Tap an arrow to slide it off the board.\nFind the right order, then clear the way.';
  String get startDriving => _ur ? 'کھیلنا شروع کریں' : 'Play';
  String get level => _ur ? 'لیول' : 'LEVEL';
  String get dailyChallenge => _ur ? 'روزانہ کا چیلنج' : 'Daily challenge';
  String streak(int days) => _ur ? '$days دن کا سلسلہ' : '$days day streak';
  String get dailyCalendar => _ur ? 'روزانہ کیلنڈر' : 'Daily calendar';
  String get achievements => _ur ? 'کامیابیاں' : 'Achievements';
  String get missions => _ur ? 'روزانہ مشن' : 'Daily missions';
  String get claim => _ur ? 'حاصل کریں' : 'Claim';
  String get claimed => _ur ? 'حاصل ہو گیا' : 'Claimed';
  String get missionComplete => _ur ? 'مشن مکمل!' : 'Mission complete!';
  String get achievementComplete => _ur ? 'کامیابی مکمل!' : 'Achievement complete!';
  String achievementName(String id) => _ur
      ? switch (id) {
          'clear-10-no-hints' => 'اشارے کے بغیر ۱۰ لیول',
          'clear-boss' => 'باس لیول صاف کریں',
          'daily-streak-7' => '۷ دن کا سلسلہ',
          'reach-level-80' => 'لیول ۸۰ تک پہنچیں',
          _ => id,
        }
      : switch (id) {
          'clear-10-no-hints' => 'Clear 10 levels without hints',
          'clear-boss' => 'Clear a boss level',
          'daily-streak-7' => 'Reach a 7-day streak',
          'reach-level-80' => 'Reach level 80',
          _ => id,
        };
  String missionName(String id) => _ur
      ? (id.contains('clear-levels')
            ? 'لیول مکمل کریں'
            : id.contains('no-hints')
            ? 'اشارے کے بغیر مکمل کریں'
            : 'باس لیول صاف کریں')
      : (id.contains('clear-levels')
            ? 'Complete levels'
            : id.contains('no-hints')
            ? 'Clear without hints'
            : 'Clear a boss level');
  String progressLabel(int value, int target) =>
      _ur ? '${_digits(value)} / ${_digits(target)}' : '$value / $target';
  String coinsReward(int coins) =>
      _ur ? '+🪙${_digits(coins)}' : '+🪙$coins';
  String get yardShop => _ur ? 'دکان' : 'Shop';
  String get settings => _ur ? 'ترتیبات' : 'Settings';
  String get shopTitle => _ur ? 'دکان' : 'Shop';
  String get shopCoins => _ur ? 'سکے اور اشارے' : 'Coins and hints';
  String get shopSkins => _ur ? 'تیر کی کھالیں' : 'Arrow skins';
  String get shopAds => _ur ? 'روزانہ اشتہاری انعامات' : 'Daily ad offers';
  String get shopRemoveAds => _ur ? 'اشتہارات ہٹائیں' : 'Remove Ads';
  String get comingSoon => _ur ? 'جلد آ رہا ہے' : 'Coming soon';
  String get owned => _ur ? 'ملکیت میں' : 'Owned';
  String get selected => _ur ? 'منتخب' : 'Selected';
  String get select => _ur ? 'منتخب کریں' : 'Select';
  String get buy => _ur ? 'خریدیں' : 'Buy';
  String get insufficientCoins => _ur ? 'سکے کم ہیں' : 'Not enough coins';
  String get unavailableOffline => _ur ? 'آف لائن دستیاب نہیں' : 'Unavailable offline';
  String get settingsAccount => _ur ? 'اکاؤنٹ' : 'Account';
  String get username => _ur ? 'صارف نام' : 'Username';
  String get usernameHelp => _ur ? 'صرف انگریزی حروف، اعداد اور _ (۳ تا ۱۵ حروف)۔' : 'English letters, numbers and _ only (3-15 characters).';
  String get usernameTooShort => _ur ? 'صارف نام کم از کم ۳ حروف کا ہونا چاہیے۔' : 'Username must be at least 3 characters.';
  String get usernameTooLong => _ur ? 'صارف نام زیادہ سے زیادہ ۱۵ حروف کا ہو سکتا ہے۔' : 'Username can be at most 15 characters.';
  String get usernameInvalid => _ur ? 'صرف انگریزی حروف، اعداد اور انڈر سکور (_) استعمال کریں۔' : 'Use only English letters, numbers and underscore (_).';
  String usernameTaken(String name) => _ur ? '$name پہلے سے لیا جا چکا ہے۔ کوئی اور نام چنیں۔' : '"$name" is already taken. Please choose another name.';
  String get anonymousAccount => _ur ? 'گمنام اکاؤنٹ' : 'Anonymous account';
  String get linkAccount => _ur ? 'پیش رفت محفوظ کرنے کے لیے اکاؤنٹ لنک کریں' : 'Link account to save your progress';
  String get linkedAccount => _ur ? 'اکاؤنٹ لنک ہے' : 'Account linked';
  String get notifications => _ur ? 'اطلاعات' : 'Notifications';
  String get notificationPermissionTitle =>
      _ur ? 'یاد دہانیاں آن کریں؟' : 'Turn on reminders?';
  String get notificationPermissionMessage => _ur
      ? 'ہم صرف زیر التوا لیول اور روزانہ چیلنج کی یاد دہانی بھیجیں گے۔ آپ یہ اختیار کبھی بھی ترتیبات میں بند کر سکتے ہیں۔'
      : 'We will only remind you about an unfinished level and the daily challenge. You can turn reminders off anytime in Settings.';
  String get notificationPermissionEnable =>
      _ur ? 'یاد دہانیاں آن کریں' : 'Turn on reminders';
  String get notificationPermissionNotNow => _ur ? 'ابھی نہیں' : 'Not now';
  String get midLevelReminderTitle =>
      _ur ? 'آپ کا لیول ابھی باقی ہے' : 'Your level is waiting';
  String get midLevelReminderBody => _ur
      ? 'واپس آئیں اور اپنا لیول مکمل کریں۔'
      : 'Come back and finish your level.';
  String get dailyReminderTitle =>
      _ur ? 'روزانہ چیلنج تیار ہے' : 'Daily challenge ready';
  String get dailyReminderBody => _ur
      ? 'آج کا چیلنج مکمل کرنے کے لیے واپس آئیں۔'
      : 'Come back for today’s challenge.';
  String get notificationChannelName =>
      _ur ? 'Clearway یاد دہانیاں' : 'Clearway reminders';
  String get notificationChannelDescription => _ur
      ? 'زیر التوا لیول اور روزانہ چیلنج کی اختیاری یاد دہانیاں۔'
      : 'Optional reminders for unfinished levels and daily challenges.';
  String get rateUs => _ur ? 'ہمیں ریٹ کریں' : 'Rate Us';
  String get ratingTitle => _ur ? 'Clearway کو ریٹ کریں' : 'Rate Clearway';
  String get ratingQuestion => _ur ? 'آپ کو کھیل کیسا لگا؟' : 'How are you enjoying the game?';
  String get ratingStorePrompt => _ur
      ? 'کیا آپ Clearway کو Play Store پر ریٹ کرنا چاہیں گے؟'
      : 'Would you like to rate Clearway on the Play Store?';
  String get ratingNow => _ur ? 'ابھی ریٹ کریں' : 'Rate now';
  String get ratingNotNow => _ur ? 'ابھی نہیں' : 'Not now';
  String get sendFeedback => _ur ? 'رائے بھیجیں' : 'Send Feedback';
  String get privacyPolicy => _ur ? 'رازداری کی پالیسی' : 'Privacy Policy';
  String get terms => _ur ? 'شرائط و ضوابط' : 'Terms & Conditions';
  String get termsGateTitle => _ur ? 'کھیلنے سے پہلے' : 'Before you play';
  String get termsGateBody => _ur
      ? 'Clearway کھیلنے کے لیے براہ کرم شرائط و ضوابط اور رازداری کی پالیسی پڑھ کر قبول کریں۔'
      : 'Please read and accept the Terms & Conditions and the Privacy Policy to play Clearway.';
  String get termsGateCheckbox => _ur
      ? 'شرائط و ضوابط اور رازداری کی پالیسی پڑھ لی ہیں اور میں ان سے متفق ہوں۔'
      : 'I have read and accept the Terms & Conditions and the Privacy Policy.';
  String get termsGateContinue =>
      _ur ? 'قبول کریں اور جاری رکھیں' : 'Accept and continue';
  String get appVersion => _ur ? 'ایپ ورژن' : 'App version';
  String get logout => _ur ? 'لاگ آؤٹ' : 'Logout';
  String get deleteAccount => _ur ? 'اکاؤنٹ حذف کریں' : 'Delete Account';
  String get cancel => _ur ? 'منسوخ' : 'Cancel';
  String get confirm => _ur ? 'تصدیق کریں' : 'Confirm';
  String get logoutConfirm => _ur ? 'کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟' : 'Are you sure you want to log out?';
  String get deleteAccountConfirm => _ur
      ? 'یہ کارروائی واپس نہیں ہو سکتی۔ اکاؤنٹ اور اس سے منسلک آن لائن ڈیٹا حذف ہو جائے گا۔'
      : 'This cannot be undone. Your account and associated online data will be deleted.';
  String get accountActionUnavailable => _ur
      ? 'اکاؤنٹ لنک کرنے کا عمل اگلے مرحلے میں دستیاب ہوگا۔ آپ کی مقامی پیش رفت محفوظ ہے۔'
      : 'Account linking will be available in a later phase. Your local progress remains safe.';
  String get accountDeleted => _ur ? 'اکاؤنٹ حذف ہو گیا' : 'Account deleted';
  String get accountDeleteFailed => _ur ? 'اکاؤنٹ حذف نہیں ہو سکا۔ دوبارہ کوشش کریں۔' : 'Account deletion failed. Please retry.';
  String get feedbackUnavailable => _ur ? 'رائے بھیجنے کے لیے آن لائن کنکشن درکار ہے۔' : 'An online connection is required to send feedback.';
  String get feedbackSent => _ur ? 'رائے بھیج دی گئی۔' : 'Feedback sent.';
  String get feedbackQueued => _ur ? 'رائے محفوظ ہو گئی۔ انٹرنیٹ آنے پر بھیج دی جائے گی۔' : 'Saved. It will be sent when you are back online.';
  String get feedbackQueueFull => _ur ? 'بھیجنے کے منتظر پیغامات کی حد پوری ہو گئی ہے۔ آن لائن ہو کر دوبارہ کوشش کریں۔' : 'Too many messages are waiting to be sent. Please go online and try again.';
  String get feedbackPrompt => _ur ? 'اپنی رائے لکھیں' : 'Write your feedback';
  String get feedbackEmpty => _ur ? 'رائے خالی نہیں ہو سکتی۔' : 'Feedback cannot be empty.';
  String get linkOpenError => _ur ? 'لنک نہیں کھل سکا۔' : 'Could not open the link.';
  String get rateUnavailable => _ur ? 'ریٹنگ ابھی دستیاب نہیں۔' : 'Rating is not available yet.';
  String skinName(String id) => _ur
      ? switch (id) {
          'classic' => 'کلاسک',
          'sunset' => 'غروب آفتاب',
          'spectrum' => 'اسپیکٹرم',
          _ => id,
        }
      : switch (id) {
          'classic' => 'Classic',
          'sunset' => 'Sunset',
          'spectrum' => 'Spectrum',
          _ => id,
        };
  String skinDescription(String id) => _ur
      ? switch (id) {
          'classic' => 'صاف یک رنگ تیر',
          'sunset' => 'گرم رنگوں کا مجموعہ',
          'spectrum' => 'لیول ۸۰ پر مفت کھلتا ہے',
          _ => '',
        }
      : switch (id) {
          'classic' => 'Clean monochrome arrows',
          'sunset' => 'A warm color palette',
          'spectrum' => 'Free at level 80',
          _ => '',
        };
  String get unlockAt80 => _ur ? 'لیول ۸۰ پر کھلے گا' : 'Unlocks at level 80';
  String get skinPurchased => _ur ? 'اسکن خرید لیا گیا' : 'Skin purchased';
  String get skinEquipped => _ur ? 'اسکن منتخب ہے' : 'Skin equipped';
  String get skinUnlocked => _ur ? 'نیا اسکن مفت کھل گیا!' : 'New skin unlocked for free!';
  String get rewardSummary => _ur ? 'سنگ میل کا انعام' : 'Milestone reward';
  String milestoneReward(int level, int coins, int hints) => _ur
      ? 'لیول ${_digits(level)}: +🪙${_digits(coins)}، +${_digits(hints)} اشارے'
      : 'Level $level: +🪙$coins, +$hints hints';
  String shopOfferTitle(String id) => _ur
      ? switch (id) {
          'hint-pack' => '۲ اشارے',
          'undo-pack' => '۳ واپسی کے مواقع',
          'ad-coins' => '+۳۰ سکے',
          'classic' => 'کلاسک',
          'sunset' => 'غروب آفتاب',
          'remove-ads' => 'اشتہارات ہٹائیں',
          _ => id,
        }
      : switch (id) {
          'hint-pack' => '2 hints',
          'undo-pack' => '3 undos',
          'ad-coins' => '+30 coins',
          'classic' => 'Classic',
          'sunset' => 'Sunset',
          'remove-ads' => 'Remove Ads',
          _ => id,
        };
  String shopOfferDescription(String id) => _ur
      ? switch (id) {
          'hint-pack' => 'ابھی نکلنے والی سواری دیکھیں',
          'undo-pack' => 'آخری نکلی سواری واپس لائیں',
          'ad-coins' => 'انعامی اشتہار دیکھیں',
          'classic' => 'اصل Clearway تیر کا انداز',
          'sunset' => 'صرف UI اور ملکیت کی تیاری؛ مرحلہ ۷ میں آئے گا',
          'remove-ads' => 'ایک بار کی خریداری',
          _ => '',
        }
      : switch (id) {
          'hint-pack' => 'Find a vehicle that can leave now',
          'undo-pack' => 'Bring back your last cleared vehicle',
          'ad-coins' => 'Watch a rewarded ad',
          'classic' => 'The original Clearway arrow style',
          'sunset' => 'UI and ownership wiring only; arrives in Phase 7',
          'remove-ads' => 'One-time purchase',
          _ => '',
        };
  String get sound => _ur ? 'آواز' : 'Sound effects';
  String get music => _ur ? 'موسیقی' : 'Music';
  String get haptics => _ur ? 'وائبریشن' : 'Haptics';
  String get darkTheme => _ur ? 'ڈارک تھیم' : 'Dark theme';
  String get colorblind =>
      _ur ? 'رنگوں کے متبادل نشانات' : 'Color-blind patterns';
  String get languageLabel => _ur ? 'زبان' : 'Language';
  String hintPack(int count) =>
      _ur ? '${_digits(count)} اشارے' : '$count hints';
  String get hintDescription => _ur
      ? 'ابھی نکلنے والی سواری دیکھیں'
      : 'Find a vehicle that can leave now';
  String get undos3 => _ur ? '۳ واپسی کے موقع' : '3 undos';
  String get undoDescription => _ur
      ? 'آخری نکلی سواری واپس لائیں'
      : 'Bring back your last cleared vehicle';
  String get practiceReward => _ur ? 'مشق کا انعام' : 'Practice reward';
  String get offlineDemoReward =>
      _ur ? 'آف لائن نمونہ انعام' : 'Offline demo reward';
  String get chooseYard => _ur ? 'لیول منتخب کریں' : 'Choose a level';
  String get rushHour => _ur ? 'رش آور' : 'RUSH HOUR';
  String get daily => _ur ? 'روزانہ' : 'DAILY';
  String newPuzzleIn(String countdown) =>
      _ur ? 'نیا چیلنج $countdown میں' : 'New puzzle in $countdown';
  String get firstDepartureTip => _ur
      ? 'اس سواری کو چھوئیں جس کا راستہ صاف ہے۔'
      : 'Tap the bus whose road ahead is already clear.';
  String get blockedVehicleTip => _ur
      ? 'پہلے وہ سواری ہٹائیں جو راستہ روک رہی ہے۔'
      : 'Clear the bus blocking another bus’s exit.';
  String get orderTip => _ur
      ? 'چال چلنے سے پہلے محفوظ ترتیب دیکھیں۔'
      : 'Look for the safe order before moving.';
  // The strings from here to the end of this block are English only for now.
  String chapterLabel(int number) => 'CHAPTER $number';
  String chapterLevels(int first, int last) => 'Levels $first–$last';
  String chapterBoard(int width, int height) =>
      'Boards start at $width×$height.';
  String chapterBoss(int level) => 'A boss yard waits at level $level.';
  String get letsGo => 'Let’s go';
  String reviveLabel(int cost) => 'Revive  🪙$cost';
  String reviveShort(int missing) => 'Earn 🪙$missing more to revive.';
  String watchAdRevive(int lives) =>
      _ur ? 'اشتہار دیکھیں · +$lives جانیں' : 'Watch ad · +$lives lives';
  String watchAdDouble(int coins) => _ur
      ? 'اشتہار دیکھیں · انعام دگنا (+🪙$coins)'
      : 'Watch ad · double reward (+🪙$coins)';
  String get rewardDoubled => _ur ? 'انعام دگنا ہو گیا!' : 'Reward doubled!';
  String get adNotReady => _ur
      ? 'کوئی انعام نہیں ملا۔ اشتہار دستیاب نہیں یا جلدی بند ہو گیا۔'
      : 'No reward. Ad not available or closed early.';
  String get adForHint => _ur
      ? 'اشارے ختم ہو گئے۔ مختصر اشتہار دیکھ کر 1 اشارہ پائیں؟'
      : 'Out of hints. Watch a short ad to get 1 hint?';
  String get adForUndo => _ur
      ? 'واپسی کے موقع ختم۔ مختصر اشتہار دیکھ کر 1 موقع پائیں؟'
      : 'No undos left. Watch a short ad to get 1 undo?';
  String get hintAdded => _ur ? '1 اشارہ مل گیا!' : 'Hint added!';
  String get undoAdded => _ur ? '1 واپسی مل گئی!' : 'Undo added!';
  String get watchAd => _ur ? 'اشتہار دیکھیں' : 'Watch ad';
  String get notNow => _ur ? 'ابھی نہیں' : 'Not now';
  String dailyGift(int coins) =>
      _ur ? 'روزانہ تحفہ · +🪙$coins' : 'Daily gift · +🪙$coins';
  String giftClaimed(int coins) =>
      _ur ? 'تحفہ مل گیا! +🪙$coins' : 'Gift claimed! +🪙$coins';
  String get freeCoinsAd => _ur ? 'مفت سکے' : 'Free coins';
  String freeCoinsLeft(int left) => left > 0
      ? (_ur
            ? 'اشتہار دیکھیں · آج $left باقی'
            : 'Watch an ad · $left left today')
      : (_ur ? 'کل دوبارہ آئیں' : 'Come back tomorrow');
  String get lockZoom => 'Lock zoom';
  String get zoomLocked => 'Zoom locked';
  String get bossShapeTip =>
      'Boss level! The board has a shape now. Buses bend to fit it.';
  String get breatherTip =>
      'A breather: fewer buses. Start with one that has a clear line out.';
  String get bigBoardTip =>
      'Boss level! Pinch to zoom, drag to pan, free the front buses first.';
  String get blockedByVehicle =>
      _ur ? 'دوسری سواری راستہ روک رہی ہے' : 'Blocked by another vehicle';
  String get coneBlocked => _ur ? 'راستے میں کون ہے' : 'A cone is in the way';
  String get gateBlocked => _ur ? 'یک طرفہ گیٹ' : 'One-way gate';
  String get convoyBlocked =>
      _ur ? 'قافلے کی دوسری سواری پھنسی ہے' : 'Convoy partner is blocked';
  String get outOfHints => _ur
      ? 'اشارے ختم — مزید کے لیے دکان دیکھیں۔'
      : 'Out of hints — visit the shop for more.';
  String get outOfUndos => _ur
      ? 'واپسی کے موقع ختم — دکان دیکھیں۔'
      : 'No undos left — visit the shop for more.';
  String get wayClear => _ur ? 'راستہ صاف ہے!' : 'Way clear!';
  String get allVehiclesOut => _ur
      ? 'آپ نے تمام سواریوں کو باہر نکال دیا۔'
      : 'You guided every vehicle out.';
  String get trafficJam => _ur ? 'ٹریفک جام!' : 'Traffic jam!';
  String get retryMessage => _ur
      ? 'وقفہ لیں اور دوسری ترتیب آزمائیں۔'
      : 'Take a breath and try a different order.';
  String get backToHome => _ur ? 'ہوم پر واپس' : 'Back to home';
  String get nextLevel => _ur ? 'اگلا لیول' : 'Next level';
  String get replay => _ur ? 'دوبارہ کھیلیں' : 'Replay';
  String get tryAgain => _ur ? 'پھر کوشش کریں' : 'Try again';
  String get home => _ur ? 'ہوم' : 'Home';
  String get takeABreak => _ur ? 'وقفہ لیں' : 'Take a break';
  String get pauseMessage => _ur
      ? 'آپ کی پیش رفت یہیں محفوظ ہے۔'
      : 'Your progress is saved right here.';
  String get keepPlaying => _ur ? 'کھیل جاری رکھیں' : 'Keep playing';
  String get restartLevel => _ur ? 'لیول دوبارہ شروع کریں' : 'Restart level';
  String get hint => _ur ? 'اشارہ' : 'Hint';
  String get undo => _ur ? 'واپس' : 'Undo';
  String get bossLevel => _ur ? 'باس لیول' : 'BOSS LEVEL';
  String get synced => _ur ? 'کلاؤڈ محفوظ' : 'Cloud save synced';
  String get syncing => _ur ? 'ہم وقت ہو رہا ہے' : 'Syncing progress';
  String get offline => _ur ? 'آف لائن / محفوظ نہیں' : 'Offline / not synced';
  String get cloudError => _ur ? 'کلاؤڈ کی خرابی' : 'Cloud sync error';
  String get cloudUnavailable =>
      _ur ? 'کلاؤڈ محفوظ دستیاب نہیں' : 'Cloud save unavailable';
  String get ready => _ur ? 'تیار' : 'READY';
  String chapterName(String chapter) => !_ur
      ? chapter
      : switch (chapter) {
          'Lahore' => 'لاہور',
          'Karachi' => 'کراچی',
          'Multan' => 'ملتان',
          'Quetta' => 'کوئٹہ',
          'Peshawar' => 'پشاور',
          'Faisalabad' => 'فیصل آباد',
          'Rush Hour' => 'رش آور',
          _ => chapter,
        };
  String levelTitle(String title) {
    if (!_ur) return title;
    return switch (title) {
      'First departure' => 'پہلی روانگی',
      'Wait your turn' => 'اپنی باری کا انتظار کریں',
      'Plan the order' => 'ترتیب بنائیں',
      'Daily rush' => 'روزانہ کا رش',
      _ when title.startsWith('Yard ') => 'لیول ${title.substring(5)}',
      _ when title.endsWith(' yard') => chapterName(
        title.substring(0, title.length - 5),
      ),
      _ => title,
    };
  }

  String get monthlyTrophy =>
      _ur ? 'ماہانہ ٹرافی حاصل!' : 'Monthly trophy earned';
  String get rushHourDays => _ur ? 'رش آور کے دن' : 'Rush Hour days';
  String get boss => _ur ? 'باس' : 'BOSS';
  String get dailyLabel => _ur ? 'روزانہ' : 'DAILY';
  String get starsLabel => _ur ? 'ستارے' : 'STARS';
  String get ratingPrompt => _ur ? 'اچھا کھیلا!' : 'Nice driving!';
  String get outOfHintsShort => _ur
      ? 'اشارے ختم — دکان دیکھیں۔'
      : 'Out of hints — visit the shop for more.';
  String get outOfUndosShort => _ur
      ? 'واپسی ختم — دکان دیکھیں۔'
      : 'No undos left — visit the shop for more.';

  String dailyWithStreak(int days) =>
      '$dailyChallenge${days > 0 ? '  •  ${streak(days)}' : ''}';
  String levelNumber(int number) =>
      '${_ur ? 'لیول' : 'LEVEL'} ${number.toString().padLeft(2, '0')}';
  String vehiclesRemaining(int count) =>
      _ur ? '$count سواریاں باقی ہیں' : '$count vehicles left';
  String hintCount(int count) => '$hint ${_digits(count)}';
  String undoCount(int count) => '$undo ${_digits(count)}';
  String monthName(int month) => _ur
      ? const [
          'جنوری',
          'فروری',
          'مارچ',
          'اپریل',
          'مئی',
          'جون',
          'جولائی',
          'اگست',
          'ستمبر',
          'اکتوبر',
          'نومبر',
          'دسمبر',
        ][month - 1]
      : const [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ][month - 1];
  String calendarProgress(int completed, int days) => _ur
      ? '${_digits(completed)} / ${_digits(days)} $rushHourDays${completed == days ? '  •  🏆 $monthlyTrophy' : ''}'
      : '$completed / $days $rushHourDays${completed == days ? '  •  🏆 $monthlyTrophy' : ''}';
  String _digits(int value) => _ur
      ? value
            .toString()
            .replaceAll('0', '۰')
            .replaceAll('1', '۱')
            .replaceAll('2', '۲')
            .replaceAll('3', '۳')
            .replaceAll('4', '۴')
            .replaceAll('5', '۵')
            .replaceAll('6', '۶')
            .replaceAll('7', '۷')
            .replaceAll('8', '۸')
            .replaceAll('9', '۹')
      : '$value';
}
