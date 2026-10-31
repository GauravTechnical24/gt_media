# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-10-31

### Added
- Comprehensive unit and widget test suite covering `MediaPickerConfig`, `MediaPickerResult`, `MediaPickerError`, and `VideoPlayerUtility`.
- Example application widget smoke test suite in `example/test/widget_test.dart`.
- Android platform integration in `example/android` using modern Gradle Kotlin DSL, AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1, Java 17 target compatibility, and `UCropActivity` configuration.
- iOS platform integration in `example/ios` targeting iOS 15.0+, modern UIScene lifecycle, and usage descriptions for Photo Library, Camera, and Microphone.

### Changed
- Modernized SDK constraints to `sdk: '>=3.3.0 <4.0.0'` and `flutter: '>=3.19.0'`.
- Upgraded direct dependencies:
  - `image_cropper: '>=11.0.0 <14.0.0'` (upgraded to support modern crop interfaces and Android 14+ / iOS 17+).
  - `file_picker: '>=10.3.8 <14.0.0'` (expanded constraint compatibility).
  - `flutter_lints: ^6.0.0` (latest lint rules).
- Replaced deprecated `Colors.red.withOpacity(...)` with modern `withValues(alpha: ...)`.
- Fixed async gaps with `mounted` checks across `Navigator` and `ScaffoldMessenger` in example code.
- Added comprehensive docstrings and resolved doc comment bracket references for full dartdoc compliance.
- Achieved verified 160/160 points on pub.dev pana package analysis.

## [1.0.0] - 2025-12-27

### Added
- `MediaPickerUtility` - Comprehensive media picking utility
  - Image picking from gallery and camera
  - Multi-image selection support
  - Image cropping with customizable aspect ratios and styles
  - Smart image compression with quality control
  - Video picking with optional trimming
  - Document/file picking with extension filtering
  - Progress callbacks and error handling
- `MediaPickerConfig` - Flexible configuration options
  - Cropping, compression, and trimming toggles
  - Size limits for images, videos, and documents
  - Custom crop styles (rectangle/circle)
  - Aspect ratio presets
- `MediaPickerResult` - Rich result object with file metadata
- `VideoPlayerUtility` - Feature-rich video player widget
  - Support for local and network videos
  - Gesture-based controls (tap to play/pause, swipe to seek)
  - Fullscreen mode toggle
  - Custom progress bar with seek functionality
  - Memory-optimized with proper lifecycle management
