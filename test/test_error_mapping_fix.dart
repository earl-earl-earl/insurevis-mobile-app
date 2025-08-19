/// Test to verify our error mapping fix works correctly
void main() {
  print('🧪 Testing Error Mapping Fix...\n');

  // Simulate the exact error we're getting
  final errorResponse =
      '{"code":500,"error_code":"unexpected_failure","msg":"Error sending confirmation email","error_id":"9707b995f7244eeb-MNL"}';

  print('📝 Original error: $errorResponse\n');

  // Test our error mapping logic
  final mappedMessage = mapErrorMessage(errorResponse, 'signup');

  print('📋 Result:');
  print('Mapped message: "$mappedMessage"\n');

  if (mappedMessage.contains('email verification failed')) {
    print('✅ SUCCESS! Fixed error mapping now works');
    print('   Users will see: "$mappedMessage"');
    print('   Instead of generic: "Failed to create account"');
  } else {
    print('❌ Fix didn\'t work. Still showing: "$mappedMessage"');
  }
}

/// Simplified version of our error mapping function to test
String mapErrorMessage(String error, String operation) {
  final errorLower = error.toLowerCase();

  // Email-related errors (check early, before server errors)
  if (errorLower.contains('email already registered') ||
      errorLower.contains('email_already_exists') ||
      errorLower.contains('duplicate') && errorLower.contains('email')) {
    return 'An account with this email already exists. Please sign in instead or use a different email.';
  }

  if (errorLower.contains('email not confirmed') ||
      errorLower.contains('email_not_confirmed')) {
    return 'Please verify your email address before signing in. Check your inbox for a verification link.';
  }

  if (errorLower.contains('invalid email') ||
      errorLower.contains('email') && errorLower.contains('invalid') ||
      errorLower.contains('email_address_invalid')) {
    return 'Please enter a valid email address. Some email providers may not be supported.';
  }

  // Network errors
  if (errorLower.contains('network') ||
      errorLower.contains('connection') ||
      errorLower.contains('timeout') ||
      errorLower.contains('socket')) {
    return 'Network error. Please check your internet connection and try again.';
  }

  // Email sending errors (check before server errors)
  if (errorLower.contains('error sending confirmation email') ||
      errorLower.contains('confirmation email') ||
      errorLower.contains('email delivery failed') ||
      errorLower.contains('smtp') && errorLower.contains('error')) {
    return 'Account created, but email verification failed. Please contact support or try signing in directly.';
  }

  // Server errors
  if (errorLower.contains('server error') ||
      errorLower.contains('internal server error') ||
      errorLower.contains('502') ||
      errorLower.contains('503') ||
      errorLower.contains('500') ||
      errorLower.contains('bad gateway') ||
      errorLower.contains('service unavailable') ||
      errorLower.contains('gateway timeout')) {
    return 'Server temporarily unavailable. Please try again in a few moments.';
  }

  // Default messages based on operation
  switch (operation) {
    case 'signup':
      return 'Failed to create account. Please try again or contact support if the problem persists.';
    case 'signin':
      return 'Failed to sign in. Please check your credentials and try again.';
    default:
      return 'An unexpected error occurred. Please try again.';
  }
}
