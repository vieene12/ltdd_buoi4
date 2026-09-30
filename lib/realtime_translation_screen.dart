import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class RealtimeTranslationScreen extends StatefulWidget {
  const RealtimeTranslationScreen({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  final TranslateLanguage sourceLanguage;
  final TranslateLanguage targetLanguage;

  @override
  State<RealtimeTranslationScreen> createState() =>
      _RealtimeTranslationScreenState();
}

class _RealtimeTranslationScreenState extends State<RealtimeTranslationScreen>
    with WidgetsBindingObserver {
  static const _orientations = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  final TextRecognizer _textRecognizer = TextRecognizer();
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();
  CameraController? _cameraController;
  OnDeviceTranslator? _translator;
  CameraDescription? _camera;
  bool _processing = false;
  bool _initializing = true;
  String _recognizedText = '';
  String _translatedText = '';
  String? _error;
  DateTime _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      setState(() {
        _initializing = false;
        _error = 'Dịch camera realtime chỉ hỗ trợ Android và iOS.';
      });
      return;
    }

    try {
      await _ensureModel(widget.sourceLanguage);
      await _ensureModel(widget.targetLanguage);
      _translator = OnDeviceTranslator(
        sourceLanguage: widget.sourceLanguage,
        targetLanguage: widget.targetLanguage,
      );
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('Không tìm thấy camera.');
      _camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      await _startCamera();
    } catch (_) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = 'Không thể mở camera hoặc tải mô hình dịch.';
        });
      }
    }
  }

  Future<void> _ensureModel(TranslateLanguage language) async {
    if (!await _modelManager.isModelDownloaded(language.bcpCode)) {
      await _modelManager.downloadModel(language.bcpCode);
    }
  }

  Future<void> _startCamera() async {
    final camera = _camera;
    if (camera == null) return;
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _cameraController = controller;
    await controller.initialize();
    await controller.startImageStream(_processFrame);
    if (mounted) setState(() => _initializing = false);
  }

  Future<void> _stopCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller == null) return;
    if (controller.value.isStreamingImages) await controller.stopImageStream();
    await controller.dispose();
  }

  Future<void> _processFrame(CameraImage image) async {
    final now = DateTime.now();
    if (_processing || now.difference(_lastProcessedAt).inMilliseconds < 700) {
      return;
    }
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;

    _processing = true;
    _lastProcessedAt = now;
    try {
      final recognized = await _textRecognizer.processImage(inputImage);
      final text = recognized.text.trim();
      if (text.isEmpty || text == _recognizedText) return;
      final translated = await _translator?.translateText(text) ?? '';
      if (mounted) {
        setState(() {
          _recognizedText = text;
          _translatedText = translated;
        });
      }
    } catch (_) {
      // Bỏ qua khung hình lỗi và tiếp tục xử lý khung tiếp theo.
    } finally {
      _processing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _camera;
    final controller = _cameraController;
    if (camera == null || controller == null) return null;

    final InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    } else {
      final compensation = _orientations[controller.value.deviceOrientation];
      if (compensation == null) return null;
      final rotationDegrees = camera.lensDirection == CameraLensDirection.front
          ? (camera.sensorOrientation + compensation) % 360
          : (camera.sensorOrientation - compensation + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(rotationDegrees);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888) ||
        image.planes.length != 1) {
      return null;
    }

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed &&
        _cameraController == null) {
      _startCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _textRecognizer.close();
    _translator?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;
    return Scaffold(
      appBar: AppBar(title: const Text('Dịch camera realtime')),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!),
              ),
            )
          : _initializing ||
                controller == null ||
                !controller.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CameraPreview(controller),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 260),
                    padding: const EdgeInsets.all(16),
                    color: Colors.black.withValues(alpha: 0.72),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text(
                            'Văn bản nhận dạng',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            _recognizedText.isEmpty
                                ? 'Đưa camera về phía văn bản…'
                                : _recognizedText,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const Divider(color: Colors.white38),
                          const Text(
                            'Bản dịch realtime',
                            style: TextStyle(color: Colors.lightBlueAccent),
                          ),
                          Text(
                            _translatedText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
