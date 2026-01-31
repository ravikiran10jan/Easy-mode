import 'package:flutter_test/flutter_test.dart';
import 'package:easy_mode/core/models/user_model.dart';
import 'package:easy_mode/core/models/task_model.dart';
import 'package:easy_mode/core/models/script_model.dart';
import 'package:easy_mode/core/models/ritual_model.dart';

void main() {
  group('UserModel', () {
    test('fromMap creates UserModel correctly', () {
      final map = {
        'name': 'Test User',
        'email': 'test@example.com',
        'photoUrl': 'https://example.com/photo.jpg',
        'xpTotal': 500,
        'level': 2,
        'streak': 5,
        'createdAt': '2024-01-01T00:00:00.000Z',
      };

      final user = UserModel.fromMap(map, 'uid123');

      expect(user.uid, 'uid123');
      expect(user.name, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.xpTotal, 500);
      expect(user.level, 2);
      expect(user.streak, 5);
    });

    test('toMap creates correct map', () {
      final user = UserModel(
        uid: 'uid123',
        name: 'Test User',
        email: 'test@example.com',
        xpTotal: 500,
        level: 2,
        streak: 5,
        createdAt: DateTime(2024, 1),
      );

      final map = user.toMap();

      expect(map['name'], 'Test User');
      expect(map['email'], 'test@example.com');
      expect(map['xpTotal'], 500);
      expect(map['level'], 2);
      expect(map['streak'], 5);
    });

    test('hasCompletedOnboarding returns false when profile is null', () {
      final user = UserModel(
        uid: 'uid123',
        createdAt: DateTime.now(),
      );

      expect(user.hasCompletedOnboarding, false);
    });

    test('hasCompletedOnboarding returns true when profile exists', () {
      final user = UserModel(
        uid: 'uid123',
        profile: UserProfile(
          pain: 'test pain',
          goal: 'test goal',
          dailyTimeMinutes: 10,
          createdAt: DateTime.now(),
        ),
        createdAt: DateTime.now(),
      );

      expect(user.hasCompletedOnboarding, true);
    });

    test('xpForNextLevel calculates correctly', () {
      final user = UserModel(
        uid: 'uid123',
        level: 3,
        createdAt: DateTime.now(),
      );

      expect(user.xpForNextLevel, 1500); // level * 500
    });

    test('levelProgress calculates correctly', () {
      final user = UserModel(
        uid: 'uid123',
        level: 2,
        xpTotal: 750, // 500 for level 1, 250 into level 2
        createdAt: DateTime.now(),
      );

      expect(user.levelProgress, 0.25); // 250 / 1000 = 0.25
    });

    test('copyWith creates new instance with updated values', () {
      final user = UserModel(
        uid: 'uid123',
        name: 'Old Name',
        xpTotal: 100,
        createdAt: DateTime.now(),
      );

      final updated = user.copyWith(name: 'New Name', xpTotal: 200);

      expect(updated.uid, 'uid123'); // Unchanged
      expect(updated.name, 'New Name');
      expect(updated.xpTotal, 200);
    });
  });

  group('TaskModel', () {
    test('fromMap creates TaskModel correctly', () {
      final map = {
        'title': 'Test Task',
        'description': 'Task description',
        'type': 'action',
        'estimatedMinutes': 10,
        'xpReward': 100,
      };

      final task = TaskModel.fromMap(map, 'task123');

      expect(task.id, 'task123');
      expect(task.title, 'Test Task');
      expect(task.type, 'action');
      expect(task.estimatedMinutes, 10);
      expect(task.xpReward, 100);
    });

    test('toMap creates correct map', () {
      final task = TaskModel(
        id: 'task123',
        title: 'Test Task',
        description: 'Description',
        type: 'audacity',
        estimatedMinutes: 15,
        xpReward: 200,
      );

      final map = task.toMap();

      expect(map['title'], 'Test Task');
      expect(map['type'], 'audacity');
      expect(map['xpReward'], 200);
    });
  });

  group('ScriptModel', () {
    test('fromMap creates ScriptModel correctly', () {
      final map = {
        'title': 'Test Script',
        'category': 'Work',
        'template': 'Hello, this is a template',
        'riskLevel': 'medium',
        'exampleOutcomes': ['Outcome 1', 'Outcome 2'],
        'estimatedMinutes': 5,
      };

      final script = ScriptModel.fromMap(map, 'script123');

      expect(script.id, 'script123');
      expect(script.title, 'Test Script');
      expect(script.category, 'Work');
      expect(script.riskLevel, 'medium');
      expect(script.exampleOutcomes.length, 2);
    });

    test('handles empty exampleOutcomes', () {
      final map = {
        'title': 'Test Script',
        'category': 'Work',
        'template': 'Template',
        'riskLevel': 'low',
        'estimatedMinutes': 5,
      };

      final script = ScriptModel.fromMap(map, 'script123');

      expect(script.exampleOutcomes, isEmpty);
    });
  });

  group('RitualModel', () {
    test('fromMap creates RitualModel correctly', () {
      final map = {
        'title': 'Morning Playlist',
        'description': 'Start your day with music',
        'steps': ['Step 1', 'Step 2', 'Step 3'],
        'estimatedMinutes': 5,
        'category': 'Morning',
        'iconName': 'music',
      };

      final ritual = RitualModel.fromMap(map, 'ritual123');

      expect(ritual.id, 'ritual123');
      expect(ritual.title, 'Morning Playlist');
      expect(ritual.steps.length, 3);
      expect(ritual.iconName, 'music');
    });

    test('toMap creates correct map', () {
      final ritual = RitualModel(
        id: 'ritual123',
        title: 'Test Ritual',
        description: 'Description',
        steps: ['Step 1', 'Step 2'],
        estimatedMinutes: 10,
      );

      final map = ritual.toMap();

      expect(map['title'], 'Test Ritual');
      expect(map['steps'], ['Step 1', 'Step 2']);
      expect(map['estimatedMinutes'], 10);
    });
  });
}
