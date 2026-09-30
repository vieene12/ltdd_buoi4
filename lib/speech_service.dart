import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  SpeechService._();

  static final SpeechService instance = SpeechService._();

  final SpeechToText _speech = SpeechToText();
  void Function(String status)? _statusListener;
  void Function(SpeechRecognitionError error)? _errorListener;
  bool _initialized = false;
  bool _available = false;

  bool get isListening => _speech.isListening;

  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(SpeechRecognitionError error)? onError,
  }) async {
    _statusListener = onStatus;
    _errorListener = onError;
    if (_initialized) return _available;

    _available = await _speech.initialize(
      onStatus: (status) => _statusListener?.call(status),
      onError: (error) => _errorListener?.call(error),
    );
    _initialized = true;
    return _available;
  }

  Future<List<LocaleName>> locales() => _speech.locales();

  Future<LocaleName?> systemLocale() => _speech.systemLocale();

  Future<void> listen({
    required SpeechResultListener onResult,
    required String? localeId,
    void Function(String status)? onStatus,
    void Function(SpeechRecognitionError error)? onError,
  }) async {
    final available = await initialize(onStatus: onStatus, onError: onError);
    if (!available) return;

    _statusListener = onStatus;
    _errorListener = onError;
    await _speech.listen(
      onResult: onResult,
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();
}
