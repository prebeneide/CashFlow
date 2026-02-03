class AuthValidators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email er påkrevd';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Ugyldig email-format';
    }
    
    return null;
  }

  static String? phoneNumber(String? value, String countryCode) {
    if (value == null || value.isEmpty) {
      return 'Telefonnummer er påkrevd';
    }
    
    // Fjern alle ikke-numeriske tegn
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (countryCode == '+47') {
      // Norsk telefonnummer: 8 sifre
      if (digitsOnly.length != 8) {
        return 'Norsk telefonnummer må ha 8 sifre';
      }
    } else {
      // Generell validering: minst 7 sifre
      if (digitsOnly.length < 7) {
        return 'Telefonnummer må ha minst 7 sifre';
      }
    }
    
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'Brukernavn er påkrevd';
    }
    
    if (value.length < 3) {
      return 'Brukernavn må være minst 3 tegn';
    }
    
    if (value.length > 20) {
      return 'Brukernavn kan maks være 20 tegn';
    }
    
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Brukernavn kan kun inneholde bokstaver, tall og underscore';
    }
    
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Passord er påkrevd';
    }
    
    if (value.length < 6) {
      return 'Passord må være minst 6 tegn';
    }
    
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Bekreft passord er påkrevd';
    }
    
    if (value != password) {
      return 'Passordene matcher ikke';
    }
    
    return null;
  }
}

