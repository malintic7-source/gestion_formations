import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import 'package:gestion_formations/Models/user.dart';
import 'package:gestion_formations/Services/db_services.dart';
import 'package:gestion_formations/config/theme.dart';

class FormateurEtudiants extends StatefulWidget {
  final User user;

  const FormateurEtudiants({super.key, required this.user});

  @override
  State<FormateurEtudiants> createState() => _FormateurEtudiantsState();
}

class _FormateurEtudiantsState extends State<FormateurEtudiants> with TickerProviderStateMixin {
  final LocalDataService _db = LocalDataService();
  final searchController = TextEditingController();
  late AnimationController _fadeController;

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
    searchController.dispose();
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
          _buildSearchBar(),
          SizedBox(height: 28),
          _buildEtudiantsStream(context),
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
                'Mes Étudiants',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Étudiants ayant vos formations',
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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Rechercher par nom, email...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black38,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppTheme.primary,
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildEtudiantsStream(BuildContext context) {
    return FutureBuilder<Map<String, List<String>>>(
      future: _getFormateurFormationsWithModules(),
      builder: (context, formationSnapshot) {
        if (formationSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.primary),
            ),
          );
        }

        final formateurModulesByFormation = formationSnapshot.data ?? {};

        return StreamBuilder<List<User>>(
          stream: _db.watchUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                ),
              );
            }

            final allUsers = snapshot.data ?? [];
            final docs = allUsers.where((u) => u.role == UserRole.etudiant).map((u) => u.toMap()).toList();

            final filtered = docs.where((doc) {
              final data = doc;
              final assigned = data['assignedFormations'] as List<dynamic>? ?? [];

              bool hasCommonModules = false;
              for (final a in assigned) {
                final formationId = a['formationId'] ?? '';
                final etudiantModules = a['modules'] as List<dynamic>? ?? [];

                if (formateurModulesByFormation.containsKey(formationId)) {
                  final formateurModules = formateurModulesByFormation[formationId] ?? [];

                  for (final m in etudiantModules) {
                    final moduleTitle = m['title'] ?? '';
                    if (formateurModules.contains(moduleTitle)) {
                      hasCommonModules = true;
                      break;
                    }
                  }
                }
                if (hasCommonModules) break;
              }

              if (!hasCommonModules) return false;

              final nom = (data['prenom'] ?? '').toString().toLowerCase();
              final email = (data['email'] ?? '').toString().toLowerCase();
              final nomComplet = ('$nom ${data['nom'] ?? ''}').toLowerCase();
              final query = searchController.text.trim().toLowerCase();

              if (query.isEmpty) return true;

              return nomComplet.contains(query) || email.contains(query);
            }).toList();

            if (filtered.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.person_off_rounded, size: 48, color: Colors.black12),
                      SizedBox(height: 16),
                      Text(
                        'Aucun étudiant',
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
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final data = filtered[index];
                final userId = (data['id'] ?? data['uid'] ?? '') as String;
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _buildEtudiantCard(context, userId, data, index, formateurModulesByFormation),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEtudiantCard(BuildContext context, String userId, Map<String, dynamic> data, int index, Map<String, List<String>> formateurModulesByFormation) {
    final prenom = data['prenom'] ?? '';
    final nom = data['nom'] ?? '';
    final email = data['email'] ?? '';
    final phone = data['phone'] ?? '';
    final isActif = data['estActif'] ?? true;
    final assigned = data['assignedFormations'] as List<dynamic>? ?? [];

    List<Map<String, dynamic>> commonFormations = [];
    int totalAssignedHours = 0;
    int totalDoneHours = 0;

    for (final a in assigned) {
      final formationId = a['formationId'] ?? '';
      final etudiantModules = a['modules'] as List<dynamic>? ?? [];

      if (formateurModulesByFormation.containsKey(formationId)) {
        final formateurModules = formateurModulesByFormation[formationId] ?? [];

        List<Map<String, dynamic>> commonModules = [];
        int formAssigned = 0;
        int formDone = 0;

        for (final m in etudiantModules) {
          final moduleTitle = m['title'] ?? '';
          if (formateurModules.contains(moduleTitle)) {
            final assignedH = (m['assignedHours'] ?? 0) as int;
            final doneH = (m['doneHours'] ?? 0) as int;
            formAssigned += assignedH;
            formDone += doneH;
            commonModules.add({
              'title': moduleTitle,
              'assignedHours': assignedH,
              'doneHours': doneH,
            });
          }
        }

        if (commonModules.isNotEmpty) {
          totalAssignedHours += formAssigned;
          totalDoneHours += formDone;
          commonFormations.add({
            'formationId': formationId,
            'title': a['title'] ?? 'Formation',
            'modules': commonModules,
            'dateAssigned': a['dateAssigned'],
          });
        }
      }
    }

    final progress = totalAssignedHours == 0 ? 0.0 : (totalDoneHours / totalAssignedHours).clamp(0.0, 1.0);

    return SlideInUp(
      delay: Duration(milliseconds: 50 + (index * 40)),
      duration: Duration(milliseconds: 600),
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
          padding: EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        prenom.isNotEmpty ? prenom[0].toUpperCase() : 'E',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$prenom $nom',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          email,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '$totalDoneHours / $totalAssignedHours heures (${(progress * 100).toStringAsFixed(0)}%) • ${commonFormations.length} formations',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.black.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'voir') {
                        _showEtudiantDetail(userId, data, commonFormations);
                      } else if (value == 'appeler') {
                        await _callStudent(phone);
                      } else if (value == 'bloquer') {
                        await _toggleBlockStudent(userId, isActif);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'voir',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Voir détails'),
                          ],
                        ),
                      ),
                      if (phone.isNotEmpty)
                        PopupMenuItem(
                          value: 'appeler',
                          child: Row(
                            children: [
                              Icon(Icons.call_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Appeler'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'bloquer',
                        child: Row(
                          children: [
                            Icon(
                              isActif ? Icons.block_rounded : Icons.check_circle_rounded,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(isActif ? 'Bloquer' : 'Débloquer'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, List<String>>> _getFormateurFormationsWithModules() async {
    final formations = _db.getFormations();
    Map<String, List<String>> result = {};
    for (var f in formations) {
      result[f.id] = f.modules;
    }
    return result;
  }

  Future<void> _callStudent(String phone) async {
    try {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phone,
      );
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'appeler ce numéro')),
        );
      }
    }
  }

  Future<void> _toggleBlockStudent(String userId, bool isCurrentlyActif) async {
    try {
      await _db.setUserActive(userId, !isCurrentlyActif);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyActif ? 'Étudiant bloqué' : 'Étudiant débloqué'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  void _showEtudiantDetail(String userId, Map<String, dynamic> data, List<Map<String, dynamic>> commonFormations) {
    showDialog(
      context: context,
      builder: (context) {
        final assignedCopy = commonFormations
            .map((a) => {
                  'formationId': a['formationId'],
                  'title': a['title'],
                  'dateAssigned': a['dateAssigned'],
                  'modules': (a['modules'] as List<dynamic>? ?? [])
                      .map((m) => Map<String, dynamic>.from(m as Map<String, dynamic>))
                      .toList(),
                })
            .toList();

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              '${data['prenom'] ?? ''} ${data['nom'] ?? ''}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.email_rounded, color: AppTheme.primary, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data['email'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  if (assignedCopy.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'Aucune formation commune',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Formations communes',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12),
                        ...assignedCopy.map((a) {
                          final modules = (a['modules'] as List).cast<Map<String, dynamic>>();
                          int totalAssigned = 0;
                          int totalDone = 0;
                          for (final m in modules) {
                            totalAssigned += (m['assignedHours'] ?? 0) as int;
                            totalDone += (m['doneHours'] ?? 0) as int;
                          }
                          final formationProgress = totalAssigned == 0 ? 0.0 : (totalDone / totalAssigned).clamp(0.0, 1.0);

                          return Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a['title'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$totalDone / $totalAssigned heures',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: formationProgress,
                                                minHeight: 6,
                                                backgroundColor: Colors.black.withValues(alpha: 0.08),
                                                valueColor: AlwaysStoppedAnimation(Color(0xFFEF4444)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFEF4444).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${(formationProgress * 100).toStringAsFixed(0)}%',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  ...modules
                                      .where((m) {
                                        final title = (m['title'] ?? '').toString().trim();
                                        final assignedH = (m['assignedHours'] ?? 0) as num;
                                        return title.isNotEmpty && assignedH > 0;
                                      })
                                      .map((m) {
                                    final assignedH = (m['assignedHours'] ?? 0) as int;
                                    final doneH = (m['doneHours'] ?? 0) as int;
                                    final moduleProgress = assignedH == 0 ? 0.0 : (doneH / assignedH).clamp(0.0, 1.0);

                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  m['title'] ?? '',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '$doneH/$assignedH h',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(3),
                                                  child: LinearProgressIndicator(
                                                    value: moduleProgress,
                                                    minHeight: 4,
                                                    backgroundColor: Colors.black.withValues(alpha: 0.08),
                                                    valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              SizedBox(
                                                width: 60,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    InkWell(
                                                      onTap: () async {
                                                        if (doneH <= 0) return;
                                                        final prev = m['doneHours'] as int? ?? 0;
                                                        m['doneHours'] = (prev - 1).clamp(0, assignedH);
                                                        setState(() {});
                                                        try {
                                                          await _updateModuleDoneHours(userId, a['formationId'], m['title'], -1);
                                                        } catch (e) {
                                                          m['doneHours'] = prev;
                                                          setState(() {});
                                                        }
                                                      },
                                                      child: Icon(Icons.remove_rounded, size: 16, color: AppTheme.primary),
                                                    ),
                                                    SizedBox(width: 4),
                                                    InkWell(
                                                      onTap: () async {
                                                        if (doneH >= assignedH) return;
                                                        final prev = m['doneHours'] as int? ?? 0;
                                                        m['doneHours'] = (prev + 1).clamp(0, assignedH);
                                                        setState(() {});
                                                        try {
                                                          await _updateModuleDoneHours(userId, a['formationId'], m['title'], 1);
                                                        } catch (e) {
                                                          m['doneHours'] = prev;
                                                          setState(() {});
                                                        }
                                                      },
                                                      child: Icon(Icons.add_rounded, size: 16, color: AppTheme.primary),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateModuleDoneHours(String userId, String formationId, String moduleTitle, int delta) async {
    if (!mounted) return;
    setState(() {});
  }
}
