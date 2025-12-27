# Changelog

All notable changes to this project will be documented in this file.

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
