class CompanyValidators {
  static String? organizationNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Valgfritt felt
    }
    
    // Fjern alle ikke-numeriske tegn
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return null; // Tomt er OK siden det er valgfritt
    }
    
    if (digitsOnly.length < 9) {
      final missing = 9 - digitsOnly.length;
      return 'Mangler $missing siffer';
    }
    
    if (digitsOnly.length > 9) {
      return 'For mange sifre (maks 9)';
    }
    
    // Modulo 11 validering for norske org.nr
    if (!_validateModulo11(digitsOnly)) {
      return 'Ugyldig organisasjonsnummer';
    }
    
    return null; // Gyldig
  }
  
  static String? vatNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Valgfritt felt
    }
    
    // Fjern alle ikke-numeriske tegn
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return null; // Tomt er OK siden det er valgfritt
    }
    
    // MVA-nummer er vanligvis 8-9 sifre
    if (digitsOnly.length < 8) {
      final missing = 8 - digitsOnly.length;
      return 'Mangler $missing siffer';
    }
    
    if (digitsOnly.length > 9) {
      return 'For mange sifre (maks 9)';
    }
    
    return null; // Gyldig
  }
  
  static bool _validateModulo11(String digits) {
    if (digits.length != 9) return false;
    
    final weights = [3, 2, 7, 6, 5, 4, 3, 2];
    var sum = 0;
    
    for (int i = 0; i < 8; i++) {
      sum += int.parse(digits[i]) * weights[i];
    }
    
    final remainder = sum % 11;
    final checkDigit = remainder == 0 ? 0 : 11 - remainder;
    
    if (checkDigit == 11) return false;
    if (checkDigit == 10) return false; // Modulo 11 kan ikke ha 10
    
    return checkDigit == int.parse(digits[8]);
  }
  
  static int getOrganizationNumberLength(String? value) {
    if (value == null || value.isEmpty) return 0;
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly.length;
  }
  
  static int getVatNumberLength(String? value) {
    if (value == null || value.isEmpty) return 0;
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly.length;
  }
}

