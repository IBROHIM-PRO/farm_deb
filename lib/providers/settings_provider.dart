import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyEditDeleteEnabled = 'edit_delete_enabled';
  static const String _keyActivationTime = 'activation_time';
  bool _editDeleteEnabled = false; // Default to disabled
  Timer? _autoDisableTimer;

  bool get editDeleteEnabled => _editDeleteEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _editDeleteEnabled = prefs.getBool(_keyEditDeleteEnabled) ?? false;
      
      // Check if feature was activated and if 5 minutes have passed
      if (_editDeleteEnabled) {
        final activationTimeStr = prefs.getString(_keyActivationTime);
        if (activationTimeStr != null) {
          final activationTime = DateTime.parse(activationTimeStr);
          final elapsed = DateTime.now().difference(activationTime);
          
          if (elapsed.inMinutes >= 5) {
            // More than 5 minutes passed, disable it
            await setEditDeleteEnabled(false);
          } else {
            // Start timer for remaining time
            final remainingTime = const Duration(minutes: 5) - elapsed;
            _startAutoDisableTimer(remainingTime);
          }
        } else {
          // No activation time stored, disable it
          await setEditDeleteEnabled(false);
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> setEditDeleteEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEditDeleteEnabled, enabled);
      _editDeleteEnabled = enabled;
      
      // Cancel existing timer
      _autoDisableTimer?.cancel();
      
      if (enabled) {
        // Store activation time
        await prefs.setString(_keyActivationTime, DateTime.now().toIso8601String());
        // Start 5-minute timer
        _startAutoDisableTimer(const Duration(minutes: 5));
      } else {
        // Clear activation time when disabled
        await prefs.remove(_keyActivationTime);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> toggleEditDeleteEnabled() async {
    await setEditDeleteEnabled(!_editDeleteEnabled);
  }
  
  void _startAutoDisableTimer(Duration duration) {
    _autoDisableTimer?.cancel();
    _autoDisableTimer = Timer(duration, () async {
      await setEditDeleteEnabled(false);
    });
  }
  
  @override
  void dispose() {
    _autoDisableTimer?.cancel();
    super.dispose();
  }
}

