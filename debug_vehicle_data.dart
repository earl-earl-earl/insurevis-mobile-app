import 'package:flutter/material.dart';
import 'lib/services/claims_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test creating a claim with vehicle data
  final testClaim = await ClaimsService.createClaim(
    userId: 'test-user-id',
    incidentDate: DateTime.now(),
    incidentLocation: 'Test Location',
    incidentDescription: 'Test Description',
    vehicleMake: 'Toyota',
    vehicleModel: 'Camry',
    vehicleYear: 2020,
    vehiclePlateNumber: 'ABC123',
    estimatedDamageCost: 5000.0,
  );

  if (testClaim != null) {
    print('Claim created successfully:');
    print('ID: ${testClaim.id}');
    print('Vehicle Make: ${testClaim.vehicleMake}');
    print('Vehicle Model: ${testClaim.vehicleModel}');
    print('Vehicle Year: ${testClaim.vehicleYear}');
    print('Plate Number: ${testClaim.vehiclePlateNumber}');
  } else {
    print('Failed to create claim');
  }
}
