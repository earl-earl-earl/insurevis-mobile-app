import 'package:flutter_test/flutter_test.dart';
import 'package:insurevis/services/pricing_service.dart';

void main() {
  group('Damage Detection to API Integration', () {
    test(
      'should handle complete flow from damage detection to pricing display',
      () async {
        // Simulate the damage detection API response format
        final damageDetectionResponse = {
          "overall_severity": "moderate",
          "damages": [
            {
              "damage_type": "Dent",
              "confidence": 0.8290035724639893,
              "damaged_part":
                  "Back-door", // This is what comes from your damage detection API
              "bounding_box": [155, 61, 565, 291],
            },
          ],
        };

        print('🔍 Damage Detection API Response:');
        final damages = damageDetectionResponse['damages'] as List;
        final firstDamage = damages[0] as Map<String, dynamic>;
        print('   Damaged Part: "${firstDamage['damaged_part']}"');

        // Extract the damaged part
        final originalDamagedPart = firstDamage['damaged_part'] as String;

        // Format it for your pricing API
        final formattedPart = formatDamagedPartForApi(originalDamagedPart);
        print('🔧 Formatted for Pricing API: "$formattedPart"');

        // Get pricing from your API
        final pricing = await PricingService.getPricingForDamagedPart(
          formattedPart,
        );

        if (pricing != null) {
          print('💰 Pricing Found:');
          print('   Part Name: ${pricing['part_name']}');
          print('   Source: ${pricing['source']}');
          print('   Labor Fee: ₱${pricing['labor_fee']}');
          print('   Final Price: ₱${pricing['final_price']}');

          // Verify the pricing matches what we expect for Back Door
          expect(pricing['part_name'], equals('Back Door'));
          expect(pricing['source'], equals('thinsmith'));
          expect(pricing['labor_fee'], equals(2000.0));
          expect(pricing['final_price'], equals(8800.0));

          print('✅ Complete integration working successfully!');
        } else {
          fail('❌ No pricing found for formatted part');
        }
      },
    );

    test('should handle multiple damage parts formatting', () async {
      final multipleDamages = [
        "Back-door",
        "front-bumper",
        "side-mirror",
        "windshield",
      ];

      print('🔍 Testing multiple damage parts:');

      for (final damagedPart in multipleDamages) {
        final formatted = formatDamagedPartForApi(damagedPart);
        final pricing = await PricingService.getPricingForDamagedPart(
          formatted,
        );

        final status = pricing != null ? '✅' : '❌';
        final price =
            pricing != null ? '₱${pricing['final_price']}' : 'Not found';

        print('   $status "$damagedPart" -> "$formatted" -> $price');
      }
    });
  });
}

// Helper function to format damaged part names
String formatDamagedPartForApi(String partName) {
  if (partName.isEmpty) return partName;

  // Replace hyphens with spaces and handle common variations
  String formatted = partName.replaceAll('-', ' ').replaceAll('_', ' ').trim();

  // Convert to title case (first letter of each word capitalized)
  List<String> words = formatted.split(' ');
  List<String> capitalizedWords =
      words.map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).toList();

  return capitalizedWords.join(' ');
}
