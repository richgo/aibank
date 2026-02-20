# AIBank App

Flutter mobile/desktop app that renders AI-generated banking UI using the GenUI/A2UI protocol.

## Prerequisites

- Flutter SDK 3.3+ (`flutter doctor` to verify)
- Agent backend running on port 8080 — see [agent/README.md](../agent/README.md)

## Starting the app

```bash
# Install dependencies
flutter pub get

# Run (pick a connected device or emulator when prompted)
flutter run

# Or target a specific device
flutter run -d linux       # Linux desktop
flutter run -d chrome      # Web
flutter run -d <emulator>  # Android/iOS emulator
```

> **Important:** start the agent backend first or the app will not be able to fetch banking data.

## Agent URL

The app automatically selects the backend URL based on the target platform:

| Platform | Default URL |
|---|---|
| Android emulator | `http://10.0.2.2:8080` |
| iOS / desktop / web | `http://127.0.0.1:8080` |

Pass a custom URL via `ChatScreen(serverUrl: '...')` if needed.

## Running tests

```bash
flutter test
```
