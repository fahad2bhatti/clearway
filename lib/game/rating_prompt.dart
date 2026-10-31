const ratingPromptMilestones = {10, 25, 50};

bool shouldShowRatingPrompt({
  required int level,
  required bool won,
  required bool daily,
  required Set<int> shownMilestones,
}) {
  if (!won || daily || !ratingPromptMilestones.contains(level)) return false;
  final shownCount =
      shownMilestones.intersection(ratingPromptMilestones).length;
  return shownCount < ratingPromptMilestones.length &&
      !shownMilestones.contains(level);
}
