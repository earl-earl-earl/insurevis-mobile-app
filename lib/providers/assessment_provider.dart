import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/assessment_model.dart';

class AssessmentProvider with ChangeNotifier {
  final List<Assessment> _assessments = [];
  bool _isLoading = false;
  final Uuid _uuid = const Uuid();

  List<Assessment> get assessments => List.unmodifiable(_assessments);
  List<Assessment> get activeAssessments =>
      _assessments
          .where((a) => a.status == AssessmentStatus.processing)
          .toList();
  List<Assessment> get completedAssessments =>
      _assessments
          .where((a) => a.status == AssessmentStatus.completed)
          .toList();
  bool get isLoading => _isLoading;

  // Add a new assessment when a photo is taken or selected
  Future<Assessment> addAssessment(String imagePath) async {
    final assessment = Assessment(
      id: _uuid.v4(),
      imagePath: imagePath,
      timestamp: DateTime.now(),
    );

    _assessments.add(assessment);
    notifyListeners();

    // Simulate API call/processing
    await _processAssessment(assessment);

    return _assessments.firstWhere((a) => a.id == assessment.id);
  }

  // Process the image assessment (without mock data)
  Future<void> _processAssessment(Assessment assessment) async {
    try {
      // Simply set the status to processing - no fake data
      final index = _assessments.indexWhere((a) => a.id == assessment.id);
      if (index >= 0) {
        _assessments[index] = _assessments[index].copyWith(
          status: AssessmentStatus.processing,
        );
        notifyListeners();
      }
    } catch (e) {
      print("Error preparing assessment: $e");
      final index = _assessments.indexWhere((a) => a.id == assessment.id);
      if (index >= 0) {
        _assessments[index] = _assessments[index].copyWith(
          status: AssessmentStatus.failed,
          errorMessage: e.toString(),
        );
        notifyListeners();
      }
    }
  }

  // Clear all assessments (for testing)
  void clearAssessments() {
    _assessments.clear();
    notifyListeners();
  }

  // Add this method to the AssessmentProvider class
  Future<Assessment?> getAssessmentById(String id) async {
    try {
      // Find the assessment with the given ID
      final assessment = _assessments.firstWhere(
        (assessment) => assessment.id == id,
        orElse: () => throw Exception('Assessment not found with ID: $id'),
      );

      print('Found assessment with ID: $id');
      return assessment;
    } catch (e) {
      print('Error finding assessment: $e');
      return null;
    }
  }

  // Add this method to store real API results
  Future<void> updateAssessmentWithApiResponse(
    String assessmentId,
    String apiResponse,
  ) async {
    try {
      final index = _assessments.indexWhere((a) => a.id == assessmentId);
      if (index >= 0) {
        // Try to parse the API response as JSON
        Map<String, dynamic>? results;
        try {
          results = jsonDecode(apiResponse);
        } catch (e) {
          print("Warning: Could not parse API response as JSON: $e");
        }

        _assessments[index] = _assessments[index].copyWith(
          status: AssessmentStatus.completed,
          apiResponse: apiResponse,
          results: results,
        );
        notifyListeners();
      }
    } catch (e) {
      print("Error updating assessment with API response: $e");
    }
  }
}
