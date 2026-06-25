const MAX_LEVEL = 99;

const getRequiredPointsForLevel = (level) => {
  if (level <= 1) return 0;

  // Progressive curve: each level requires more points than the previous one.
  return Math.floor(50 * Math.pow(level - 1, 1.6));
};

const getLevelFromPoints = (totalPoints) => {
  let level = 1;

  while (level < MAX_LEVEL && totalPoints >= getRequiredPointsForLevel(level + 1)) {
    level += 1;
  }

  return level;
};

const getLevelProgress = (totalPoints) => {
  const safePoints = Math.max(0, Number(totalPoints) || 0);
  const level = getLevelFromPoints(safePoints);

  const currentLevelThreshold = getRequiredPointsForLevel(level);
  const nextLevelThreshold = level >= MAX_LEVEL ? currentLevelThreshold : getRequiredPointsForLevel(level + 1);
  const pointsIntoLevel = safePoints - currentLevelThreshold;
  const pointsNeededForNextLevel = Math.max(0, nextLevelThreshold - currentLevelThreshold);

  return {
    level,
    maxLevel: MAX_LEVEL,
    totalPoints: safePoints,
    currentLevelThreshold,
    nextLevelThreshold,
    pointsIntoLevel,
    pointsNeededForNextLevel,
    pointsRemainingForNextLevel: Math.max(0, nextLevelThreshold - safePoints),
    isMaxLevel: level >= MAX_LEVEL
  };
};

module.exports = {
  MAX_LEVEL,
  getRequiredPointsForLevel,
  getLevelFromPoints,
  getLevelProgress
};
