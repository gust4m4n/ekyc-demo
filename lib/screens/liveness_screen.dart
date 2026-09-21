import 'dart:io';

import 'package:flutter/material.dart';
import 'package:liveness_sdk/liveness_sdk.dart';
import 'package:video_player/video_player.dart';

import '../models/ekyc_draft.dart';
import '../state/ekyc_controller.dart';
import '../theme/brand.dart';
import '../utils/validators.dart';
import '../widgets/guideline_list.dart';
import '../widgets/step_scaffold.dart';
import '../widgets/video_preview_player.dart';
import 'selfie_screen.dart';

/// Step 2 — liveness video, powered by the bundled `liveness_sdk`.
///
/// Proof of presence is captured first, before any photo is taken.
class LivenessScreen extends StatefulWidget {
  const LivenessScreen({super.key, this.returnToReview = false});

  final bool returnToReview;

  @override
  State<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends State<LivenessScreen> {
  File? _pendingFile;
  Duration _pendingDuration = Duration.zero;
  String? _error;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    final existing = EKycScope.read(context).livenessVideo;
    if (existing != null && existing.file.existsSync()) {
      _pendingFile = existing.file;
      _pendingDuration = Duration(
        milliseconds: ((existing.durationSeconds ?? 0) * 1000).round(),
      );
    }
  }

  Future<void> _record() async {
    if (_running) return;
    setState(() {
      _running = true;
      _error = null;
    });

    LivenessResult? result;
    try {
      result = await const LivenessSdk(
        config: kLivenessConfig,
        theme: kLivenessTheme,
      ).start(context: context, expressions: kLivenessExpressions);
    } finally {
      if (mounted) setState(() => _running = false);
    }

    if (!mounted) return;

    final video = result?.video;
    if (video == null) {
      setState(() {
        _pendingFile = null;
        _error =
            'The liveness session was cancelled or timed out. Record again '
            'and follow each prompt.';
      });
      return;
    }

    final file = File(video.path);
    final duration = await _readDuration(file);
    if (!mounted) return;

    final error = validateVideoFile(file, duration: duration);
    setState(() {
      _error = error;
      _pendingDuration = duration;
      _pendingFile = error == null ? file : null;
    });
  }

  Future<Duration> _readDuration(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      return controller.value.duration;
    } catch (_) {
      return Duration.zero;
    } finally {
      await controller.dispose();
    }
  }

  void _submit() {
    final file = _pendingFile;
    if (file == null) return;

    EKycScope.read(context).setLivenessVideo(
      MediaAsset(
        uri: file.path,
        mimeType: videoMimeTypeOf(file.path) ?? 'video/mp4',
        sizeBytes: file.lengthSync(),
        durationSeconds: _pendingDuration.inMilliseconds / 1000,
      ),
    );

    if (widget.returnToReview) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SelfieScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final file = _pendingFile;

    return StepScaffold(
      step: 2,
      title: 'Liveness video',
      actions: file == null
          ? ElevatedButton.icon(
              onPressed: _running ? null : _record,
              icon: const Icon(Icons.videocam_rounded),
              label: Text(_running ? 'Recording...' : 'Start recording'),
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _running ? null : _record,
                    child: const Text('Record again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Use video'),
                  ),
                ),
              ],
            ),
      child: ListView(
        children: [
          const SectionTitle(
            'Record proof of presence',
            subtitle:
                'Follow the prompts: face the camera, smile, blink, then turn '
                'your head to the right.',
          ),
          const SizedBox(height: 20),
          if (file != null)
            VideoPreviewPlayer(
              // The SDK always writes to the same filename, so key on mtime to
              // force a fresh controller after a re-record.
              key: ValueKey(file.lastModifiedSync().millisecondsSinceEpoch),
              file: file,
            )
          else
            const _RecordingPlaceholder(),
          const SizedBox(height: 16),
          if (_error != null)
            InfoBanner(
              message: _error!,
              tone: InfoTone.danger,
              icon: Icons.error_outline_rounded,
            )
          else if (file != null)
            InfoBanner(
              message:
                  'Liveness prompts completed (simulated). Clip length '
                  '${formatDuration(_pendingDuration)}.',
              tone: InfoTone.success,
              icon: Icons.verified_outlined,
            ),
          const SizedBox(height: 20),
          const GuidelineList(
            title: 'Before you record',
            items: [
              'Recording starts automatically once the camera is ready.',
              'Aim for 5–10 seconds; 15 seconds is the maximum.',
              'Follow the on-screen prompts one at a time.',
              'Audio is not needed for this demo.',
            ],
          ),
          const SizedBox(height: 12),
          const InfoBanner(
            message: 'MP4 up to 25 MB. The video is kept on your device only.',
          ),
        ],
      ),
    );
  }
}

class _RecordingPlaceholder extends StatelessWidget {
  const _RecordingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: BrandColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.border),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_outlined, size: 44, color: BrandColors.primary),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tap "Start recording" to begin the liveness session.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: BrandColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
