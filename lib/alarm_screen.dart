import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'alarm_service.dart';
import 'speech_service.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final SpeechService _speech = SpeechService.instance;
  late final Timer _clockTimer;

  DateTime _now = DateTime.now();
  TimeOfDay? _alarmTime;
  DateTime? _scheduledAlarm;
  List<LocaleName> _locales = const <LocaleName>[];
  String? _selectedLocaleId;
  String _recognizedWords = '';
  String _speechMessage = 'Nhấn micro và nói giờ muốn đặt.';
  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isScheduling = false;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _initializeSpeech();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (String status) {
          if (!mounted) return;
          setState(() => _isListening = status == 'listening');
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _speechMessage = 'Không nhận dạng được: ${error.errorMsg}';
          });
        },
      );
      if (!available) {
        if (mounted) {
          setState(
            () => _speechMessage = 'Thiết bị không hỗ trợ nhận dạng giọng nói.',
          );
        }
        return;
      }

      final locales = await _speech.locales();
      final systemLocale = await _speech.systemLocale();
      locales.sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      setState(() {
        _speechAvailable = true;
        _locales = locales;
        _selectedLocaleId =
            systemLocale?.localeId ??
            (locales.isEmpty ? null : locales.first.localeId);
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _speechMessage = 'Không thể khởi tạo nhận dạng giọng nói.',
        );
      }
    }
  }

  Future<void> _toggleListening() async {
    if (_speech.isListening) {
      await _speech.stop();
      return;
    }
    if (!_speechAvailable) {
      await _initializeSpeech();
      if (!_speechAvailable) return;
    }

    setState(() {
      _recognizedWords = '';
      _speechMessage = 'Đang nghe…';
      _isListening = true;
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final parsedTime = parseAlarmTime(result.recognizedWords);
        setState(() {
          _recognizedWords = result.recognizedWords;
          if (parsedTime != null) {
            _alarmTime = parsedTime;
            _speechMessage = 'Đã nhận giờ ${parsedTime.format(context)}';
          } else if (result.finalResult) {
            _speechMessage = 'Chưa tìm thấy giờ. Hãy nói ví dụ “7 giờ 30”.';
          }
        });
      },
      localeId: _selectedLocaleId,
      onStatus: (String status) {
        if (mounted) setState(() => _isListening = status == 'listening');
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _speechMessage = 'Không nhận dạng được: ${error.errorMsg}';
        });
      },
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) setState(() => _alarmTime = picked);
  }

  Future<void> _scheduleAlarm() async {
    final alarmTime = _alarmTime;
    if (alarmTime == null) {
      _showMessage('Hãy nói hoặc chọn giờ báo thức trước.');
      return;
    }

    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      alarmTime.hour,
      alarmTime.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    setState(() => _isScheduling = true);
    try {
      await AlarmService.instance.schedule(scheduled);
      if (!mounted) return;
      setState(() => _scheduledAlarm = scheduled);
      _showMessage('Đã đặt báo thức lúc ${_formatDateTime(scheduled)}.');
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isScheduling = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatClock(DateTime value) =>
      '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}:${_twoDigits(value.second)}';

  String _formatDateTime(DateTime value) =>
      '${_twoDigits(value.hour)}:${_twoDigits(value.minute)} '
      '${_twoDigits(value.day)}/${_twoDigits(value.month)}/${value.year}';

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo thức giọng nói')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Semantics(
            label: 'Giờ hiện tại',
            child: Text(
              _formatClock(_now),
              key: const Key('liveClock'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Text('Giờ hệ thống hiện tại', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (_locales.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _selectedLocaleId,
              decoration: const InputDecoration(
                labelText: 'Ngôn ngữ nhận dạng',
                border: OutlineInputBorder(),
              ),
              items: _locales
                  .map(
                    (locale) => DropdownMenuItem<String>(
                      value: locale.localeId,
                      child: Text(locale.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: _isListening
                  ? null
                  : (value) => setState(() => _selectedLocaleId = value),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 42,
                    color: _isListening ? Colors.red : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recognizedWords.isEmpty
                        ? _speechMessage
                        : _recognizedWords,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _toggleListening,
                    icon: Icon(_isListening ? Icons.stop : Icons.mic),
                    label: Text(
                      _isListening ? 'Dừng nghe' : 'Nói giờ báo thức',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.schedule),
            label: Text(
              _alarmTime == null
                  ? 'Chọn giờ thủ công'
                  : 'Giờ đã chọn: ${_alarmTime!.format(context)}',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isScheduling ? null : _scheduleAlarm,
            icon: const Icon(Icons.alarm_add),
            label: Text(_isScheduling ? 'Đang đặt…' : 'Đặt báo thức'),
          ),
          if (_scheduledAlarm != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              'Báo thức tiếp theo: ${_formatDateTime(_scheduledAlarm!)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ],
      ),
    );
  }
}

TimeOfDay? parseAlarmTime(String speech) {
  final text = speech.toLowerCase().trim();
  if (text.isEmpty) return null;

  final numericWithSeparator = RegExp(
    r'(?<!\d)([01]?\d|2[0-3])\s*(?::|h|giờ|hours?)\s*([0-5]?\d)?',
  ).firstMatch(text);
  if (numericWithSeparator != null) {
    return _buildTime(
      int.parse(numericWithSeparator.group(1)!),
      int.tryParse(numericWithSeparator.group(2) ?? '') ?? 0,
      text,
    );
  }

  final numericAfterKeyword = RegExp(
    r'(?:lúc|at|for)\s+([01]?\d|2[0-3])(?:\s+([0-5]?\d))?',
  ).firstMatch(text);
  if (numericAfterKeyword != null) {
    return _buildTime(
      int.parse(numericAfterKeyword.group(1)!),
      int.tryParse(numericAfterKeyword.group(2) ?? '') ?? 0,
      text,
    );
  }

  final marker = RegExp(r'(giờ|\bhours?\b)').firstMatch(text);
  if (marker == null) return null;
  final hour = _numberFromSuffix(text.substring(0, marker.start));
  final minute = _numberFromPrefix(text.substring(marker.end)) ?? 0;
  if (hour == null || hour > 23 || minute > 59) return null;
  return _buildTime(hour, minute, text);
}

TimeOfDay _buildTime(int hour, int minute, String text) {
  var adjustedHour = hour;
  final isPm = RegExp(r'\b(pm|chiều|tối)\b').hasMatch(text);
  final isAm = RegExp(r'\b(am|sáng)\b').hasMatch(text);
  if (isPm && adjustedHour < 12) adjustedHour += 12;
  if (isAm && adjustedHour == 12) adjustedHour = 0;
  return TimeOfDay(hour: adjustedHour, minute: minute);
}

int? _numberFromSuffix(String value) {
  final words = value
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  for (var count = 1; count <= 4 && count <= words.length; count++) {
    final parsed = _parseNumberWords(words.sublist(words.length - count));
    if (parsed != null) return parsed;
  }
  return null;
}

int? _numberFromPrefix(String value) {
  final words = value
      .replaceAll(RegExp(r'\b(phút|minutes?)\b'), '')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  for (var count = words.length < 4 ? words.length : 4; count >= 1; count--) {
    final parsed = _parseNumberWords(words.take(count).toList());
    if (parsed != null) return parsed;
  }
  return null;
}

int? _parseNumberWords(List<String> words) {
  const units = <String, int>{
    'không': 0,
    'zero': 0,
    'một': 1,
    'mốt': 1,
    'one': 1,
    'hai': 2,
    'two': 2,
    'ba': 3,
    'three': 3,
    'bốn': 4,
    'tư': 4,
    'four': 4,
    'năm': 5,
    'lăm': 5,
    'five': 5,
    'sáu': 6,
    'six': 6,
    'bảy': 7,
    'seven': 7,
    'tám': 8,
    'eight': 8,
    'chín': 9,
    'nine': 9,
    'mười': 10,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
  };
  const tens = <String, int>{
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
  };

  if (words.length == 1) {
    return int.tryParse(words.first) ?? units[words.first] ?? tens[words.first];
  }
  if (words.length == 2 && words[1] == 'mươi') {
    final first = units[words.first];
    return first == null ? null : first * 10;
  }
  if (words.length == 3 && words[1] == 'mươi') {
    final first = units[words.first];
    final last = units[words.last];
    return first == null || last == null ? null : first * 10 + last;
  }
  if (words.length == 3 && words[1] == 'mười') {
    final first = units[words.first];
    final last = units[words.last];
    return first == 1 && last != null ? 10 + last : null;
  }
  if (words.length == 2) {
    final first = tens[words.first];
    final last = units[words.last];
    return first == null || last == null ? null : first + last;
  }
  return null;
}
