/// GT Media - A comprehensive Flutter media utility package.
///
/// This package provides utilities for:
/// - Image picking from gallery and camera
/// - Image cropping with customizable UI
/// - Image compression with quality control
/// - Video picking and trimming
/// - Document/file picking
/// - Feature-rich video player with gesture controls
library;

// Media Picker Utility
export 'media_picker_handler/media_picker_utility.dart'
    show
        MediaPickerUtility,
        MediaPickerConfig,
        MediaPickerResult,
        MediaPickerError,
        MediaPickerErrorCode,
        MediaType;

// Video Player Utility
export 'media_picker_handler/video_player_utility.dart' show VideoPlayerUtility;
