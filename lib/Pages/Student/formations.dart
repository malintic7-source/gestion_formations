import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:gestion_formations/Models/user.dart';
import 'package:gestion_formations/Models/formation.dart';
import 'package:gestion_formations/Services/db_services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gestion_formations/config/theme.dart';

class StudentFormations extends StatefulWidget {
  final User user;

  const StudentFormations({super.key, required this.user});

  @override
  State<StudentFormations> createState() => _StudentFormationsState();
}

class _StudentFormationsState extends State<StudentFormations> with TickerProviderStateMixin {
  final LocalDataService _db = LocalDataService();
  late AnimationController _fadeController;
  late GlobalKey qrKey;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    qrKey = GlobalKey();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          SizedBox(height: 28),
          _buildFormationsList(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return FadeTransition(
      opacity: _fadeController,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mes Formations',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Gérez vos formations et votre progression',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormationsList() {
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

        final allFormations = snapshot.data ?? [];
        if (allFormations.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.school_rounded, size: 48, color: Colors.black12),
                SizedBox(height: 16),
                Text(
                  'Aucune formation inscrite',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        final formations = allFormations.map((f) => {
          'title': f.titre,
          'type': f.type.name,
          'formationId': f.id,
          'modules': f.modules.map((m) => {'title': m, 'completed': false}).toList(),
        }).toList();

        if (formations.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.school_rounded, size: 48, color: Colors.black12),
                SizedBox(height: 16),
                Text(
                  'Aucune formation inscrite',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: formations.length,
          itemBuilder: (context, index) {
            final formation = formations[index] as Map<String, dynamic>;
            return _buildFormationCard(formation, index);
          },
        );
      },
    );
  }

  Widget _buildFormationCard(Map<String, dynamic> formationData, int index) {
    final formationId = formationData['formationId'] ?? '';
    final formationTitle = formationData['title'] ?? 'Formation';
    final modules = formationData['modules'] as List<dynamic>? ?? [];
    final modulesWithHours = modules.where((m) {
      final assignedHours = (m['assignedHours'] ?? 0) as int;
      return assignedHours > 0;
    }).toList();

    if (modulesWithHours.isEmpty) {
      return SizedBox.shrink();
    }

      final totalAssignedHours = modulesWithHours.fold<int>(0, (acc, m) {
        return acc + (m['assignedHours'] as int? ?? 0);
    });

      final totalDoneHours = modulesWithHours.fold<int>(0, (acc, m) {
        return acc + (m['doneHours'] as int? ?? 0);
    });

    final progressPercent = totalAssignedHours > 0 ? (totalDoneHours / totalAssignedHours * 100).toStringAsFixed(1) : '0';

    return SlideInUp(
      delay: Duration(milliseconds: 50 + (index * 40)),
      duration: Duration(milliseconds: 600),
      child: Padding(
        padding: EdgeInsets.only(bottom: 16),
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
          child: Padding(
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
                            formationTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$totalDoneHours / $totalAssignedHours heures',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      onSelected: (value) {
                        if (value == 'partager') {
                          _showFormationQrDialog(context, formationTitle, formationId);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'partager',
                          child: Row(
                            children: [
                              Icon(Icons.share_rounded, size: 18, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text('Partager'),
                            ],
                          ),
                        ),
                      ],
                      icon: Icon(Icons.more_vert_rounded, color: AppTheme.primary),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: totalAssignedHours > 0 ? totalDoneHours / totalAssignedHours : 0,
                          minHeight: 8,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$progressPercent%',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Modules (${modulesWithHours.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: modulesWithHours.map((m) {
                    final moduleTitle = m['title'] ?? '';
                    final assignedHours = m['assignedHours'] ?? 0;
                    final doneHours = m['doneHours'] ?? 0;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppTheme.primary.withValues(alpha: 0.05),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        padding: EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              moduleTitle,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '$doneHours/$assignedHours h',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                _buildFormateurs(formationId, modulesWithHours),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormateurs(String formationId, List<dynamic> studentModules) {
    return StreamBuilder<List<User>>(
      stream: _db.watchUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        final formateurs = <String, Map<String, dynamic>>{};
        final formateursList = snapshot.data!.where((u) => u.role == UserRole.formateur).toList();

        for (var formateur in formateursList) {
          formateurs[formateur.nomComplet] = {
            'prenom': formateur.prenom,
            'nom': formateur.nom,
            'email': formateur.email,
          };
        }

        if (formateurs.isEmpty) {
          return SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Formateurs',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: formateurs.entries.map((entry) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    entry.key,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showFormationQrDialog(BuildContext context, String formationTitle, String formationId) async {
    final shareUrl = await _buildLocalShareUrl(formationId);

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
                    data: shareUrl,
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
                    shareUrl,
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
          TextButton(
            onPressed: () async {
              final uri = Uri.parse(shareUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else if (!mounted) {
                return;
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Impossible d’ouvrir le lien local.')),
                );
              }
            },
            child: Text('Ouvrir sur le réseau'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final bytes = await _captureQrPng(qrKey);
                  if (bytes == null) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Impossible de générer le QR.')),
                    );
                    return;
                  }

                  final directory = await getTemporaryDirectory();
                  final file = File('${directory.path}/formation_qr.png');
                  await file.writeAsBytes(bytes);

                  final shareText = '''
📚 *$formationTitle*

🔗 Découvrez plus:
$shareUrl

👇 Scannez le QR code ci-dessous pour accéder directement!
                  ''';

                  if (!mounted) return;
                  Share.shareXFiles(
                    [XFile(file.path)],
                    text: shareText,
                  );
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

  Future<String> _buildLocalShareUrl(String formationId) async {
    // Prefer the current app origin so shared links work in Docker/local dev
    try {
      final origin = Uri.base.origin;
      final localTarget = '$origin/formation.html?id=$formationId';

      // Try to expose LAN IP for sharing on the same network (use host port 8080)
      const port = 8080;
      const path = 'formation.html';
      try {
        final interfaces = await NetworkInterface.list(includeLoopback: false, type: InternetAddressType.IPv4);
        for (final interface in interfaces) {
          for (final address in interface.addresses) {
            if (!address.isLoopback && address.type == InternetAddressType.IPv4) {
              return 'http://${address.address}:$port/$path?id=$formationId';
            }
          }
        }
      } catch (e) {
        debugPrint('Local LAN URL lookup failed: $e');
      }

      return localTarget;
    } catch (e) {
      return 'http://127.0.0.1:8080/formation.html?id=$formationId';
    }
  }

  Future<Uint8List?> _captureQrPng(GlobalKey key) async {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}
