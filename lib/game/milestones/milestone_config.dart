final class MilestoneReward {
  const MilestoneReward({
    required this.level,
    required this.coins,
    required this.hints,
  });

  final int level;
  final int coins;
  final int hints;
  String get id => 'level-$level';
}

abstract final class MilestoneConfig {
  static const rewards = [
    MilestoneReward(level: 10, coins: 25, hints: 1),
    MilestoneReward(level: 20, coins: 30, hints: 1),
    MilestoneReward(level: 30, coins: 35, hints: 1),
    MilestoneReward(level: 40, coins: 40, hints: 2),
    MilestoneReward(level: 50, coins: 45, hints: 2),
    MilestoneReward(level: 60, coins: 50, hints: 2),
    MilestoneReward(level: 70, coins: 60, hints: 3),
    MilestoneReward(level: 80, coins: 75, hints: 3),
  ];
}
