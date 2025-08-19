void main() {
  // Test the formatting function
  print('Testing damaged part name formatting:');

  // Test cases that match what we expect from damage detection API
  final testCases = {
    'Back-door': 'Back Door',
    'front-bumper': 'Front Bumper',
    'side_mirror': 'Side Mirror',
    'tail-lamp': 'Tail Lamp',
    'sliding-door': 'Sliding Door',
    'windshield': 'Windshield',
    'HOOD': 'Hood',
    'door': 'Door',
    'front-grille': 'Front Grille',
    'head-lamp': 'Head Lamp',
  };

  for (final entry in testCases.entries) {
    final formatted = formatDamagedPartForApi(entry.key);
    final expected = entry.value;
    final match = formatted == expected ? '✅' : '❌';
    print('$match "${entry.key}" -> "$formatted" (expected: "$expected")');
  }
}

// Copy of the formatting function from the result screen
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
