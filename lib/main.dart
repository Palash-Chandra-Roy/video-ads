// Multiple ads and
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MaterialApp(home: VideoPlaylistApp()));
}

class VideoPlaylistApp extends StatefulWidget {
  const VideoPlaylistApp({super.key});

  @override
  State<VideoPlaylistApp> createState() => _VideoPlaylistAppState();
}

class _VideoPlaylistAppState extends State<VideoPlaylistApp> {
  VideoPlayerController? _mainController;
  VideoPlayerController? _adController;

  bool _isLoading = false;
  bool _isMuted = false;
  bool _isAdPlaying = false;
  bool _canSkip = false;

  int _countdown = 5;
  Timer? _timer;

  final List<String> playlist = [
    "assets/images/record.mp4",
    "assets/images/record3.mp4",
    "assets/images/record2.mp4",
  ];
  int currentIndex = 0;

  // Ads
  final List<Duration> adSchedule = [
    const Duration(seconds: 5),
    const Duration(seconds: 15),
  ];
  final List<String> adVideos = [
    "assets/images/ads.mp4",
    "assets/images/ads1.mp4",
    //"assets/images/ads2.mp4",
  ];
  int currentAdIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMainVideo(currentIndex);
  }

  Future<void> _loadMainVideo(int index) async {
    setState(() => _isLoading = true);

    await _mainController?.dispose();
    _mainController = VideoPlayerController.asset(playlist[index]);

    await _mainController!.initialize();
    _mainController!.setLooping(false);
    _mainController!.setVolume(_isMuted ? 0 : 1);
    _mainController!.play();

    // auto update UI
    _mainController!.addListener(() {
      if (mounted) setState(() {});

      if (!_isAdPlaying &&
          currentAdIndex < adSchedule.length &&
          _mainController!.value.position >= adSchedule[currentAdIndex]) {
        showAd(currentAdIndex);
      }

      if (_mainController!.value.position >= _mainController!.value.duration &&
          !_isAdPlaying) {
        _playNextVideo();
      }
    });

    setState(() {
      currentIndex = index;
      currentAdIndex = 0;
      _isLoading = false;
    });
  }

  void _playNextVideo() {
    if (currentIndex < playlist.length - 1) {
      currentIndex++;
      _loadMainVideo(currentIndex);
    }
  }

  Future<void> showAd(int index) async {
    await _adController?.dispose();
    _adController = VideoPlayerController.asset(adVideos[index]);

    await _adController!.initialize();

    setState(() {
      _isAdPlaying = true;
      _canSkip = false;
      _countdown = 5;
      _mainController?.pause();
    });

    _adController!.setVolume(_isMuted ? 0 : 1);
    _adController!.play();

    _startCountdown();

    _adController!.addListener(() {
      if (mounted) setState(() {});
      if (_adController!.value.position >= _adController!.value.duration &&
          _isAdPlaying) {
        closeAd();
      }
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        setState(() => _canSkip = true);
        timer.cancel();
      }
    });
  }

  void closeAd() {
    if (!_isAdPlaying) return;
    _timer?.cancel();

    setState(() {
      _isAdPlaying = false;
      _canSkip = false;
      _adController?.pause();
      _adController?.seekTo(Duration.zero);
      _mainController?.play();
      currentAdIndex++;
    });
  }

  void _togglePlay(VideoPlayerController controller) {
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  void _toggleMute(VideoPlayerController controller) {
    setState(() {
      _isMuted = !_isMuted;
      controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  void _seekRelative(VideoPlayerController controller, Duration offset) {
    final current = controller.value.position;
    final target = current + offset;

    if (target < Duration.zero) {
      controller.seekTo(Duration.zero);
    } else if (target > controller.value.duration) {
      controller.seekTo(controller.value.duration);
    } else {
      controller.seekTo(target);
    }
  }

  @override
  void dispose() {
    _mainController?.dispose();
    _adController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _isAdPlaying ? _adController : _mainController;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Playlist Video Player with Ads")),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : (controller != null && controller.value.isInitialized)
                  ? Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),

                        // Skip Button
                        if (_isAdPlaying)
                          Positioned(
                            bottom: 80,
                            right: 20,
                            child: _canSkip
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => closeAd(),
                                    child: const Text("Skip Ad"),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "Skip in $_countdown",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                          ),

                        // Controls
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    controller.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => _togglePlay(controller),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isMuted
                                        ? Icons.volume_off
                                        : Icons.volume_up,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => _toggleMute(controller),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.replay_10,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => _seekRelative(
                                    controller,
                                    const Duration(seconds: -10),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.forward_10,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => _seekRelative(
                                    controller,
                                    const Duration(seconds: 5),
                                  ),
                                ),
                                Expanded(
                                  child: VideoProgressIndicator(
                                    controller,
                                    allowScrubbing: true,
                                    colors: const VideoProgressColors(
                                      playedColor: Colors.red,
                                      bufferedColor: Colors.white54,
                                      backgroundColor: Colors.grey,
                                    ),
                                  ),
                                ),
                                Text(
                                  "${_formatDuration(controller.value.position)} / ${_formatDuration(controller.value.duration)}",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),

          // Playlist UI
          Container(
            height: 100,
            color: Colors.grey[900],
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: playlist.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _loadMainVideo(index),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.all(8),
                    color: index == currentIndex
                        ? Colors.red
                        : Colors.grey[700],
                    child: Center(
                      child: Text(
                        "Video ${index + 1}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(1, "0");
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
