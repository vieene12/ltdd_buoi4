import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

  static const String _phoneNumber = '0356781111';

  Future<void> _makePhoneCall(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: _phoneNumber);
    await _launchExternal(
      context,
      phoneUri,
      errorMessage: 'Thiết bị không hỗ trợ gọi điện.',
    );
  }

  Future<void> _openYouTube(BuildContext context) async {
    final bool openedApp = await _tryLaunch(
      Uri.parse('youtube://www.youtube.com/'),
    );

    if (openedApp) return;
    if (!context.mounted) return;

    await _launchExternal(
      context,
      Uri.parse('https://www.youtube.com/'),
      errorMessage: 'Không thể mở YouTube.',
    );
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> _launchExternal(
    BuildContext context,
    Uri uri, {
    required String errorMessage,
  }) async {
    final bool launched = await _tryLaunch(uri);
    if (launched || !context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông Tin Cá Nhân')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        children: <Widget>[
          const CircleAvatar(radius: 64, child: Icon(Icons.person, size: 72)),
          const SizedBox(height: 16),
          const Text(
            'Mai Hà Thanh Vy',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Khoa Công nghệ Thông tin',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          const _InfoCard(icon: Icons.phone, text: '0332753723'),
          const _InfoCard(icon: Icons.email, text: 'maivy0822@gmail.com'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _makePhoneCall(context),
            icon: const Icon(Icons.call),
            label: const Text('Gọi điện'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _openYouTube(context),
            icon: const Icon(Icons.play_circle_fill),
            label: const Text('Mở YouTube'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(leading: Icon(icon), title: Text(text)),
    );
  }
}
