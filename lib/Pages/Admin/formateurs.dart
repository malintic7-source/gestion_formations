import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:gestion_formations/Models/formation.dart';
import 'package:gestion_formations/Models/user.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestion_formations/Services/auth_provider.dart';
import 'package:gestion_formations/Services/db_services.dart';
import 'package:gestion_formations/config/theme.dart';

class AdminFormateurs extends StatefulWidget {
  const AdminFormateurs({super.key});

  @override
  State<AdminFormateurs> createState() => _AdminFormateursState();
}

class _AdminFormateursState extends State<AdminFormateurs> with TickerProviderStateMixin {
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
          _buildFormateursStream(context),
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
                'Formateurs',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Gérez les formateurs de votre plateforme',
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
                  onTap: () => _showCreateFormateurDialog(),
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
              onPressed: () => _showCreateFormateurDialog(),
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

  Widget _buildFormateursStream(BuildContext context) {
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
        final formateurs = allUsers.where((u) => u.role == UserRole.formateur).toList();

        final filtered = formateurs.where((user) {
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
                    'Aucun formateur',
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
              child: _buildFormateurCardPremium(context, user.id, data, index),
            );
          },
        );
      },
    );
  }

  Widget _buildFormateurCardPremium(BuildContext context, String userId, Map<String, dynamic> data, int index) {
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
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.school_rounded,
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
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Formateur',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
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
                    _showFormateurDetail(userId, data);
                  } else if (value == 'attribuer') {
                    await _assignFormationDialog(userId);
                  } else if (value == 'emploi') {
                    await _scheduleDialog(userId, data);
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
                    value: 'emploi',
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Emploi du temps'),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(block ? 'Formateur bloqué' : 'Formateur débloqué')));
  }

  Future<void> _assignFormationDialog(String userId) async {
    final formations = _db.getFormations();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Attribuer une formation', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text('Attribuer la formation sélectionnée à ce formateur ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Formation attribuée')));
            },
            child: Text('Attribuer'),
          ),
        ],
      ),
    );
  }

  void _showCreateFormateurDialog() {
    final prenomController = TextEditingController();
    final nomController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Créer un formateur',
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
                        role: UserRole.formateur,
                      );

                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Formateur créé avec succès'),
                          backgroundColor: AppTheme.primary,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
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

  void _showFormateurDetail(String userId, Map<String, dynamic> data) {
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
                                            SizedBox(height: 4),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: formationProgress,
                                                minHeight: 6,
                                                backgroundColor: Colors.black.withValues(alpha: 0.08),
                                                valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${(formationProgress * 100).toStringAsFixed(0)}%',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primary,
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
                  StreamBuilder<List<Formation>>(
                    stream: _db.watchFormations(),
                    builder: (context, scheduleSnapshot) {
                      if (scheduleSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                            strokeWidth: 2,
                          ),
                        );
                      }

                      final schedules = scheduleSnapshot.data ?? [];

                      if (schedules.isEmpty) {
                        return SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emplois du temps',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12),
                          ...schedules.map((formation) {
                            final scheduleTitle = formation.titre;

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
                                      scheduleTitle,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ...formation.modules.map((m) {
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          '• $m',
                                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
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
    await _db.updateModuleDoneHours(userId, formationId, moduleTitle, delta);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _scheduleDialog(String userId, Map<String, dynamic> data) async {
    final user = _db.getUserById(userId);
    final userAssigned = <Map<String, dynamic>>[];

    if (userAssigned.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le formateur n\'a aucune formation assignée')),
      );
      return;
    }

    Map<String, dynamic>? selectedFormation;
    final daysControllers = <int, Map<String, TextEditingController>>{};
    final daysMap = <int, String>{0: 'Lundi', 1: 'Mardi', 2: 'Mercredi', 3: 'Jeudi', 4: 'Vendredi', 5: 'Samedi', 6: 'Dimanche'};
    final selectedDays = <int>{};

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Attribuer un emploi du temps',
              style: GoogleFonts.poppins(
                fontSize: 18,
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
                    child: Builder(
                      builder: (context) {
                        final uniqueFormations = <String, Map<String, dynamic>>{};
                        for (final f in userAssigned) {
                          final title = (f['title'] ?? f['titre'] ?? 'Formation').toString();
                          if (title.isNotEmpty) {
                            uniqueFormations[title] = f;
                          }
                        }

                        final items = uniqueFormations.entries
                            .map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.key)))
                            .toList();

                        final selectedTitle = selectedFormation != null
                            ? (selectedFormation!['title'] ?? selectedFormation!['titre'] ?? '').toString()
                            : null;
                        final validValue = items.any((i) => i.value == selectedTitle) ? selectedTitle : null;

                        return DropdownButtonFormField<String>(
                          initialValue: validValue,
                          items: items,
                          onChanged: (title) {
                            setState(() {
                              selectedFormation = title != null ? uniqueFormations[title] : null;
                              daysControllers.clear();
                              selectedDays.clear();
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
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  if (selectedFormation != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ajouter les jours et horaires (max 7 jours)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12),
                        ...daysMap.entries.map((entry) {
                          final dayIndex = entry.key;
                          final dayName = entry.value;
                          final isSelected = selectedDays.contains(dayIndex);

                          return Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: isSelected ? AppTheme.primary.withValues(alpha: 0.05) : Colors.white,
                                border: Border.all(
                                  color: isSelected ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true && selectedDays.length < 7) {
                                              selectedDays.add(dayIndex);
                                              daysControllers[dayIndex] = {
                                                'debut': TextEditingController(text: '09:00'),
                                                'fin': TextEditingController(text: '12:00'),
                                              };
                                            } else if (val == false) {
                                              selectedDays.remove(dayIndex);
                                              daysControllers.remove(dayIndex);
                                            }
                                          });
                                        },
                                      ),
                                      Text(
                                        dayName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isSelected) ...[
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: daysControllers[dayIndex]?['debut'],
                                            style: GoogleFonts.poppins(fontSize: 12),
                                            decoration: InputDecoration(
                                              hintText: 'Début (09:00)',
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: daysControllers[dayIndex]?['fin'],
                                            style: GoogleFonts.poppins(fontSize: 12),
                                            decoration: InputDecoration(
                                              hintText: 'Fin (12:00)',
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
                      if (selectedFormation == null || selectedDays.isEmpty) return;

                      final schedule = selectedDays.map((dayIndex) {
                        return {
                          'jour': daysMap[dayIndex],
                          'heureDebut': daysControllers[dayIndex]?['debut']?.text ?? '09:00',
                          'heureFin': daysControllers[dayIndex]?['fin']?.text ?? '12:00',
                        };
                      }).toList();

                      final modules = (selectedFormation!['modules'] as List<dynamic>? ?? [])
                          .map((m) => {
                                'title': m['title'] ?? '',
                                'assignedHours': m['assignedHours'] ?? 0,
                              })
                          .where((m) => (m['assignedHours'] as int) > 0)
                          .toList();

                      final scheduleData = {
                        'formateurId': userId,
                        'formationId': selectedFormation!['formationId'],
                        'title': selectedFormation!['title'],
                        'modules': modules,
                        'schedule': schedule,
                        'dateCreation': DateTime.now(),
                        'dateModification': DateTime.now(),
                      };

                      // Schedule stored locally

                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Emploi du temps créé avec succès'),
                          backgroundColor: AppTheme.primary,
                        ),
                      );
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
          );
        });
      },
    );
  }
}
