import 'package:flutter/services.dart';

class CameraKitService {
  static const MethodChannel _channel =
      MethodChannel('com.example.vton_auth/camerakit');

  static Future<void> openCameraKit({
    String lensGroupId = '12433cb9-95e5-4ecc-a9b4-9cbad9b43e7b',
    String lensId = '2ce6c480-9472-4b71-8451-da1e33f06a59',
  }) async {
    try {
      await _channel.invokeMethod<void>('openCameraKit', <String, String>{
        'lensGroupId': lensGroupId,
        'lensId': lensId,
      });
    } on PlatformException catch (e) {
      throw Exception('CameraKit error: ${e.message}');
    }
  }
}
