import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:gestion_formations/config/theme.dart';
import 'package:gestion_formations/Models/user.dart';
import 'package:gestion_formations/Models/inscription.dart';
import 'package:gestion_formations/Models/payment.dart';
import 'package:gestion_formations/Services/db_services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


Map<String, dynamic> resolveInscriptionUserData(
  Map<dynamic, dynamic>? userData,
  Map<dynamic, dynamic> inscription,
) {
  final fallback = {
    'prenom': (inscription['prenom'] ?? '').toString(),
    'nom': (inscription['nom'] ?? '').toString(),
    'email': (inscription['email'] ?? '').toString(),
    'telephone': (inscription['telephone'] ?? '').toString(),
  };

  if (userData == null || userData.isEmpty) {
    return fallback;
  }

  return {
    'prenom': (userData['prenom'] ?? fallback['prenom']).toString(),
    'nom': (userData['nom'] ?? fallback['nom']).toString(),
    'email': (userData['email'] ?? fallback['email']).toString(),
    'telephone': (userData['telephone'] ?? fallback['telephone']).toString(),
  };
}

Map<String, dynamic> resolveInscriptionFormationData(
  Map<dynamic, dynamic>? formationData,
  Map<dynamic, dynamic> inscription,
) {
  final fallback = {
    'titre': 'Formation',
    'description': '',
    'prix': 0,
    'prixEnLigne': 0,
    'type': 'presentiel',
  };

  if (formationData == null || formationData.isEmpty) {
    return fallback;
  }

  return {
    'titre': (formationData['titre'] ?? fallback['titre']).toString(),
    'description': (formationData['description'] ?? fallback['description']).toString(),
    'prix': formationData['prix'] ?? fallback['prix'],
    'prixEnLigne': formationData['prixEnLigne'] ?? fallback['prixEnLigne'],
    'type': (formationData['type'] ?? fallback['type']).toString(),
  };
}

String normalizeInscriptionEmail(String? email) {
  return (email ?? '').trim().toLowerCase();
}

Map<String, dynamic> buildStudentUserDataFromInscription(
  Map<dynamic, dynamic> inscription,
  String userId,
) {
  final prenom = (inscription['prenom'] ?? '').toString().trim();
  final nom = (inscription['nom'] ?? '').toString().trim();
  final email = (inscription['email'] ?? '').toString().trim();
  final phone = (inscription['telephone'] ?? '').toString().trim();

  return {
    'id': userId,
    'email': email,
    'nom': nom,
    'prenom': prenom,
    'phone': phone,
    'role': UserRole.etudiant.toString(),
    'estActif': true,
    'dateCreation': DateTime.now(),
    'dateModification': DateTime.now(),
  };
}

class AdminInscriptions extends StatefulWidget {
  const AdminInscriptions({super.key});

  @override
  State<AdminInscriptions> createState() => _AdminInscriptionsState();
}

class _AdminInscriptionsState extends State<AdminInscriptions> with TickerProviderStateMixin {
  final LocalDataService _db = LocalDataService();
  late AnimationController _fadeController;
  String filterStatus = 'en_attente';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    // Import remote inscriptions from API (if available)
    _importInscriptionsFromApi();
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
            _buildHeader(),
            SizedBox(height: 28),
            _buildFilterButtons(),
            SizedBox(height: 24),
            _buildInscriptionsList(),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Gestion des Inscriptions',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final imported = await _importInscriptionsFromApi();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Importées: $imported')),
                    );
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Rafraîchir les inscriptions',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Validez, rejetez ou mettez en attente les inscriptions reçues',
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

  Widget _buildFilterButtons() {
    return SlideInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 100),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton('En Attente', 'en_attente', AppTheme.warningDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterButton('Validées', 'valide', AppTheme.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterButton('Rejetées', 'rejete', AppTheme.error),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String status, Color color) {
    final isSelected = filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => filterStatus = status),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: color, width: isSelected ? 0 : 2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildInscriptionsList() {
    return StreamBuilder<List<Inscription>>(
      stream: _db.watchInscriptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.primary),
            ),
          );
        }

        final allInscriptions = snapshot.data ?? [];
        final filteredInscriptions = allInscriptions.where((i) {
          if (filterStatus == 'valide' || filterStatus == 'acceptee') {
            return i.status == InscriptionStatus.acceptee;
          }
          if (filterStatus == 'rejete' || filterStatus == 'rejetee') {
            return i.status == InscriptionStatus.rejetee;
          }
          return i.status == InscriptionStatus.enAttente;
        }).toList();

        if (filteredInscriptions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  const Icon(Icons.inbox_rounded, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune inscription',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredInscriptions.length,
          itemBuilder: (context, index) {
            final ins = filteredInscriptions[index];
            return _buildInscriptionCard(ins.id, ins.toMap(), index);
          },
        );
      },
    );
  }

  Widget _buildInscriptionCard(String inscriptionId, Map<String, dynamic> inscription, int index) {
    final userDocId = (inscription['etudiantId'] ?? '').toString();
    final formationDocId = (inscription['formationId'] ?? '').toString();

    final user = _db.getUserById(userDocId);
    final formation = _db.getFormationById(formationDocId);

    final userData = user?.toMap() ?? {};
    final formationData = formation?.toMap() ?? {};

    final displayUserData = resolveInscriptionUserData(userData, inscription);
    final displayFormationData = resolveInscriptionFormationData(formationData, inscription);

                return GestureDetector(
                  onTap: () => _showDetailDialog(
                    inscriptionId,
                    inscription,
                    resolveInscriptionUserData(userData, inscription),
                    resolveInscriptionFormationData(formationData, inscription),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(16),
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
                                  Text(
                                    '${displayUserData['prenom']} ${displayUserData['nom']}'.trim(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    displayFormationData['titre'] ?? 'Formation',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(inscription['statut']).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getStatusLabel(inscription['statut']),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _getStatusColor(inscription['statut']),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.email_rounded, size: 14, color: Colors.black54),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                displayUserData['email'] ?? 'N/A',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.phone_rounded, size: 14, color: Colors.black54),
                            SizedBox(width: 8),
                            Text(
                              displayUserData['telephone'] ?? 'N/A',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
  }

  void _showDetailDialog(
    String inscriptionId,
    Map<String, dynamic> inscription,
    Map<String, dynamic> userData,
    Map<String, dynamic> formationData,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Détails de l\'Inscription',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogSection('Étudiant', [
                '${userData['prenom']} ${userData['nom']}',
                userData['email'] ?? 'N/A',
                userData['telephone'] ?? 'N/A',
              ]),
              SizedBox(height: 16),
              _buildDialogSection('Formation', [
                formationData['titre'] ?? 'N/A',
                formationData['description'] ?? '',
                'Type: ${_getFormationTypeLabel(formationData['type'] ?? 'presentiel')}',
                'Prix: ${_getFormationPrice(formationData, inscription)} FCFA',
              ]),
              SizedBox(height: 16),
              _buildDialogSection('Modules Sélectionnés', [
                ...((inscription['modules'] as List<dynamic>?) ?? []).map((m) => '• $m'),
              ]),
              if (inscription['description']?.isNotEmpty ?? false)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    _buildDialogSection('Description', [
                      inscription['description'],
                    ]),
                  ],
                ),
              SizedBox(height: 20),
              _buildStatusSection(inscriptionId, inscription),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(String inscriptionId, Map<String, dynamic> inscription) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATUT',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statut Actuel: ${_getStatusLabel(inscription['statut'])}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusButton(
                      'En Attente',
                      'en_attente',
                      Colors.amber,
                      inscription['statut'],
                      () => _updateStatus(inscriptionId, 'en_attente'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusButton(
                      'Validée',
                      'valide',
                      Color(0xFF10B981),
                      inscription['statut'],
                      () => _updateStatus(inscriptionId, 'valide'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusButton(
                      'Rejetée',
                      'rejete',
                      Color(0xFFEF4444),
                      inscription['statut'],
                      () => _updateStatus(inscriptionId, 'rejete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton(
    String label,
    String status,
    Color color,
    String currentStatus,
    VoidCallback onTap,
  ) {
    final isActive = status == currentStatus;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          border: Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildDialogSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                item,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            )),
      ],
    );
  }

  Future<void> _updateStatus(String inscriptionId, String newStatus) async {
    if (newStatus == 'valide') {
      // Show dialog to set hours for each module
      await _showValidationDialog(inscriptionId);
    } else {
      try {
        await _db.updateInscriptionStatus(inscriptionId, newStatus);

        if (!mounted) return;
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Statut mis à jour'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
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
  }

  Future<void> _showValidationDialog(String inscriptionId) async {
    final inscription = _db.getInscriptionById(inscriptionId);
    if (inscription == null) return;

    final form = _db.getFormationById(inscription.formationId);
    final modules = form?.modules ?? [];

    int initialDefaultHours = 1;
    if (form != null) {
      final dureeStr = form.dureeHeures ?? '';
      final match = RegExp(r'\d+').firstMatch(dureeStr);
      if (match != null) {
        final totalHours = int.tryParse(match.group(0)!) ?? 0;
        if (totalHours > 0 && modules.isNotEmpty) {
          initialDefaultHours = (totalHours / modules.length).round();
          if (initialDefaultHours < 1) initialDefaultHours = 1;
        }
      }
    }

    final moduleHours = <String, int>{};
    for (final module in modules) {
      moduleHours[module] = initialDefaultHours;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final totalAssigned = moduleHours.values.fold(0, (acc, h) => acc + h);

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            actionsPadding: const EdgeInsets.all(20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.verified_user_rounded, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valider l\'Inscription',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Assignation des heures par module (Min. 1h)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Heures établies par module (Minimum 1h requis). Total : ${totalAssigned}h',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.primaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...modules.map((module) {
                    final hours = moduleHours[module] ?? 1;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  module,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Heures attribuées',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Boutons de contrôle + et -
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Bouton - (Minimum 1h)
                                InkWell(
                                  onTap: hours > 1
                                      ? () {
                                          setDialogState(() {
                                            moduleHours[module] = hours - 1;
                                          });
                                        }
                                      : null,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(9),
                                    bottomLeft: Radius.circular(9),
                                  ),
                                    child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: hours > 1 ? AppTheme.accent.withValues(alpha: 0.06) : AppTheme.surfaceVariant,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(9),
                                        bottomLeft: Radius.circular(9),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.remove_rounded,
                                      size: 18,
                                      color: hours > 1 ? AppTheme.accent : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                                // Affichage du nombre d'heures
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    child: Text(
                                    '$hours h',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                                // Bouton +
                                InkWell(
                                  onTap: () {
                                    setDialogState(() {
                                      moduleHours[module] = hours + 1;
                                    });
                                  },
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(9),
                                    bottomRight: Radius.circular(9),
                                  ),
                                    child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(9),
                                        bottomRight: Radius.circular(9),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add_rounded,
                                      size: 18,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
                OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accent,
                  side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.2)),
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.06),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                child: Text('Annuler', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              ),
                ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 2,
                ),
                label: Text('Valider', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                onPressed: () async {
                  await _db.updateInscriptionStatus(inscriptionId, 'valide');
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Inscription validée!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<int> _importInscriptionsFromApi() async {
    var importedCount = 0;
    try {
      final base = Uri.base.origin;
      final uri = Uri.parse('$base/api/inscriptions');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return importedCount;
      final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          // avoid duplicates: match by email + formationId + dateInscription
          final existing = _db.getInscriptions().where((i) {
            final sameEmail = (i.email ?? '').toString().trim() == (item['email'] ?? '').toString().trim();
            final sameFormation = i.formationId == (item['formationId'] ?? '');
            return sameEmail && sameFormation;
          }).isNotEmpty;

          if (!existing) {
            final montant = (item['montant'] ?? 0).toDouble();
            PaymentMethod methode = PaymentMethod.virement;
            final m = (item['methode'] ?? '').toString().toLowerCase();
            if (m.contains('carte')) methode = PaymentMethod.carte;
            if (m.contains('especes')) methode = PaymentMethod.especes;

            await _db.createInscription(
              etudiantId: item['etudiantId']?.toString() ?? 'web_${DateTime.now().millisecondsSinceEpoch}',
              formationId: item['formationId']?.toString() ?? '',
              montant: montant,
              methode: methode,
              prenom: item['prenom']?.toString(),
              nom: item['nom']?.toString(),
              email: item['email']?.toString(),
              telephone: item['telephone']?.toString(),
              description: item['description']?.toString(),
              modules: item['modules'] is List ? List<String>.from(item['modules']) : null,
              typeFormation: item['typeFormation']?.toString(),
            );
            importedCount++;
          }
        }
      }
    } catch (e) {
      // fail silently; API may be unavailable
    }
    return importedCount;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_attente':
        return Colors.amber;
      case 'valide':
        return Color(0xFF10B981);
      case 'rejete':
        return Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'en_attente':
        return 'En Attente';
      case 'valide':
        return 'Validée';
      case 'rejete':
        return 'Rejetée';
      default:
        return 'Unknown';
    }
  }

  String _getFormationTypeLabel(String type) {
    switch (type) {
      case 'enligne':
        return 'En ligne';
      case 'presentiel':
        return 'Présentiel';
      case 'mixte':
        return 'Mixte';
      default:
        return 'Présentiel';
    }
  }

  String _getFormationPrice(Map<String, dynamic> formationData, Map<String, dynamic> inscription) {
    final type = inscription['typeFormation'] ?? formationData['type'] ?? 'presentiel';
    if (type == 'enligne' && formationData['prixEnLigne'] != null) {
      return formationData['prixEnLigne'].toString();
    }
    return formationData['prix']?.toString() ?? '0';
  }
}
