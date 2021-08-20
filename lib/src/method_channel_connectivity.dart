// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:connectivity/connectivity_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'utils.dart';

/// An implementation of [ConnectivityPlatform] that uses method channels.
class MethodChannelConnectivity extends ConnectivityPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  MethodChannel methodChannel =
      MethodChannel('plugins.flutter.io/connectivity');

  /// The event channel used to receive ConnectivityResult changes from the native platform.
  @visibleForTesting
  EventChannel eventChannel =
      EventChannel('plugins.flutter.io/connectivity_status');

  Stream<ConnectivityResult>? _onConnectivityChanged;

  static ConnectivityPlatform get _platform => ConnectivityPlatform.instance;

  /// Fires whenever the connectivity state changes.
  Stream<ConnectivityResult> get onConnectivityChanged {
    if (_onConnectivityChanged == null) {
      _onConnectivityChanged = eventChannel
          .receiveBroadcastStream()
          .map((dynamic result) => result.toString())
          .map(parseConnectivityResult);
    }
    return _onConnectivityChanged!;
  }

  @override
  Future<ConnectivityResult> checkConnectivity() {
    return _platform.checkConnectivity();
  }

  @override
  Future<String> getWifiName() async {
    String? wifiName = await methodChannel.invokeMethod<String>('wifiName');
    // as Android might return <unknown ssid>, uniforming result
    // our iOS implementation will return null
    if (wifiName == '<unknown ssid>') {
      wifiName = null;
    }
    return wifiName!;
  }

  @override
  Future<String> getWifiBSSID() async {
    String? bssid = await methodChannel.invokeMethod<String>('wifiBSSID');
    return bssid!;
  }

  @override
  Future<String> getWifiIP() async {
    String? ipAddress =
        await methodChannel.invokeMethod<String>('wifiIPAddress');
    return ipAddress!;
  }

  @override
  Future<bool> enableWifi() async {
    bool? isEnable = await methodChannel.invokeMethod<bool>('enableWifi');
    return isEnable!;
  }

  @override
  Future<bool> disableWifi() async {
    bool? isDisable = await methodChannel.invokeMethod<bool>('disableWifi');
    return isDisable!;
  }

  @override
  Future<LocationAuthorizationStatus> requestLocationServiceAuthorization({
    bool requestAlwaysLocationUsage = false,
  }) {
    // `assert(Platform.isIOS)` will prevent us from doing dart side unit testing.
    // TODO: These should noop for non-Android, instead of throwing, so people don't need to rely on dart:io for this.
    assert(!Platform.isAndroid);
    return _platform.requestLocationServiceAuthorization(
        requestAlwaysLocationUsage: false);
    /*methodChannel.invokeMethod<String>(
        'requestLocationServiceAuthorization', <bool>[
      requestAlwaysLocationUsage
    ]).then(parseLocationAuthorizationStatus);*/
  }

  @override
  Future<LocationAuthorizationStatus> getLocationServiceAuthorization() {
    // `assert(Platform.isIOS)` will prevent us from doing dart side unit testing.
    assert(!Platform.isAndroid);
    return _platform.getLocationServiceAuthorization();
    /*methodChannel
        .invokeMethod<String>('getLocationServiceAuthorization')
        .then(parseLocationAuthorizationStatus);*/
  }
}
