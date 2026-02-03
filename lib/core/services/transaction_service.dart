import 'supabase_service.dart';
import 'company_service.dart';

class Transaction {
  final String id;
  final String companyId;
  final String? documentId;
  final String status;
  final Map<String, dynamic> aiAnalysis;
  final Map<String, dynamic> userChoices;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? bookedAt;
  // Dokumentinformasjon (hentes via join)
  final String? documentFilePath;
  final String? documentFileType;

  Transaction({
    required this.id,
    required this.companyId,
    this.documentId,
    required this.status,
    required this.aiAnalysis,
    required this.userChoices,
    required this.createdAt,
    required this.updatedAt,
    this.bookedAt,
    this.documentFilePath,
    this.documentFileType,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Håndter både direkte dokumentinfo og nested document-objekt
    final document = json['document'] as Map<String, dynamic>?;
    final documentFilePath = document?['file_path'] as String? ?? 
                            json['document_file_path'] as String?;
    final documentFileType = document?['file_type'] as String? ?? 
                            json['document_file_type'] as String?;

    return Transaction(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      documentId: json['document_id'] as String?,
      status: json['status'] as String,
      aiAnalysis: json['ai_analysis'] as Map<String, dynamic>? ?? {},
      userChoices: json['user_choices'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      bookedAt: json['booked_at'] != null 
          ? DateTime.parse(json['booked_at'] as String)
          : null,
      documentFilePath: documentFilePath,
      documentFileType: documentFileType,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'NEW':
        return 'Ny';
      case 'NEEDS_INFO':
        return 'Trenger info';
      case 'NEEDS_USER_CHOICE':
        return 'Trenger valg';
      case 'READY_TO_BOOK':
        return 'Klar til bokføring';
      case 'BOOKED':
        return 'Bokført';
      default:
        return status;
    }
  }
}

class TransactionService {
  static Future<List<Transaction>> getTransactions({
    String? status,
    int? limit,
  }) async {
    final company = await CompanyService.getCurrentCompany();
    if (company == null) return [];

    try {
      // Hent transaksjoner med dokumentinformasjon via join
      dynamic query = SupabaseService.client
          .from('transactions')
          .select('*, document:documents(file_path, file_type)')
          .eq('company_id', company.id);

      if (status != null) {
        query = query.eq('status', status);
      }

      query = query.order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      return (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, int>> getTransactionCounts() async {
    final company = await CompanyService.getCurrentCompany();
    if (company == null) {
      return {
        'total': 0,
        'needs_attention': 0,
        'ready_to_book': 0,
        'booked': 0,
      };
    }

    try {
      final allTransactions = await getTransactions();
      
      return {
        'total': allTransactions.length,
        'needs_attention': allTransactions
            .where((t) => 
                t.status == 'NEW' || 
                t.status == 'NEEDS_INFO' || 
                t.status == 'NEEDS_USER_CHOICE')
            .length,
        'ready_to_book': allTransactions
            .where((t) => t.status == 'READY_TO_BOOK')
            .length,
        'booked': allTransactions
            .where((t) => t.status == 'BOOKED')
            .length,
      };
    } catch (e) {
      return {
        'total': 0,
        'needs_attention': 0,
        'ready_to_book': 0,
        'booked': 0,
      };
    }
  }
}

