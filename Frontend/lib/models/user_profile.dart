class UserProfile {
  final String userId;
  final String userName;
  final int xp;
  final int level;
  final int streakFreezeTokens;
  final int avatarEnergy;
  final int bestStreak; // Best active streak across habits
  final int healthXp;
  final int productivityXp;
  final int mindfulnessXp;
  final int learningXp;
  final String equippedAvatar;

  UserProfile({
    required this.userId,
    required this.userName,
    required this.xp,
    required this.level,
    required this.streakFreezeTokens,
    required this.avatarEnergy,
    required this.bestStreak,
    required this.healthXp,
    required this.productivityXp,
    required this.mindfulnessXp,
    required this.learningXp,
    required this.equippedAvatar,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] ?? '',
      userName: json['name'] ?? 'Habitster User',
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      streakFreezeTokens: json['streakFreezeTokens'] ?? 0,
      avatarEnergy: json['avatarEnergy'] ?? 100,
      bestStreak: json['bestStreak'] ?? 0,
      healthXp: json['healthXp'] ?? 0,
      productivityXp: json['productivityXp'] ?? 0,
      mindfulnessXp: json['mindfulnessXp'] ?? 0,
      learningXp: json['learningXp'] ?? 0,
      equippedAvatar: json['equippedAvatar'] ?? 'default_avatar',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': userName,
      'xp': xp,
      'level': level,
      'streakFreezeTokens': streakFreezeTokens,
      'avatarEnergy': avatarEnergy,
      'healthXp': healthXp,
      'productivityXp': productivityXp,
      'mindfulnessXp': mindfulnessXp,
      'learningXp': learningXp,
      'equippedAvatar': equippedAvatar,
    };
  }

  double get xpProgressToNextLevel {
    // Current level requires level * 100 XP
    // Level 1 -> 100 XP
    // If level 1 and xp 50, progress is 0.5
    // If level 2 and xp 150, progress is 0.5
    int nextLevelXp = level * 100;
    int previousLevelXp = (level - 1) * 100;
    int currentLevelProgress = xp - previousLevelXp;
    return (currentLevelProgress / 100).clamp(0.0, 1.0);
  }
}
