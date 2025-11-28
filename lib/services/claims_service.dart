// Claims Service for InsureVis
// Handles CRUD operations for claims with mandatory document references

// import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/insurevis_models.dart';

class ClaimsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new claim
  static Future<ClaimModel?> createClaim({
    required String userId,
    required DateTime incidentDate,
    required String incidentLocation,
    required String incidentDescription,
    String? vehicleMake,
    String? vehicleModel,
    int? vehicleYear,
    String? vehiclePlateNumber,
    double? estimatedDamageCost,
    List<Map<String, dynamic>>? damages,
  }) async {
    try {
      // Generate unique claim number
      final claimNumber = await _generateClaimNumber();

      final claimData = {
        'user_id': userId,
        'claim_number': claimNumber,
        'incident_date': incidentDate.toIso8601String().split('T')[0],
        'incident_location': incidentLocation,
        'incident_description': incidentDescription,
        'vehicle_make': vehicleMake,
        'vehicle_model': vehicleModel,
        'vehicle_year': vehicleYear,
        'vehicle_plate_number': vehiclePlateNumber,
        'estimated_damage_cost': estimatedDamageCost,
        // store damages payload (JSON) if provided
        // if (damages != null) 'detected_damages': jsonEncode(damages),
        // 'status': 'draft',
      };

      final response =
          await _supabase.from('claims').insert(claimData).select().single();

      return ClaimModel.fromJson(response);
    } catch (e) {
      print('Error creating claim: $e');
      return null;
    }
  }

  /// Get claims for a specific user
  static Future<List<ClaimModel>> getUserClaims(String userId) async {
    try {
      final response = await _supabase
          .from('claims')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ClaimModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching user claims: $e');
      return [];
    }
  }

  /// Get a specific claim by ID
  static Future<ClaimModel?> getClaim(String claimId) async {
    try {
      final response =
          await _supabase.from('claims').select('*').eq('id', claimId).single();

      return ClaimModel.fromJson(response);
    } catch (e) {
      print('Error fetching claim: $e');
      return null;
    }
  }

  /// Update claim status
  /// Update claim status
  static Future<bool> updateClaimStatus(String claimId, String status) async {
    try {
      await _supabase
          .from('claims')
          .update({
            'status': status,
            // FIX: Convert to UTC here too
          })
          .eq('id', claimId);

      return true;
    } catch (e) {
      print('Error updating claim status: $e');
      return false;
    }
  }

  /// Submit claim (change status from draft to submitted)
  /// Submit claim (change status from draft to submitted)
  static Future<bool> submitClaim(String claimId) async {
    try {
      await _supabase
          .from('claims')
          .update({
            'status': 'submitted',
            // FIX: Convert to UTC before stringifying
            'submitted_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', claimId);

      return true;
    } catch (e) {
      print('Error submitting claim: $e');
      return false;
    }
  }

  /// Get claims for car company verification
  static Future<List<ClaimModel>> getClaimsForCarVerification() async {
    try {
      final response = await _supabase
          .from('claims')
          .select('*')
          .eq('status', 'submitted')
          .eq('is_approved_by_car_company', false)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ClaimModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching claims for car verification: $e');
      return [];
    }
  }

  /// Get claims for insurance verification
  /// Only shows claims where car company has completed verification
  static Future<List<ClaimModel>> getClaimsForInsuranceVerification() async {
    try {
      final response = await _supabase
          .from('claims')
          .select('*')
          .eq('is_approved_by_car_company', true)
          .eq('is_approved_by_insurance_company', false)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ClaimModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching claims for insurance verification: $e');
      return [];
    }
  }

  /// Generate unique claim number
  static Future<String> _generateClaimNumber() async {
    final year = DateTime.now().year;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Format: CLM-YYYY-XXXXXX (where X is last 6 digits of timestamp)
    final shortTimestamp = timestamp.toString().substring(
      timestamp.toString().length - 6,
    );

    return 'CLM-$year-$shortTimestamp';
  }

  /// Get claim statistics for a user
  static Future<Map<String, int>> getClaimStatistics(String userId) async {
    try {
      final claims = await getUserClaims(userId);

      final stats = <String, int>{
        'total': claims.length,
        'draft': 0,
        'submitted': 0,
        'under_review': 0,
        'pending_documents': 0,
        'approved': 0,
        'rejected': 0,
      };

      for (final claim in claims) {
        stats[claim.status] = (stats[claim.status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Error fetching claim statistics: $e');
      return {'total': 0};
    }
  }
}
