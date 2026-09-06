# Sonic Pals

iOS LiDAR AR application for interactive ultrasonic wave visualization and
simulation.

## Layout

| Path | What is in it |
| --- | --- |
| `POC/` | The app: `App/`, `Game/`, `Services/`, `UI/`, `Debug/` |
| `POCTests/` | Unit tests for the app |
| `Packages/SonarCore` | The pure sonar simulation, and its own tests |
| `Packages/RealityKitContent` | Reality Composer Pro assets |

## Tests

```bash
xcodebuild test -project POC.xcodeproj -scheme POC \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

The `SonarCore` package has its own suite, which needs no simulator:

```bash
cd Packages/SonarCore && swift test
```

Both use [Swift Testing](https://developer.apple.com/documentation/testing).

A LiDAR device is still required to actually play: the simulator has no
scene reconstruction, so the AR session refuses to start there. The menu,
HUD and tutorial screens do run on a simulator.
