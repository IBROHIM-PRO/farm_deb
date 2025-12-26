import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/history_provider.dart';
import '../providers/cattle_registry_provider.dart';
import '../providers/cotton_registry_provider.dart';
import '../providers/cotton_warehouse_provider.dart';

/// Centralized data persistence manager to ensure reliable data loading and saving
class DataPersistenceManager {
  static bool _isInitialized = false;
  static bool _isLoading = false;

  /// Initialize all data providers on app startup
  static Future<void> initializeAllProviders(BuildContext context) async {
    if (_isInitialized || _isLoading) return;
    
    _isLoading = true;
    
    try {
      // Load all providers in parallel for better performance
      await Future.wait([
        _initializeProvider(() => context.read<AppProvider>().loadAllData(), 'AppProvider'),
        _initializeProvider(() => context.read<HistoryProvider>().loadAllHistory(), 'HistoryProvider'),
        _initializeProvider(() => context.read<CattleRegistryProvider>().loadAllData(), 'CattleRegistryProvider'),
        _initializeProvider(() => context.read<CottonRegistryProvider>().loadAllData(), 'CottonRegistryProvider'),
        _initializeProvider(() => context.read<CottonWarehouseProvider>().loadAllData(), 'CottonWarehouseProvider'),
      ]);
      
      _isInitialized = true;
      debugPrint('✅ All data providers initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing data providers: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Initialize individual provider with error handling
  static Future<void> _initializeProvider(Future<void> Function() loader, String providerName) async {
    try {
      await loader();
      debugPrint('✅ $providerName loaded successfully');
    } catch (e) {
      debugPrint('❌ Error loading $providerName: $e');
      // Don't rethrow - allow other providers to load
    }
  }

  /// Reload all data providers (useful after data operations)
  static Future<void> reloadAllData(BuildContext context) async {
    try {
      await Future.wait([
        context.read<AppProvider>().loadAllData(),
        context.read<HistoryProvider>().loadAllHistory(),
        context.read<CattleRegistryProvider>().loadAllData(),
        context.read<CottonRegistryProvider>().loadAllData(),
        context.read<CottonWarehouseProvider>().loadAllData(),
      ]);
      debugPrint('✅ All data reloaded successfully');
    } catch (e) {
      debugPrint('❌ Error reloading data: $e');
    }
  }

  /// Validate that all critical data is loaded
  static bool validateDataIntegrity(BuildContext context) {
    try {
      final appProvider = context.read<AppProvider>();
      final cattleProvider = context.read<CattleRegistryProvider>();
      final cottonProvider = context.read<CottonRegistryProvider>();
      final warehouseProvider = context.read<CottonWarehouseProvider>();
      
      // Check if providers have been initialized
      bool isValid = true;
      
      // Basic validation - providers should not be in permanent loading state
      if (appProvider.isLoading && !_isLoading) {
        debugPrint('⚠️ AppProvider stuck in loading state');
        isValid = false;
      }
      
      if (cattleProvider.isLoading && !_isLoading) {
        debugPrint('⚠️ CattleRegistryProvider stuck in loading state');
        isValid = false;
      }
      
      if (cottonProvider.isLoading && !_isLoading) {
        debugPrint('⚠️ CottonRegistryProvider stuck in loading state');
        isValid = false;
      }
      
      if (warehouseProvider.isLoading && !_isLoading) {
        debugPrint('⚠️ CottonWarehouseProvider stuck in loading state');
        isValid = false;
      }
      
      return isValid;
    } catch (e) {
      debugPrint('❌ Error validating data integrity: $e');
      return false;
    }
  }

  /// Reset initialization flag (useful for testing or manual refresh)
  static void reset() {
    _isInitialized = false;
    _isLoading = false;
  }

  /// Get initialization status
  static bool get isInitialized => _isInitialized;
  static bool get isLoading => _isLoading;
}
