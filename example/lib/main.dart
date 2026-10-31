import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gt_media/gt_media.dart';
import 'package:image_cropper/image_cropper.dart';

void main() {
  runApp(const MyApp());
}

/// Global theme notifier for dynamically switching between light and dark themes.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);

/// Root application widget for GT Media Example.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'GT Media Example',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.light,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF818CF8),
              brightness: Brightness.dark,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
            ),
          ),
          home: const MediaExampleScreen(),
        );
      },
    );
  }
}

/// Main interactive screen demonstrating GT Media capabilities.
class MediaExampleScreen extends StatefulWidget {
  const MediaExampleScreen({super.key});

  @override
  State<MediaExampleScreen> createState() => _MediaExampleScreenState();
}

class _MediaExampleScreenState extends State<MediaExampleScreen> {
  final MediaPickerUtility _mediaPicker = MediaPickerUtility();
  MediaPickerResult? _selectedMedia;
  List<MediaPickerResult> _multiMediaList = [];
  bool _isLoading = false;
  double _processingProgress = 0.0;

  Future<void> _pickImage() async {
    setState(() => _isLoading = true);
    try {
      final result = await _mediaPicker.pickImageFromGallery(
        config: MediaPickerConfig(
          enableCropping: true,
          enableCompression: true,
          maxImageSizeKB: 500,
          imageQuality: 85,
          onProgress: (p) => setState(() => _processingProgress = p),
        ),
      );

      if (result != null) {
        setState(() {
          _selectedMedia = result;
          _multiMediaList = [];
        });
        _showResult(result);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    setState(() => _isLoading = true);
    try {
      final result = await _mediaPicker.pickImageFromGallery(
        config: const MediaPickerConfig(
          enableCropping: true,
          cropStyle: CropStyle.circle,
          cropAspectRatioPresets: [CropAspectRatioPreset.square],
          maxImageSizeKB: 256,
        ),
      );

      if (result != null) {
        setState(() {
          _selectedMedia = result;
          _multiMediaList = [];
        });
        _showResult(result);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMultipleImages() async {
    setState(() => _isLoading = true);
    try {
      final results = await _mediaPicker.pickMultipleImagesFromGallery(
        config: const MediaPickerConfig(
          enableCompression: true,
          maxImageSizeKB: 500,
          imageQuality: 80,
        ),
      );

      if (results.isNotEmpty) {
        setState(() {
          _selectedMedia = results.first;
          _multiMediaList = results;
        });
        _showSuccess(
          'Selected ${results.length} images (${results.fold<double>(0, (sum, item) => sum + item.fileSizeKB).toStringAsFixed(1)} KB total)',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _captureCameraImage() async {
    setState(() => _isLoading = true);
    try {
      final result = await _mediaPicker.pickImageFromCamera(
        config: const MediaPickerConfig(
          enableCropping: true,
          enableCompression: true,
          maxImageSizeKB: 500,
        ),
      );

      if (result != null) {
        setState(() {
          _selectedMedia = result;
          _multiMediaList = [];
        });
        _showResult(result);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickVideo() async {
    setState(() => _isLoading = true);
    try {
      final result = await _mediaPicker.pickVideoFromGallery(
        context: context,
        config: const MediaPickerConfig(
          enableTrimming: true,
          maxVideoSizeMB: 25,
          maxVideoDurationSeconds: 60,
        ),
      );

      if (result != null) {
        setState(() {
          _selectedMedia = result;
          _multiMediaList = [];
        });
        _showResult(result);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerUtility(videoPath: result.file.path),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDocument() async {
    setState(() => _isLoading = true);
    try {
      final results = await _mediaPicker.pickDocuments(
        config: const MediaPickerConfig(
          allowedExtensions: ['pdf', 'doc', 'docx'],
          maxDocumentSizeMB: 5,
        ),
      );

      if (results.isNotEmpty) {
        setState(() {
          _selectedMedia = results.first;
          _multiMediaList = results;
        });
        _showResult(results.first);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showResult(MediaPickerResult result) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              _getMediaTypeIcon(result.mediaType),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${result.mediaType.name.toUpperCase()}: ${result.fileName} (${result.fileSizeKB.toStringAsFixed(1)} KB)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message),
      ),
    );
  }

  IconData _getMediaTypeIcon(MediaType type) {
    switch (type) {
      case MediaType.image:
        return Icons.image_rounded;
      case MediaType.video:
        return Icons.videocam_rounded;
      case MediaType.document:
        return Icons.description_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'GT Media Example',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'v1.1.0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: () {
              themeModeNotifier.value = isDark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Intro Card
              _buildHeroBanner(theme),
              const SizedBox(height: 16),

              // Progress Indicator during async operations
              if (_isLoading) ...[
                LinearProgressIndicator(
                  value: _processingProgress > 0 ? _processingProgress : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 16),
              ],

              // Active Media Preview
              if (_selectedMedia != null) ...[
                _buildSelectedMediaCard(theme),
                const SizedBox(height: 20),
              ],

              // Multi-item preview gallery if multiple selected
              if (_multiMediaList.length > 1) ...[
                _buildMultiPreviewRow(theme),
                const SizedBox(height: 20),
              ],

              // Image Section
              _buildSectionHeader(
                title: 'Image',
                subtitle:
                    'Picking, multi-select, cropping, and smart compression',
                icon: Icons.photo_library_rounded,
                color: Colors.indigo,
              ),
              const SizedBox(height: 10),
              _buildCardGroup([
                _buildActionTile(
                  icon: Icons.crop_rounded,
                  title: 'Pick Image (with crop & compress)',
                  subtitle: 'Gallery image with ratio cropping and compression',
                  color: Colors.indigo,
                  onTap: _pickImage,
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.account_circle_rounded,
                  title: 'Pick Profile Picture (circular)',
                  subtitle: 'Circular avatar cropping with 256 KB max size',
                  color: Colors.indigo,
                  onTap: _pickProfileImage,
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.camera_alt_rounded,
                  title: 'Capture Image from Camera',
                  subtitle: 'Take live photo with optional crop and compress',
                  color: Colors.indigo,
                  onTap: _captureCameraImage,
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.collections_rounded,
                  title: 'Pick Multiple Images',
                  subtitle: 'Batch select images from gallery with compression',
                  color: Colors.indigo,
                  onTap: _pickMultipleImages,
                ),
              ]),
              const SizedBox(height: 24),

              // Video Section
              _buildSectionHeader(
                title: 'Video',
                subtitle: 'Video picking, native trimming, and gesture player',
                icon: Icons.videocam_rounded,
                color: Colors.amber.shade800,
              ),
              const SizedBox(height: 10),
              _buildCardGroup([
                _buildActionTile(
                  icon: Icons.content_cut_rounded,
                  title: 'Pick Video (with trimmer)',
                  subtitle: 'Pick video and trim with custom time constraints',
                  color: Colors.amber.shade800,
                  onTap: _pickVideo,
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.play_circle_fill_rounded,
                  title: 'Play Sample Network Video',
                  subtitle:
                      'Stream Big Buck Bunny sample with gesture controls',
                  color: Colors.amber.shade800,
                  onTap: () {
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
                ),
              ]),
              const SizedBox(height: 24),

              // Document Section
              _buildSectionHeader(
                title: 'Document',
                subtitle: 'Document picking with extension and size validation',
                icon: Icons.description_rounded,
                color: Colors.teal,
              ),
              const SizedBox(height: 10),
              _buildCardGroup([
                _buildActionTile(
                  icon: Icons.upload_file_rounded,
                  title: 'Pick Document (PDF/DOC)',
                  subtitle: 'Filter by PDF, DOC, DOCX up to 5 MB',
                  color: Colors.teal,
                  onTap: _pickDocument,
                ),
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.perm_media_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GT Media Toolkit',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Picking • Cropping • Compression • Player',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBadge(theme, 'Modern Material 3'),
              _buildBadge(theme, 'Cropping Presets'),
              _buildBadge(theme, 'Trimmer Ready'),
              _buildBadge(theme, 'Gesture Player'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSelectedMediaCard(ThemeData theme) {
    final media = _selectedMedia!;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            child: Row(
              children: [
                Icon(
                  _getMediaTypeIcon(media.mediaType),
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Selected ${media.mediaType.name.toUpperCase()}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Clear Selection',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      _selectedMedia = null;
                      _multiMediaList = [];
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (media.mediaType == MediaType.image &&
                    File(media.file.path).existsSync())
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Image.file(
                          media.file,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${media.fileSizeKB.toStringAsFixed(1)} KB',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        _getMediaTypeIcon(media.mediaType),
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Text(
                  media.fileName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Size: ${media.fileSizeKB.toStringAsFixed(1)} KB  •  Path: ${media.file.path}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (media.mediaType == MediaType.video) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VideoPlayerUtility(videoPath: media.file.path),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play Video'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiPreviewRow(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Batch Selection (${_multiMediaList.length} items)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _multiMediaList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = _multiMediaList[index];
              return InkWell(
                onTap: () => setState(() => _selectedMedia = item),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedMedia == item
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      width: _selectedMedia == item ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.mediaType == MediaType.image
                      ? Image.file(item.file, fit: BoxFit.cover)
                      : Center(
                          child: Icon(
                            _getMediaTypeIcon(item.mediaType),
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: theme.colorScheme.outlineVariant,
      ),
      onTap: onTap,
    );
  }
}
