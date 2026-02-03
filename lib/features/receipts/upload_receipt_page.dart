import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/document_service.dart';
import '../../core/services/company_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/glass_card.dart';
import 'dart:ui' as ui;

class UploadReceiptPage extends StatefulWidget {
  const UploadReceiptPage({super.key});

  @override
  State<UploadReceiptPage> createState() => _UploadReceiptPageState();
}

class _UploadReceiptPageState extends State<UploadReceiptPage> {
  File? _selectedFile;
  Uint8List? _selectedFileBytes; // For web
  bool _isUploading = false;
  String? _errorMessage;
  String? _fileName;

  final ImagePicker _imagePicker = ImagePicker();

  bool _isImageFile(String? fileName) {
    if (fileName == null) return false;
    final extension = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(extension);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _fileName = image.name;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Feil ved valg av bilde: $e';
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        final file = result.files.single;
        
        if (kIsWeb) {
          // På web, bruk bytes direkte
          if (file.bytes != null) {
            setState(() {
              _selectedFileBytes = file.bytes;
              _selectedFile = null;
              _fileName = file.name;
              _errorMessage = null;
            });
          } else {
            throw Exception('Kunne ikke lese filinnhold');
          }
        } else {
          // På mobile, bruk path
          if (file.path != null) {
            setState(() {
              _selectedFile = File(file.path!);
              _selectedFileBytes = null;
              _fileName = file.name;
              _errorMessage = null;
            });
          } else {
            throw Exception('Kunne ikke finne filsti');
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Feil ved valg av fil: $e';
      });
    }
  }

  Future<void> _uploadReceipt() async {
    if (_selectedFile == null && _selectedFileBytes == null) {
      setState(() {
        _errorMessage = 'Vennligst velg en fil';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Last opp dokument
      final document = await DocumentService.uploadDocument(
        file: _selectedFile,
        fileBytes: _selectedFileBytes,
        fileName: _fileName ?? 'unknown',
        metadata: {
          'upload_source': kIsWeb ? 'web_app' : 'mobile_app',
        },
      );

      // Opprett transaksjon
      final company = await CompanyService.getCurrentCompany();
      if (company == null) {
        throw Exception('Ingen bedriftsprofil funnet');
      }

      await SupabaseService.client.from('transactions').insert({
        'company_id': company.id,
        'document_id': document.id,
        'status': 'NEW',
        'ai_analysis': {},
        'user_choices': {},
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kvittering lastet opp!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        String errorText = e.toString();
        // Fjern "Exception: " prefiks hvis det finnes
        if (errorText.startsWith('Exception: ')) {
          errorText = errorText.substring(11);
        }
        setState(() {
          _errorMessage = errorText;
          _isUploading = false;
        });
        
        // Vis også en snackbar for bedre synlighet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<ui.Image?> _getImagePreview() async {
    try {
      Uint8List bytes;
      if (_selectedFileBytes != null) {
        bytes = _selectedFileBytes!;
      } else if (_selectedFile != null) {
        bytes = await _selectedFile!.readAsBytes();
      } else {
        return null;
      }

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Last opp kvittering'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? AppColors.backgroundGradientDark 
              : AppColors.backgroundGradientLight,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Last opp kvittering',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ta bilde av kvitteringen eller last opp en fil',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Valg av fil
                Row(
                  children: [
                    Expanded(
                      child: _UploadButton(
                        icon: Icons.camera_alt,
                        label: 'Ta bilde',
                        onTap: _pickImage,
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _UploadButton(
                        icon: Icons.folder,
                        label: 'Velg fil',
                        onTap: _pickFile,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondary,
                            AppColors.secondary.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (_selectedFile != null || _selectedFileBytes != null) ...[
                  const SizedBox(height: 20),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Forhåndsvisning eller ikon
                        if (_isImageFile(_fileName))
                          // Bilde-forhåndsvisning
                          FutureBuilder<ui.Image?>(
                            future: _getImagePreview(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Container(
                                  height: 300,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              
                              if (snapshot.hasData && snapshot.data != null) {
                                return ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  child: CustomPaint(
                                    size: Size.infinite,
                                    painter: _ImagePainter(snapshot.data!),
                                    child: SizedBox(
                                      height: 300,
                                      width: double.infinity,
                                    ),
                                  ),
                                );
                              }
                              
                              // Fallback hvis bilde ikke kan lastes
                              return Container(
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 64,
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          // PDF eller annen fil - vis ikon
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf,
                                    size: 64,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'PDF-dokument',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Filinfo og fjern-knapp
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                _isImageFile(_fileName)
                                    ? Icons.image
                                    : Icons.picture_as_pdf,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _fileName ?? 'Fil valgt',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Klar for opplasting',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _selectedFile = null;
                                    _selectedFileBytes = null;
                                    _fileName = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Opplastingsknapp
                Container(
                  decoration: BoxDecoration(
                    gradient: (_selectedFile != null || _selectedFileBytes != null) && !_isUploading
                        ? AppColors.primaryGradient
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: (_selectedFile != null || _selectedFileBytes != null) && !_isUploading
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: (_selectedFile != null || _selectedFileBytes != null) && !_isUploading
                        ? _uploadReceipt
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: (_selectedFile != null || _selectedFileBytes != null) && !_isUploading
                          ? Colors.transparent
                          : null,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Last opp kvittering',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for å vise bildet med riktig aspect ratio
class _ImagePainter extends CustomPainter {
  final ui.Image image;

  _ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final imageAspectRatio = image.width / image.height;
    final containerAspectRatio = size.width / size.height;

    double drawWidth = size.width;
    double drawHeight = size.height;
    double offsetX = 0;
    double offsetY = 0;

    if (imageAspectRatio > containerAspectRatio) {
      // Bilde er bredere - fyll bredden
      drawHeight = size.width / imageAspectRatio;
      offsetY = (size.height - drawHeight) / 2;
    } else {
      // Bilde er høyere - fyll høyden
      drawWidth = size.height * imageAspectRatio;
      offsetX = (size.width - drawWidth) / 2;
    }

    final rect = Rect.fromLTWH(offsetX, offsetY, drawWidth, drawHeight);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UploadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Gradient gradient;

  const _UploadButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

