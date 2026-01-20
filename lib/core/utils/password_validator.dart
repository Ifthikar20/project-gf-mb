/// Password validation utility for Better & Bliss app
/// 
/// Validates passwords against AWS Cognito requirements:
/// - Minimum 8 characters
/// - At least 1 uppercase letter (A-Z)
/// - At least 1 lowercase letter (a-z)
/// - At least 1 number (0-9)
/// - At least 1 special character (!@#$%^&*()_+-=[]{}|')
class PasswordValidator {
  static const int minLength = 8;
  static const String _specialChars = r'[!@#$%^&*()_+\-=\[\]{}|' "'" r']';

  /// Validates password meets all AWS Cognito requirements.
  /// Returns null if valid, or the first error message if invalid.
  static String? validate(String password) {
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!password.contains(RegExp(_specialChars))) {
      return 'Password must contain at least one special character (!@#\$%^&*)';
    }
    return null; // Valid
  }

  /// Returns a list of all password requirements with their current status.
  /// Use this for interactive UI feedback as the user types.
  static List<PasswordRequirement> getRequirements(String password) {
    return [
      PasswordRequirement(
        label: 'At least 8 characters',
        isMet: password.length >= minLength,
      ),
      PasswordRequirement(
        label: 'One uppercase letter (A-Z)',
        isMet: password.contains(RegExp(r'[A-Z]')),
      ),
      PasswordRequirement(
        label: 'One lowercase letter (a-z)',
        isMet: password.contains(RegExp(r'[a-z]')),
      ),
      PasswordRequirement(
        label: 'One number (0-9)',
        isMet: password.contains(RegExp(r'[0-9]')),
      ),
      PasswordRequirement(
        label: 'One special character (!@#\$%^&*)',
        isMet: password.contains(RegExp(_specialChars)),
      ),
    ];
  }

  /// Quick check if password is valid
  static bool isValid(String password) => validate(password) == null;
}

/// Represents a single password requirement with its validation status
class PasswordRequirement {
  final String label;
  final bool isMet;

  const PasswordRequirement({
    required this.label,
    required this.isMet,
  });
}
