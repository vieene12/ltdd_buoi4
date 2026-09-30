import 'package:flutter/material.dart';

import 'InformationScreen.dart';
import 'TemperatureConverterScreen.dart';
import 'UnitConverterScreen.dart';
import 'alarm_screen.dart';
import 'translation_screen.dart';
import 'team_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    TemperatureConverterScreen(),
    UnitConverterScreen(),
    InformationScreen(),
    AlarmScreen(),
    TranslationScreen(),
    TeamScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack giữ lại dữ liệu đã nhập khi người dùng chuyển tab.
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.thermostat),
            label: 'Nhiệt độ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Đơn vị',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Báo thức'),
          BottomNavigationBarItem(icon: Icon(Icons.translate), label: 'Dịch'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Nhóm'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
