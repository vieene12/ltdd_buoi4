import 'package:flutter/material.dart';

class TemperatureConverterScreen extends StatefulWidget {
  const TemperatureConverterScreen({super.key});

  @override
  State<TemperatureConverterScreen> createState() =>
      _TemperatureConverterScreenState();
}

class _TemperatureConverterScreenState
    extends State<TemperatureConverterScreen> {
  final TextEditingController _controller = TextEditingController();
  String _result = 'Kết quả sẽ hiển thị ở đây';
  bool _isCelsiusToFahrenheit = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _convertTemperature() {
    final input = double.tryParse(_controller.text.replaceAll(',', '.'));

    setState(() {
      if (input == null) {
        _result = 'Vui lòng nhập một số hợp lệ';
      } else if (_isCelsiusToFahrenheit) {
        final value = input * 9 / 5 + 32;
        _result = '${value.toStringAsFixed(1)} °F';
      } else {
        final value = (input - 32) * 5 / 9;
        _result = '${value.toStringAsFixed(1)} °C';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chuyển đổi nhiệt độ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment(value: true, label: Text('°C sang °F')),
                ButtonSegment(value: false, label: Text('°F sang °C')),
              ],
              selected: <bool>{_isCelsiusToFahrenheit},
              onSelectionChanged: (Set<bool> selection) {
                setState(() => _isCelsiusToFahrenheit = selection.first);
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Nhập nhiệt độ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(_result, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _convertTemperature,
              icon: const Icon(Icons.thermostat),
              label: const Text('Chuyển đổi'),
            ),
          ],
        ),
      ),
    );
  }
}
