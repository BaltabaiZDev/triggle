import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

enum LanPermissionResult { granted, denied, permanentlyDenied }

class LanPermissionService {
  const LanPermissionService();

  Future<LanPermissionResult> ensureAccess() async {
    if (!Platform.isAndroid) {
      // iOS presents its Local Network prompt when DNS-SD or a socket first
      // touches the LAN. There is no supported preflight request API.
      return LanPermissionResult.granted;
    }
    final current = await Permission.nearbyWifiDevices.status;
    if (current.isGranted || current.isLimited) {
      return LanPermissionResult.granted;
    }
    final requested = await Permission.nearbyWifiDevices.request();
    if (requested.isGranted || requested.isLimited) {
      return LanPermissionResult.granted;
    }
    return requested.isPermanentlyDenied || requested.isRestricted
        ? LanPermissionResult.permanentlyDenied
        : LanPermissionResult.denied;
  }

  Future<bool> openSystemSettings() => openAppSettings();
}
