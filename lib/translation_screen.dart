import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:image_picker/image_picker.dart';

import 'speech_service.dart';
import 'realtime_translation_screen.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  static const _languages = <TranslateLanguage, String>{
    TranslateLanguage.vietnamese: 'Tiếng Việt',
    TranslateLanguage.english: 'English',
    TranslateLanguage.french: 'Français',
    TranslateLanguage.german: 'Deutsch',
    TranslateLanguage.spanish: 'Español',
    TranslateLanguage.italian: 'Italiano',
    TranslateLanguage.japanese: '日本語',
    TranslateLanguage.korean: '한국어',
    TranslateLanguage.chinese: '中文',
  };

  final TextEditingController _sourceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  final SpeechService _speech = SpeechService.instance;
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  TranslateLanguage _sourceLanguage = TranslateLanguage.vietnamese;
  TranslateLanguage _targetLanguage = TranslateLanguage.english;
  String _translatedText = '';
  String? _capturedImagePath;
  bool _isBusy = false;
  bool _isListening = false;

  @override
  void dispose() {
    _sourceController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _translateText() async {
    final text = _sourceController.text.trim();
    if (text.isEmpty) {
      _showMessage('Hãy nhập, nói hoặc chụp văn bản cần dịch.');
      return;
    }

    setState(() => _isBusy = true);
    OnDeviceTranslator? translator;
    try {
      await _ensureModel(_sourceLanguage);
      await _ensureModel(_targetLanguage);
      translator = OnDeviceTranslator(
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      );
      final result = await translator.translateText(text);
      if (mounted) setState(() => _translatedText = result);
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Không thể dịch. Hãy kiểm tra kết nối để tải mô hình ML Kit.',
        );
      }
    } finally {
      await translator?.close();
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _ensureModel(TranslateLanguage language) async {
    final code = language.bcpCode;
    if (!await _modelManager.isModelDownloaded(code)) {
      await _modelManager.downloadModel(code);
    }
  }

  Future<void> _toggleSpeech() async {
    if (_speech.isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    try {
      final available = await _speech.initialize(
        onStatus: _handleSpeechStatus,
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
            _showMessage('Lỗi nhận dạng giọng nói: ${error.errorMsg}');
          }
        },
      );
      if (!available) {
        _showMessage('Thiết bị không hỗ trợ nhận dạng giọng nói.');
        return;
      }

      final locales = await _speech.locales();
      final languageCode = _sourceLanguage.bcpCode.toLowerCase();
      String? localeId;
      for (final locale in locales) {
        if (locale.localeId.toLowerCase().startsWith(languageCode)) {
          localeId = locale.localeId;
          break;
        }
      }

      if (!mounted) return;
      setState(() => _isListening = true);
      await _speech.listen(
        localeId: localeId,
        onStatus: _handleSpeechStatus,
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
            _showMessage('Lỗi nhận dạng giọng nói: ${error.errorMsg}');
          }
        },
        onResult: (result) async {
          _sourceController.text = result.recognizedWords;
          if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
            await _translateText();
          }
        },
      );
    } catch (_) {
      if (mounted) _showMessage('Không thể khởi động micro.');
    }
  }

  void _handleSpeechStatus(String status) {
    if (mounted) setState(() => _isListening = status == 'listening');
  }

  Future<void> _captureAndTranslate() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (image == null) return;

      if (mounted) {
        setState(() {
          _isBusy = true;
          _capturedImagePath = image.path;
        });
      }
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      _sourceController.text = recognizedText.text;
      if (recognizedText.text.trim().isEmpty) {
        if (mounted) _showMessage('ML Kit không tìm thấy văn bản trong ảnh.');
        return;
      }
      await _translateText();
    } catch (_) {
      if (mounted) _showMessage('Không thể chụp hoặc đọc văn bản từ ảnh.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _swapLanguages() {
    setState(() {
      final oldSource = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = oldSource;
      final oldSourceText = _sourceController.text;
      _sourceController.text = _translatedText;
      _translatedText = oldSourceText;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openRealtimeTranslation() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RealtimeTranslationScreen(
          sourceLanguage: _sourceLanguage,
          targetLanguage: _targetLanguage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dropdownItems = _languages.entries
        .map(
          (entry) => DropdownMenuItem<TranslateLanguage>(
            value: entry.key,
            child: Text(entry.value),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Dịch bằng ML Kit')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<TranslateLanguage>(
                  key: ValueKey(_sourceLanguage),
                  initialValue: _sourceLanguage,
                  decoration: const InputDecoration(
                    labelText: 'Ngôn ngữ nguồn',
                  ),
                  items: dropdownItems,
                  onChanged: (value) {
                    if (value != null) setState(() => _sourceLanguage = value);
                  },
                ),
              ),
              IconButton(
                onPressed: _swapLanguages,
                tooltip: 'Đổi ngôn ngữ',
                icon: const Icon(Icons.swap_horiz),
              ),
              Expanded(
                child: DropdownButtonFormField<TranslateLanguage>(
                  key: ValueKey(_targetLanguage),
                  initialValue: _targetLanguage,
                  decoration: const InputDecoration(labelText: 'Ngôn ngữ đích'),
                  items: dropdownItems,
                  onChanged: (value) {
                    if (value != null) setState(() => _targetLanguage = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sourceController,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Văn bản cần dịch',
              hintText: 'Nhập văn bản hoặc dùng micro/camera',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _isBusy ? null : _translateText,
                icon: const Icon(Icons.translate),
                label: const Text('Dịch văn bản'),
              ),
              OutlinedButton.icon(
                onPressed: _isBusy ? null : _toggleSpeech,
                icon: Icon(_isListening ? Icons.stop : Icons.mic),
                label: Text(_isListening ? 'Dừng nghe' : 'Nói và dịch'),
              ),
              OutlinedButton.icon(
                onPressed: _isBusy ? null : _captureAndTranslate,
                icon: const Icon(Icons.document_scanner),
                label: const Text('Chụp ảnh và dịch'),
              ),
              OutlinedButton.icon(
                onPressed: _isBusy ? null : _openRealtimeTranslation,
                icon: const Icon(Icons.videocam),
                label: const Text('Dịch camera realtime'),
              ),
            ],
          ),
          if (_isBusy) ...const <Widget>[
            SizedBox(height: 16),
            LinearProgressIndicator(),
            SizedBox(height: 8),
            Text('Đang xử lý bằng Google ML Kit…', textAlign: TextAlign.center),
          ],
          if (_capturedImagePath != null) ...<Widget>[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_capturedImagePath!),
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text('Kết quả', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            key: const Key('translationResult'),
            constraints: const BoxConstraints(minHeight: 100),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              _translatedText.isEmpty
                  ? 'Bản dịch sẽ hiển thị tại đây.'
                  : _translatedText,
            ),
          ),
        ],
      ),
    );
  }
}
