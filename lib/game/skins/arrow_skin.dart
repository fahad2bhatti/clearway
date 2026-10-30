import 'package:flutter/material.dart';

enum SkinCategory { free, premium, milestone }

final class ArrowSkin {
  const ArrowSkin({
    required this.id,
    required this.category,
    required this.primaryColors,
    required this.price,
    this.unlockLevel,
  });

  final String id;
  final SkinCategory category;
  final List<Color> primaryColors;
  final int price;
  final int? unlockLevel;

  Color colorFor(int index) => primaryColors[index % primaryColors.length];

  String name(String language) => language == 'ur' ? switch (id) {
    'classic' => 'کلاسک',
    'sunset' => 'غروب آفتاب',
    'spectrum' => 'اسپیکٹرم',
    _ => id,
  } : switch (id) {
    'classic' => 'Classic',
    'sunset' => 'Sunset',
    'spectrum' => 'Spectrum',
    _ => id,
  };

  String description(String language) => language == 'ur' ? switch (id) {
    'classic' => 'صاف یک رنگ تیر',
    'sunset' => 'گرم رنگوں کا مجموعہ',
    'spectrum' => 'لیول ۸۰ پر مفت کھلتا ہے',
    _ => '',
  } : switch (id) {
    'classic' => 'Clean monochrome arrows',
    'sunset' => 'A warm color palette',
    'spectrum' => 'Free at level 80',
    _ => '',
  };
}

class ArrowSkinCatalog {
  static final classic = ArrowSkin(
    id: 'classic',
    category: SkinCategory.free,
    primaryColors: [Color(0xffd9e5df)],
    price: 0,
  );
  static final sunset = ArrowSkin(
    id: 'sunset',
    category: SkinCategory.premium,
    primaryColors: [Color(0xffffb347), Color(0xffed6ca7), Color(0xffff796c)],
    price: 150,
  );
  static final spectrum = ArrowSkin(
    id: 'spectrum',
    category: SkinCategory.milestone,
    primaryColors: [
      Color(0xffff5c8d),
      Color(0xffffb347),
      Color(0xff61c69a),
      Color(0xff4ecac1),
    ],
    price: 0,
    unlockLevel: 80,
  );

  static const all = [classic, sunset, spectrum];

  static ArrowSkin byId(String id) => 
      all.where((skin) => skin.id == id).firstOrNull ?? classic;

  static bool contains(String id) => all.any((skin) => skin.id == id);

  static int get spectrumUnlockLevel => spectrum.unlockLevel!;
}