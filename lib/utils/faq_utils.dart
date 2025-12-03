class FAQUtils {
  /// Get all FAQ items
  static List<Map<String, String>> getFAQItems() {
    return [
      {
        'category': 'Getting Started',
        'question': 'How do I create an account?',
        'answer':
            'Open the app and tap Sign Up. Provide your name, email and a strong password (minimum 8 characters, upper + lower case, number and special character). The app uses Supabase for authentication. If an account with the email already exists you will be prompted to sign in instead.',
      },
      {
        'category': 'Getting Started',
        'question': 'What do I need to get started?',
        'answer':
            'You need a smartphone with a camera, internet connection, and basic vehicle information. Make sure your camera can take clear photos of your vehicle damage.',
      },
      {
        'category': 'Damage Assessment',
        'question': 'How accurate are the damage assessments?',
        'answer':
            'InsureVis produces automated AI assessments and cost estimates. Accuracy depends on image quality, number of angles provided and damage complexity. Use the report as a reliable preliminary assessment — insurers may still require a physical inspection for final claim approval.',
      },
      {
        'category': 'Damage Assessment',
        'question': 'What types of damage can be detected?',
        'answer':
            'InsureVis can detect various types of vehicle damage including dents, scratches, cracks, broken parts, paint damage, and structural damage on cars, motorcycles, and light trucks.',
      },
      {
        'category': 'Damage Assessment',
        'question': 'How long does the assessment take?',
        'answer':
            'Most damage assessments are completed within 30 seconds to 2 minutes, depending on image processing time and internet connection speed.',
      },
      {
        'category': 'Photos & Images',
        'question': 'What makes a good damage photo?',
        'answer':
            'Use good, even lighting, keep the camera steady and include multiple angles of the damaged area. Make sure the damage fills the frame enough to be clearly visible. Avoid heavy shadows, reflections and extreme zoom which can reduce analysis quality.',
      },
      {
        'category': 'Photos & Images',
        'question': 'Can I upload multiple photos?',
        'answer':
            'Yes. The app supports multi-photo assessments and the exported PDF/report will include all images submitted for that assessment. Note that individual file uploads are validated; most document/photo uploads have a 10MB per-file limit.',
      },
      {
        'category': 'Insurance Claims',
        'question': 'Can I use InsureVis reports for insurance claims?',
        'answer':
            'Yes — the app can generate detailed PDF assessment reports (summary, insurance and technical templates) that many insurers accept as preliminary documentation. Insurers may still request a physical inspection before finalising a claim.',
      },
      {
        'category': 'Insurance Claims',
        'question': 'Which insurance companies accept InsureVis reports?',
        'answer':
            'Most major insurance companies in the Philippines accept our reports including MAPFRE, Philippine AXA, Malayan Insurance, and others. Check with your specific insurer for their requirements.',
      },
      {
        'category': 'Cost Estimates',
        'question': 'How are repair costs calculated?',
        'answer':
            'Cost estimates are generated from the detected damage type and severity, combined with vehicle make/model data and local pricing when available. Estimates are indicative — actual repair shop quotes may vary.',
      },
      {
        'category': 'Cost Estimates',
        'question': 'Are the cost estimates guaranteed?',
        'answer':
            'Cost estimates are provided for reference only and may vary based on actual repair shop pricing, parts availability, and additional damage discovered during repair.',
      },
      {
        'category': 'Technical Issues',
        'question': 'The app is running slowly. What should I do?',
        'answer':
            'Close background apps, check your internet connection and try again. Large uploads or slow connections can delay processing. If problems persist, update the app and contact support with logs via the Contact screen.',
      },
      {
        'category': 'Technical Issues',
        'question': 'My photos won\'t upload. What\'s wrong?',
        'answer':
            'Common causes: poor connection, camera/storage permissions not granted, or the file exceeds the 10MB per-file limit. Try re-taking the photo, reduce image size or use the gallery uploader. The web portal and services also enforce a 10MB file limit for documents.',
      },
      {
        'category': 'Account & Settings',
        'question': 'How do I change my password?',
        'answer':
            'While signed in go to Settings > Security > Change Password and provide your current password plus a new strong password. If you forgot your password use the Reset Password option on the login screen — a reset email will be sent to your address.',
      },
      {
        'category': 'Account & Settings',
        'question': 'Can I delete my account?',
        'answer':
            'Account deletion is available from Settings > Account > Delete Account. Deleting your account removes your profile, assessments and documents from the app and backend — this action is permanent. If you need help restoring data contact support immediately.',
      },
      {
        'category': 'Privacy & Security',
        'question': 'Is my data secure?',
        'answer':
            'The app uses Supabase and standard transport/security practices to protect your data. Files and personal information are stored with access controls; the Privacy Policy screen describes collection and sharing practices. Contact support for data deletion or export requests.',
      },
      {
        'category': 'Privacy & Security',
        'question': 'Who can see my assessment reports?',
        'answer':
            'By default reports are private to your account. You can export or share generated PDFs with insurers, repair shops or other parties. Sharing is a manual action initiated by you.',
      },
      {
        'category': 'Billing & Subscriptions',
        'question': 'Is the app free to use?',
        'answer':
            'Yes — InsureVis is 100% free to use. There are no paid plans or subscriptions required to access the app\'s features.',
      },
      {
        'category': 'Billing & Subscriptions',
        'question': 'How do I cancel my subscription?',
        'answer':
            'There are no subscriptions to cancel — the app is fully free. If you see billing-related messages, please contact support so we can investigate.',
      },
      {
        'category': 'Exports & Reports',
        'question': 'Can I export assessment reports?',
        'answer':
            'Yes. The app generates PDF reports (multiple templates: summary, insurance and technical). PDFs include images, cost breakdowns and metadata and are intended for sharing with insurers and repair shops.',
      },
    ];
  }

  /// Filter FAQ items by search query
  static List<Map<String, String>> filterFAQs(
    List<Map<String, String>> faqs,
    String query,
  ) {
    if (query.isEmpty) {
      return faqs;
    }

    final lowerQuery = query.toLowerCase();
    return faqs.where((faq) {
      return faq['question']!.toLowerCase().contains(lowerQuery) ||
          faq['answer']!.toLowerCase().contains(lowerQuery) ||
          faq['category']!.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get unique categories from FAQ items
  static List<String> getCategories(List<Map<String, String>> faqs) {
    return faqs.map((faq) => faq['category']!).toSet().toList();
  }

  /// Toggle expansion state for an FAQ item
  static Map<int, bool> toggleExpansion(
    Map<int, bool> expandedItems,
    int index,
  ) {
    final updated = Map<int, bool>.from(expandedItems);
    updated[index] = !(updated[index] ?? false);
    return updated;
  }

  /// Check if an item is expanded
  static bool isExpanded(Map<int, bool> expandedItems, int index) {
    return expandedItems[index] ?? false;
  }
}
