import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Import Cupertino for the spinner
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Power-House Video Player Utility
/// Optimized for memory, performance, and UI/UX.
class VideoPlayerUtility extends StatefulWidget {
  /// Local file path or remote HTTP/HTTPS URL of the video.
  final String videoPath;

  /// Whether the video is loaded from network URL (true) or local filesystem (false).
  final bool isNetwork;

  /// Whether playback starts automatically once initialized.
  final bool autoPlay;

  /// Whether the video should loop when it reaches the end.
  final bool looping;

  /// Creates a [VideoPlayerUtility] widget.
  const VideoPlayerUtility({
    super.key,
    required this.videoPath,
    this.isNetwork = false,
    this.autoPlay = true,
    this.looping = false,
  });

  @override
  State<VideoPlayerUtility> createState() => _VideoPlayerUtilityState();
}

class _VideoPlayerUtilityState extends State<VideoPlayerUtility>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;

  // State Variables
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isFullScreen = false;
  bool _isBuffering = false;
  bool _isDisposed = false;
  bool _isSeeking = false; // New flag to track seeking state

  // Timers
  Timer? _hideControlsTimer;
  Timer? _seekTimer; // For long press continuous seek
  Timer? _seekFeedbackTimer; // For hiding the text indicator
  Timer?
      _bufferingHideTimer; // New timer to suppress buffering spinner after seek

  // Playback State
  Duration _totalDuration = Duration.zero;
  List<DurationRange> _buffered = [];
  late ValueNotifier<Duration> _positionNotifier;
  DateTime _lastPositionUpdate = DateTime.now(); // For throttling updates

  // Seek Feedback State
  bool _showSeekIndicator = false;
  bool _isForwardSeek = true; // True = Forward, False = Backward
  int _seekOffsetAccumulator = 0; // Tracks total seconds jumped

  @override
  void initState() {
    super.initState();
    _positionNotifier = ValueNotifier(Duration.zero);
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initializeVideoPlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_isInitialized) return;
    if (state == AppLifecycleState.paused) {
      if (_isPlaying) _controller?.pause();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    // CRITICAL: Remove listener FIRST before any other cleanup
    // This prevents setState() calls during disposal
    _controller?.removeListener(_videoListener);
    _controller?.pause(); // Stop playback immediately

    // Cancel all timers
    _hideControlsTimer?.cancel();
    _seekTimer?.cancel();
    _seekFeedbackTimer?.cancel();
    _bufferingHideTimer?.cancel();

    // Dispose notifier
    _positionNotifier.dispose();

    // Dispose controller in microtask to ensure listener cleanup completes
    Future.microtask(() {
      _controller?.dispose();
      _controller = null;
    });

    WidgetsBinding.instance.removeObserver(this);

    // Reset orientations to allow all for previous screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      VideoPlayerController controller;
      if (widget.isNetwork) {
        controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoPath),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      } else {
        controller = VideoPlayerController.file(
          File(widget.videoPath),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      }
      _controller = controller;
      controller.addListener(_videoListener);
      // Add timeout for network videos to prevent hanging
      await controller.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Video initialization timeout');
        },
      );
      if (_isDisposed) {
        controller.dispose();
        return;
      }
      setState(() {
        _isInitialized = true;
        _totalDuration = controller.value.duration;
      });
      if (widget.autoPlay) {
        _playPause();
      }
      controller.setLooping(widget.looping);
    } catch (e) {
      debugPrint("Video Error: $e");
    }
  }

  // Optimized Listener with throttling and mounted guards
  void _videoListener() {
    // CRITICAL: Check mounted FIRST to prevent setState() during disposal
    if (_isDisposed || _controller == null || !mounted) return;

    final val = _controller!.value;
    final hasChanges = val.isPlaying != _isPlaying ||
        val.isBuffering != _isBuffering ||
        val.buffered != _buffered ||
        val.duration != _totalDuration;

    // PERFORMANCE: Throttle position updates to max 10 FPS (100ms intervals)
    // This prevents 30-60 FPS rebuilds of the progress bar
    if (val.position != _positionNotifier.value) {
      final now = DateTime.now();
      if (now.difference(_lastPositionUpdate).inMilliseconds > 100) {
        _positionNotifier.value = val.position;
        _lastPositionUpdate = now;
      }
    }

    if (hasChanges) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isPlaying = val.isPlaying;
          _isBuffering = val.isBuffering;
          _buffered = val.buffered;
          if (val.duration != _totalDuration) {
            _totalDuration = val.duration;
          }
        });
      }
    }

    // Hide buffering indicator after seek if not truly buffering
    if (_isSeeking && !_isBuffering) {
      _bufferingHideTimer?.cancel();
      _bufferingHideTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted &&
            !_isDisposed &&
            _controller != null &&
            !_controller!.value.isBuffering) {
          setState(() {
            _isSeeking = false;
          });
        }
      });
    }
  }

  // --- Unified Seek Logic ---
  void _performSeek(bool forward, {int seconds = 10}) {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isSeeking = true; // Set seeking flag
    });
    final targetSeconds = forward ? seconds : -seconds;
    final newPos = _positionNotifier.value + Duration(seconds: targetSeconds);
    final clampedPos = newPos < Duration.zero
        ? Duration.zero
        : (newPos > _totalDuration ? _totalDuration : newPos);
    _controller!.seekTo(clampedPos);
    _triggerSeekFeedback(forward, seconds);
    _showControlsTemporarily();
  }

  void _triggerSeekFeedback(bool forward, int seconds) {
    setState(() {
      if (_showSeekIndicator && _isForwardSeek == forward) {
        _seekOffsetAccumulator += seconds;
      } else {
        _isForwardSeek = forward;
        _seekOffsetAccumulator = seconds;
      }
      _showSeekIndicator = true;
    });
    _seekFeedbackTimer?.cancel();
    _seekFeedbackTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && !_isDisposed) {
        setState(() {
          _showSeekIndicator = false;
          _seekOffsetAccumulator = 0;
        });
      }
    });
  }

  void _startContinuousSeek(bool forward) {
    _performSeek(forward);
    _seekTimer?.cancel();
    _seekTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      _performSeek(forward);
    });
  }

  void _stopContinuousSeek() {
    _seekTimer?.cancel();
    // Reset seeking flag after continuous seek ends
    if (mounted && !_isDisposed) {
      setState(() {
        _isSeeking = false;
      });
    }
  }

  // --- Controls & UI Logic ---
  void _playPause() {
    if (_controller == null) return;
    if (_isPlaying) {
      _controller!.pause();
      _hideControlsTimer?.cancel();
      setState(() => _showControls = true);
    } else {
      _controller!.play();
      _startHideControlsTimer();
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _goBack() {
    Navigator.pop(context);
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying && !_isDisposed) {
        setState(() => _showControls = false);
      }
    });
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final aspectRatio = _controller?.value.aspectRatio ?? 16 / 9;
    return PopScope(
      canPop: !_isFullScreen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isFullScreen) _toggleFullScreen();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: _isInitialized
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. The Video
                    AspectRatio(
                      aspectRatio: aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                    // 2. Gesture Area (Invisible)
                    _buildGestureDetectors(),
                    // 3. Central Buffering/Loading Indicator (Cupertino Style) - Suppress during seeking
                    if (!_isInitialized || (_isBuffering && !_isSeeking))
                      const CupertinoActivityIndicator(
                        radius: 20,
                        color: Colors.white,
                      ),
                    // 4. Seek Status Pill (Safe & Top)
                    if (_showSeekIndicator)
                      SafeArea(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: _buildSeekIndicatorPill(),
                          ),
                        ),
                      ),
                    // 5. Controls Overlay
                    if (_showControls) _buildControlsOverlay(),
                  ],
                )
              : const CupertinoActivityIndicator(
                  radius: 20,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }

  Widget _buildGestureDetectors() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _toggleControlsVisibility,
            onLongPressStart: (_) => _startContinuousSeek(false),
            onLongPressEnd: (_) => _stopContinuousSeek(),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _toggleControlsVisibility,
            onLongPressStart: (_) => _startContinuousSeek(true),
            onLongPressEnd: (_) => _stopContinuousSeek(),
          ),
        ),
      ],
    );
  }

  void _toggleControlsVisibility() {
    if (_showControls) {
      setState(() => _showControls = false);
    } else {
      _showControlsTemporarily();
    }
  }

  Widget _buildSeekIndicatorPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isForwardSeek ? Icons.fast_forward : Icons.fast_rewind,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            "${_seekOffsetAccumulator}s",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      color: Colors.black26,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Always show back button to go to previous screen
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: _goBack,
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Center Controls (Play/Seek)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.replay_10, color: Colors.white),
                  onPressed: () => _performSeek(false),
                ),
                IconButton(
                  iconSize: 64,
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: Colors.white,
                  ),
                  onPressed: _playPause,
                ),
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.forward_10, color: Colors.white),
                  onPressed: () => _performSeek(true),
                ),
              ],
            ),
            const Spacer(),
            // Footer (Progress Bar & Time)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: ValueListenableBuilder<Duration>(
                valueListenable: _positionNotifier,
                builder: (context, currentPosition, child) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            _formatDuration(currentPosition),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Progress Bar - Isolated with RepaintBoundary for performance
                          Expanded(
                            child: RepaintBoundary(
                              child: _buildStylishProgressBar(currentPosition),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _formatDuration(_totalDuration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _toggleFullScreen,
                            child: Icon(
                              _isFullScreen
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Stylish Progress Bar with Integrated Buffering ---
  Widget _buildStylishProgressBar(Duration currentPosition) {
    return SizedBox(
      height: 20,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // 1. Base Track (Inactive area of the track)
          Positioned(
            left: 0.0,
            top: 9.0,
            right: 0.0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 2. Buffered Ranges (White/Grey loaded parts)
          LayoutBuilder(
            builder: (ctx, constraints) {
              return Stack(
                children: _buffered.map((range) {
                  final totalMs = _totalDuration.inMilliseconds;
                  if (totalMs == 0) return const SizedBox();
                  final start = range.start.inMilliseconds / totalMs;
                  final end = range.end.inMilliseconds / totalMs;
                  return Positioned(
                    top: 9,
                    left: start * constraints.maxWidth,
                    width: (end - start) * constraints.maxWidth,
                    height: 2,
                    child: Container(color: Colors.white30),
                  );
                }).toList(),
              );
            },
          ),
          // 3. Main Slider (Interactive)
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              activeTrackColor: Colors.redAccent,
              // Crucial: Make inactive track transparent to show buffered/base track
              inactiveTrackColor: Colors.transparent,
              thumbColor: Colors.redAccent,
              trackShape: const NoInsetSliderTrackShape(),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6,
                elevation: 4,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              overlayColor: Colors.red.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: currentPosition.inMilliseconds.toDouble().clamp(
                    0.0,
                    _totalDuration.inMilliseconds.toDouble(),
                  ),
              min: 0.0,
              max: _totalDuration.inMilliseconds.toDouble() > 0
                  ? _totalDuration.inMilliseconds.toDouble()
                  : 1.0,
              onChanged: (v) {
                _startHideControlsTimer();
                _positionNotifier.value = Duration(milliseconds: v.toInt());
              },
              onChangeEnd: (v) {
                setState(() {
                  _isSeeking = true; // Set seeking on slider drag end
                });
                _controller?.seekTo(Duration(milliseconds: v.toInt()));
                if (_isPlaying) _controller?.play();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom track shape with no insets for full edge-to-edge coverage.
class NoInsetSliderTrackShape extends RectangularSliderTrackShape {
  const NoInsetSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 3;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
