import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android declares offline LAN discovery and QR permissions', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    for (final permission in [
      'android.permission.INTERNET',
      'android.permission.ACCESS_NETWORK_STATE',
      'android.permission.ACCESS_WIFI_STATE',
      'android.permission.CHANGE_WIFI_STATE',
      'android.permission.CHANGE_WIFI_MULTICAST_STATE',
      'android.permission.NEARBY_WIFI_DEVICES',
      'android.permission.CAMERA',
    ]) {
      expect(manifest, contains(permission), reason: permission);
    }
    expect(
      manifest,
      contains('android:usesPermissionFlags="neverForLocation"'),
    );
    expect(manifest, contains('android.hardware.camera'));
    expect(manifest, contains('android:required="false"'));
  });

  test('iOS declares local network, Bonjour, camera, and 60 FPS support', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(plist, contains('<key>NSLocalNetworkUsageDescription</key>'));
    expect(plist, contains('<key>NSBonjourServices</key>'));
    expect(plist, contains('<string>_trigrid._tcp</string>'));
    expect(plist, contains('<key>NSCameraUsageDescription</key>'));
    expect(plist, contains('<key>CADisableMinimumFrameDurationOnPhone</key>'));
    expect(plist, contains('<true/>'));
  });

  test('LAN discovery and Android runtime permission paths are wired', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final discovery = File(
      'lib/core/network/discovery/lan_discovery_service.dart',
    ).readAsStringSync();
    final permissionService = File(
      'lib/services/permissions/lan_permission_service.dart',
    ).readAsStringSync();

    expect(pubspec, contains('nsd:'));
    expect(discovery, contains("bonjourServiceType = '_trigrid._tcp'"));
    expect(discovery, contains('nsd.startDiscovery'));
    expect(discovery, contains('RawDatagramSocket.bind'));
    expect(permissionService, contains('Permission.nearbyWifiDevices'));
  });

  test('mobile projects keep supported toolchain baselines', () {
    final androidBuild = File(
      'android/app/build.gradle.kts',
    ).readAsStringSync();
    final xcodeProject = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    expect(androidBuild, contains('JavaVersion.VERSION_17'));
    expect(androidBuild, contains('targetSdk = flutter.targetSdkVersion'));
    expect(xcodeProject, contains('IPHONEOS_DEPLOYMENT_TARGET = 13.0;'));
    expect(xcodeProject, contains('SWIFT_VERSION = 5.0;'));
  });
}
