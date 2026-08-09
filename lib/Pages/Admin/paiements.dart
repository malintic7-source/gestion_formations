import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:gestion_formations/config/theme.dart';
import 'package:gestion_formations/Models/user.dart';
import 'package:gestion_formations/Models/payment.dart';
import 'package:gestion_formations/Services/pdf_helper.dart';
import 'package:gestion_formations/Services/payment_report_service.dart';
import 'package:gestion_formations/Services/db_services.dart';


class AdminPaiements extends StatefulWidget {
  const AdminPaiements({super.key});

  @override
  State<AdminPaiements> createState() => _AdminPaiementsState();
}

class _AdminPaiementsState extends State<AdminPaiements> with TickerProviderStateMixin {
  final LocalDataService _db = LocalDataService();
  late AnimationController _fadeController;

  String? _selectedStudentId;
  String? _selectedFormationId;
  double _montant = 0;
  String _motif = '';
  String _selectedStatus = 'en_attente';
  // Filters for payments list
  String _filterStatus = 'all';
  List<Map<String, dynamic>> _studentFormations = [];
  DateTime? _reportStartDate;
  DateTime? _reportEndDate;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildHeader()),
                SizedBox(width: 16),
                _buildGenerateReportButton(),
              ],
            ),
            SizedBox(height: 28),
            _buildPaymentForm(),
            SizedBox(height: 24),
            _buildFiltersRow(),
            SizedBox(height: 12),
            _buildPaymentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.heroShadow,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestion des Paiements',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enregistrez les reçus et suivez l\'état financier des étudiants',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateReportButton() {
    return GestureDetector(
      onTap: _showDateRangePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Rapport PDF',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPaymentForm() {
    return SlideInUp(
      duration: Duration(milliseconds: 600),
      delay: Duration(milliseconds: 100),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student selection
            Text(
              'Sélectionner un Étudiant',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            SizedBox(height: 10),
            StreamBuilder<List<User>>(
              stream: _db.watchUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return DropdownButton<String>(
                    items: const [],
                    onChanged: null,
                    hint: const Text('Chargement...'),
                  );
                }

                final students = snapshot.data!.where((u) => u.role == UserRole.etudiant).toList();
                final uniqueStudents = <String, String>{};
                for (final u in students) {
                  uniqueStudents[u.id] = u.nomComplet;
                }

                final studentItems = uniqueStudents.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList();

                final selectedStudentValue = studentItems.any((item) => item.value == _selectedStudentId)
                    ? _selectedStudentId
                    : null;

                return DropdownButton<String>(
                  isExpanded: true,
                  value: selectedStudentValue,
                  hint: const Text('Choisir un étudiant'),
                  items: studentItems,
                  onChanged: (value) async {
                    setState(() {
                      _selectedStudentId = value;
                      _selectedFormationId = null;
                      _studentFormations = [];
                    });
                    if (value != null) {
                      await _loadStudentFormations(value);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            // Formation selection
            if (_selectedStudentId != null) ...[
              Text(
                'Sélectionner une Formation',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  final uniqueFormations = <String, String>{};
                  for (final f in _studentFormations) {
                    final id = (f['id'] ?? '').toString();
                    final title = (f['titre'] ?? 'Formation').toString();
                    if (id.isNotEmpty) {
                      uniqueFormations[id] = title;
                    }
                  }

                  final formationItems = uniqueFormations.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList();

                  final selectedFormationValue = formationItems.any((item) => item.value == _selectedFormationId)
                      ? _selectedFormationId
                      : (formationItems.isNotEmpty ? formationItems.first.value : null);

                  return DropdownButton<String>(
                    isExpanded: true,
                    value: selectedFormationValue,
                    hint: const Text('Choisir une formation'),
                    items: formationItems,
                    onChanged: (value) => setState(() => _selectedFormationId = value),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            // Amount
            Text(
              'Montant (FCFA)',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            SizedBox(height: 10),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Entrez le montant',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (value) => setState(() => _montant = double.tryParse(value) ?? 0),
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            SizedBox(height: 20),

            // Motif
            Text(
              'Motif (Optionnel)',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Ex: Paiement en ligne, Virement bancaire...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (value) => setState(() => _motif = value),
              maxLines: 2,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            SizedBox(height: 20),

            // Status
            Text(
              'Statut du Paiement',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatusOption('En Attente', 'en_attente', Colors.amber),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatusOption('Incomplet', 'incomplet', Colors.orange),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatusOption('Validé', 'valide', Color(0xFF10B981)),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Submit button
            if (_selectedStudentId != null && _selectedFormationId != null && _montant > 0)
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _createPayment,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: AppTheme.heroShadow,
                    ),
                    child: Text(
                      'Créer le Paiement',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _filterStatus,
              items: [
                DropdownMenuItem(value: 'all', child: Text('Tous statuts')),
                DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
                DropdownMenuItem(value: 'incomplet', child: Text('Incomplet')),
                DropdownMenuItem(value: 'valide', child: Text('Validé')),
              ],
              onChanged: (v) => setState(() => _filterStatus = v ?? 'all'),
            ),
          ),
          SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: Icon(Icons.refresh),
            label: Text('Appliquer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String label, String status, Color color) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paiements Récents',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        StreamBuilder<List<Payment>>(
          stream: _db.watchPayments(),
          builder: (context, snapshot) {
            final allPayments = snapshot.data ?? [];
            final filteredPayments = allPayments.where((p) {
              if (_filterStatus == 'all') return true;
              if (_filterStatus == 'en_attente') return p.status == PaymentStatus.enAttente;
              if (_filterStatus == 'incomplet') return p.status == PaymentStatus.echoue;
              if (_filterStatus == 'valide') return p.status == PaymentStatus.effectue;
              return true;
            }).toList();

            if (filteredPayments.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'Aucun paiement',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: filteredPayments.length,
              itemBuilder: (context, index) {
                final p = filteredPayments[index];
                return _buildPaymentCard(p, index);
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _updatePaymentStatus(String paiementId, String status) async {
    try {
      await _db.updatePaymentStatus(paiementId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Statut mis à jour'), backgroundColor: Color(0xFF10B981)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur mise à jour: $e'), backgroundColor: Color(0xFFEF4444)),
      );
    }
  }

  Widget _buildPaymentCard(Payment paiementObj, int index) {
    final student = _db.getUserById(paiementObj.etudiantId);
    final paiement = paiementObj.toMap();

    return SlideInUp(
      delay: Duration(milliseconds: 50 + (index * 40)),
      duration: Duration(milliseconds: 600),
      child: Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Builder(
          builder: (context) {
            final userData = {'prenom': student?.prenom ?? '', 'nom': student?.nom ?? ''};
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${userData['prenom']} ${userData['nom']}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${paiementObj.montant.toStringAsFixed(0)} FCFA',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        SizedBox(height: 6),
                        // Motif (optionnel)
                        if ((paiement['motif'] ?? '').toString().isNotEmpty)
                          Text(
                            paiement['motif'] ?? '',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
                          ),
                        // Référence transaction (si disponible)
                        if ((paiementObj.referenceTransaction ?? '').toString().isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'Réf: ${paiementObj.referenceTransaction}',
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
                            ),
                          ),
                        // Date d'effectuation (si disponible)
                        if (paiementObj.dateEffectuation != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Le: ${paiementObj.dateEffectuation!.toLocal().toString().split('.').first}',
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.black45),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getStatusColorFromPayment(paiementObj.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusLabelFromPayment(paiementObj.status),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _getStatusColorFromPayment(paiementObj.status),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (paiementObj.status != PaymentStatus.effectue)
                            ElevatedButton(
                              onPressed: () => _updatePaymentStatus(paiementObj.id, 'effectue'),
                              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF10B981), minimumSize: Size(80, 36)),
                              child: Text('Valider'),
                            ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _updatePaymentStatus(paiementObj.id, 'echoue'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: Size(80, 36)),
                            child: Text('Marquer échoué'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _loadStudentFormations(String studentId) async {
    final allFormations = _db.getFormations();
    final formations = allFormations.map((f) => {'id': f.id, 'titre': f.titre}).toList();

    if (mounted) {
      setState(() {
        _studentFormations = formations;
        _selectedFormationId = formations.isNotEmpty ? formations.first['id'] : null;
      });
    }
  }

  Future<void> _createPayment() async {
    if (_selectedStudentId == null || _selectedFormationId == null || _montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Remplissez tous les champs requis')),
      );
      return;
    }

    try {
      final student = _db.getUserById(_selectedStudentId!);
      final formation = _db.getFormationById(_selectedFormationId!);

      if (student == null || formation == null) return;

      final newPayment = Payment(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        inscriptionId: 'insc_${_selectedFormationId!}',
        etudiantId: _selectedStudentId!,
        formationId: _selectedFormationId!,
        montant: _montant,
        status: _selectedStatus == 'valide' ? PaymentStatus.effectue : PaymentStatus.enAttente,
        methode: PaymentMethod.especes,
        dateCreation: DateTime.now(),
        motif: _motif.isNotEmpty ? _motif : null,
      );

      _db.addPayment(newPayment);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Paiement créé et enregistré'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      setState(() {
        _selectedStudentId = null;
        _selectedFormationId = null;
        _montant = 0;
        _motif = '';
        _selectedStatus = 'en_attente';
        _studentFormations = [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      initialDateRange: _reportStartDate != null && _reportEndDate != null
          ? DateTimeRange(start: _reportStartDate!, end: _reportEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _reportStartDate = picked.start;
        _reportEndDate = picked.end;
      });
      _generatePaymentReport();
    }
  }

  Future<void> _generatePaymentReport() async {
    try {
      final paymentsList = _db.getPayments();
      final List<Map<String, dynamic>> payments = [];

      for (final p in paymentsList) {
        final student = _db.getUserById(p.etudiantId);
        payments.add({
          ...p.toMap(),
          'studentName': student?.nomComplet ?? 'N/A',
        });
      }

      // Calculate statistics
      String statusKeyFromMap(Map<String, dynamic> m) {
        final s = (m['status'] ?? '').toString();
        if (s.contains('effectue')) return 'valide';
        if (s.contains('echoue')) return 'incomplet';
        return 'en_attente';
      }

      final statusCounts = {
        'en_attente': payments.where((p) => statusKeyFromMap(p) == 'en_attente').length,
        'incomplet': payments.where((p) => statusKeyFromMap(p) == 'incomplet').length,
        'valide': payments.where((p) => statusKeyFromMap(p) == 'valide').length,
      };

      final totalAmount = payments.fold<double>(
        0,
        (sum, p) => sum + ((p['montant'] is num) ? (p['montant'] as num).toDouble() : double.tryParse(p['montant']?.toString() ?? '0') ?? 0),
      );

      // Generate PDF
      final pdfBytes = await PaymentReportService.generatePaymentReportPDF(
        payments: payments,
        statusCounts: statusCounts,
        totalAmount: totalAmount,
      );

      // Download PDF
      await PdfHelper.downloadPDF(
        pdfBytes,
        fileName: 'rapport_paiements_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Rapport généré et téléchargé'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error generating report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Color _getStatusColorFromPayment(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.enAttente:
        return Colors.amber;
      case PaymentStatus.effectue:
        return Color(0xFF10B981);
      case PaymentStatus.echoue:
        return Colors.orange;
    }
  }

  String _getStatusLabelFromPayment(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.enAttente:
        return 'En Attente';
      case PaymentStatus.effectue:
        return 'Validé';
      case PaymentStatus.echoue:
        return 'Échoué';
    }
  }
}
