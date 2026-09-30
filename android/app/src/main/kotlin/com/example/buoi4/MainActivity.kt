package com.example.buoi4

import android.content.ActivityNotFoundException
import android.content.Intent
import android.provider.AlarmClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val alarmChannel = "com.example.buoi4/system_alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, alarmChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "setSystemAlarm") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val hour = call.argument<Int>("hour")
                val minute = call.argument<Int>("minute")
                val message = call.argument<String>("message") ?: "Báo thức từ buoi4"
                if (hour == null || minute == null) {
                    result.error("INVALID_TIME", "Thiếu giờ hoặc phút báo thức.", null)
                    return@setMethodCallHandler
                }

                val alarmIntent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                    putExtra(AlarmClock.EXTRA_HOUR, hour)
                    putExtra(AlarmClock.EXTRA_MINUTES, minute)
                    putExtra(AlarmClock.EXTRA_MESSAGE, message)
                    putExtra(AlarmClock.EXTRA_VIBRATE, true)
                    putExtra(AlarmClock.EXTRA_SKIP_UI, true)
                }

                try {
                    startActivity(alarmIntent)
                    result.success(true)
                } catch (_: ActivityNotFoundException) {
                    result.error(
                        "NO_ALARM_APP",
                        "Điện thoại không có ứng dụng Đồng hồ hỗ trợ đặt báo thức.",
                        null,
                    )
                }
            }
    }
}
