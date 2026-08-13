import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CommunityVideoPlayerPage extends StatefulWidget {
  const CommunityVideoPlayerPage({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<CommunityVideoPlayerPage> createState() =>
      _CommunityVideoPlayerPageState();
}

class _CommunityVideoPlayerPageState extends State<CommunityVideoPlayerPage>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  Object? _error;
  bool _muted = false;

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final uri = Uri.parse(widget.videoUrl);
      if (!uri.hasScheme || !(uri.scheme == 'https' || uri.scheme == 'http')) {
        throw const FormatException('Invalid video URL');
      }
      final controller = VideoPlayerController.networkUrl(uri);
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(false);
      await controller.play();
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _controller?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
    setState(() {});
  }

  Future<void> _toggleMute() async {
    final controller = _controller;
    if (controller == null) return;
    _muted = !_muted;
    await controller.setVolume(_muted ? 0 : 1);
    if (mounted) setState(() {});
  }

  String _duration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (value.inHours > 0) {
      return '${value.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_error != null)
              _ErrorView(
                message:
                    _isVi
                        ? 'Không thể phát video này.'
                        : 'This video could not be played.',
                retryLabel: _isVi ? 'Thử lại' : 'Retry',
                onRetry: () async {
                  await _controller?.dispose();
                  setState(() {
                    _controller = null;
                    _error = null;
                  });
                  await _initialize();
                },
              )
            else if (controller == null || !controller.value.isInitialized)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6B2C)),
              )
            else
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
            Positioned(
              left: 8,
              top: 8,
              child: _CircleButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (controller != null && controller.value.isInitialized)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final value = controller.value;
                    return Container(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VideoProgressIndicator(
                            controller,
                            allowScrubbing: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            colors: const VideoProgressColors(
                              playedColor: Color(0xFFFF6B2C),
                              bufferedColor: Colors.white38,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                color: Colors.white,
                                onPressed: _togglePlay,
                                icon: Icon(
                                  value.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                              ),
                              Text(
                                '${_duration(value.position)} / ${_duration(value.duration)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                color: Colors.white,
                                onPressed: _toggleMute,
                                icon: Icon(
                                  _muted
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.58),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_rounded,
              color: Colors.white70,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
