import 'package:flutter/material.dart';
import 'package:gt_media/media_picker_handler/video_player_utility.dart';

class VideoPlayerScreens extends StatelessWidget {
  const VideoPlayerScreens({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Player')),
      body: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerUtility(
                videoPath:
                    'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                isNetwork: true,
              ),
            ),
          );
        },
        child: const Center(child: Text('Video Player')),
      ),
    );
  }
}
