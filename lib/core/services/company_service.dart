import 'supabase_service.dart';

class CompanyProfile {
  final String id;
  final String userId;
  final String name;
  final String? organizationNumber;
  final String? industry;
  final bool vatRegistered;
  final Map<String, dynamic> defaultSettings;
  final Map<String, dynamic> learnedPatterns;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompanyProfile({
    required this.id,
    required this.userId,
    required this.name,
    this.organizationNumber,
    this.industry,
    required this.vatRegistered,
    required this.defaultSettings,
    required this.learnedPatterns,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      organizationNumber: json['organization_number'] as String?,
      industry: json['industry'] as String?,
      vatRegistered: json['vat_registered'] as bool? ?? false,
      defaultSettings: json['default_settings'] as Map<String, dynamic>? ?? {},
      learnedPatterns: json['learned_patterns'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'organization_number': organizationNumber,
      'industry': industry,
      'vat_registered': vatRegistered,
      'default_settings': defaultSettings,
      'learned_patterns': learnedPatterns,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CompanyService {
  static Future<CompanyProfile?> getCurrentCompany() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    try {
      final response = await SupabaseService.client
          .from('company_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;

      return CompanyProfile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> hasCompany() async {
    final company = await getCurrentCompany();
    return company != null;
  }

  static Future<CompanyProfile> createCompany({
    required String name,
    String? organizationNumber,
    String? industry,
    bool vatRegistered = false,
    Map<String, dynamic>? defaultSettings,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('Bruker ikke logget inn');
    }

    final client = SupabaseService.client;

    // Sørg for at brukeren finnes i public.users (FK for company_profiles.user_id)
    // Dette håndterer eksisterende kontoer som ble laget før vi begynte å synke til users-tabellen.
    try {
      await client.from('users').upsert(
        {
          'id': user.id,
          'email': user.email,
        },
        onConflict: 'id',
      );
    } catch (_) {
      // Hvis dette feiler, lar vi likevel forsøket på å opprette company gå videre
      // så får vi en klarere feilmelding derfra.
    }

    final response = await client
        .from('company_profiles')
        .insert({
          'user_id': user.id,
          'name': name,
          'organization_number': organizationNumber,
          'industry': industry,
          'vat_registered': vatRegistered,
          'default_settings': defaultSettings ?? {},
        })
        .select()
        .single();

    return CompanyProfile.fromJson(response);
  }

  static Future<CompanyProfile> updateCompany({
    required String id,
    String? name,
    String? organizationNumber,
    String? industry,
    bool? vatRegistered,
    Map<String, dynamic>? defaultSettings,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (organizationNumber != null) updates['organization_number'] = organizationNumber;
    if (industry != null) updates['industry'] = industry;
    if (vatRegistered != null) updates['vat_registered'] = vatRegistered;
    if (defaultSettings != null) updates['default_settings'] = defaultSettings;
    updates['updated_at'] = DateTime.now().toIso8601String();

    final response = await SupabaseService.client
        .from('company_profiles')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return CompanyProfile.fromJson(response);
  }
}

