# WorkShiftAlarm

## Overview
iOS 26+ SwiftUI app that imports shift schedule screenshots, maps shifts, and creates system-level alarms via AlarmKit.

## Build (GitHub Actions + XcodeGen)
1. Ensure the repo root contains `WorkShiftAlarm/project.yml`.
2. The workflow uses `xcodegen generate` to create the Xcode project.
3. For IPA export, configure signing (certificate + provisioning profile) and update `ExportOptions.plist` as needed.

## Local Build (macOS)
```sh
brew install xcodegen
cd WorkShiftAlarm
xcodegen generate
xcodebuild -project WorkShiftAlarm.xcodeproj -scheme WorkShiftAlarm -configuration Debug -sdk iphonesimulator build
```

## AlarmKit Notes
This app uses AlarmKit (iOS 26+). You must keep `NSAlarmKitUsageDescription` in Info.plist.
