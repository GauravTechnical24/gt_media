# GT Media

[![pub package](https://img.shields.io/pub/v/gt_media.svg)](https://pub.dev/packages/gt_media)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive Flutter media utility package providing image picking, cropping, compression, video trimming, document picking, and a feature-rich video player with gesture controls.

## Features

- 📸 **Image Picking** - Gallery and camera support with multi-select
- ✂️ **Image Cropping** - Customizable aspect ratios, circular/rectangle crop styles
- 🗜️ **Image Compression** - Smart compression with quality control and size limits
- 🎬 **Video Picking** - Gallery and camera with optional trimming
- 📄 **Document Picking** - PDF, DOC, and custom file types
- ▶️ **Video Player** - Full-featured player with gesture controls, seek, and fullscreen

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  gt_media: ^1.0.0
```

Then run:
```bash
flutter pub get
```

## Platform Setup

### Android

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.CAMERA" />

<!-- Inside <application> tag -->
<activity
    android:name="com.yalantis.ucrop.UCropActivity"
    android:screenOrientation="portrait"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
```

Set `minSdk` to 21 in `android/app/build.gradle`.

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select images and videos.</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take photos and videos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone to record videos with audio.</string>
```

Set platform to iOS 12.0+ in `ios/Podfile`.

## Quick Start

### Image Picking

```dart
import 'package:gt_media/gt_media.dart';

final mediaPicker = MediaPickerUtility();

// Simple image pick
final result = await mediaPicker.pickImageFromGallery();
if (result != null) {
  print('File: ${result.file.path}, Size: ${result.fileSizeKB} KB');
}

// With custom configuration
final result = await mediaPicker.pickImageFromGallery(
  config: MediaPickerConfig(
    enableCropping: true,
    enableCompression: true,
    maxImageSizeKB: 500,
    imageQuality: 80,
    cropStyle: CropStyle.circle, // For profile pictures
  ),
);
```

### Video Picking

```dart
final result = await mediaPicker.pickVideoFromGallery(
  context: context,
  config: MediaPickerConfig(
    enableTrimming: true,
    maxVideoSizeMB: 25,
    maxVideoDurationSeconds: 60,
  ),
);
```

### Video Player

```dart
import 'package:gt_media/gt_media.dart';

// Local video
VideoPlayerUtility(videoPath: '/path/to/video.mp4')

// Network video
VideoPlayerUtility(
  videoPath: 'https://example.com/video.mp4',
  isNetwork: true,
)
```

### Document Picking

```dart
final results = await mediaPicker.pickDocuments(
  config: MediaPickerConfig(
    allowedExtensions: ['pdf', 'doc', 'docx'],
    maxDocumentSizeMB: 5,
    allowMultiple: true,
  ),
);
```

## Configuration Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enableCropping` | `bool` | `true` | Enable image cropping |
| `enableTrimming` | `bool` | `true` | Enable video trimming |
| `enableCompression` | `bool` | `true` | Enable image compression |
| `maxImageSizeKB` | `int` | `1024` | Maximum image size in KB |
| `maxVideoSizeMB` | `int` | `500` | Maximum video size in MB |
| `imageQuality` | `int` | `85` | Image quality (0-100) |
| `maxVideoDurationSeconds` | `int` | `0` | Max video duration (0 = no limit) |
| `cropStyle` | `CropStyle` | `rectangle` | Crop shape |
| `allowMultiple` | `bool` | `false` | Allow multiple file selection |

## Additional Information

For detailed setup instructions and advanced usage, see the [example](./example) folder.

## License

MIT License - see [LICENSE](LICENSE) for details.
