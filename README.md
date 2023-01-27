# TeamTrack: FTC Scouting

## [![Repography logo](https://images.repography.com/logo.svg)](https://repography.com) / Top contributors
[![Top contributors](https://images.repography.com/33555677/6165-MSET-CuttleFish/TeamTrack/top-contributors/CPago8aS3x0clInX1PMO9pWv0cT5LxiEuX0kxG9o66E/_awQxTL45OBUZ8tp_YtCShw9bNuYgK1_yJXL0NmSMTU_table.svg)](https://github.com/6165-MSET-CuttleFish/TeamTrack/graphs/contributors)

## Description

A mobile scouting app made for the FIRST Tech Challenge with the goal of making collaborative match scouting as simple as possible for every season.

## Setup

Download and add the firebase config files to your respective platform: iOS, Android, or Web.

- iOS: `ios/Runner/GoogleService-Info.plist`
- Android: `android/app/google-services.json`
- Web: `web/api/firebaseConfig.js`

## Common Issues

- iOS build fails
Solution: delete Podfile.lock and other folders in .gitignore and run `pod install`
- M1 Macs iOS Pod Install Fails
Prefice terminal commands with `arch -x86_64` i.e `arch -x86_64 pod install`

## Features

- Create and share cloud events
- Live editing
- Sort teams by strengths in different areas
- Visualize match analytics
