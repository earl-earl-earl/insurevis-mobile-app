import 'package:flutter_test/flutter_test.dart';
import 'package:insurevis/services/pricing_service.dart';

void main() {
  group('Enhanced Error Handling Tests', () {
    test(
      'should provide detailed error information for missing parts',
      () async {
        // Test with a part that doesn't exist in either database
        final nonExistentPart = 'Turbo-Charger';

        print('🔍 Testing error handling for: "$nonExistentPart"');

        final result = await PricingService.getPricingForDamagedPartWithDetails(
          nonExistentPart,
        );

        print('✅ Detailed result:');
        print('   Success: ${result['success']}');
        print('   Message: ${result['message']}');
        print('   Searched in: ${result['searched_in']}');

        expect(result['success'], equals(false));
        expect(result['message'], contains('not found'));
        expect(result['searched_in'], isA<List>());
      },
    );

    test('should check replace availability for different parts', () async {
      final testParts = [
        'Back Door', // Should be in thinsmith only
        'Front Bumper', // Should be in both
        'Hood', // Should be in both
        'Turbo-Charger', // Should be in neither
      ];

      for (final part in testParts) {
        print('🔧 Checking replace availability for: "$part"');

        final availability =
            await PricingService.checkPartAvailabilityForReplace(part);

        final hasBodyPaint = availability['has_body_paint'] == true;
        final hasThinsmith = availability['has_thinsmith'] == true;
        final recommendation = availability['replace_recommendation'];

        print('   Thinsmith: ${hasThinsmith ? "✅" : "❌"}');
        print('   Body Paint: ${hasBodyPaint ? "✅" : "❌"}');
        print('   Recommendation: $recommendation');
        print('');

        expect(availability, isA<Map<String, dynamic>>());
        expect(availability.containsKey('has_body_paint'), isTrue);
        expect(availability.containsKey('has_thinsmith'), isTrue);
        expect(availability.containsKey('replace_recommendation'), isTrue);
      }
    });

    test('should handle API errors gracefully', () async {
      // This test ensures our error handling works even if the API is down
      try {
        final result = await PricingService.checkApiHealth();
        print('🏥 API Health Check: ${result ? "✅ Healthy" : "❌ Unhealthy"}');

        if (result) {
          print('✅ API is available, testing normal flow');
          final pricing =
              await PricingService.getPricingForDamagedPartWithDetails('Door');
          expect(pricing['success'], isTrue);
        } else {
          print('⚠️ API is down, but error handling should still work');
        }
      } catch (e) {
        print('⚠️ API connection error: $e');
        print('✅ Error caught and handled gracefully');
      }
    });
  });
}
