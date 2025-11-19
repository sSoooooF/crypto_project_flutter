import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  Future<bool> isAvailable() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Get the primary biometric type available on the device
  /// Returns 'Face ID' on iOS, 'Fingerprint' on Android, or 'Biometric' as fallback
  Future<String> getBiometricTypeName() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return 'Fingerprint';
      } else if (availableBiometrics.contains(BiometricType.strong)) {
        return Platform.isIOS ? 'Face ID' : 'Fingerprint';
      } else if (availableBiometrics.contains(BiometricType.weak)) {
        return Platform.isIOS ? 'Face ID' : 'Fingerprint';
      }
      return Platform.isIOS ? 'Face ID' : 'Fingerprint';
    } catch (e) {
      return Platform.isIOS ? 'Face ID' : 'Fingerprint';
    }
  }

  /// Get localized biometric name for UI
  Future<String> getLocalizedBiometricName() async {
    final type = await getBiometricTypeName();
    if (type == 'Face ID') {
      return 'Face ID';
    } else {
      return 'отпечаток пальца';
    }
  }

  /// Authenticate user with biometric (fingerprint/face)
  /// Returns true if authentication is successful
  Future<bool> authenticate({
    String? reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final bool isAvailable = await this.isAvailable();
      if (!isAvailable) {
        throw Exception('Биометрическая аутентификация недоступна на этом устройстве');
      }

      // Use platform-appropriate reason if not provided
      final String authReason = reason ?? 
        (Platform.isIOS 
          ? 'Используйте Face ID для подтверждения'
          : 'Используйте отпечаток пальца для подтверждения');

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: authReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true, // Only use biometric, not device credentials
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric authentication error: $e');
      return false;
    } catch (e) {
      print('Error during biometric authentication: $e');
      return false;
    }
  }

  /// Stop authentication (if in progress)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      print('Error stopping authentication: $e');
    }
  }
}

