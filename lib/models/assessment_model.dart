enum AssessmentStatus { processing, completed, failed }

class Assessment {
  final String id;
  final String imagePath;
  final DateTime timestamp;
  AssessmentStatus status;
  Map<String, dynamic>? results;
  String? errorMessage;
  String? apiResponse; // Add this property

  Assessment({
    required this.id,
    required this.imagePath,
    required this.timestamp,
    this.status = AssessmentStatus.processing,
    this.results,
    this.errorMessage,
    this.apiResponse, // Add this to constructor
  });

  // Create a copy of the assessment with updated properties
  Assessment copyWith({
    String? id,
    String? imagePath,
    DateTime? timestamp,
    AssessmentStatus? status,
    Map<String, dynamic>? results,
    String? errorMessage,
    String? apiResponse, // Add this to copyWith
  }) {
    return Assessment(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      results: results ?? this.results,
      errorMessage: errorMessage ?? this.errorMessage,
      apiResponse: apiResponse ?? this.apiResponse, // Include in copyWith
    );
  }

  // For debugging/logging
  @override
  String toString() {
    return 'Assessment{id: $id, status: $status, timestamp: $timestamp}';
  }
}
