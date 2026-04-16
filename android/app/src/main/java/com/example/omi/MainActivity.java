package com.example.omi;

import android.content.Intent;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.omi/alarm_service";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    Intent intent = new Intent(getApplicationContext(), AlarmForegroundService.class);

                    switch (call.method) {
                        case "startAlarm":
                            intent.setAction("START");
                            ContextCompat.startForegroundService(getApplicationContext(), intent);
                            result.success(null);
                            break;
                        case "stopAlarm":
                            intent.setAction("STOP");
                            getApplicationContext().startService(intent);
                            result.success(null);
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                });
    }
}
