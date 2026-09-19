import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/brand.dart';
import '../utils/validators.dart';

/// Inline player used by the liveness step and the summary screen.
///
/// Shows a poster frame until the user presses play, plus play/pause,
/// elapsed/total duration and a mute toggle.
class VideoPreviewPlayer extends StatefulWidget {
  const VideoPreviewPlayer({
    super.key,
    required this.file,
    this.height = 260,
    this.autoPlay = false,
  });

  final File file;
  final double height;
  final bool autoPlay;

  @override
  State<VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<VideoPreviewPlayer> {
  VideoPlayerController? _controller;
  String? _error;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(VideoPreviewPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _controller?.dispose();
      _controller = null;
      _error = null;
      _initialize();
    }
  }

  Future<void> _initialize() async {
    if (!widget.file.existsSync()) {
      setState(() => _error = 'The video file could not be found.');
      return;
    }

    final controller = VideoPlayerController.file(widget.file);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() => _error = 'Video preview is not available.');
      }
      return;
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
    if (widget.autoPlay) await controller.play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _muted = !_muted);
    controller.setVolume(_muted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return _Shell(
        height: widget.height,
        child: Center(
          child: Text(
            error,
            style: const TextStyle(color: BrandColors.onPrimary, fontSize: 13),
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return _Shell(
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(color: BrandColors.onPrimary),
        ),
      );
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return _Shell(
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: value.size.width,
                  height: value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onTap: _togglePlay,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedOpacity(
                    opacity: value.isPlaying ? 0 : 1,
                    duration: const Duration(milliseconds: 180),
                    child: Center(
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: BrandColors.primary.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 38,
                          color: BrandColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _togglePlay,
                        color: Colors.white,
                        iconSize: 22,
                        icon: Icon(
                          value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                      Expanded(
                        child: VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: BrandColors.primary,
                            backgroundColor: Colors.white24,
                            bufferedColor: Colors.white38,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${formatDuration(value.position)} / '
                        '${formatDuration(value.duration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleMute,
                        color: Colors.white,
                        iconSize: 20,
                        icon: Icon(
                          _muted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: BrandColors.primaryDark,
        child: SizedBox(height: height, width: double.infinity, child: child),
      ),
    );
  }
}
