import 'package:flutter/material.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  final TextEditingController _controller = TextEditingController();
  String _result = 'Kết quả sẽ hiển thị ở đây';
  bool _isMetersToFeet = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _convertUnits() {
    final input = double.tryParse(_controller.text.replaceAll(',', '.'));

    setState(() {
      if (input == null) {
        _result = 'Vui lòng nhập một số hợp lệ';
      } else if (_isMetersToFeet) {
        _result = '${(input * 3.28084).toStringAsFixed(2)} ft';
      } else {
        _result = '${(input / 3.28084).toStringAsFixed(2)} m';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chuyển đổi đơn vị đo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment(value: true, label: Text('Mét sang feet')),
                ButtonSegment(value: false, label: Text('Feet sang mét')),
              ],
              selected: <bool>{_isMetersToFeet},
              onSelectionChanged: (Set<bool> selection) {
                setState(() => _isMetersToFeet = selection.first);
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Nhập giá trị',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(_result, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _convertUnits,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Chuyển đổi'),
            ),
          ],
        ),
      ),
    );
  }
}
