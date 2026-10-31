import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

/// Error codes for media picker operations
enum MediaPickerErrorCode {
  permissionDenied,
  fileTooLarge,
  unsupportedFormat,
  processingFailed,
  userCancelled,
  durationExceeded,
  invalidFile,
  unknown,
}

/// Error class for media picker operations
class MediaPickerError {
  final MediaPickerErrorCode code;
  final String message;
  final dynamic originalError;

  /// Creates a [MediaPickerError] instance.
  MediaPickerError({
    required this.code,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'MediaPickerError($code): $message';
}

/// Configuration class for media picking options
class MediaPickerConfig {
  /// Whether to enable image cropping after selection
  final bool enableCropping;

  /// Whether to enable video trimming after selection
  final bool enableTrimming;

  /// Whether to compress the selected media
  final bool enableCompression;

  /// Maximum image size in KB (default: 1024 KB = 1 MB)
  final int maxImageSizeKB;

  /// Maximum video size in MB (default: 500 MB)
  final int maxVideoSizeMB;

  /// Image quality for compression (0-100)
  final int imageQuality;

  /// Maximum video duration in seconds (0 = no limit)
  final int maxVideoDurationSeconds;

  /// Image cropper aspect ratio presets
  final List<CropAspectRatioPreset> cropAspectRatioPresets;

  /// Crop style (circle or rectangle)
  final CropStyle cropStyle;

  /// UI customization for image cropper
  final Color? cropperToolbarColor;
  final Color? cropperActiveControlsColor;

  /// Lock to a specific aspect ratio (if set, user cannot change it)
  final CropAspectRatioPreset? lockAspectRatio;

  /// Custom title for the cropper toolbar
  final String? cropperTitle;

  /// Allowed file extensions for document picking (e.g. `['pdf', 'doc']`)
  final List<String>? allowedExtensions;

  /// Whether to allow multiple file selection for documents
  final bool allowMultiple;

  /// Maximum document size in MB (default: 10 MB)
  final int maxDocumentSizeMB;

  /// Allowed image formats (e.g. `['jpg', 'jpeg', 'png']`)
  final List<String> allowedImageFormats;

  /// Allowed video formats (e.g. `['mp4', 'mov']`)
  final List<String> allowedVideoFormats;

  /// Validate files before processing
  final bool validateBeforeProcessing;

  /// Progress callback (0.0 to 1.0)
  final void Function(double progress)? onProgress;

  /// Error callback
  final void Function(MediaPickerError error)? onError;

  /// Log callback for debugging/analytics
  final void Function(String message)? onLog;

  /// Creates a [MediaPickerConfig] instance with customizable picking, cropping,
  /// compression, and validation settings.
  const MediaPickerConfig({
    this.enableCropping = true,
    this.enableTrimming = true,
    this.enableCompression = true,
    this.maxImageSizeKB = 1024,
    this.maxVideoSizeMB = 500,
    this.imageQuality = 85,
    this.maxVideoDurationSeconds = 0,
    this.cropAspectRatioPresets = const [
      CropAspectRatioPreset.square,
      CropAspectRatioPreset.ratio3x2,
      CropAspectRatioPreset.ratio4x3,
      CropAspectRatioPreset.ratio16x9,
      CropAspectRatioPreset.original,
    ],
    this.cropStyle = CropStyle.rectangle,
    this.lockAspectRatio,
    this.cropperTitle,
    this.cropperToolbarColor,
    this.cropperActiveControlsColor,
    this.allowedExtensions,
    this.allowMultiple = false,
    this.maxDocumentSizeMB = 10,
    this.allowedImageFormats = const ['jpg', 'jpeg', 'png', 'heic', 'webp'],
    this.allowedVideoFormats = const ['mp4', 'mov', 'avi', 'mkv'],
    this.validateBeforeProcessing = true,
    this.onProgress,
    this.onError,
    this.onLog,
  });
}

/// Result class containing the selected and processed media file
class MediaPickerResult {
  final File file;
  final MediaType mediaType;
  final int fileSizeBytes;
  final String fileName;

  /// Creates a [MediaPickerResult] instance.
  MediaPickerResult({
    required this.file,
    required this.mediaType,
    required this.fileSizeBytes,
    required this.fileName,
  });

  double get fileSizeKB => fileSizeBytes / 1024;
  double get fileSizeMB => fileSizeBytes / (1024 * 1024);
}

enum MediaType { image, video, document }

/// Global utility class for media picking, cropping, trimming, and compression
class MediaPickerUtility {
  static final MediaPickerUtility _instance = MediaPickerUtility._internal();
  factory MediaPickerUtility() => _instance;
  MediaPickerUtility._internal();

  final ImagePicker _picker = ImagePicker();

  // Validation Methods

  /// Validate image file
  MediaPickerError? _validateImageFile(File file, MediaPickerConfig config) {
    try {
      config.onLog?.call('Validating image file: ${file.path}');

      // Check if file exists
      if (!file.existsSync()) {
        return MediaPickerError(
          code: MediaPickerErrorCode.invalidFile,
          message: 'File does not exist',
        );
      }

      // Check file extension
      final extension =
          path.extension(file.path).toLowerCase().replaceAll('.', '');
      if (!config.allowedImageFormats.contains(extension)) {
        return MediaPickerError(
          code: MediaPickerErrorCode.unsupportedFormat,
          message:
              'Unsupported image format: $extension. Allowed: ${config.allowedImageFormats.join(", ")}',
        );
      }

      // Check file size
      final sizeKB = file.lengthSync() / 1024;
      if (sizeKB > config.maxImageSizeKB && !config.enableCompression) {
        return MediaPickerError(
          code: MediaPickerErrorCode.fileTooLarge,
          message:
              'Image size (${sizeKB.toStringAsFixed(2)} KB) exceeds maximum (${config.maxImageSizeKB} KB)',
        );
      }

      return null;
    } catch (e) {
      return MediaPickerError(
        code: MediaPickerErrorCode.unknown,
        message: 'Error validating image: $e',
        originalError: e,
      );
    }
  }

  /// Validate video file
  Future<MediaPickerError?> _validateVideoFile(
    File file,
    MediaPickerConfig config,
  ) async {
    try {
      config.onLog?.call('Validating video file: ${file.path}');

      // Check if file exists
      if (!file.existsSync()) {
        return MediaPickerError(
          code: MediaPickerErrorCode.invalidFile,
          message: 'File does not exist',
        );
      }

      // Check file extension
      final extension =
          path.extension(file.path).toLowerCase().replaceAll('.', '');
      if (!config.allowedVideoFormats.contains(extension)) {
        return MediaPickerError(
          code: MediaPickerErrorCode.unsupportedFormat,
          message:
              'Unsupported video format: $extension. Allowed: ${config.allowedVideoFormats.join(", ")}',
        );
      }

      // Check file size
      final sizeMB = file.lengthSync() / (1024 * 1024);
      if (sizeMB > config.maxVideoSizeMB) {
        return MediaPickerError(
          code: MediaPickerErrorCode.fileTooLarge,
          message:
              'Video size (${sizeMB.toStringAsFixed(2)} MB) exceeds maximum (${config.maxVideoSizeMB} MB)',
        );
      }

      return null;
    } catch (e) {
      return MediaPickerError(
        code: MediaPickerErrorCode.unknown,
        message: 'Error validating video: $e',
        originalError: e,
      );
    }
  }

  /// Validate document file
  MediaPickerError? _validateDocumentFile(File file, MediaPickerConfig config) {
    try {
      config.onLog?.call('Validating document file: ${file.path}');

      // Check if file exists
      if (!file.existsSync()) {
        return MediaPickerError(
          code: MediaPickerErrorCode.invalidFile,
          message: 'File does not exist',
        );
      }

      // Check file extension if allowed extensions are specified
      if (config.allowedExtensions != null &&
          config.allowedExtensions!.isNotEmpty) {
        final extension =
            path.extension(file.path).toLowerCase().replaceAll('.', '');
        if (!config.allowedExtensions!.contains(extension)) {
          return MediaPickerError(
            code: MediaPickerErrorCode.unsupportedFormat,
            message:
                'Unsupported document format: $extension. Allowed: ${config.allowedExtensions!.join(", ")}',
          );
        }
      }

      // Check file size
      final sizeMB = file.lengthSync() / (1024 * 1024);
      if (sizeMB > config.maxDocumentSizeMB) {
        return MediaPickerError(
          code: MediaPickerErrorCode.fileTooLarge,
          message:
              'Document size (${sizeMB.toStringAsFixed(2)} MB) exceeds maximum (${config.maxDocumentSizeMB} MB)',
        );
      }

      return null;
    } catch (e) {
      return MediaPickerError(
        code: MediaPickerErrorCode.unknown,
        message: 'Error validating document: $e',
        originalError: e,
      );
    }
  }

  /// Handle error and invoke callback
  void _handleError(MediaPickerError error, MediaPickerConfig config) {
    debugPrint(error.toString());
    config.onError?.call(error);
    config.onLog?.call('Error: ${error.message}');
  }

  /// Report progress
  void _reportProgress(double progress, MediaPickerConfig config) {
    config.onProgress?.call(progress);
    config.onLog?.call('Progress: ${(progress * 100).toStringAsFixed(1)}%');
  }

  /// Clear temporary files older than specified duration
  Future<void> clearTemporaryFiles({Duration? olderThan}) async {
    try {
      final dir = await getTemporaryDirectory();
      if (!await dir.exists()) return;

      final cutoffTime =
          olderThan != null ? DateTime.now().subtract(olderThan) : null;

      final entities = dir.listSync(recursive: true);
      int deletedCount = 0;

      for (var entity in entities) {
        if (entity is File) {
          // Check if file is old enough to delete
          if (cutoffTime != null) {
            final stat = entity.statSync();
            if (stat.modified.isAfter(cutoffTime)) {
              continue; // Skip recent files
            }
          }

          // Delete files created by this utility (based on naming pattern)
          final fileName = path.basename(entity.path);
          if (fileName.startsWith('compressed_') ||
              fileName.startsWith('trimmed_') ||
              fileName.contains('image_cropper') ||
              fileName.contains('image_picker')) {
            try {
              entity.deleteSync();
              deletedCount++;
            } catch (e) {
              debugPrint('Failed to delete ${entity.path}: $e');
            }
          }
        }
      }

      debugPrint('Cleared $deletedCount temporary files');
    } catch (e) {
      debugPrint('Error clearing temporary files: $e');
    }
  }

  /// Clean up a specific file
  Future<void> _cleanupFile(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) {
        await file.delete();
        debugPrint('Cleaned up file: ${file.path}');
      }
    } catch (e) {
      debugPrint('Error cleaning up file: $e');
    }
  }

  /// Pick image from gallery
  Future<MediaPickerResult?> pickImageFromGallery({
    MediaPickerConfig config = const MediaPickerConfig(),
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // Pick at full quality, compress later if needed
      );

      if (pickedFile == null) return null;

      return await _processPickedImage(File(pickedFile.path), config);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<MediaPickerResult>> pickMultipleImagesFromGallery({
    MediaPickerConfig config = const MediaPickerConfig(),
  }) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 100,
      );

      if (pickedFiles.isEmpty) return [];

      // Process images in parallel
      final futures = pickedFiles.map((pickedFile) {
        return _processPickedImage(File(pickedFile.path), config);
      });

      final results = await Future.wait(futures);

      // Filter out nulls (failed/cancelled)
      return results.whereType<MediaPickerResult>().toList();
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  /// Process a picked image (crop, compress, create result)
  Future<MediaPickerResult?> _processPickedImage(
    File imageFile,
    MediaPickerConfig config,
  ) async {
    File? tempFile;
    try {
      config.onLog?.call('Processing image: ${imageFile.path}');
      _reportProgress(0.1, config);

      // Validate if enabled
      if (config.validateBeforeProcessing) {
        final error = _validateImageFile(imageFile, config);
        if (error != null) {
          _handleError(error, config);
          return null;
        }
      }

      _reportProgress(0.2, config);

      // Crop if enabled
      if (config.enableCropping) {
        config.onLog?.call('Cropping image...');
        final croppedFile = await _cropImage(imageFile, config);
        if (croppedFile == null) {
          // User cancelled cropping
          config.onLog?.call('Cropping cancelled by user');
          return null;
        }
        tempFile = imageFile; // Keep track for cleanup
        imageFile = croppedFile;
        _reportProgress(0.5, config);
      }

      // Compress if enabled
      if (config.enableCompression) {
        config.onLog?.call('Compressing image...');
        final compressedFile = await _compressImage(
          imageFile,
          config.imageQuality,
          config.maxImageSizeKB,
          config,
        );
        if (compressedFile != null) {
          if (tempFile != imageFile) {
            await _cleanupFile(tempFile); // Clean up previous temp file
          }
          tempFile = imageFile;
          imageFile = compressedFile;
        }
        _reportProgress(0.9, config);
      }

      // Create result
      final fileSize = await imageFile.length();
      final fileName = path.basename(imageFile.path);

      _reportProgress(1.0, config);
      config.onLog?.call(
        'Image processing complete: $fileName (${(fileSize / 1024).toStringAsFixed(2)} KB)',
      );

      return MediaPickerResult(
        file: imageFile,
        mediaType: MediaType.image,
        fileSizeBytes: fileSize,
        fileName: fileName,
      );
    } catch (e) {
      final error = MediaPickerError(
        code: MediaPickerErrorCode.processingFailed,
        message: 'Failed to process image: $e',
        originalError: e,
      );
      _handleError(error, config);
      await _cleanupFile(tempFile);
      return null;
    }
  }

  /// Pick image from camera
  Future<MediaPickerResult?> pickImageFromCamera({
    MediaPickerConfig config = const MediaPickerConfig(),
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (pickedFile == null) return null;

      return await _processPickedImage(File(pickedFile.path), config);
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Pick video from gallery
  Future<MediaPickerResult?> pickVideoFromGallery({
    required BuildContext context,
    MediaPickerConfig config = const MediaPickerConfig(),
  }) async {
    try {
      config.onLog?.call('Picking video from gallery...');
      _reportProgress(0.1, config);

      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) {
        config.onLog?.call('Video selection cancelled');
        return null;
      }

      File videoFile = File(pickedFile.path);
      _reportProgress(0.3, config);

      // Validate if enabled
      if (config.validateBeforeProcessing) {
        final error = await _validateVideoFile(videoFile, config);
        if (error != null) {
          _handleError(error, config);
          await _cleanupFile(videoFile);
          return null;
        }
      }

      _reportProgress(0.5, config);

      // Trim if enabled
      if (config.enableTrimming && context.mounted) {
        config.onLog?.call('Trimming video...');
        final trimmedFile = await _trimVideo(context, videoFile);
        if (trimmedFile == null) {
          config.onLog?.call('Video trimming cancelled');
          return null;
        }
        await _cleanupFile(videoFile);
        videoFile = trimmedFile;
        _reportProgress(0.9, config);
      }

      final finalFileSize = await videoFile.length();
      final fileName = path.basename(videoFile.path);

      _reportProgress(1.0, config);
      config.onLog?.call(
        'Video processing complete: $fileName (${(finalFileSize / (1024 * 1024)).toStringAsFixed(2)} MB)',
      );

      return MediaPickerResult(
        file: videoFile,
        mediaType: MediaType.video,
        fileSizeBytes: finalFileSize,
        fileName: fileName,
      );
    } catch (e) {
      final error = MediaPickerError(
        code: MediaPickerErrorCode.processingFailed,
        message: 'Failed to pick video: $e',
        originalError: e,
      );
      _handleError(error, config);
      return null;
    }
  }

  /// Pick video from camera
  Future<MediaPickerResult?> pickVideoFromCamera({
    MediaPickerConfig config = const MediaPickerConfig(),
    required BuildContext context,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: config.maxVideoDurationSeconds > 0
            ? Duration(seconds: config.maxVideoDurationSeconds)
            : null,
      );

      if (pickedFile == null) return null;

      File videoFile = File(pickedFile.path);

      // Check video size
      final fileSize = await videoFile.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      if (fileSizeMB > config.maxVideoSizeMB) {
        debugPrint(
          'Video size (${fileSizeMB.toStringAsFixed(2)} MB) exceeds maximum allowed size (${config.maxVideoSizeMB} MB)',
        );
        return null;
      }

      // Trim if enabled
      if (config.enableTrimming && context.mounted) {
        final trimmedFile = await _trimVideo(context, videoFile);
        if (trimmedFile == null) return null;
        videoFile = trimmedFile;
      }

      final finalFileSize = await videoFile.length();
      final fileName = path.basename(videoFile.path);

      return MediaPickerResult(
        file: videoFile,
        mediaType: MediaType.video,
        fileSizeBytes: finalFileSize,
        fileName: fileName,
      );
    } catch (e) {
      debugPrint('Error picking video from camera: $e');
      return null;
    }
  }

  /// Pick documents (files)
  Future<List<MediaPickerResult>> pickDocuments({
    MediaPickerConfig config = const MediaPickerConfig(),
  }) async {
    try {
      config.onLog?.call('Picking documents...');
      _reportProgress(0.1, config);

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: config.allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: config.allowedExtensions,
        allowMultiple: config.allowMultiple,
      );

      if (result == null || result.files.isEmpty) {
        config.onLog?.call('Document selection cancelled');
        return [];
      }

      List<MediaPickerResult> pickedDocuments = [];
      int totalFiles = result.files.length;

      for (int i = 0; i < result.files.length; i++) {
        var file = result.files[i];
        if (file.path == null) continue;

        final documentFile = File(file.path!);

        // Validate if enabled
        if (config.validateBeforeProcessing) {
          final error = _validateDocumentFile(documentFile, config);
          if (error != null) {
            _handleError(error, config);
            continue; // Skip this file
          }
        }

        final fileSize = await documentFile.length();

        pickedDocuments.add(
          MediaPickerResult(
            file: documentFile,
            mediaType: MediaType.document,
            fileSizeBytes: fileSize,
            fileName: file.name,
          ),
        );

        _reportProgress(0.1 + (0.9 * (i + 1) / totalFiles), config);
      }

      config.onLog?.call('Picked ${pickedDocuments.length} document(s)');
      return pickedDocuments;
    } catch (e) {
      final error = MediaPickerError(
        code: MediaPickerErrorCode.processingFailed,
        message: 'Failed to pick documents: $e',
        originalError: e,
      );
      _handleError(error, config);
      return [];
    }
  }

  /// Crop image using image_cropper
  Future<File?> _cropImage(File imageFile, MediaPickerConfig config) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: config.cropperTitle ?? 'Crop Image',
            toolbarColor: config.cropperToolbarColor ?? Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor:
                config.cropperActiveControlsColor ?? Colors.deepOrange,
            initAspectRatio:
                config.lockAspectRatio ?? CropAspectRatioPreset.original,
            lockAspectRatio: config.lockAspectRatio != null,
          ),
          IOSUiSettings(
            title: config.cropperTitle ?? 'Crop Image',
            aspectRatioLockEnabled: config.lockAspectRatio != null,
            resetAspectRatioEnabled: config.lockAspectRatio == null,
            aspectRatioPickerButtonHidden: config.lockAspectRatio != null,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  /// Compress image to reduce file size (Optimized with Binary Search)
  Future<File?> _compressImage(
    File imageFile,
    int quality,
    int maxSizeKB,
    MediaPickerConfig config,
  ) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Binary search for optimal quality (running on main thread as platform channels don't support isolates)
      File? resultFile;
      int low = 10;
      int high = quality;
      final int targetSizeBytes = maxSizeKB * 1024;

      while (low <= high) {
        int mid = (low + high) ~/ 2;
        final currentTargetPath = targetPath.replaceAll('.jpg', '_q$mid.jpg');

        final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
          imageFile.path,
          currentTargetPath,
          quality: mid,
          format: CompressFormat.jpeg,
        );

        if (compressed == null) break;

        final file = File(compressed.path);
        final size = await file.length();

        if (size <= targetSizeBytes) {
          resultFile = file;
          low = mid + 1; // Try to get better quality
        } else {
          high = mid - 1; // File too big, reduce quality
        }
      }

      // Fallback if binary search failed
      if (resultFile == null) {
        final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
          imageFile.path,
          targetPath.replaceAll('.jpg', '_min.jpg'),
          quality: 10,
          format: CompressFormat.jpeg,
        );
        if (compressed != null) {
          resultFile = File(compressed.path);
        }
      }

      return resultFile ?? imageFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageFile;
    }
  }

  /// Trim video using video_trimmer
  Future<File?> _trimVideo(BuildContext context, File videoFile) async {
    try {
      final Trimmer trimmer = Trimmer();
      await trimmer.loadVideo(videoFile: videoFile);

      if (!context.mounted) return null;

      final result = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              VideoTrimmerScreen(trimmer: trimmer, videoFile: videoFile),
        ),
      );

      return result;
    } catch (e) {
      debugPrint('Error trimming video: $e');
      return null;
    }
  }
}

/// Video trimmer screen widget
class VideoTrimmerScreen extends StatefulWidget {
  final Trimmer trimmer;
  final File videoFile;

  const VideoTrimmerScreen({
    super.key,
    required this.trimmer,
    required this.videoFile,
  });

  @override
  State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
}

class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;
  bool _isProcessing = false;
  bool _isCanceled = false; // Cancellation flag to prevent memory leaks

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    await widget.trimmer.loadVideo(videoFile: widget.videoFile);
    setState(() {});
  }

  Future<void> _saveVideo() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // final dir = await getTemporaryDirectory();
      // final fileName = 'trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4';
      // final outputPath = path.join(dir.path, fileName);

      await widget.trimmer.saveTrimmedVideo(
        startValue: _startValue,
        endValue: _endValue,
        // Note: 'ffmpegCommand' is not supported in video_trimmer 5.0.0.
        // The package uses native trimming which may re-encode with default settings.
        // To optimize size/speed further, a different package or custom FFmpeg implementation would be needed.
        onSave: (String? outputPath) async {
          // Check cancellation before processing result
          if (_isCanceled || !mounted) return;

          if (outputPath != null) {
            final trimmedFile = File(outputPath);
            if (mounted && !_isCanceled) {
              Navigator.of(context).pop(trimmedFile);
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Error saving trimmed video: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _isCanceled =
        true; // Signal cancellation to prevent callbacks after disposal
    widget.trimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trim Video'),
        actions: [
          if (!_isProcessing)
            IconButton(icon: const Icon(Icons.check), onPressed: _saveVideo),
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing video...'),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(child: VideoViewer(trimmer: widget.trimmer)),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TrimViewer(
                      trimmer: widget.trimmer,
                      viewerHeight: 50.0,
                      viewerWidth: MediaQuery.of(context).size.width,
                      maxVideoLength: const Duration(seconds: 60),
                      onChangeStart: (value) {
                        _startValue = value;
                      },
                      onChangeEnd: (value) {
                        _endValue = value;
                      },
                      onChangePlaybackState: (value) {
                        // Schedule the update to avoid "widget tree locked" error during dispose
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _isPlaying = value;
                            });
                          }
                        });
                      },
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final bool playbackState =
                        await widget.trimmer.videoPlaybackControl(
                      startValue: _startValue,
                      endValue: _endValue,
                    );
                    setState(() {
                      _isPlaying = playbackState;
                    });
                  },
                  child: _isPlaying
                      ? const Icon(Icons.pause, size: 40)
                      : const Icon(Icons.play_arrow, size: 40),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}
