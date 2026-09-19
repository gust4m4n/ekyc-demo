import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/brand.dart';

/// Shape of the cut-out drawn over the preview.
enum CaptureGuide {
  /// Rectangular document frame; the ratio is supplied by the caller.
  idCard,

  /// Face oval used by the selfie step.
  faceOval,
}

/// Full screen camera used for the document and selfie captures.
///
/// Pops with the captured [XFile], or `null` when the user backs out.
class CaptureCameraPage extends StatefulWidget {
  const CaptureCameraPage({
    super.key,
    required this.title,
    required this.instruction,
    required this.guide,
    required this.lensDirection,
    this.guideAspectRatio = 1.586,
  });

  final String title;
  final String instruction;
  final CaptureGuide guide;
  final CameraLensDirection lensDirection;

  /// Width divided by height of the document frame, e.g. 1.586 for an ID-1
  /// card and 1.42 for a passport data page.
  final double guideAspectRatio;

  @override
  State<CaptureCameraPage> createState() => _CaptureCameraPageState();
}

class _CaptureCameraPageState extends State<CaptureCameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _permissionDenied = false;
  bool _capturing = false;

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
        setState(() => _error = 'No camera is available on this device.');
        return;
      }

      final description = cameras.firstWhere(
        (camera) => camera.lensDirection == widget.lensDirection,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        description,
        ResolutionPreset.high,
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
            ? 'Camera access has not been granted. The app needs the camera '
                  'to photograph your document and your face. Enable the '
                  'Camera permission for eKYC Demo in your device settings, '
                  'then try again.'
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
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file);
    } on CameraException {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _error = 'The photo could not be taken. Please try again.';
      });
    }
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
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
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
        child: CircularProgressIndicator(color: BrandColors.onPrimary),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _FullScreenPreview(controller: controller),
        CustomPaint(
          painter: _GuideOverlayPainter(
            guide: widget.guide,
            aspectRatio: widget.guideAspectRatio,
          ),
        ),
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
            child: const Text('Go back'),
          ),
        ],
      ),
    );
  }
}

class _GuideOverlayPainter extends CustomPainter {
  const _GuideOverlayPainter({required this.guide, required this.aspectRatio});

  final CaptureGuide guide;
  final double aspectRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = BrandColors.primary;

    final Path hole;
    if (guide == CaptureGuide.idCard) {
      final width = size.width * 0.88;
      final height = width / aspectRatio;
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.42),
        width: width,
        height: height,
      );
      hole = Path()
        ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));
    } else {
      final width = size.width * 0.68;
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.40),
        width: width,
        height: width * 1.35,
      );
      hole = Path()..addOval(rect);
    }

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
      oldDelegate.guide != guide || oldDelegate.aspectRatio != aspectRatio;
}
