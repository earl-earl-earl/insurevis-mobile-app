import '../models/insurevis_models.dart';

Map<String, dynamic> buildAppealUpdates(ClaimModel claim) {
  final updates = <String, dynamic>{};

  final carRejected = claim.carCompanyStatus.toLowerCase() == 'rejected';
  final insuranceRejected = claim.status.toLowerCase() == 'rejected';

  if (carRejected && insuranceRejected) {
    updates['car_company_status'] = 'appealed';
    updates['status'] = 'appealed';
  } else if (carRejected) {
    updates['car_company_status'] = 'appealed';
  } else if (insuranceRejected) {
    updates['status'] = 'appealed';
  } else {
    // Default to claim-level appeal
    updates['status'] = 'appealed';
  }

  // Only reset the approval flags and approval notes for the company that rejected the claim.
  // For example, if car company rejected the claim, reset only its approval flag.
  if (carRejected) {
    updates['is_approved_by_car_company'] = false;
    updates['car_company_approval_notes'] = null;
  }
  if (insuranceRejected) {
    updates['is_approved_by_insurance_company'] = false;
    updates['insurance_company_approval_notes'] = null;
  }
  // Note: approval notes for the rejecting company are cleared above.
  updates['rejected_at'] = null;
  updates['updated_at'] = DateTime.now().toIso8601String();

  return updates;
}
