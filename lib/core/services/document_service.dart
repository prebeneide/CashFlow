import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'company_service.dart';

class Document {
  final String id;
  final String companyId;
  final String filePath;
  final String fileType;
  final Map<String, dynamic> metadata;
  final DateTime uploadedAt;

  Document({
    required this.id,
    required this.companyId,
    required this.filePath,
    required this.fileType,
    required this.metadata,
    required this.uploadedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      filePath: json['file_path'] as String,
      fileType: json['file_type'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }
}

class DocumentService {
  static Future<Document> uploadDocument({
    File? file,
    Uint8List? fileBytes,
    required String fileName,
    Map<String, dynamic>? metadata,
  }) async {
    final company = await CompanyService.getCurrentCompany();
    if (company == null) {
      throw Exception('Ingen bedriftsprofil funnet');
    }

    // Valider at vi har enten file eller fileBytes
    if (file == null && fileBytes == null) {
      throw Exception('Enten file eller fileBytes må være satt');
    }

    try {
      // Bestem filtype
      final fileExtension = fileName.split('.').last.toLowerCase();
      final fileType = _getFileType(fileExtension);

      // Generer unik filnavn (bruk user.id for RLS-kompatibilitet)
      final user = SupabaseService.currentUser;
      if (user == null) {
        throw Exception('Bruker ikke logget inn');
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${user.id}/$timestamp-$fileName';

      // Debug: Print filstien for feilsøking
      print('DEBUG: Uploading file with path: $uniqueFileName');
      print('DEBUG: User ID: ${user.id}');

      // Hent filbytes (fra File eller direkte fra bytes)
      final Uint8List bytes;
      if (fileBytes != null) {
        bytes = fileBytes;
      } else if (file != null) {
        bytes = await file.readAsBytes();
      } else {
        throw Exception('Enten file eller fileBytes må være satt');
      }
      
      try {
        await SupabaseService.client.storage
            .from('documents')
            .uploadBinary(
              uniqueFileName,
              bytes,
              fileOptions: FileOptions(
                contentType: _getContentType(fileExtension),
                upsert: false,
              ),
            );
      } on StorageException catch (storageError) {
        print('DEBUG: Storage error: ${storageError.message}');
        print('DEBUG: Status code: ${storageError.statusCode}');
        rethrow;
      }

      // Hent public URL (hvis nødvendig)
      final fileUrl = SupabaseService.client.storage
          .from('documents')
          .getPublicUrl(uniqueFileName);

      // Opprett dokument i database
      final response = await SupabaseService.client
          .from('documents')
          .insert({
            'company_id': company.id,
            'file_path': uniqueFileName,
            'file_type': fileType,
            'metadata': {
              ...?metadata,
              'original_name': fileName,
              'file_size': bytes.length,
              'file_url': fileUrl,
            },
          })
          .select()
          .single();

      return Document.fromJson(response);
    } catch (e) {
      // Gi mer detaljert feilmelding
      print('DEBUG: Error caught: $e');
      String errorMessage = 'Feil ved opplasting av dokument';
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('row-level security') || 
          errorString.contains('rls') ||
          errorString.contains('policy')) {
        errorMessage = 'RLS-feil: Sjekk at storage policies er oppdatert i Supabase. '
            'Kjør SQL-filen 003_storage_setup.sql på nytt i SQL Editor.';
      } else if (errorString.contains('bucket not found')) {
        errorMessage = 'Storage bucket "documents" ikke funnet. Sjekk at bucket-en er opprettet i Supabase.';
      } else if (errorString.contains('duplicate') || errorString.contains('already exists')) {
        errorMessage = 'Fil med samme navn eksisterer allerede. Prøv igjen.';
      } else {
        errorMessage = 'Feil ved opplasting: ${e.toString()}';
      }
      throw Exception(errorMessage);
    }
  }

  static String _getFileType(String extension) {
    final imageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'];
    final pdfTypes = ['pdf'];
    
    if (imageTypes.contains(extension)) {
      return 'image';
    } else if (pdfTypes.contains(extension)) {
      return 'pdf';
    } else {
      return 'other';
    }
  }

  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}

