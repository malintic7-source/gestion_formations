import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:file_saver/file_saver.dart';

class PdfHelper {
  static Future<void> downloadPDF(
    Uint8List pdfBytes, {
    required String fileName,
  }) async {
    try {
      final String path = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: pdfBytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      debugPrint('✅ PDF téléchargé: $path');
    } catch (e) {
      debugPrint('❌ Erreur téléchargement PDF: $e');
      rethrow;
    }
  }

  static Future<void> downloadCSV(
    Uint8List csvBytes, {
    required String fileName,
  }) async {
    try {
      final String path = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: csvBytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );
      debugPrint('✅ CSV téléchargé: $path');
    } catch (e) {
      debugPrint('❌ Erreur téléchargement CSV: $e');
      rethrow;
    }
  }

  static Future<void> printPDF(Uint8List pdfBytes) async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
      );
      debugPrint('✅ PDF envoyé à l\'imprimante');
    } catch (e) {
      debugPrint('❌ Erreur impression: $e');
      rethrow;
    }
  }

  static Future<void> sharePDF(Uint8List pdfBytes) async {
    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'facture_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      debugPrint('✅ PDF partagé');
    } catch (e) {
      debugPrint('❌ Erreur partage: $e');
      rethrow;
    }
  }
}
