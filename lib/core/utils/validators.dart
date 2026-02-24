class Validators {
  /// Validates an Indian vehicle registration number.
  /// Supported formats:
  /// - MH 12 AB 1234
  /// - DL01C4567
  /// - KA 05 MN 9876
  ///
  /// Pattern explanation:
  /// ^[A-Z]{2}      : Exactly two uppercase letters (State Code)
  /// \s?            : Optional space
  /// [0-9]{1,2}     : One or two digits (RTO District Code)
  /// \s?            : Optional space
  /// [A-Z]{1,3}     : One to three uppercase letters (Series Code, can be 1, 2, or 3 letters for some special series)
  /// \s?            : Optional space
  /// [0-9]{4}$      : Exactly four digits (Unique Registration Number)
  static String? validateVehicleNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your vehicle number';
    }

    final cleanValue = value.trim().toUpperCase();
    
    // Strict Indian Vehicle Registration Regex
    final regex = RegExp(r'^[A-Z]{2}\s?[0-9]{1,2}\s?[A-Z]{1,3}\s?[0-9]{4}$');

    if (!regex.hasMatch(cleanValue)) {
      return 'Please enter a valid Indian vehicle number\n(e.g. MH 12 AB 1234)';
    }

    // List of valid Indian State/UT codes (simplified check)
    final stateCodes = {
      'AN', 'AP', 'AR', 'AS', 'BR', 'CH', 'CG', 'DD', 'DL', 'GA', 'GJ', 'HR', 'HP', 'JK', 'JH', 'KA', 'KL', 'LA', 'LD', 'MP', 'MH', 'MN', 'ML', 'MZ', 'NL', 'OD', 'PY', 'PB', 'RJ', 'SK', 'TN', 'TS', 'TR', 'UP', 'UK', 'UA', 'WB'
    };

    final stateCode = cleanValue.substring(0, 2);
    if (!stateCodes.contains(stateCode)) {
      return 'Invalid state code in vehicle number';
    }

    return null;
  }
}
