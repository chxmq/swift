# Wake Protocol

A science-based alarm app that uses cognitive challenges to combat sleep inertia. Built for the **Apple Swift Student Challenge 2025**.

## The Problem

Traditional alarms only engage one sense. Your brain can dismiss them without fully waking up — leading to the snooze cycle. Research on **sleep inertia** shows that the prefrontal cortex (responsible for decision-making) takes the longest to activate after sleep.

## The Solution

Wake Protocol escalates alarm intensity through 3 phases and requires a **cognitive challenge** to dismiss — activating the part of your brain that actually needs to wake up.

## Features

- **Escalating 3-Phase Alarm** — Standby → Warning → Critical with visual, haptic, and audio feedback
- **3 Dismiss Challenges** — Sequence tapping, pattern tracing, and color matching
- **6 Synthesized Alarm Sounds** — Radar, Beacon, Pulse, Chime, Siren, Digital (generated via `AVAudioEngine`)
- **Local Notifications** — Real alarm scheduling with `UserNotifications`
- **Snooze Support** — 5-minute snooze option after challenge completion
- **Sleep Science Education** — Learn tab explaining sleep inertia research
- **Full Accessibility** — VoiceOver labels, Dynamic Type support
- **Zero Dependencies** — 100% Apple frameworks (SwiftUI, UIKit, AVFoundation, AudioToolbox, UserNotifications)

## Requirements

- Xcode 16+ / Swift Playgrounds 4.5+
- iOS 18.0+

## How to Run

1. Open `WakeProtocol.swiftpm` in Xcode or Swift Playgrounds
2. Build and run on a simulator or device
3. Create an alarm and tap the play button to test the experience

## Architecture

```
Sources/
├── App/              → Entry point, onboarding, app delegate
├── Models/           → Alarm data model with UserDefaults persistence
├── Views/
│   ├── Tabs/         → Alarm list, Learn, About
│   └── AlarmFlow/    → Countdown → Alarm → Challenge → Success
└── Utilities/        → Theme, haptics, sound synthesis, notifications
```
