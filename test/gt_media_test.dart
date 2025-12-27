import 'package:flutter_test/flutter_test.dart';
import 'package:gt_media/gt_media.dart';
import 'package:image_cropper/image_cropper.dart';

void main() {
  group('MediaPickerConfig', () {
    test('default values are correct', () {
      const config = MediaPickerConfig();

      expect(config.enableCropping, true);
      expect(config.enableTrimming, true);
      expect(config.enableCompression, true);
      expect(config.maxImageSizeKB, 1024);
      expect(config.maxVideoSizeMB, 500);
      expect(config.imageQuality, 85);
      expect(config.maxVideoDurationSeconds, 0);
      expect(config.cropStyle, CropStyle.rectangle);
      expect(config.allowMultiple, false);
    });

    test('custom values are applied', () {
      const config = MediaPickerConfig(
        enableCropping: false,
        enableCompression: false,
        maxImageSizeKB: 500,
        imageQuality: 70,
        cropStyle: CropStyle.circle,
      );

      expect(config.enableCropping, false);
      expect(config.enableCompression, false);
      expect(config.maxImageSizeKB, 500);
      expect(config.imageQuality, 70);
      expect(config.cropStyle, CropStyle.circle);
    });
  });

  group('MediaPickerError', () {
    test('toString returns formatted message', () {
      final error = MediaPickerError(
        code: MediaPickerErrorCode.fileTooLarge,
        message: 'File exceeds maximum size',
      );

      expect(error.toString(), contains('fileTooLarge'));
      expect(error.toString(), contains('File exceeds maximum size'));
    });
  });

  group('MediaType', () {
    test('enum values exist', () {
      expect(MediaType.values.length, 3);
      expect(MediaType.values.contains(MediaType.image), true);
      expect(MediaType.values.contains(MediaType.video), true);
      expect(MediaType.values.contains(MediaType.document), true);
    });
  });
}
