import 'package:flutter_test/flutter_test.dart';
import 'package:insurevis/services/pricing_service.dart';

void main() {
  test('should format "Back-door" to "Back Door" and find pricing', () async {
    // Test the specific case from your damage detection API
    final originalPartName = 'Back-door';
    final formattedPartName = formatDamagedPartForApi(originalPartName);

    print('Original: "$originalPartName"');
    print('Formatted: "$formattedPartName"');

    expect(formattedPartName, equals('Back Door'));

    // Now test if the formatted name finds pricing in the API
    try {
      final pricingData = await PricingService.getPricingForDamagedPart(
        formattedPartName,
      );

      if (pricingData != null) {
        print('✅ Successfully found pricing for formatted part name:');
        print('   Source: ${pricingData['source']}');
        print('   Part name: ${pricingData['part_name']}');
        print('   Labor fee: ₱${pricingData['labor_fee']}');
        print('   Final price: ₱${pricingData['final_price']}');

        expect(pricingData['part_name'], equals('Back Door'));
        expect(pricingData['labor_fee'], equals(2000.0));
        expect(pricingData['final_price'], equals(8800.0));
      } else {
        print('❌ No pricing found for formatted part name');
        fail('Expected to find pricing for "Back Door"');
      }
    } catch (e) {
      print('❌ Error getting pricing: $e');
      fail('Error getting pricing: $e');
    }
  });
}

// Copy of the formatting function
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
