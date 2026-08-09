import 'package:animate_do/animate_do.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestion_formations/config/theme.dart';
import 'package:gestion_formations/Models/formation.dart';
import 'package:gestion_formations/Services/db_services.dart';
import 'package:gestion_formations/Services/imagekit_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class AdminFormations extends StatefulWidget {
  const AdminFormations({super.key});


  @override
  State<AdminFormations> createState() => _AdminFormationsState();
}

class _AdminFormationsState extends State<AdminFormations>
    with TickerProviderStateMixin {
  final searchController = TextEditingController();
  final LocalDataService _db = LocalDataService();
  String selectedStatus = 'Tous';
  String selectedSort = 'Date création';
  String selectedFormationKind = 'Tous';
  bool _hasChosenFormationType = false;
  final Set<String> _expandedFormationIds = {};
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasChosenFormationType) {
        _showFormationTypeDialog(context);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _toggleFormationExpansion(String formationId) {
    setState(() {
      if (_expandedFormationIds.contains(formationId)) {
        _expandedFormationIds.remove(formationId);
      } else {
        _expandedFormationIds.add(formationId);
      }
    });
  }

  void _showFormationTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Afficher les formations',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
              onPressed: () {
                setState(() {
                  _hasChosenFormationType = true;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
        content: Text(
          'Choisissez la catégorie de formations à afficher par défaut.',
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.orangeGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () {
                setState(() {
                  selectedFormationKind = 'Stage';
                  _hasChosenFormationType = true;
                });
                Navigator.pop(context);
              },
              child: Text(
                'Stage (SFP)',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () {
                setState(() {
                  selectedFormationKind = 'Formation';
                  _hasChosenFormationType = true;
                });
                Navigator.pop(context);
              },
              child: Text(
                'Formation',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 28),
          _buildSearchAndFilters(isMobile),
          const SizedBox(height: 28),
          _buildFormationsStream(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return FadeTransition(
      opacity: _fadeController,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Formations',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gérez le catalogue et les sessions de formations',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          if (!isMobile)
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.heroShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showCreateFormationDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Créer',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (isMobile)
            FloatingActionButton(
              onPressed: () => _showCreateFormationDialog(context),
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.add_rounded),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isMobile) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.softShadow,
          ),
          child: TextField(
            controller: searchController,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Rechercher une formation...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),

        SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Tous', 'Tous'),
              SizedBox(width: 10),
              _buildFilterChip('Programmée', 'Programmée'),
              SizedBox(width: 10),
              _buildFilterChip('En Cours', 'En Cours'),
              SizedBox(width: 10),
              _buildFilterChip('Terminée', 'Terminée'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedStatus == value;
    return GestureDetector(
      onTap: () => setState(() => selectedStatus = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: isSelected
              ? AppTheme.primaryGradient
              : null,
          color: isSelected ? null : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildFormationsStream(BuildContext context, bool isMobile) {
    return StreamBuilder<List<Formation>>(
      stream: _db.watchFormations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.primary),
            ),
          );
        }

        final formations = snapshot.data ?? [];
        final filtered = _filterFormations(formations);
        final sorted = _sortFormations(filtered);

        if (sorted.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.school_rounded, size: 48, color: Colors.black12),
                  SizedBox(height: 16),
                  Text(
                    'Aucune formation',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: sorted.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: _buildFormationCardPremium(context, sorted[index], index),
          ),
        );
      },
    );
  }

  Widget _buildFormationCardPremium(
    BuildContext context,
    Formation formation,
    int index,
  ) {
    final formationId = formation.id;
    final isExpanded = _expandedFormationIds.contains(formationId);

    return SlideInUp(
      delay: Duration(milliseconds: 50 + (index * 40)),
      duration: Duration(milliseconds: 420),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              leading:
                  formation.imageUrl != null && formation.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        formation.imageUrl!,
                        width: formation.imageFormat == ImageFormat.carre ? 64 : 48,
                        height: formation.imageFormat == ImageFormat.carre ? 64 : 85,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: formation.imageFormat == ImageFormat.carre ? 64 : 48,
                          height: formation.imageFormat == ImageFormat.carre ? 64 : 85,
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        color: Colors.grey.shade600,
                      ),
                    ),
              title: Text(
                formation.titre,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                formation.description,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (formation.type == FormationType.mixte && formation.prixEnLigne != null) ...[
                        Text(
                          'En ligne: ${formation.prixEnLigne!.toStringAsFixed(0)}F',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Présentiel: ${formation.prix.toStringAsFixed(0)}F',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ] else if (formation.type == FormationType.enligne) ...[
                        Text(
                          'En ligne: ${(formation.prixEnLigne ?? formation.prix).toStringAsFixed(0)}F',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Présentiel: ${formation.prix.toStringAsFixed(0)}F',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(width: 8),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'modifier') {
                        _showEditFormationDialog(context, formation);
                      } else if (value == 'supprimer') {
                        _confirmDeleteFormation(context, formation);
                      } else if (value == 'partager') {
                        _showFormationQrDialog(context, formation);
                      } else if (value == 'voir') {
                        _toggleFormationExpansion(formationId);
                      }
                    },
                    itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'voir',
                            child: Text(
                              isExpanded ? 'Cacher détails' : 'Voir détails',
                            ),
                          ),
                          PopupMenuItem(
                            value: 'modifier',
                            child: Text('Modifier'),
                          ),
                          PopupMenuItem(
                            value: 'partager',
                            child: Text('Partager'),
                          ),
                          PopupMenuItem(
                            value: 'supprimer',
                            child: Text(
                              'Supprimer',
                              style: TextStyle(color: Color(0xFFEF4444)),
                            ),
                          ),
                        ],
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: Colors.black54,
                        ),
                      ),
                ],
              ),
              onTap: () => _toggleFormationExpansion(formationId),
            ),
            AnimatedSize(
              duration: Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildInfoRowCompact(
                                'Type',
                                _formatType(formation.type),
                              ),
                              _buildInfoRowCompact(
                                'Statut',
                                _formatStatus(formation.status),
                              ),
                              _buildInfoRowCompact(
                                'Durée',
                                '${formation.dureeSemaines} sem.',
                              ),
                              _buildInfoRowCompact(
                                'Places',
                                '${formation.nombreInscrits ?? 0}/${formation.capaciteMax ?? 0}',
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (formation.dateDebut != null)
                                _buildInfoRowCompact(
                                  'Début',
                                  _formatDate(formation.dateDebut!),
                                ),
                              if (formation.dateFin != null)
                                _buildInfoRowCompact(
                                  'Fin',
                                  _formatDate(formation.dateFin!),
                                ),
                              if (formation.dureeHeures != null &&
                                  formation.dureeHeures!.isNotEmpty)
                                _buildInfoRowCompact(
                                  'Heures',
                                  formation.dureeHeures!,
                                ),
                            ],
                          ),
                          if (formation.modules.isNotEmpty) ...[
                            SizedBox(height: 12),
                            Text(
                              'Modules',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              formation.modules.join(' • '),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                          if (formation.modulesBonus.isNotEmpty) ...[
                            SizedBox(height: 12),
                            Text(
                              'Modules bonus',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              formation.modulesBonus.join(' • '),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                          if (formation.formateurIds.isNotEmpty) ...[
                            SizedBox(height: 12),
                            Text(
                              'Formateurs',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              formation.formateurIds.join(', '),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                          if (formation.horaires.isNotEmpty) ...[
                            SizedBox(height: 12),
                            Text(
                              'Horaires',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              formation.horaires
                                  .map(
                                    (h) =>
                                        '${h.jour}: ${h.heureDebut}-${h.heureFin}',
                                  )
                                  .join('\n'),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowCompact(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  List<Formation> _filterFormations(List<Formation> formations) {
    final query = searchController.text.trim().toLowerCase();
    return formations.where((formation) {
      final formationStatus = _formatStatus(formation.status);
      final matchesStatus =
          selectedStatus == 'Tous' || formationStatus == selectedStatus;
      final matchesType =
          selectedFormationKind == 'Tous' ||
          (selectedFormationKind == 'Stage'
              ? formation.estStage
              : !formation.estStage);
      final matchesSearch =
          query.isEmpty ||
          formation.titre.toLowerCase().contains(query) ||
          formation.description.toLowerCase().contains(query);
      return matchesStatus && matchesType && matchesSearch;
    }).toList();
  }

  List<Formation> _sortFormations(List<Formation> formations) {
    final sorted = [...formations];
    switch (selectedSort) {
      case 'Prix':
        sorted.sort((a, b) => a.prix.compareTo(b.prix));
        break;
      case 'Titre':
        sorted.sort((a, b) => a.titre.compareTo(b.titre));
        break;
      default:
        sorted.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    }
    return sorted;
  }

  String _formatType(FormationType type) {
    switch (type) {
      case FormationType.presentielle:
        return 'Présentielle';
      case FormationType.mixte:
        return 'Mixte';
      default:
        return 'En ligne';
    }
  }

  String _formatStatus(FormationStatus status) {
    switch (status) {
      case FormationStatus.enCours:
        return 'En Cours';
      case FormationStatus.terminee:
        return 'Terminée';
      default:
        return 'Programmée';
    }
  }

  Future<void> _showFormationQrDialog(
    BuildContext context,
    Formation formation,
  ) async {
    final qrKey = GlobalKey();
    // Build a share URL that points to the public static formation page
    final origin = Uri.base.origin;
    final url = '$origin/formation.html?id=${formation.id}';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Partager la formation',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: qrKey,
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(12),
                  child: QrImageView(
                    data: url,
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                    embeddedImage: const AssetImage('images/Malintic.png'),
                    embeddedImageStyle: QrEmbeddedImageStyle(
                      size: const Size(30, 30),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    url,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final localContext = context;
                  final bytes = await _captureQrPng(qrKey);
                  if (bytes == null) {
                    if (!localContext.mounted) return;
                    ScaffoldMessenger.of(localContext).showSnackBar(
                      SnackBar(content: Text('Impossible de générer le QR.')),
                    );
                    return;
                  }

                  final directory = await getTemporaryDirectory();
                  final file = File('${directory.path}/formation_qr.png');
                  await file.writeAsBytes(bytes);

                  final shareText =
                      '''
📚 *${formation.titre}*

${formation.description}

💰 *Prix:* ${(formation.type == FormationType.enligne || formation.type == FormationType.mixte ? (formation.prixEnLigne ?? formation.prix) : formation.prix)}F CFA
⏱️ *Durée:* ${formation.dureeSemaines} semaine(s)
📍 *Type:* ${formation.type == FormationType.enligne
                          ? '🌐 En ligne'
                          : formation.type == FormationType.mixte
                          ? '🧩 Mixte'
                          : '🏢 Présentielle'}

✨ *Modules:*
${formation.modules.map((m) => '• $m').join('\n')}

🔗 Découvrez plus:
$url

👇 Scannez le QR code ci-dessous pour accéder directement!
                  ''';

                  if (!localContext.mounted) return;
                  Share.shareXFiles([XFile(file.path)], text: shareText);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.share_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Partager',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _captureQrPng(GlobalKey key) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime? _parseDate(String rawDate) {
    final trimmed = rawDate.trim();
    if (trimmed.isEmpty) return null;

    final isoDate = DateTime.tryParse(trimmed);
    if (isoDate != null) return isoDate;

    final frenchMatch = RegExp(
      r'^(\d{2})[\/\-](\d{2})[\/\-](\d{4})$',
    ).firstMatch(trimmed);
    if (frenchMatch != null) {
      final day = int.parse(frenchMatch.group(1)!);
      final month = int.parse(frenchMatch.group(2)!);
      final year = int.parse(frenchMatch.group(3)!);
      return DateTime(year, month, day);
    }

    final dashFormat = RegExp(
      r'^(\d{4})[\/\-](\d{2})[\/\-](\d{2})$',
    ).firstMatch(trimmed);
    if (dashFormat != null) {
      final year = int.parse(dashFormat.group(1)!);
      final month = int.parse(dashFormat.group(2)!);
      final day = int.parse(dashFormat.group(3)!);
      return DateTime(year, month, day);
    }

    return null;
  }

  void _showCreateFormationDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titreController = TextEditingController();
    final descriptionController = TextEditingController();
    final modulesController = TextEditingController();
    
    final imageUrlController = TextEditingController();
    final formateursController = TextEditingController();
    final prixController = TextEditingController();
    final prixEnLigneController = TextEditingController();
    final dureeController = TextEditingController();
    final heuresController = TextEditingController();
    final horairesController = TextEditingController();
    final dateDebutController = TextEditingController();
    final dateFinController = TextEditingController();
    final capaciteController = TextEditingController();
    final maxModulesController = TextEditingController();
    String typeValue = 'En ligne';
    String statusValue = 'Programmée';
    bool isStage = false;
    String? uploadedImageUrl;
    bool isUploading = false;
    ImageFormat? imageFormatValue;

    showDialog(
      context: context,
      builder: (context) => SizedBox(
        width: 600,
        child: StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Créer une formation',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFormField(
                      titreController,
                      'Titre',
                      'Titre requis',
                      Icons.title_rounded,
                    ),
                    _buildFormField(
                      descriptionController,
                      'Description',
                      'Description requise',
                      Icons.description_rounded,
                      maxLines: 3,
                    ),
                    _buildFormField(
                      modulesController,
                      'Modules (séparés par des virgules)',
                      null,
                      Icons.book_rounded,
                      helperText: 'Exemple : HTML, CSS, Flutter',
                      maxLines: 2,
                    ),
                    // Image picker avec upload ImageKit
                    Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Image',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          if (uploadedImageUrl != null &&
                              uploadedImageUrl!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    uploadedImageUrl!,
                                    fit: BoxFit.cover,
                                    height: 150,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: 150,
                                              color: Colors.grey.shade200,
                                              child: Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          uploadedImageUrl = null;
                                          imageUrlController.clear();
                                        });
                                      },
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      label: Text(
                                        'Supprimer',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
                            InkWell(
                              onTap: isUploading
                                  ? null
                                  : () async {
                                      final localContext = context;
                                      setState(() {
                                        isUploading = true;
                                      });
                                      try {
                                        final imageKitService =
                                            ImageKitService();
                                        final url = await imageKitService
                                            .pickAndUploadImage();
                                        if (!mounted) return;
                                        if (url != null) {
                                          setState(() {
                                            uploadedImageUrl = url;
                                            imageUrlController.text = url;
                                          });
                                        }
                                      } catch (e) {
                                        if (!localContext.mounted) return;
                                        ScaffoldMessenger.of(
                                          localContext,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Erreur: ${e.toString()}',
                                            ),
                                            backgroundColor: Color(0xFFEF4444),
                                          ),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            isUploading = false;
                                          });
                                        }
                                      }
                                    },
                              child: Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isUploading
                                        ? Colors.grey.shade300
                                        : AppTheme.primary,
                                    style: BorderStyle.solid,
                                  ),
                                  color: isUploading
                                      ? Colors.grey.shade100
                                      : Colors.white,
                                ),
                                child: isUploading
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                    AppTheme.primary,
                                                  ),
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              'Upload en cours...',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_rounded,
                                            size: 48,
                                            color: AppTheme.primary,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Cliquer pour ajouter une image',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<ImageFormat>(
                      initialValue: imageFormatValue,
                      decoration: InputDecoration(
                        labelText: 'Format de l\'image',
                        prefixIcon: Icon(Icons.crop),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: ImageFormat.carre,
                          child: Text('Carré (1:1)'),
                        ),
                        DropdownMenuItem(
                          value: ImageFormat.vertical,
                          child: Text('Vertical (9:16)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => imageFormatValue = value);
                      },
                    ),
                    _buildFormField(
                      formateursController,
                      'Formateurs (IDs)',
                      null,
                      Icons.school_rounded,
                    ),
                    _buildFormField(
                      prixController,
                      'Prix',
                      null,
                      Icons.attach_money_rounded,
                      isNumber: true,
                    ),
                    if (typeValue == 'En ligne' || typeValue == 'Mixte')
                      _buildFormField(
                        prixEnLigneController,
                        'Prix en ligne',
                        null,
                        Icons.computer_rounded,
                        isNumber: true,
                      ),
                    _buildFormField(
                      dureeController,
                      'Durée (semaines)',
                      null,
                      Icons.schedule_rounded,
                      isNumber: true,
                    ),
                    _buildFormField(
                      heuresController,
                      'Heures',
                      null,
                      Icons.timer_rounded,
                    ),
                    _buildFormField(
                      horairesController,
                      'Horaires',
                      null,
                      Icons.access_time_rounded,
                      maxLines: 3,
                    ),
                    _buildFormField(
                      dateDebutController,
                      'Début (JJ/MM/AAAA)',
                      null,
                      Icons.calendar_today_rounded,
                    ),
                    _buildFormField(
                      dateFinController,
                      'Fin (JJ/MM/AAAA)',
                      null,
                      Icons.calendar_today_rounded,
                    ),
                    _buildFormField(
                      capaciteController,
                      'Places max',
                      null,
                      Icons.people_rounded,
                      isNumber: true,
                    ),
                    if (isStage)
                      Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 8),
                        child: _buildFormField(
                          maxModulesController,
                          'Nbr max de modules par étudiant (SFP)',
                          null,
                          Icons.view_module_rounded,
                          isNumber: true,
                        ),
                      ),
                    SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'C’est un stage',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      value: isStage,
                      onChanged: (value) =>
                          setState(() => isStage = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppTheme.primary,
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: ['En ligne', 'Présentielle', 'Mixte'].contains(typeValue) ? typeValue : 'En ligne',
                      decoration: InputDecoration(
                        labelText: 'Type',
                        prefixIcon: Icon(Icons.computer_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['En ligne', 'Présentielle', 'Mixte']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => typeValue = value);
                      },
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: ['Programmée', 'En Cours', 'Terminée'].contains(statusValue) ? statusValue : 'Programmée',
                      decoration: InputDecoration(
                        labelText: 'Statut',
                        prefixIcon: Icon(Icons.info_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['Programmée', 'En Cours', 'Terminée']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => statusValue = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (!formKey.currentState!.validate()) return;

                      final modules = modulesController.text
                          .split(',')
                          .map((value) => value.trim())
                          .where((value) => value.isNotEmpty)
                          .toList();
                      final formateurIds = formateursController.text
                          .split(',')
                          .map((value) => value.trim())
                          .where((value) => value.isNotEmpty)
                          .toList();
                      final prix =
                          double.tryParse(prixController.text.trim()) ?? 0.0;
                      final prixEnLigne = prixEnLigneController.text.trim().isEmpty
                          ? null
                          : double.tryParse(prixEnLigneController.text.trim());
                      final dureeSemaines =
                          int.tryParse(dureeController.text.trim()) ?? 0;
                      final capaciteMax = int.tryParse(
                        capaciteController.text.trim(),
                      );
                      final maxModulesParEtudiant = isStage
                          ? null
                          : int.tryParse(maxModulesController.text.trim());
                      final dateDebut = dateDebutController.text.trim().isEmpty
                          ? null
                          : _parseDate(dateDebutController.text.trim());
                      final dateFin = dateFinController.text.trim().isEmpty
                          ? null
                          : _parseDate(dateFinController.text.trim());
                      final horaires = _parseHoraires(
                        horairesController.text.trim(),
                      );

                      final newFormation = Formation(
                        id: '',
                        titre: titreController.text.trim(),
                        description: descriptionController.text.trim(),
                        modules: modules,
                        imageUrl: imageUrlController.text.trim().isEmpty
                            ? null
                            : imageUrlController.text.trim(),
                        imageFormat: imageFormatValue,
                        formateurIds: formateurIds,
                        prix: prix,
                        prixEnLigne: prixEnLigne,
                        type: typeValue == 'Présentielle'
                            ? FormationType.presentielle
                            : typeValue == 'Mixte'
                            ? FormationType.mixte
                            : FormationType.enligne,
                        status: statusValue == 'En Cours'
                            ? FormationStatus.enCours
                            : statusValue == 'Terminée'
                            ? FormationStatus.terminee
                            : FormationStatus.programmee,
                        dureeSemaines: dureeSemaines,
                        dureeHeures: heuresController.text.trim().isEmpty
                            ? null
                            : heuresController.text.trim(),
                        horaires: horaires,
                        dateDebut: dateDebut,
                        dateFin: dateFin,
                        dateCreation: DateTime.now(),
                        capaciteMax: capaciteMax,
                        nombreInscrits: 0,
                        estStage: isStage,
                        maxModulesParEtudiant: maxModulesParEtudiant,
                      );

                      final localContext = context;
                      try {
                        await _db.addFormation(newFormation);
                        if (!localContext.mounted) return;
                        Navigator.pop(localContext);
                        ScaffoldMessenger.of(localContext).showSnackBar(
                          SnackBar(
                            content: Text('Formation créée avec succès'),
                            backgroundColor: AppTheme.primary,
                          ),
                        );
                      } catch (e) {
                        if (!localContext.mounted) return;
                        ScaffoldMessenger.of(localContext).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: ${e.toString()}'),
                            backgroundColor: Color(0xFFEF4444),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Text(
                        'Créer',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
    TextEditingController controller,
    String label,
    String? validator,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
    String? helperText,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: validator != null
            ? (value) => value?.trim().isEmpty == true ? validator : null
            : null,
      ),
    );
  }

  void _showEditFormationDialog(BuildContext context, Formation formation) {
    final titreController = TextEditingController(text: formation.titre);
    final descriptionController = TextEditingController(
      text: formation.description,
    );
    final modulesController = TextEditingController(
      text: formation.modules.join(', '),
    );
    
    final imageUrlController = TextEditingController(
      text: formation.imageUrl ?? '',
    );
    final formateursController = TextEditingController(
      text: formation.formateurIds.join(', '),
    );
    final prixController = TextEditingController(
      text: formation.prix.toString(),
    );
    final prixEnLigneController = TextEditingController(
      text: formation.prixEnLigne?.toString() ?? '',
    );
    final dureeController = TextEditingController(
      text: formation.dureeSemaines.toString(),
    );
    final heuresController = TextEditingController(
      text: formation.dureeHeures ?? '',
    );
    final horairesController = TextEditingController(
      text: formation.horaires
          .map((h) => '${h.jour};${h.heureDebut};${h.heureFin}')
          .join('\n'),
    );
    final dateDebutController = TextEditingController(
      text: formation.dateDebut != null
          ? _formatDate(formation.dateDebut!)
          : '',
    );
    final dateFinController = TextEditingController(
      text: formation.dateFin != null ? _formatDate(formation.dateFin!) : '',
    );
    final capaciteController = TextEditingController(
      text: formation.capaciteMax?.toString() ?? '',
    );
    final maxModulesController = TextEditingController(
      text: formation.maxModulesParEtudiant?.toString() ?? '',
    );
    String typeValue = _formatType(formation.type);
    String statusValue = _formatStatus(formation.status);
    bool isStage = formation.estStage;
    final formKey = GlobalKey<FormState>();
    String? uploadedImageUrl = formation.imageUrl;
    bool isUploading = false;
    ImageFormat? imageFormatValue = formation.imageFormat;

    showDialog(
      context: context,
      builder: (context) => SizedBox(
        width: 600,
        child: StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Modifier la formation',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFormField(
                      titreController,
                      'Titre',
                      'Titre requis',
                      Icons.title_rounded,
                    ),
                    _buildFormField(
                      descriptionController,
                      'Description',
                      'Description requise',
                      Icons.description_rounded,
                      maxLines: 3,
                    ),
                    _buildFormField(
                      modulesController,
                      'Modules (séparés par des virgules)',
                      null,
                      Icons.book_rounded,
                      helperText: 'Exemple : HTML, CSS, Flutter',
                      maxLines: 2,
                    ),
                    // Image picker avec upload ImageKit
                    Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Image',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          if (uploadedImageUrl != null &&
                              uploadedImageUrl!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    uploadedImageUrl!,
                                    fit: BoxFit.cover,
                                    height: 150,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: 150,
                                              color: Colors.grey.shade200,
                                              child: Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          uploadedImageUrl = null;
                                          imageUrlController.clear();
                                        });
                                      },
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      label: Text(
                                        'Supprimer',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
                            InkWell(
                              onTap: isUploading
                                  ? null
                                  : () async {
                                    final localContext = context;
                                      setState(() {
                                        isUploading = true;
                                      });
                                      try {
                                        final imageKitService =
                                            ImageKitService();
                                        final url = await imageKitService
                                            .pickAndUploadImage();
                                        if (url != null) {
                                          setState(() {
                                            uploadedImageUrl = url;
                                            imageUrlController.text = url;
                                          });
                                        }
                                      } catch (e) {
                                        if (!localContext.mounted) return;
                                        ScaffoldMessenger.of(
                                          localContext,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Erreur: ${e.toString()}',
                                            ),
                                            backgroundColor: Color(0xFFEF4444),
                                          ),
                                        );
                                      } finally {
                                        setState(() {
                                          isUploading = false;
                                        });
                                      }
                                    },
                              child: Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isUploading
                                        ? Colors.grey.shade300
                                        : AppTheme.primary,
                                    style: BorderStyle.solid,
                                  ),
                                  color: isUploading
                                      ? Colors.grey.shade100
                                      : Colors.white,
                                ),
                                child: isUploading
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                    AppTheme.primary,
                                                  ),
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              'Upload en cours...',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_rounded,
                                            size: 48,
                                            color: AppTheme.primary,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Cliquer pour ajouter une image',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<ImageFormat>(
                      initialValue: imageFormatValue,
                      decoration: InputDecoration(
                        labelText: 'Format de l\'image',
                        prefixIcon: Icon(Icons.crop),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: ImageFormat.carre,
                          child: Text('Carré (1:1)'),
                        ),
                        DropdownMenuItem(
                          value: ImageFormat.vertical,
                          child: Text('Vertical (9:16)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => imageFormatValue = value);
                      },
                    ),
                    _buildFormField(
                      formateursController,
                      'Formateurs (IDs)',
                      null,
                      Icons.school_rounded,
                    ),
                    _buildFormField(
                      prixController,
                      'Prix',
                      null,
                      Icons.attach_money_rounded,
                      isNumber: true,
                    ),
                    if (typeValue == 'En ligne' || typeValue == 'Mixte')
                      _buildFormField(
                        prixEnLigneController,
                        'Prix en ligne',
                        null,
                        Icons.computer_rounded,
                        isNumber: true,
                      ),
                    _buildFormField(
                      dureeController,
                      'Durée (semaines)',
                      null,
                      Icons.schedule_rounded,
                      isNumber: true,
                    ),
                    _buildFormField(
                      heuresController,
                      'Heures',
                      null,
                      Icons.timer_rounded,
                    ),
                    _buildFormField(
                      horairesController,
                      'Horaires',
                      null,
                      Icons.access_time_rounded,
                      maxLines: 3,
                    ),
                    _buildFormField(
                      dateDebutController,
                      'Début (JJ/MM/AAAA)',
                      null,
                      Icons.calendar_today_rounded,
                    ),
                    _buildFormField(
                      dateFinController,
                      'Fin (JJ/MM/AAAA)',
                      null,
                      Icons.calendar_today_rounded,
                    ),
                    _buildFormField(
                      capaciteController,
                      'Places max',
                      null,
                      Icons.people_rounded,
                      isNumber: true,
                    ),
                    if (!isStage)
                      Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 8),
                        child: _buildFormField(
                          maxModulesController,
                          'Nbr max de modules par étudiant (SFP)',
                          null,
                          Icons.view_module_rounded,
                          isNumber: true,
                        ),
                      ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: ['En ligne', 'Présentielle', 'Mixte'].contains(typeValue) ? typeValue : 'En ligne',
                      decoration: InputDecoration(
                        labelText: 'Type',
                        prefixIcon: Icon(Icons.computer_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['En ligne', 'Présentielle', 'Mixte']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => typeValue = value);
                      },
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: ['Programmée', 'En Cours', 'Terminée'].contains(statusValue) ? statusValue : 'Programmée',
                      decoration: InputDecoration(
                        labelText: 'Statut',
                        prefixIcon: Icon(Icons.info_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['Programmée', 'En Cours', 'Terminée']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => statusValue = value);
                      },
                    ),
                    SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'C’est un stage',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      value: isStage,
                      onChanged: (value) =>
                          setState(() => isStage = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppTheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (!formKey.currentState!.validate()) return;

                      final modules = modulesController.text
                          .split(',')
                          .map((value) => value.trim())
                          .where((value) => value.isNotEmpty)
                          .toList();
                      final formateurIds = formateursController.text
                          .split(',')
                          .map((value) => value.trim())
                          .where((value) => value.isNotEmpty)
                          .toList();
                      final prix =
                          double.tryParse(prixController.text.trim()) ?? 0.0;
                      final prixEnLigne = prixEnLigneController.text.trim().isEmpty
                          ? null
                          : double.tryParse(prixEnLigneController.text.trim());
                      final dureeSemaines =
                          int.tryParse(dureeController.text.trim()) ?? 0;
                      final capaciteMax = int.tryParse(
                        capaciteController.text.trim(),
                      );
                      final maxModulesParEtudiant = isStage
                          ? null
                          : int.tryParse(maxModulesController.text.trim());
                      final dateDebut = dateDebutController.text.trim().isEmpty
                          ? null
                          : _parseDate(dateDebutController.text.trim());
                      final dateFin = dateFinController.text.trim().isEmpty
                          ? null
                          : _parseDate(dateFinController.text.trim());
                      final horaires = _parseHoraires(
                        horairesController.text.trim(),
                      );

                      final updatedFormation = Formation(
                        id: formation.id,
                        titre: titreController.text.trim(),
                        description: descriptionController.text.trim(),
                        modules: modules,
                        imageUrl: imageUrlController.text.trim().isEmpty
                            ? null
                            : imageUrlController.text.trim(),
                        imageFormat: imageFormatValue,
                        formateurIds: formateurIds,
                        prix: prix,
                        prixEnLigne: prixEnLigne,
                        type: typeValue == 'Présentielle'
                            ? FormationType.presentielle
                            : typeValue == 'Mixte'
                            ? FormationType.mixte
                            : FormationType.enligne,
                        status: statusValue == 'En Cours'
                            ? FormationStatus.enCours
                            : statusValue == 'Terminée'
                            ? FormationStatus.terminee
                            : FormationStatus.programmee,
                        dureeSemaines: dureeSemaines,
                        dureeHeures: heuresController.text.trim().isEmpty
                            ? null
                            : heuresController.text.trim(),
                        horaires: horaires,
                        dateDebut: dateDebut,
                        dateFin: dateFin,
                        dateCreation: formation.dateCreation,
                        capaciteMax: capaciteMax,
                        nombreInscrits: formation.nombreInscrits,
                        estStage: isStage,
                        maxModulesParEtudiant: maxModulesParEtudiant,
                      );

                      final localContext = context;
                      try {
                        await _db.updateFormation(updatedFormation);
                        if (!localContext.mounted) return;
                        Navigator.pop(localContext);
                        ScaffoldMessenger.of(localContext).showSnackBar(
                          SnackBar(
                            content: Text('Formation mise à jour'),
                            backgroundColor: Color(0xFFEF4444),
                          ),
                        );
                      } catch (e) {
                        if (!localContext.mounted) return;
                        ScaffoldMessenger.of(localContext).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: ${e.toString()}'),
                            backgroundColor: Color(0xFFEF4444),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Text(
                        'Enregistrer',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteFormation(
    BuildContext context,
    Formation formation,
  ) async {
    final localContext = context;
    final confirmed = await showDialog<bool>(
      context: localContext,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Supprimer la formation',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${formation.titre}" ?',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context, true),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Supprimer',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _db.deleteFormation(formation.id);
      if (!localContext.mounted) return;
      ScaffoldMessenger.of(localContext).showSnackBar(
        SnackBar(
          content: Text('Formation supprimée'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    } catch (e) {
      if (!localContext.mounted) return;
      ScaffoldMessenger.of(localContext).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  List<Horaire> _parseHoraires(String rawHoraires) {
    if (rawHoraires.isEmpty) return [];
    return rawHoraires.split('\n').map((line) {
      final parts = line
          .split(RegExp(r'[;,]'))
          .map((part) => part.trim())
          .toList();
      if (parts.length >= 3) {
        return Horaire(
          jour: parts[0],
          heureDebut: parts[1],
          heureFin: parts[2],
        );
      }
      return Horaire(
        jour: parts[0],
        heureDebut: parts.length > 1 ? parts[1] : '',
        heureFin: parts.length > 2 ? parts[2] : '',
      );
    }).toList();
  }
}
