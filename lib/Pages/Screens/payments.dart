import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestion_formations/Models/payment.dart';
import 'package:gestion_formations/Models/user.dart';
import 'package:gestion_formations/Services/db_services.dart';
import 'package:gestion_formations/config/theme.dart';

class PaymentsPage extends StatefulWidget {
  final User user;

  const PaymentsPage({super.key, required this.user});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> with TickerProviderStateMixin {
  final LocalDataService _db = LocalDataService();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  String _filterStatus = 'Tous';
  String _sortBy = 'Date';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: Duration(milliseconds: 600), vsync: this)..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get isAdmin => widget.user.role == UserRole.admin;

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return _buildStudentPaymentView();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 860;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppPadding.md : AppPadding.lg,
                vertical: AppPadding.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAdminHeader(context, isMobile),
                  SizedBox(height: AppPadding.lg),
                  _buildAdminToolbar(context, isMobile),
                  SizedBox(height: AppPadding.lg),
                  _buildPaymentsList(context, isMobile),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentPaymentView() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: FadeTransition(
        opacity: _fadeController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mes paiements',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Suivi de vos transactions',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24),
            _buildStudentPaymentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHeader(BuildContext context, bool isMobile) {
    return FadeTransition(
      opacity: _fadeController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paiements',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Gérez l\'ensemble des paiements des formations',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminToolbar(BuildContext context, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppPadding.lg),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchField(),
                  SizedBox(height: AppPadding.md),
                  _buildToolbarControls(),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildSearchField()),
                  SizedBox(width: AppPadding.lg),
                  _buildToolbarControls(),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary),
        hintText: 'Rechercher un paiement...',
        hintStyle: GoogleFonts.poppins(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      style: GoogleFonts.poppins(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildToolbarControls() {
    return Wrap(
      spacing: AppPadding.md,
      runSpacing: AppPadding.md,
      alignment: WrapAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<String>(
            value: _filterStatus,
            items: ['Tous', 'En attente', 'Effectué', 'Échoué']
                .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _filterStatus = value);
            },
            underline: SizedBox(),
            icon: Icon(Icons.filter_list_rounded, color: AppTheme.primary),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<String>(
            value: _sortBy,
            items: ['Date', 'Montant', 'Statut']
                .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _sortBy = value);
            },
            underline: SizedBox(),
            icon: Icon(Icons.sort_rounded, color: AppTheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsList(BuildContext context, bool isMobile) {
    return StreamBuilder<List<Payment>>(
      stream: _db.watchPayments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data ?? [];

        var filtered = payments.where((payment) {
          if (_filterStatus != 'Tous') {
            final statusMap = {
              'En attente': PaymentStatus.enAttente,
              'Effectué': PaymentStatus.effectue,
              'Échoué': PaymentStatus.echoue,
            };
            if (payment.status != statusMap[_filterStatus]) return false;
          }

          final query = _searchController.text.trim().toLowerCase();
          if (query.isEmpty) return true;
          return payment.etudiantId.toLowerCase().contains(query) ||
              payment.montant.toString().contains(query);
        }).toList();

        _sortPayments(filtered);

        if (filtered.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(AppPadding.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 64,
                  color: AppTheme.textSecondary,
                ),
                SizedBox(height: AppPadding.lg),
                Text(
                  'Aucun paiement',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }

        final cardWidth = isMobile ? double.infinity : 520.0;

        return Wrap(
          spacing: AppPadding.lg,
          runSpacing: AppPadding.lg,
          children: filtered.map((payment) {
            return SizedBox(
              width: cardWidth,
              child: _buildPaymentCard(context, payment),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) {
    final statusColor = _getStatusColor(payment.status);
    final statusLabel = _getStatusLabel(payment.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPaymentDetails(payment),
          child: Padding(
            padding: EdgeInsets.all(AppPadding.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (context) {
                              final student = _db.getUserById(payment.etudiantId);
                              final studentName = student?.prenom ?? 'Étudiant';
                              return Text(
                                studentName,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ref: ${payment.id.substring(0, 8)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppPadding.lg),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Montant',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${payment.montant.toStringAsFixed(2)} €',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppPadding.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        'Méthode',
                        _getMethodLabel(payment.methode),
                      ),
                    ),
                    SizedBox(width: AppPadding.md),
                    Expanded(
                      child: _buildInfoRow(
                        'Date',
                        '${payment.dateCreation.day}/${payment.dateCreation.month}/${payment.dateCreation.year}',
                      ),
                    ),
                  ],
                ),
                if (payment.status == PaymentStatus.effectue && payment.dateEffectuation != null) ...[
                  SizedBox(height: AppPadding.md),
                  _buildInfoRow(
                    'Effectué le',
                    '${payment.dateEffectuation!.day}/${payment.dateEffectuation!.month}/${payment.dateEffectuation!.year}',
                  ),
                ],
                if (payment.status == PaymentStatus.echoue && payment.motifEchec != null) ...[
                  SizedBox(height: AppPadding.md),
                  _buildInfoRow(
                    'Motif',
                    payment.motifEchec!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentPaymentsList() {
    return StreamBuilder<List<Payment>>(
      stream: _db.watchPayments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final allPayments = snapshot.data ?? [];
        final payments = allPayments.where((p) => p.etudiantId == widget.user.id).toList();

        if (payments.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_rounded, size: 56, color: AppTheme.textSecondary),
                  SizedBox(height: 14),
                  Text(
                    'Aucun paiement enregistré',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: payments.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + (index * 60)),
                builder: (context, anim, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - anim)),
                    child: Opacity(
                      opacity: anim,
                      child: _buildStudentPaymentCard(payments[index]),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStudentPaymentCard(Payment payment) {
    final statusColor = _getStatusColor(payment.status);
    final statusLabel = _getStatusLabel(payment.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPaymentDetails(payment),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${payment.montant.toStringAsFixed(2)} €',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Méthode: ${_getMethodLabel(payment.methode)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '${payment.dateCreation.day}/${payment.dateCreation.month}/${payment.dateCreation.year}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPaymentDetails(Payment payment) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Détails du paiement',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailSection('Montant', '${payment.montant.toStringAsFixed(2)} €', AppTheme.primary),
              _buildDetailSection('Statut', _getStatusLabel(payment.status), _getStatusColor(payment.status)),
              _buildDetailSection('Méthode', _getMethodLabel(payment.methode), AppTheme.primaryDark),
              _buildDetailSection('Date création', '${payment.dateCreation.day}/${payment.dateCreation.month}/${payment.dateCreation.year}', AppTheme.primary),
              if (payment.dateEffectuation != null)
                _buildDetailSection('Date effectuation', '${payment.dateEffectuation!.day}/${payment.dateEffectuation!.month}/${payment.dateEffectuation!.year}', Color(0xFF10B981)),
              if (payment.referenceTransaction != null)
                _buildDetailSection('Référence', payment.referenceTransaction!, AppTheme.primary),
              if (payment.motifEchec != null)
                _buildDetailSection('Motif échec', payment.motifEchec!, Color(0xFFEF4444)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sortPayments(List<Payment> payments) {
    if (_sortBy == 'Montant') {
      payments.sort((a, b) => b.montant.compareTo(a.montant));
    } else if (_sortBy == 'Statut') {
      payments.sort((a, b) => a.status.toString().compareTo(b.status.toString()));
    } else {
      payments.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    }
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.effectue:
        return Color(0xFF10B981);
      case PaymentStatus.echoue:
        return Color(0xFFEF4444);
      case PaymentStatus.enAttente:
      return Color(0xFFFB923C);
    }
  }

  String _getStatusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.effectue:
        return 'Effectué';
      case PaymentStatus.echoue:
        return 'Échoué';
      case PaymentStatus.enAttente:
      return 'En attente';
    }
  }

  String _getMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.virement:
        return 'Virement';
      case PaymentMethod.especes:
        return 'Espèces';
      case PaymentMethod.carte:
      return 'Carte bancaire';
    }
  }
}
