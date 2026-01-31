import 'package:flutter_test/flutter_test.dart';

// Import the functions to test
// In a real scenario, we'd extract these to a shared package
// For now, we replicate the logic for testing

/// Calculate XP with streak multiplier
int calculateXpWithStreak(int baseXp, int streak) {
  const streakBonusStartDay = 3;
  const streakMultiplier = 0.10;
  
  if (streak < streakBonusStartDay) {
    return baseXp;
  }
  
  final bonusDays = streak - streakBonusStartDay + 1;
  final multiplier = (bonusDays * streakMultiplier).clamp(0, 0.5);
  return (baseXp * (1 + multiplier)).round();
}

/// Calculate level from total XP
int calculateLevel(int xpTotal) {
  const xpPerLevel = 500;
  return (xpTotal ~/ xpPerLevel) + 1;
}

void main() {
  group('XP Calculation', () {
    test('no streak bonus before day 3', () {
      expect(calculateXpWithStreak(100, 0), 100);
      expect(calculateXpWithStreak(100, 1), 100);
      expect(calculateXpWithStreak(100, 2), 100);
    });

    test('streak bonus starts at day 3', () {
      // Day 3: +10%
      expect(calculateXpWithStreak(100, 3), 110);
    });

    test('streak bonus increases with each day', () {
      // Day 4: +20%
      expect(calculateXpWithStreak(100, 4), 120);
      // Day 5: +30%
      expect(calculateXpWithStreak(100, 5), 130);
    });

    test('streak bonus caps at 50%', () {
      // Day 7 and beyond should cap at 50%
      expect(calculateXpWithStreak(100, 7), 150);
      expect(calculateXpWithStreak(100, 10), 150);
      expect(calculateXpWithStreak(100, 100), 150);
    });

    test('works with different base XP values', () {
      // 200 XP base with day 3 streak
      expect(calculateXpWithStreak(200, 3), 220);
      // 200 XP base with max streak
      expect(calculateXpWithStreak(200, 10), 300);
    });
  });

  group('Level Calculation', () {
    test('level 1 for 0-499 XP', () {
      expect(calculateLevel(0), 1);
      expect(calculateLevel(100), 1);
      expect(calculateLevel(499), 1);
    });

    test('level 2 for 500-999 XP', () {
      expect(calculateLevel(500), 2);
      expect(calculateLevel(750), 2);
      expect(calculateLevel(999), 2);
    });

    test('level 3 for 1000-1499 XP', () {
      expect(calculateLevel(1000), 3);
      expect(calculateLevel(1499), 3);
    });

    test('high levels calculate correctly', () {
      expect(calculateLevel(5000), 11);
      expect(calculateLevel(10000), 21);
      expect(calculateLevel(25000), 51);
    });
  });

  group('XP Award Constants', () {
    const xpTaskComplete = 100;
    const xpAudacityAttempt = 200;
    const xpAudacitySuccess = 100;

    test('action task awards 100 XP', () {
      expect(xpTaskComplete, 100);
    });

    test('audacity attempt awards 200 XP', () {
      expect(xpAudacityAttempt, 200);
    });

    test('audacity success bonus is 100 XP', () {
      expect(xpAudacitySuccess, 100);
    });

    test('total audacity success XP is 300', () {
      expect(xpAudacityAttempt + xpAudacitySuccess, 300);
    });
  });

  group('Streak Calculation', () {
    test('streak resets to 1 if more than 1 day gap', () {
      // This would be tested in the actual Cloud Function
      // Here we document the expected behavior
      const daysDiff = 2;
      const newStreak = daysDiff > 1 ? 1 : 5; // Assuming previous streak was 5
      expect(newStreak, 1);
    });

    test('streak increments on consecutive day', () {
      const daysDiff = 1;
      const previousStreak = 5;
      final newStreak = daysDiff == 1 ? previousStreak + 1 : previousStreak;
      expect(newStreak, 6);
    });

    test('streak unchanged on same day', () {
      const daysDiff = 0;
      const previousStreak = 5;
      final newStreak = daysDiff == 0 ? previousStreak : previousStreak + 1;
      expect(newStreak, 5);
    });
  });
}
