import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

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

  /// Authenticate user with biometric (fingerprint/face)
  /// Returns true if authentication is successful
  Future<bool> authenticate({
    String reason = 'Пожалуйста, подтвердите свою личность',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final bool isAvailable = await this.isAvailable();
      if (!isAvailable) {
        throw Exception('Биометрическая аутентификация недоступна на этом устройстве');
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
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

