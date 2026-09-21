import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/ktp_capture.dart';
import 'ktp_scanner_colors.dart';

/// Full screen camera used to photograph a KTP.
///
/// Pops with a [KtpCapture] carrying the photo and the guide frame it was
/// framed in, or `null` when the user backs out.
class KtpCameraPage extends StatefulWidget {
  const KtpCameraPage({
    super.key,
    this.title = 'Scan ID card',
    this.instruction =
        'Place the KTP inside the frame. Make sure the whole card, its text '
        'and the photo are visible, well lit and free of glare.',
    this.guideAspectRatio = 1.586,
  });

  final String title;
  final String instruction;

  /// Width divided by height of the document frame; 1.586 is the ID-1 ratio
  /// of the KTP (ISO/IEC 7810).
  final double guideAspectRatio;

  @override
  State<KtpCameraPage> createState() => _KtpCameraPageState();
}

class _KtpCameraPageState extends State<KtpCameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _permissionDenied = false;
  bool _capturing = false;
  Size? _viewport;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_setupCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_setupCamera());
    }
  }

  Future<void> _setupCamera() async {
    setState(() {
      _error = null;
      _permissionDenied = false;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'This device has no camera.');
        return;
      }

      final description = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        description,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on CameraException catch (error) {
      if (!mounted) return;
      final denied =
          error.code == 'CameraAccessDenied' ||
          error.code == 'CameraAccessDeniedWithoutPrompt' ||
          error.code == 'CameraAccessRestricted';
      setState(() {
        _permissionDenied = denied;
        _error = denied
            ? 'Camera access has not been granted. This app needs the camera '
                  'to photograph the KTP. Enable the Camera permission in your '
                  'device settings and try again.'
            : 'The camera could not be started. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'The camera could not be started. Please try again.',
      );
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }

    setState(() => _capturing = true);
    try {
      final guide = _guideFraction();
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(KtpCapture(path: file.path, guide: guide));
    } on CameraException {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _error = 'The photo could not be taken. Please try again.';
      });
    }
  }

  /// The card frame drawn over the preview, in viewport coordinates.
  Rect _guideRect(Size viewport) {
    final width = viewport.width * 0.88;
    return Rect.fromCenter(
      center: Offset(viewport.width / 2, viewport.height * 0.42),
      width: width,
      height: width / widget.guideAspectRatio,
    );
  }

  /// Re-expresses the guide frame as fractions of the photo about to be taken.
  ///
  /// The preview is painted with [BoxFit.cover], so the visible part of it is
  /// scaled up and centre-cropped inside the viewport; undoing that gives the
  /// frame's position on the sensor, which the still shares.
  Rect? _guideFraction() {
    final viewport = _viewport;
    final preview = _controller?.value.previewSize;
    if (viewport == null ||
        preview == null ||
        viewport.isEmpty ||
        preview.isEmpty) {
      return null;
    }

    // `previewSize` is reported in landscape orientation.
    final source = Size(preview.height, preview.width);
    final scale = math.max(
      viewport.width / source.width,
      viewport.height / source.height,
    );
    final displayed = source * scale;
    final dx = (viewport.width - displayed.width) / 2;
    final dy = (viewport.height - displayed.height) / 2;

    // A small outward margin keeps the card edges from being shaved off when
    // the still is framed a hair tighter than the preview.
    final guide = _guideRect(viewport).inflate(_guideMargin);

    final left = (guide.left - dx) / scale / source.width;
    final top = (guide.top - dy) / scale / source.height;
    final right = (guide.right - dx) / scale / source.width;
    final bottom = (guide.bottom - dy) / scale / source.height;

    return Rect.fromLTRB(
      left.clamp(0.0, 1.0),
      top.clamp(0.0, 1.0),
      right.clamp(0.0, 1.0),
      bottom.clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _viewport = constraints.biggest;
              return _buildBody(constraints.biggest);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(Size viewport) {
    final error = _error;
    if (error != null && _controller == null) {
      return _CameraErrorView(
        message: error,
        showRetry: !_permissionDenied,
        onRetry: _setupCamera,
        onClose: () => Navigator.of(context).pop(),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: KtpScannerColors.onPrimary),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _FullScreenPreview(controller: controller),
        CustomPaint(painter: _GuideOverlayPainter(guide: _guideRect(viewport))),
        Positioned(
          top: 8,
          left: 4,
          right: 4,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
              ),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 130,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 28,
          child: Center(
            child: _ShutterButton(busy: _capturing, onPressed: _capture),
          ),
        ),
      ],
    );
  }
}

class _FullScreenPreview extends StatelessWidget {
  const _FullScreenPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.previewSize;
    if (size == null) return CameraPreview(controller);

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        // `previewSize` is reported in landscape orientation.
        width: size.height,
        height: size.width,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onPressed,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Center(
          child: busy
              ? const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
              : Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({
    required this.message,
    required this.showRetry,
    required this.onRetry,
    required this.onClose,
  });

  final String message;
  final bool showRetry;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.no_photography_rounded,
            color: Colors.white70,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, height: 1.5),
          ),
          const SizedBox(height: 24),
          if (showRetry)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onClose,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}

class _GuideOverlayPainter extends CustomPainter {
  const _GuideOverlayPainter({required this.guide});

  final Rect guide;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = KtpScannerColors.primary;

    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(guide, const Radius.circular(16)));

    final overlay = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      hole,
    );
    canvas.drawPath(overlay, scrim);
    canvas.drawPath(hole, outline);
  }

  @override
  bool shouldRepaint(_GuideOverlayPainter oldDelegate) =>
      oldDelegate.guide != guide;
}

/// Outward slack added to the crop so the card edges survive a small
/// preview-to-still framing difference.
const double _guideMargin = 12;
