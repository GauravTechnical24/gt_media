import 'package:flutter/material.dart';
import 'package:gt_media/gt_media.dart';
import 'package:image_cropper/image_cropper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GT Media Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MediaExampleScreen(),
    );
  }
}

class MediaExampleScreen extends StatefulWidget {
  const MediaExampleScreen({super.key});

  @override
  State<MediaExampleScreen> createState() => _MediaExampleScreenState();
}

class _MediaExampleScreenState extends State<MediaExampleScreen> {
  final MediaPickerUtility _mediaPicker = MediaPickerUtility();
  MediaPickerResult? _selectedMedia;

  Future<void> _pickImage() async {
    final result = await _mediaPicker.pickImageFromGallery(
      config: const MediaPickerConfig(
        enableCropping: true,
        enableCompression: true,
        maxImageSizeKB: 500,
        imageQuality: 85,
      ),
    );

    if (result != null) {
      setState(() => _selectedMedia = result);
      _showResult(result);
    }
  }

  Future<void> _pickProfileImage() async {
    final result = await _mediaPicker.pickImageFromGallery(
      config: const MediaPickerConfig(
        enableCropping: true,
        cropStyle: CropStyle.circle,
        cropAspectRatioPresets: [CropAspectRatioPreset.square],
        maxImageSizeKB: 256,
      ),
    );

    if (result != null) {
      setState(() => _selectedMedia = result);
      _showResult(result);
    }
  }

  Future<void> _pickVideo() async {
    final result = await _mediaPicker.pickVideoFromGallery(
      context: context,
      config: const MediaPickerConfig(
        enableTrimming: true,
        maxVideoSizeMB: 25,
        maxVideoDurationSeconds: 60,
      ),
    );

    if (result != null) {
      setState(() => _selectedMedia = result);
      _showResult(result);

      // Navigate to video player
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerUtility(videoPath: result.file.path),
          ),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    final results = await _mediaPicker.pickDocuments(
      config: const MediaPickerConfig(
        allowedExtensions: ['pdf', 'doc', 'docx'],
        maxDocumentSizeMB: 5,
      ),
    );

    if (results.isNotEmpty) {
      setState(() => _selectedMedia = results.first);
      _showResult(results.first);
    }
  }

  void _showResult(MediaPickerResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.mediaType.name}: ${result.fileName} (${result.fileSizeKB.toStringAsFixed(1)} KB)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GT Media Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview
            if (_selectedMedia != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                        )
                      else
                        Icon(
                          _selectedMedia!.mediaType == MediaType.video
                              ? Icons.videocam
                              : Icons.description,
                          size: 80,
                          color: Colors.grey,
                        ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedMedia!.fileName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Size: ${_selectedMedia!.fileSizeKB.toStringAsFixed(1)} KB',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Image Section
            Text('Image', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Pick Image (with crop & compress)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickProfileImage,
              icon: const Icon(Icons.account_circle),
              label: const Text('Pick Profile Picture (circular)'),
            ),
            const SizedBox(height: 24),

            // Video Section
            Text('Video', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.videocam),
              label: const Text('Pick Video (with trimmer)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VideoPlayerUtility(
                      videoPath:
                          'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                      isNetwork: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play Sample Network Video'),
            ),
            const SizedBox(height: 24),

            // Document Section
            Text('Document', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickDocument,
              icon: const Icon(Icons.description),
              label: const Text('Pick Document (PDF/DOC)'),
            ),
          ],
        ),
      ),
    );
  }
}
