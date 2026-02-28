# Wake Protocol

A science-based alarm app that uses cognitive challenges to combat sleep inertia. Built for the **Apple Swift Student Challenge 2026**.

---

## The Problem

Traditional alarms only engage one sense. Your brain can dismiss them without fully waking up — leading to the snooze cycle. Research on **sleep inertia** shows that the prefrontal cortex (responsible for decision-making) takes the longest to activate after sleep. That’s why you can tap “dismiss” and fall straight back asleep: your conscious brain wasn’t involved.

## The Solution

Wake Protocol escalates alarm intensity through **three phases** and requires a **cognitive challenge** to dismiss — activating the part of your brain that actually needs to wake up. No network required; everything runs on-device.

---

## Features

- **Escalating 3-phase alarm** — Standby → Warning → Critical with visual, haptic, and audio feedback  
- **3 dismiss challenges** — Sequence tap (1→6), pattern trace, and color match  
- **6 synthesized alarm sounds** — Radar, Beacon, Pulse, Chime, Siren, Digital (AVAudioEngine)  
- **Local notifications** — Real alarm scheduling with `UserNotifications`; works when the app is in background or the screen is locked (with Time Sensitive Notifications capability)  
- **Snooze** — 5-minute snooze after completing the challenge  
- **Learn tab** — Sleep science education and sleep inertia research  
- **Sleep insights** — From Apple Health (device) or from alarm completion history (Simulator)  
- **Accessibility** — VoiceOver labels, Dynamic Type, multi-sensory feedback  
- **Zero dependencies** — SwiftUI, AVFoundation, UserNotifications, HealthKit (optional)

---

## Requirements

- **Xcode 26 or later** (or Swift Playgrounds 4.6+)  
- **iOS 18.0+**  
- Built and run in **Simulator** for submission; use a **device** for alarms when the screen is locked and for Apple Health.

---

## How to Run

1. **Open the project**  
   Open `WakeProtocol.swiftpm` in Xcode (or Swift Playgrounds).

2. **Build and run**  
   Choose a simulator or device and run (⌘R). The app runs fully offline.

3. **Optional: App icon**  
   The icon is in `Sources/Resources/Assets.xcassets/AppIcon.appiconset`. If the home screen still shows the default icon, in Xcode: select the **WakeProtocol** target → **General** → **App Icons and Launch Screen** and ensure the asset catalog is used (or add it under **Copy Bundle Resources** if needed).

4. **Optional: Alarm when screen is locked**  
   On a device, for alarms to fire when the phone is locked: **Signing & Capabilities** → **+ Capability** → **Time Sensitive Notifications**.

5. **Optional: Apple Health (device only)**  
   For sleep insights from Health: **Signing & Capabilities** → **+ Capability** → **HealthKit**. Then in the app, open **Learn** → expand **Your Sleep Insights** → tap **Connect Apple Health**.

---

## Submission / Judging

- **Run in Simulator** — The app is judged in Simulator. Alarms fire via local notifications; the full alarm flow (countdown → alarm → challenge → success) works.  
- **No network** — All data is local (UserDefaults, HealthKit on device). No server or internet required.  
- **Apple Health in Simulator** — Health is not available in Simulator. The Learn tab shows a short message and uses alarm-based insights instead.  
- **Content** — All copy and UI are in English.

---

## Project Structure

```
WakeProtocol.swiftpm/
├── Package.swift
├── Info.plist
├── README.md
└── Sources/
    ├── App/
    │   ├── WakeProtocolApp.swift    # @main, AppDelegate, notification handling
    │   └── ContentView.swift       # Onboarding gate, alarm trigger overlay
    ├── Models/
    │   ├── Alarm.swift            # Alarm model, AlarmStore, UserDefaults
    │   ├── SleepInsight.swift     # Shared insight model
    │   └── WakeHistory.swift      # Alarm completion history for insights
    ├── Resources/
    │   └── Assets.xcassets/       # AppIcon
    ├── Utilities/
    │   ├── Theme.swift            # Olive Garden design system
    │   ├── HapticsManager.swift  # Haptics + system sounds
    │   ├── AlarmSoundManager.swift # Synthesized alarm tones
    │   ├── NotificationManager.swift # Local notification scheduling
    │   ├── SleepHealthService.swift  # HealthKit sleep data
    │   └── ParticleView.swift    # Alarm screen particles
    └── Views/
        ├── Tabs/
        │   ├── MainTabView.swift   # Tab bar (Alarms, Learn, About)
        │   ├── AlarmListView.swift # Alarm list, add/edit
        │   ├── AlarmEditView.swift # Create/edit alarm
        │   ├── LearnView.swift     # Science cards + sleep insights
        │   └── AboutView.swift    # Story and credits
        └── AlarmFlow/
            ├── AlarmFlowView.swift      # Container, countdown → alarm → challenge
            ├── AlarmView.swift          # 3-phase alarm UI + override
            ├── ChallengeRouterView.swift# Picks sequence / trace / color
            ├── SequenceChallengeView.swift
            ├── PatternTraceChallengeView.swift
            ├── ColorMatchChallengeView.swift
            └── SuccessView.swift        # Done + snooze option
```

---

## Quick Test Flow

1. Open the app → complete onboarding if shown.  
2. Create or use the default alarm → set time a minute ahead.  
3. Wait for the notification (or bring the app to foreground at alarm time).  
4. Complete the countdown → experience the 3-phase alarm → tap **OVERRIDE REQUIRED** → complete the challenge (e.g. tap nodes 1→6).  
5. Tap **Snooze** or **Dismiss**.  
6. Open **Learn** to read the science and (on device with HealthKit) connect Apple Health for sleep insights.

---

## License

This project was created for the Apple Swift Student Challenge 2026.  
All rights reserved by the author.
