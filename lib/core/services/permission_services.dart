import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  const PermissionService._();

  static Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> isMicGranted() => Permission.microphone.isGranted;

  static Future<bool> isNotificationGranted() =>
      Permission.notification.isGranted;

  static Future<void> openSettings() => openAppSettings();
}
