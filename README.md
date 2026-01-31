# Easy Mode - AI Life Coach

Your AI life coach for building confidence through **Action**, **Audacity**, and **Enjoyment**.

Easy Mode teaches users three core principles:
- **Action**: Clear and simple actions to build momentum
- **Audacity**: Bold asks that expand your comfort zone  
- **Enjoyment**: Romanticize everyday moments

## Architecture

```
easy_mode/
├── lib/
│   ├── core/                    # Shared code
│   │   ├── constants/           # App constants
│   │   ├── models/              # Data models
│   │   ├── providers/           # Riverpod providers
│   │   ├── services/            # Firebase services
│   │   └── theme/               # App theming
│   ├── features/                # Feature modules
│   │   ├── auth/                # Authentication
│   │   ├── onboarding/          # User onboarding
│   │   ├── home/                # Daily task screen
│   │   ├── scripts/             # Audacity scripts
│   │   ├── rituals/             # Joy rituals
│   │   ├── progress/            # XP & badges
│   │   └── profile/             # User settings
│   ├── widgets/                 # Shared widgets
│   ├── app_shell.dart           # Bottom navigation
│   └── main.dart                # Entry point
├── functions/                   # Firebase Cloud Functions
│   ├── src/
│   │   └── index.ts             # XP, badges, notifications
│   └── test/
├── scripts/                     # Utility scripts
│   ├── seed_data.json           # Seed content
│   └── seed_firestore.js        # Seed script
├── test/                        # Flutter tests
│   ├── unit/
│   └── widget/
└── demo/                        # Demo materials
```

## Tech Stack

- **Frontend**: Flutter 3.16+, Riverpod, Google Fonts
- **Backend**: Firebase (Auth, Firestore, Cloud Functions, FCM)
- **State Management**: Riverpod
- **CI/CD**: GitHub Actions

## Getting Started

### Prerequisites

- Flutter 3.16+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Node.js 18+ (for Cloud Functions)
- Firebase CLI (`npm install -g firebase-tools`)
- A Firebase project

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/easy-mode.git
   cd easy-mode
   ```

2. **Set up Firebase**
   ```bash
   # Login to Firebase
   firebase login
   
   # Initialize Firebase (select your project)
   firebase init
   
   # Select: Firestore, Functions, Hosting (optional)
   ```

3. **Configure Firebase for Flutter**
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase
   flutterfire configure
   ```

4. **Install dependencies**
   ```bash
   # Flutter dependencies
   flutter pub get
   
   # Cloud Functions dependencies
   cd functions && npm install && cd ..
   ```

5. **Seed Firestore with initial data**
   ```bash
   cd scripts
   node seed_firestore.js
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

### Environment Variables

Create a `.env` file (not committed to git):

```
# Optional: For LLM-powered features
OPENAI_API_KEY=your_key_here
```

For Firebase, the configuration is handled by FlutterFire CLI which generates `firebase_options.dart`.

## AI Features Setup

Easy Mode includes AI-powered coaching features that provide personalized task descriptions and daily insights.

### Features

| Feature | Description |
|---------|-------------|
| **Task Personalization** | AI personalizes task descriptions based on user context (name, streak, level, goals) and provides a "Coach Tip" |
| **Daily AI Insights** | Generates personalized daily coaching messages with greeting, insight, focus area, and encouragement |

### Setup OpenAI API Key

1. **Get an OpenAI API Key**
   - Visit [platform.openai.com](https://platform.openai.com)
   - Create an account or sign in
   - Navigate to API Keys and create a new key

2. **Set the API key in Firebase Functions config**
   ```bash
   cd functions
   firebase functions:config:set openai.key="YOUR_OPENAI_API_KEY"
   ```

3. **Deploy the functions**
   ```bash
   firebase deploy --only functions
   ```

4. **Verify deployment**
   ```bash
   firebase functions:config:get
   ```
   You should see your key configured (partially masked).

### Local Development with Emulator

To test AI features locally without deploying:

```bash
cd functions

# Set environment variable for emulator
export OPENAI_KEY="your_key_here"

# Or create .runtimeconfig.json for emulator
echo '{"openai":{"key":"YOUR_OPENAI_API_KEY"}}' > .runtimeconfig.json

# Start the emulator
firebase emulators:start --only functions
```

### Cost Estimates

The AI features use OpenAI's `gpt-4o-mini` model for cost efficiency:

| Operation | Tokens | Est. Cost |
|-----------|--------|-----------|
| Task Personalization | ~300 | ~$0.0005 |
| Daily Insight | ~250 | ~$0.0004 |
| **Per user per day** | ~550 | ~$0.001 |

### Disabling AI Features

If you want to run without AI features, they gracefully fall back to default content when:
- OpenAI API key is not configured
- API calls fail for any reason
- User is offline

No code changes needed - the app will show original task descriptions and static quotes instead.

## Running Tests

### Flutter Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/models_test.dart
```

### Cloud Functions Tests
```bash
cd functions
npm test
```

## Deployment

### Cloud Functions
```bash
cd functions
npm run build
firebase deploy --only functions
```

### Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### Mobile Apps

For TestFlight/Play Store deployment, see `fastlane/README.md` (when configured).

## Demo

See [demo/DEMO_SCRIPT.md](demo/DEMO_SCRIPT.md) for a 60-90 second walkthrough of the app.

### Demo User

After seeding, you can create a test account or use:
- Email: `demo@easymode.app`
- Password: `demo123!`

## Data Model

### Firestore Collections

| Collection | Description |
|------------|-------------|
| `users/{uid}` | User profile, XP, level, streak |
| `users/{uid}/userTasks` | Completed task records |
| `users/{uid}/userScripts` | Audacity script attempts |
| `users/{uid}/userRituals` | Ritual completions |
| `tasks` | Task templates (seeded) |
| `scripts` | Audacity scripts (seeded) |
| `rituals` | Joy rituals (seeded) |
| `badges` | Badge definitions (seeded) |
| `analytics` | Event logs |

## XP Economy

| Action | XP Reward |
|--------|-----------|
| Complete daily task | 100 XP |
| Attempt audacity script | 200 XP |
| Audacity success bonus | +100 XP |
| Complete joy ritual | 100 XP |
| Streak bonus (day 3+) | +10% per day (max 50%) |

**Leveling**: 500 XP per level

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built for hackathon submission
- Inspired by principles of habit formation and positive psychology
