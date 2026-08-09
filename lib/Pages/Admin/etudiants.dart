import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:gestion_formations/Models/formation.dart';
import 'package:gestion_formations/Models/user.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestion_formations/Services/auth_provider.dart';
import 'package:gestion_formations/Services/db_services.dart';
import 'package:gestion_formations/config/theme.dart';

class AdminEtudiants extends StatefulWidget {
  const AdminEtudiants({super.key});

  @override
  State<AdminEtudiants> createState() => _AdminEtudiantsState();
}

class _AdminEtudiantsState extends State<AdminEtudiants> with TickerProviderStateMixin {
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
                'Étudiants',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Gérez les étudiants de votre plateforme',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          if (!isMobile)
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showCreateEtudiantDialog(),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Ajouter',
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
          if (isMobile)
            FloatingActionButton(
              onPressed: () => _showCreateEtudiantDialog(),
              backgroundColor: AppTheme.primary,
              child: Icon(Icons.add_rounded),
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
        final etudiants = allUsers.where((u) => u.role == UserRole.etudiant).toList();

        final filtered = etudiants.where((user) {
          final nomComplet = user.nomComplet.toLowerCase();
          final email = user.email.toLowerCase();
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
            final user = filtered[index];
            final data = user.toMap();
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _buildEtudiantCardPremium(context, user.id, data, index),
            );
          },
        );
      },
    );
  }

  Widget _buildEtudiantCardPremium(BuildContext context, String userId, Map<String, dynamic> data, int index) {
    final prenom = data['prenom'] ?? '';
    final nom = data['nom'] ?? '';
    final email = data['email'] ?? '';
    final assigned = data['assignedFormations'] as List<dynamic>? ?? [];

    int totalAssignedHours = 0;
    int totalDoneHours = 0;

    for (final a in assigned) {
      final modules = a['modules'] as List<dynamic>? ?? [];
      
      for (final m in modules) {
        final assignedH = (m['assignedHours'] ?? 0) as num;
        final doneH = (m['doneHours'] ?? 0) as num;
        totalAssignedHours += assignedH.toInt();
        totalDoneHours += doneH.toInt();
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
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFEF4444).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$prenom $nom',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      email,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Étudiant',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (data['estActif'] ?? true)
                                ? Color(0xFF10B981).withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (data['estActif'] ?? true)
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                size: 12,
                                color: (data['estActif'] ?? true)
                                    ? Color(0xFF10B981)
                                    : Colors.black54,
                              ),
                              SizedBox(width: 4),
                              Text(
                                (data['estActif'] ?? true) ? 'Actif' : 'Inactif',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: (data['estActif'] ?? true)
                                      ? Color(0xFF10B981)
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      '$totalDoneHours / $totalAssignedHours heures (${(progress * 100).toStringAsFixed(0)}%) • ${assigned.length} formations',
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
                        valueColor: AlwaysStoppedAnimation(Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'voir') {
                    _showEtudiantDetail(userId, data);
                  } else if (value == 'attribuer') {
                    await _assignFormationDialog(userId);
                  } else if (value == 'bloquer') {
                    final currentActive = (data['estActif'] ?? true) as bool;
                    await _toggleBlockUser(userId, currentActive);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'voir',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Voir'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'attribuer',
                    child: Row(
                      children: [
                        Icon(Icons.assignment_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Attribuer'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'bloquer',
                    child: Row(
                      children: [
                        Icon(
                          (data['estActif'] ?? true)
                              ? Icons.block_rounded
                              : Icons.check_circle_rounded,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text((data['estActif'] ?? true) ? 'Bloquer' : 'Débloquer'),
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
        ),
      ),
    );
  }

  Future<void> _toggleBlockUser(String userId, bool block) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(block ? 'Étudiant bloqué' : 'Étudiant débloqué')));
  }

  Future<void> _assignFormationDialog(String userId) async {
    final formations = _db.getFormations();
    final user = _db.getUserById(userId);

    Formation? selected;
    final modulesControllers = <String, TextEditingController>{};

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Attribuer une formation',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
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
                    child: DropdownButtonFormField<Formation>(
                      initialValue: selected != null && formations.any((f) => f.id == selected!.id) ? selected : null,
                      items: formations.map((f) => DropdownMenuItem(value: f, child: Text(f.titre))).toList(),
                      onChanged: (f) {
                        setState(() {
                          selected = f;
                          modulesControllers.clear();
                          if (selected != null) {
                            for (final m in selected!.modules) {
                              modulesControllers[m] = TextEditingController(text: '0');
                            }
                          }
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Sélectionner une formation',
                        prefixIcon: Icon(Icons.school_rounded, color: AppTheme.primary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (selected != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attribuer les heures',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12),
                        ...selected!.modules.map((m) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(Icons.book_rounded, color: AppTheme.primary, size: 20),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  SizedBox(
                                    width: 70,
                                    child: TextField(
                                      controller: modulesControllers[m],
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.poppins(fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: 'h',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                    ),
                                  ),
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
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Attribution enregistrée avec succès')),
                  );
                },
                child: Text('Attribuer'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showCreateEtudiantDialog() {
    final prenomController = TextEditingController();
    final nomController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Créer un étudiant',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: prenomController,
                  decoration: InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: nomController,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_rounded),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Mot de passe par défaut: 00000000',
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
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
                    if (prenomController.text.isEmpty ||
                        nomController.text.isEmpty ||
                        emailController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Veuillez remplir tous les champs')),
                      );
                      return;
                    }

                    try {
                      await AuthProvider().createUserByAdmin(
                        email: emailController.text,
                        nom: nomController.text,
                        prenom: prenomController.text,
                        phone: phoneController.text,
                        role: UserRole.etudiant,
                      );

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Étudiant créé avec succès'),
                          backgroundColor: AppTheme.primary,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: ${e.toString()}'),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
    );
  }

  void _showEtudiantDetail(String userId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        final assignedOriginal = (data['assignedFormations'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final assignedCopy = assignedOriginal
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
                          'Aucune formation attribuée',
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
                          'Formations attribuées',
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
                  SizedBox(height: 20),
                  FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                    future: _getStudentSchedule(userId, data),
                    builder: (context, scheduleSnapshot) {
                      if (scheduleSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                            strokeWidth: 2,
                          ),
                        );
                      }

                      final scheduleByDay = scheduleSnapshot.data ?? {};

                      if (scheduleByDay.isEmpty) {
                        return SizedBox.shrink();
                      }

                      final daysOrder = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
                      final scheduleDays = daysOrder.where((d) => scheduleByDay.containsKey(d)).toList();

                      if (scheduleDays.isEmpty) {
                        return SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emploi du temps',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12),
                          ...scheduleDays.map((day) {
                            final daySchedules = scheduleByDay[day] ?? [];
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: AppTheme.primary.withValues(alpha: 0.05),
                                  border: Border.all(
                                    color: AppTheme.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      day,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ...daySchedules.map((s) {
                                      final debut = s['heureDebut'] ?? '';
                                      final fin = s['heureFin'] ?? '';
                                      final formateur = s['formateur'] ?? '';
                                      final modules = s['modules'] as List? ?? [];
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 6),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$debut - $fin',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              formateur,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            if (modules.isNotEmpty)
                                              Text(
                                                'Modules: ${modules.join(", ")}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 9,
                                                  color: AppTheme.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
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
                      );
                    },
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
    await LocalDataService().updateModuleDoneHours(userId, formationId, moduleTitle, delta);
    if (!mounted) return;
    setState(() {});
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getStudentSchedule(String userId, Map<String, dynamic> data) async {
    final formations = LocalDataService().getFormations();
    Map<String, List<Map<String, dynamic>>> scheduleByDay = {};
    for (var f in formations) {
      for (var h in f.horaires) {
        scheduleByDay.putIfAbsent(h.jour, () => []).add({
          'heureDebut': h.heureDebut,
          'heureFin': h.heureFin,
          'formateur': 'Formateur',
          'modules': f.modules,
        });
      }
    }
    return scheduleByDay;
  }
}
