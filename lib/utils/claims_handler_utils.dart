import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:insurevis/models/insurevis_models.dart';
import 'package:insurevis/services/claims_service.dart';
import 'package:insurevis/services/supabase_service.dart';
import 'package:insurevis/utils/claims_cache_utils.dart';

/// Sort options for claims list
enum SortOption {
  dateNewest,
  dateOldest,
  amountHighest,
  amountLowest,
  statusAZ,
  statusZA,
  claimNumberAZ,
  claimNumberZA,
}

/// Utilities for handling claims operations
class ClaimsHandlerUtils {
  /// Sync with server and update cache
  static Future<List<ClaimModel>?> syncWithServer() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        return null;
      }

      final claims = await ClaimsService.getUserClaims(user.id);

      // Save to cache
      await ClaimsCacheUtils.saveToCache(claims);

      if (kDebugMode) print('Synced ${claims.length} claims from server');
      return claims;
    } catch (e) {
      if (kDebugMode) print('Sync claims error: $e');
      return null;
    }
  }

  /// Setup real-time updates for claims
  static StreamSubscription<List<Map<String, dynamic>>>? setupRealtimeUpdates(
    String userId,
    void Function(List<Map<String, dynamic>>) onData,
  ) {
    try {
      final subscription = SupabaseService.client
          .from('claims')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .listen(onData);

      if (kDebugMode) print('Real-time updates enabled for claims');
      return subscription;
    } catch (e) {
      if (kDebugMode) print('Error setting up real-time updates: $e');
      return null;
    }
  }

  /// Apply search query to claims list
  static List<ClaimModel> applyQuery(String query, List<ClaimModel> claims) {
    final lower = query.trim().toLowerCase();
    if (lower.isEmpty) return claims;
    return claims.where((c) {
      return c.claimNumber.toLowerCase().contains(lower) ||
          c.status.toLowerCase().contains(lower) ||
          c.incidentDescription.toLowerCase().contains(lower) ||
          c.incidentLocation.toLowerCase().contains(lower);
    }).toList();
  }

  /// Apply sorting to claims list
  static List<ClaimModel> applySorting(
    List<ClaimModel> claims,
    SortOption sortOption,
  ) {
    final sortedClaims = List<ClaimModel>.from(claims);

    switch (sortOption) {
      case SortOption.dateNewest:
        sortedClaims.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SortOption.dateOldest:
        sortedClaims.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case SortOption.amountHighest:
        sortedClaims.sort(
          (a, b) => (b.estimatedDamageCost ?? 0).compareTo(
            a.estimatedDamageCost ?? 0,
          ),
        );
        break;
      case SortOption.amountLowest:
        sortedClaims.sort(
          (a, b) => (a.estimatedDamageCost ?? 0).compareTo(
            b.estimatedDamageCost ?? 0,
          ),
        );
        break;
      case SortOption.statusAZ:
        sortedClaims.sort((a, b) => a.status.compareTo(b.status));
        break;
      case SortOption.statusZA:
        sortedClaims.sort((a, b) => b.status.compareTo(a.status));
        break;
      case SortOption.claimNumberAZ:
        sortedClaims.sort((a, b) => a.claimNumber.compareTo(b.claimNumber));
        break;
      case SortOption.claimNumberZA:
        sortedClaims.sort((a, b) => b.claimNumber.compareTo(a.claimNumber));
        break;
    }

    return sortedClaims;
  }

  /// Apply filters and sorting to claims list
  static List<ClaimModel> applyFiltersAndSort(
    List<ClaimModel> allClaims,
    String query,
    SortOption sortOption,
  ) {
    final queriedClaims = applyQuery(query, allClaims);
    return applySorting(queriedClaims, sortOption);
  }

  /// Generate demo claims for non-authenticated users
  static List<ClaimModel> generateDemoClaims(dynamic demoUser) {
    final now = DateTime.now();

    return [
      ClaimModel(
        id: 'demo-claim-1',
        userId: demoUser.id ?? 'demo_user',
        claimNumber: 'CLM-DEMO-001',
        incidentDate: now.subtract(const Duration(days: 3)),
        incidentLocation: 'Demo City',
        incidentDescription: 'Minor bumper scratch in demo',
        vehicleMake: 'DemoMake',
        vehicleModel: 'DemoModel',
        vehicleYear: 2018,
        vehiclePlateNumber: 'DEMO-001',
        estimatedDamageCost: 1200.0,
        status: 'draft',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      ClaimModel(
        id: 'demo-claim-2',
        userId: demoUser.id ?? 'demo_user',
        claimNumber: 'CLM-DEMO-002',
        incidentDate: now.subtract(const Duration(days: 10)),
        incidentLocation: 'Demo District',
        incidentDescription: 'Windshield chip (demo)',
        vehicleMake: 'DemoMake',
        vehicleModel: 'DemoModel',
        vehicleYear: 2020,
        vehiclePlateNumber: 'DEMO-002',
        estimatedDamageCost: 4500.0,
        status: 'submitted',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 9)),
      ),
      ClaimModel(
        id: 'demo-claim-3',
        userId: demoUser.id ?? 'demo_user',
        claimNumber: 'CLM-DEMO-003',
        incidentDate: now.subtract(const Duration(days: 30)),
        incidentLocation: 'Demo Suburb',
        incidentDescription: 'Demo rear-end collision, small',
        vehicleMake: 'DemoMake',
        vehicleModel: 'DemoModel',
        vehicleYear: 2016,
        vehiclePlateNumber: 'DEMO-003',
        estimatedDamageCost: 15200.0,
        status: 'approved',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
