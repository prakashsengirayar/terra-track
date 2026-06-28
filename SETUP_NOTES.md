# TerraTrack — iOS / Android / Web setup notes

This project is now scoped to three targets only: iOS, Android, and Web. No macOS, Windows, or Linux desktop folders exist or were added.

## What was fixed in this pass

The biggest blocker for Web was that photo capture (customer photo, bill photo) was built entirely around `dart:io`'s `File` class — `File`, `FileImage`, and `Storage.putFile()` are all unavailable on Flutter Web and would have failed to compile. This has been refactored end to end (domain repositories, use cases, the Firestore/Storage data source, the work-entry provider, and `new_entry_page.dart`) to pass image bytes (`Uint8List`) instead of `File`, using `ImagePicker`'s `readAsBytes()` and `Storage.putData()`. This works identically on iOS, Android, and Web, and the behavior on mobile is unchanged.

`flutter_local_notifications` has no Web implementation, so `NotificationService` would have thrown on startup in a browser. Every method now no-ops on Web (`kIsWeb`) — local "timer running" / "entry saved" notifications stay mobile-only; nothing else in the app depends on them.

The Android Gradle wiring was also broken independent of Web: `app/build.gradle` declares the modern plugin-based Flutter Gradle plugin (`id "dev.flutter.flutter-gradle-plugin"`), but `settings.gradle` was using the old pre-2023 `apply from: ".../app_plugin_loader.gradle"` style, which doesn't register that plugin id — Gradle sync would fail with "plugin not found." `settings.gradle` and the root `build.gradle` have been rewritten to the current `pluginManagement`/`plugins` DSL that matches the AGP 8.1.0 / Kotlin 1.9.10 / Gradle 8.3 versions already pinned in this project.

A `web/` platform folder (`index.html`, `manifest.json`, `favicon.png`, `icons/`) was added by hand, since this sandbox has no network access to run `flutter create`. It's a standard Flutter web scaffold branded with TerraTrack's green (#2D6A4F). Placeholder Android launcher icons (a plain "T" mark) were also generated for all five `mipmap-*` densities, since `AndroidManifest.xml` already referenced `@mipmap/ic_launcher` but no icon files existed anywhere in the project — that would have failed the Android resource link step. Swap these for real artwork whenever you have it.

## What you still need to do before each target actually runs

This sandbox has no Flutter SDK, no Android SDK, no Xcode, and restricted network access, so none of this could be installed or run here — everything above was a hand-edit/code-review pass, not a verified build. Before you build for real:

- Run `flutterfire configure` (or fill in `lib/firebase_options.dart` by hand) — the API keys for web/android/ios in that file are still placeholders. Doing so will also generate `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`, both currently missing.
- For Android: create `android/local.properties` with your local `flutter.sdk` path, then run `flutter create . --platforms=android` once (safe on an existing project — it only fills in missing scaffolding like the Gradle wrapper jar/scripts, it won't touch your `lib/` code).
- For iOS: there's no Xcode project in this zip at all (no `.xcodeproj`, no `AppDelegate.swift`, no `Assets.xcassets`). Run `flutter create . --platforms=ios` on a Mac with the Flutter SDK installed to generate it, then `cd ios && pod install`.
- For Web: `flutter create . --platforms=web` will recognize the `web/` folder already exists and leave it alone; `flutter run -d chrome` or `flutter build web` should work directly once `flutterfire configure` has real keys.

Running `flutter create . --platforms=ios,android,web` once, locally, covers all three gaps above in one shot — it's additive and won't overwrite your existing `lib/`, `android/app/src`, or this `web/` folder.
