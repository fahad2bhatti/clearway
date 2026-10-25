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
  String get yardShop => _ur ? 'دکان' : 'Shop';
  String get settings => _ur ? 'ترتیبات' : 'Settings';
  String get sound => _ur ? 'آواز' : 'Sound effects';
  String get music => _ur ? 'موسیقی' : 'Music';
  String get haptics => _ur ? 'وائبریشن' : 'Haptics';
  String get darkTheme => _ur ? 'ڈارک تھیم' : 'Dark theme';
  String get colorblind =>
      _ur ? 'رنگوں کے متبادل نشانات' : 'Color-blind patterns';
  String get languageLabel => _ur ? 'زبان' : 'Language';
  String get hints3 => _ur ? '۳ اشارے' : '3 hints';
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
  String chapterBoss(int level) => 'A boss waits at level $level.';
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
  String get assistOn => _ur ? 'مدد آن' : 'Assist on';
  String get gridAssist => _ur ? 'گرڈ مدد' : 'Grid assist';
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
