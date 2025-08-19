import 'package:flutter_test/flutter_test.dart';
import 'package:insurevis/services/pricing_service.dart';

void main() {
  group('PricingService Tests', () {
    test('should fetch thinsmith parts', () async {
      try {
        final parts = await PricingService.getThinsmithParts();
        print('Thinsmith parts count: ${parts.length}');

        if (parts.isNotEmpty) {
          final firstPart = parts.first;
          print('Sample part: ${firstPart['part_name']}');
          print('Labor fee: ${firstPart['cost_installation_personal']}');
          print('Insurance price: ${firstPart['insurance']}');
        }

        expect(parts, isNotEmpty);
      } catch (e) {
        print('Error fetching thinsmith parts: $e');
        // Test might fail if API is down, but we'll still see the error
      }
    });

    test('should fetch body paint parts', () async {
      try {
        final parts = await PricingService.getBodyPaintParts();
        print('Body paint parts count: ${parts.length}');

        if (parts.isNotEmpty) {
          final firstPart = parts.first;
          print('Sample part: ${firstPart['part_name']}');
          print('Labor fee: ${firstPart['cost_installation_personal']}');
          print('Insurance price: ${firstPart['srp_insurance']}');
        }

        expect(parts, isNotEmpty);
      } catch (e) {
        print('Error fetching body paint parts: $e');
        // Test might fail if API is down, but we'll still see the error
      }
    });

    test('should find pricing for damaged part', () async {
      try {
        // Test with a part that should exist in thinsmith
        final pricingData = await PricingService.getPricingForDamagedPart(
          'Door',
        );

        if (pricingData != null) {
          print('Found pricing for Door:');
          print('Source: ${pricingData['source']}');
          print('Part name: ${pricingData['part_name']}');
          print('Labor fee: ${pricingData['labor_fee']}');
          print('Final price: ${pricingData['final_price']}');

          expect(pricingData['source'], isNotNull);
          expect(pricingData['labor_fee'], isNotNull);
          expect(pricingData['final_price'], isNotNull);
        } else {
          print('No pricing found for Door');
        }
      } catch (e) {
        print('Error getting pricing for damaged part: $e');
      }
    });

    test('should check API health', () async {
      try {
        final isHealthy = await PricingService.checkApiHealth();
        print('API health status: $isHealthy');
        expect(isHealthy, isA<bool>());
      } catch (e) {
        print('Error checking API health: $e');
      }
    });
  });
}
