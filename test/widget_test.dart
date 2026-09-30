import 'package:buoi4/main.dart';
import 'package:buoi4/alarm_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chuyển đổi màn hình bằng BottomNavigationBar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Chuyển đổi nhiệt độ'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.swap_horiz).last);
    await tester.pumpAndSettle();
    expect(find.text('Chuyển đổi đơn vị đo'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expect(find.text('Thông Tin Cá Nhân'), findsOneWidget);
    expect(find.text('Gọi điện'), findsOneWidget);
    expect(find.text('Mở YouTube'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.alarm));
    await tester.pump();
    expect(find.text('Báo thức giọng nói'), findsOneWidget);
    expect(find.byKey(const Key('liveClock')), findsOneWidget);
    expect(find.text('Nói giờ báo thức'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.translate));
    await tester.pump();
    expect(find.text('Dịch bằng ML Kit'), findsOneWidget);
    expect(find.text('Dịch văn bản'), findsOneWidget);
    expect(find.text('Nói và dịch'), findsOneWidget);
    expect(find.text('Chụp ảnh và dịch'), findsOneWidget);
    expect(find.text('Dịch camera realtime'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.groups));
    await tester.pump();
    expect(find.text('Thông tin nhóm'), findsOneWidget);
    expect(find.text('Mai Hà Thanh Vy'), findsOneWidget);
  });

  test('phân tích giờ từ tiếng Việt và tiếng Anh', () {
    expect(
      parseAlarmTime('đặt báo thức lúc 7 giờ 30'),
      const TimeOfDay(hour: 7, minute: 30),
    );
    expect(
      parseAlarmTime('set an alarm for 8:45 pm'),
      const TimeOfDay(hour: 20, minute: 45),
    );
    expect(
      parseAlarmTime('bảy giờ ba mươi phút'),
      const TimeOfDay(hour: 7, minute: 30),
    );
  });
}
