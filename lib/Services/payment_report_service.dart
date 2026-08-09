import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:gestion_formations/config/theme.dart';

class PaymentReportService {
  static Future<Uint8List> generatePaymentReportPDF({
    required List<Map<String, dynamic>> payments,
    required Map<String, int> statusCounts,
    required double totalAmount,
  }) async {
    final pdf = pw.Document();

    // Charger le logo
    final ByteData imageData = await rootBundle.load('images/logo.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final image = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête avec logo
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    width: 80,
                    height: 80,
                    child: pw.Image(image),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'RAPPORT DE PAIEMENTS',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(AppTheme.primary.value),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Gestion Formations',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColor.fromInt(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Résumé statistiques
              pw.Container(
                padding: pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF3F4F6),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RÉSUMÉ DES PAIEMENTS',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF1F2937),
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Total Paiements',
                              style: pw.TextStyle(
                                fontSize: 11,
                                color: PdfColor.fromInt(0xFF6B7280),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              '$totalAmount FCFA',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Nombre Total',
                              style: pw.TextStyle(
                                fontSize: 11,
                                color: PdfColor.fromInt(0xFF6B7280),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              '${payments.length}',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(AppTheme.primary.value),
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'En Attente',
                              style: pw.TextStyle(
                                fontSize: 11,
                                color: PdfColor.fromInt(0xFF6B7280),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              '${statusCounts['en_attente'] ?? 0}',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Validés',
                              style: pw.TextStyle(
                                fontSize: 11,
                                color: PdfColor.fromInt(0xFF6B7280),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              '${statusCounts['valide'] ?? 0}',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Tableau des paiements
              pw.Text(
                'DÉTAILS DES PAIEMENTS',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1F2937),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColor.fromInt(0xFFE5E7EB),
                  width: 1,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(AppTheme.primary.value),
                    ),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Étudiant',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Montant',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Statut',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Date',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  ...payments.map((payment) {
                    final statusColor = _getStatusColor(payment['statutMontant'] ?? 'en_attente');
                    final statusLabel = _getStatusLabel(payment['statutMontant'] ?? 'en_attente');
                    final date = payment['dateCreation'] != null
                        ? (payment['dateCreation'] as dynamic).toDate().toString().split(' ')[0]
                        : 'N/A';

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            payment['studentName'] ?? 'N/A',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${payment['montant']?.toStringAsFixed(0) ?? 0} FCFA',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Container(
                            padding: pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: statusColor,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              statusLabel,
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            date,
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.Spacer(),

              // Pied de page
              pw.Divider(color: PdfColor.fromInt(0xFFD1D5DB)),
              pw.SizedBox(height: 12),
              pw.Text(
                'Généré le ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromInt(0xFF6B7280),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static PdfColor _getStatusColor(String status) {
    switch (status) {
      case 'en_attente':
        return PdfColor.fromInt(0xFFF59E0B);
      case 'incomplet':
        return PdfColor.fromInt(0xFFFB923C);
      case 'valide':
        return PdfColor.fromInt(0xFF10B981);
      default:
        return PdfColor.fromInt(0xFF6B7280);
    }
  }

  static String _getStatusLabel(String status) {
    switch (status) {
      case 'en_attente':
        return 'En Attente';
      case 'incomplet':
        return 'Incomplet';
      case 'valide':
        return 'Validé';
      default:
        return 'Unknown';
    }
  }
}
