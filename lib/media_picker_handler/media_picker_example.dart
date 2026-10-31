import 'package:flutter/material.dart';
import 'package:gt_media/media_picker_handler/video_player_utility.dart';
import 'package:image_cropper/image_cropper.dart';
import 'media_picker_utility.dart';

/// Comprehensive demo widget showcasing GT Media picker capabilities.
class MediaPickerDemo extends StatefulWidget {
  /// Creates a [MediaPickerDemo] instance.
  const MediaPickerDemo({super.key});

  @override
  State<MediaPickerDemo> createState() => _MediaPickerDemoState();
}

class _MediaPickerDemoState extends State<MediaPickerDemo> {
  final MediaPickerUtility _mediaPicker = MediaPickerUtility();

  MediaPickerResult? _selectedMedia;
  List<MediaPickerResult> _multiSelectedMedia = [];

  // Example 1: Simple image picking with default settings
  Future<void> _pickImageSimple() async {
    final result = await _mediaPicker.pickImageFromGallery();
    if (result != null) {
      setState(() {
        _selectedMedia = result;
      });
      _showSuccessDialog(result);
    }
  }

  // Example 2: Image picking with custom configuration
  Future<void> _pickImageCustom() async {
    final result = await _mediaPicker.pickImageFromGallery(
      config: const MediaPickerConfig(
        enableCropping: true,
        enableCompression: true,
        maxImageSizeKB: 500, // Max 500 KB
        imageQuality: 80,
        cropStyle: CropStyle.rectangle,
        cropperToolbarColor: Colors.deepPurple,
        cropperActiveControlsColor: Colors.deepPurple,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedMedia = result;
      });
      _showSuccessDialog(result);
    }
  }

  // Example 3: Pick image without cropping
  Future<void> _pickImageNoCrop() async {
    final result = await _mediaPicker.pickImageFromGallery(
      config: const MediaPickerConfig(
        enableCropping: false,
        enableCompression: true,
        maxImageSizeKB: 2048, // Max 2 MB
        imageQuality: 90,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedMedia = result;
      });
      _showSuccessDialog(result);
    }
  }

  // Example 4: Pick image without compression
  Future<void> _pickImageNoCompress() async {
    final result = await _mediaPicker.pickImageFromGallery(
      config: const MediaPickerConfig(
        enableCropping: true,
        enableCompression: false,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedMedia = result;
      });
      _showSuccessDialog(result);
    }
  }

  // Example 5: Pick image from camera
  Future<void> _pickImageFromCamera() async {
    final result = await _mediaPicker.pickImageFromCamera(
      config: const MediaPickerConfig(
        enableCropping: true,
        enableCompression: true,
        maxImageSizeKB: 1024,
        imageQuality: 85,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedMedia = result;
      });
      _showSuccessDialog(result);
    }
  }

  // Example 6: Pick video with default settings
  Future<void> _pickVideoSimple() async {
    final result = await _mediaPicker.pickVideoFromGallery(
      context: context,
      config: MediaPickerConfig(),
    );
    if (result != null) {
      if (!mounted) return;
      setState(() {
        _selectedMedia = result;
      });
      _showSuccessDialog(result);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerUtility(videoPath: result.file.path),
        ),
      );
    }
  }

  // Example 7: Pick video with custom configuration
  Future<void> _pickVideoCustom() async {
    final result = await _mediaPicker.pickVideoFromGallery(
      context: context,
      config: const MediaPickerConfig(
        enableTrimming: true,
        maxVideoSizeMB: 25, // Max 25 MB
        maxVideoDurationSeconds: 60, // Max 60 seconds
      ),
    );
    if (result != null) {
      setState(() {
        _selectedMedia = result;
      });
      _showSuccessDialog(result);
    }
  }

  // Example 8: Pick video without trimming
  Future<void> _pickVideoNoTrim() async {
    final result = await _mediaPicker.pickVideoFromGallery(
      context: context,
      config: const MediaPickerConfig(
        enableTrimming: false,
        maxVideoSizeMB: 50,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedMedia = result;
      });
      _showSuccessDialog(result);
    }
  }

  // Example 9: Pick video from camera
  Future<void> _pickVideoFromCamera() async {
    final result = await _mediaPicker.pickVideoFromCamera(
      context: context,
      config: const MediaPickerConfig(
        enableTrimming: true,
        maxVideoSizeMB: 30,
        maxVideoDurationSeconds: 30,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedMedia = result;
      });
      _showSuccessDialog(result);
    }
  }

  // Example 10: Pick image with circular crop
  Future<void> _pickImageCircular() async {
    final result = await _mediaPicker.pickImageFromGallery(
      config: const MediaPickerConfig(
        enableCropping: true,
        enableCompression: true,
        cropStyle: CropStyle.circle,
        cropAspectRatioPresets: [CropAspectRatioPreset.square],
        maxImageSizeKB: 512,
        imageQuality: 85,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedMedia = result;
        _multiSelectedMedia = [];
      });
      _showSuccessDialog(result);
    }
  }

  // Example 11: Pick image with locked Square Crop
  Future<void> _pickImageSquareCrop() async {
    final result = await _mediaPicker.pickImageFromGallery(
      config: const MediaPickerConfig(
        enableCropping: true,
        lockAspectRatio: CropAspectRatioPreset.square,
        cropperTitle: 'Crop Square',
        maxImageSizeKB: 512,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedMedia = result;
        _multiSelectedMedia = [];
      });
      _showSuccessDialog(result);
    }
  }

  // Example 12: Pick multiple images
  Future<void> _pickMultipleImages() async {
    final results = await _mediaPicker.pickMultipleImagesFromGallery(
      config: const MediaPickerConfig(
        enableCropping: false, // Cropping multiple images is usually disabled
        enableCompression: true,
        maxImageSizeKB: 500,
      ),
    );

    if (results.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _selectedMedia = null;
        _multiSelectedMedia = results;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${results.length} images selected')),
      );
    }
  }

  // Example 13: Pick single document (PDF/Doc)
  Future<void> _pickDocument() async {
    final results = await _mediaPicker.pickDocuments(
      config: const MediaPickerConfig(
        allowedExtensions: ['pdf', 'doc', 'docx'],
        maxDocumentSizeMB: 5,
      ),
    );

    if (results.isNotEmpty) {
      setState(() {
        _selectedMedia = results.first;
        _multiSelectedMedia = [];
      });
      _showSuccessDialog(results.first);
    }
  }

  // Example 14: Pick multiple documents
  Future<void> _pickMultipleDocuments() async {
    final results = await _mediaPicker.pickDocuments(
      config: const MediaPickerConfig(
        allowMultiple: true,
        allowedExtensions: ['pdf', 'jpg', 'png'], // Can mix types if needed
        maxDocumentSizeMB: 10,
      ),
    );

    if (results.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _selectedMedia = null;
        _multiSelectedMedia = results;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${results.length} documents selected')),
      );
    }
  }

  void _showSuccessDialog(MediaPickerResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Media Selected Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${result.mediaType.name}'),
            Text('File Name: ${result.fileName}'),
            Text('Size: ${result.fileSizeKB.toStringAsFixed(2)} KB'),
            if (result.fileSizeMB >= 1)
              Text('Size: ${result.fileSizeMB.toStringAsFixed(2)} MB'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media Picker Demo'), elevation: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display selected media
            if (_selectedMedia != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_selectedMedia!.mediaType == MediaType.image)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedMedia!.file,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      if (_selectedMedia!.mediaType == MediaType.video)
                        const Icon(
                          Icons.videocam,
                          size: 100,
                          color: Colors.grey,
                        ),
                      if (_selectedMedia!.mediaType == MediaType.document)
                        const Icon(
                          Icons.description,
                          size: 100,
                          color: Colors.blue,
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Selected ${_selectedMedia!.mediaType.name}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Size: ${_selectedMedia!.fileSizeKB.toStringAsFixed(2)} KB',
                      ),
                    ],
                  ),
                ),
              ),

            // Display multiple selected media
            if (_multiSelectedMedia.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Images (${_multiSelectedMedia.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _multiSelectedMedia.length,
                      itemBuilder: (context, index) {
                        final media = _multiSelectedMedia[index];
                        return Card(
                          margin: const EdgeInsets.only(right: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: media.mediaType == MediaType.image
                                      ? Image.file(
                                          media.file,
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          height: 80,
                                          width: 80,
                                          color: Colors.grey[200],
                                          child: Icon(
                                            media.mediaType == MediaType.video
                                                ? Icons.videocam
                                                : Icons.description,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${media.fileSizeKB.toStringAsFixed(0)} KB',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // Image Picker Buttons
            Text(
              'Image Picker Examples',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickImageSimple,
              icon: const Icon(Icons.image),
              label: const Text('Pick Image (Default)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickImageCustom,
              icon: const Icon(Icons.photo_size_select_actual),
              label: const Text('Pick Image (Max 500KB, Quality 80)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickImageNoCrop,
              icon: const Icon(Icons.crop_free),
              label: const Text('Pick Image (No Crop)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickImageNoCompress,
              icon: const Icon(Icons.high_quality),
              label: const Text('Pick Image (No Compress)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickImageFromCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Pick Image from Camera'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickImageCircular,
              icon: const Icon(Icons.account_circle),
              label: const Text('Pick Image (Circular Crop)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickImageSquareCrop,
              icon: const Icon(Icons.crop_square),
              label: const Text('Pick Image (Square Crop Locked)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickMultipleImages,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick Multiple Images'),
            ),
            const SizedBox(height: 20),

            // Document Picker Buttons
            Text(
              'Document Picker Examples',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickDocument,
              icon: const Icon(Icons.description),
              label: const Text('Pick Document (PDF/Doc)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickMultipleDocuments,
              icon: const Icon(Icons.library_books),
              label: const Text('Pick Multiple Documents'),
            ),
            const SizedBox(height: 20),

            // Video Picker Buttons
            Text(
              'Video Picker Examples',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickVideoSimple,
              icon: const Icon(Icons.video_library),
              label: const Text('Pick Video (Default)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickVideoCustom,
              icon: const Icon(Icons.video_call),
              label: const Text('Pick Video (Max 25MB, 60s)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickVideoNoTrim,
              icon: const Icon(Icons.videocam),
              label: const Text('Pick Video (No Trim)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickVideoFromCamera,
              icon: const Icon(Icons.videocam),
              label: const Text('Pick Video from Camera'),
            ),
            const SizedBox(height: 20),

            // Utility Buttons
            Text('Utilities', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () async {
                await _mediaPicker.clearTemporaryFiles();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Temporary files cleared')),
                  );
                }
              },
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Clear Temporary Files'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
