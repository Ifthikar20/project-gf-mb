/// Centralized error message formatter for user-facing messages
///
/// Converts technical error messages and status codes into friendly,
/// calm messages that users can understand without technical details.
/// Supports the BetterBliss Auth backend structured error codes.
class ErrorMessages {
  /// Format authentication errors into user-friendly messages
  /// Supports structured error codes from the backend
  static String formatAuthError(Object error, {int? statusCode, String? code}) {
    final errorString = error.toString().toLowerCase();

    // Handle structured error codes from the backend
    if (code != null) {
      switch (code) {
        case 'INVALID_CREDENTIALS':
          return 'The email or password you entered is incorrect. Please try again.';
        case 'ACCOUNT_NOT_FOUND':
          return 'No account found with this email. Would you like to create one?';
        case 'ACCOUNT_DISABLED':
          return 'Your account has been deactivated. Please contact support.';
        case 'EMAIL_ALREADY_EXISTS':
          return 'An account with this email already exists. Please log in instead.';
        case 'INCORRECT_CURRENT_PASSWORD':
          return 'The current password you entered is incorrect. Please try again.';
        case 'VALIDATION_ERROR':
          return 'Please check your input and try again.';
        case 'TOO_MANY_ATTEMPTS':
          return 'Too many attempts. Please wait a moment before trying again.';
        case 'OAUTH_FAILED':
          return 'Sign in was cancelled or failed. Please try again.';
        case 'SERVER_ERROR':
          return 'We\'re having trouble connecting right now. Please try again in a moment.';
      }
    }

    // Handle specific status codes
    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          return 'Please check your input and try again.';
        case 401:
          return 'The email or password you entered is incorrect. Please try again.';
        case 403:
          return 'Your account has been deactivated. Please contact support.';
        case 409:
          return 'An account with this email already exists. Please log in instead.';
        case 429:
          return 'Too many attempts. Please wait a moment before trying again.';
        case 500:
        case 502:
        case 503:
          return 'We\'re having trouble connecting right now. Please try again in a moment.';
        case 404:
          return 'Service temporarily unavailable. Please try again later.';
      }
    }

    // Handle common error patterns in message text
    if (errorString.contains('email') && errorString.contains('exists')) {
      return 'An account with this email already exists. Please log in instead.';
    }

    if (errorString.contains('invalid') && (errorString.contains('email') || errorString.contains('password'))) {
      return 'The email or password you entered is incorrect. Please try again.';
    }

    if (errorString.contains('password') && errorString.contains('weak')) {
      return 'Please choose a stronger password with at least 8 characters.';
    }

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    }

    if (errorString.contains('timeout')) {
      return 'The request took too long. Please try again.';
    }

    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Service temporarily unavailable. Please try again later.';
    }

    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'The email or password you entered is incorrect. Please try again.';
    }

    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'Access denied. Please contact support if this continues.';
    }

    if (errorString.contains('server') || errorString.contains('500')) {
      return 'We\'re having trouble connecting right now. Please try again in a moment.';
    }

    // Default friendly message
    return 'Something didn\'t work as expected. Please try again.';
  }

  /// Format API errors into user-friendly messages
  static String formatApiError(Object error, {int? statusCode, String? operation}) {
    final errorString = error.toString().toLowerCase();

    // Handle specific status codes
    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          return 'The request couldn\'t be processed. Please check your input and try again.';
        case 401:
          return 'Your session has expired. Please log in again.';
        case 403:
          return 'You don\'t have permission to access this content.';
        case 404:
          return 'The content you\'re looking for isn\'t available right now.';
        case 429:
          return 'You\'re doing that too quickly. Please wait a moment and try again.';
        case 500:
        case 502:
        case 503:
          return 'We\'re experiencing technical difficulties. Please try again shortly.';
      }
    }

    // Network-related errors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    }

    if (errorString.contains('timeout')) {
      return 'The request took too long. Please try again.';
    }

    // Default message with optional operation context
    if (operation != null) {
      return 'We couldn\'t complete your request. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  /// Format generic errors
  static String formatGenericError(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    }

    if (errorString.contains('timeout')) {
      return 'The request took too long. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }
}
