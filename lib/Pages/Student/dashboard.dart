import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:gestion_formations/Models/user.dart';
import 'package:gestion_formations/Services/db_services.dart';
import 'package:gestion_formations/Pages/Student/discover_formations.dart';
import 'package:gestion_formations/Widgets/chart_widgets.dart';
import 'package:gestion_formations/config/theme.dart';

class StudentDashboard extends StatefulWidget {
  final User user;

  const StudentDashboard({super.key, required this.user});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with TickerProviderStateMixin {
  final LocalDataService _db = LocalDataService();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;
    final isCompact = size.width < 600;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(isMobile),
              SizedBox(height: 32),
              _buildStatistics(),
              SizedBox(height: 40),
              _buildModuleProgressSection(),
            ],
          ),
        ),
        Positioned(
          bottom: isCompact ? 12 : 24,
          right: isCompact ? 12 : 24,
          child: SafeArea(
            child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiscoverFormationsPage(user: widget.user),
                ),
              );
            },
            backgroundColor: AppTheme.primary,
            icon: const Icon(Icons.explore_rounded, color: Colors.white),
              label: Text(
                'Découvrir',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader(bool isMobile) {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.heroShadow,
        ),
        padding: const EdgeInsets.all(24),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue 👋',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.user.prenom,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Votre espace de formation, soigneusement préparé pour vous.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 30),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenue 👋',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.user.prenom,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Votre espace de formation, soigneusement préparé pour vous.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.86),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 40),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatistics() {
    final formations = _db.getFormations();
    final formationCount = formations.length;
    final moduleCount = formations.fold<int>(0, (sum, f) => sum + f.modules.length);
    final averageProgress = moduleCount > 0 ? 0.72 : 0.0;
    final isCompact = MediaQuery.of(context).size.width < 700;

    return isCompact
        ? Column(
            children: [
              _buildStatCard(
                title: 'Formations actives',
                value: formationCount.toString(),
                subtitle: '$moduleCount modules enregistrés',
                icon: Icons.menu_book_rounded,
                color: AppTheme.primary,
                delay: 0,
                chartData: [12, 18, 22, 30, 34, formationCount.toDouble()],
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: 'Progression moyenne',
                value: '${(averageProgress * 100).toStringAsFixed(0)}%',
                subtitle: 'Sur vos modules en cours',
                icon: Icons.show_chart_rounded,
                color: AppTheme.success,
                delay: 50,
                chartData: [0.3, 0.45, 0.56, 0.63, 0.68, averageProgress],
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Formations actives',
                  value: formationCount.toString(),
                  subtitle: '$moduleCount modules enregistrés',
                  icon: Icons.menu_book_rounded,
                  color: AppTheme.primary,
                  delay: 0,
                  chartData: [12, 18, 22, 30, 34, formationCount.toDouble()],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Progression moyenne',
                  value: '${(averageProgress * 100).toStringAsFixed(0)}%',
                  subtitle: 'Sur vos modules en cours',
                  icon: Icons.show_chart_rounded,
                  color: AppTheme.success,
                  delay: 50,
                  chartData: [0.3, 0.45, 0.56, 0.63, 0.68, averageProgress],
                ),
              ),
            ],
          );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int delay,
    List<double>? chartData,
  }) {
    return SlideInUp(
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 600),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.08)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.72)]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      if (chartData != null && chartData.isNotEmpty)
                        SizedBox(
                          width: 120,
                          child: SparkLineChart(
                            data: chartData,
                            color: color,
                            height: 40,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleProgressSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAllModulesWithProgress(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.primary),
            ),
          );
        }

        final modules = snapshot.data ?? [];

        if (modules.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mes progrès',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.library_books_rounded, size: 48, color: Colors.black12),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun module en progression',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiscoverFormationsPage(user: widget.user),
                          ),
                        );
                      },
                      child: const Text('Découvrir des formations'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mes progrès',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final module = modules[index];
                return _buildModuleProgressCard(module, index);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildModuleProgressCard(Map<String, dynamic> module, int index) {
    final moduleTitle = module['title'] ?? 'Module';
    final formationTitle = module['formation'] ?? 'Formation';
    final doneHours = module['doneHours'] ?? 0;
    final assignedHours = module['assignedHours'] ?? 0;
    final progressPercent = assignedHours > 0 ? (doneHours / assignedHours * 100).toStringAsFixed(1) : '0';
    final progress = assignedHours > 0 ? (doneHours / assignedHours).clamp(0.0, 1.0) : 0.0;

    return SlideInUp(
      delay: Duration(milliseconds: 50 + (index * 40)),
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            boxShadow: AppTheme.cardShadow,
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moduleTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formationTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
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
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$doneHours / $assignedHours heures complétées',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getAllModulesWithProgress() async {
    final formations = _db.getFormations();
    final List<Map<String, dynamic>> allModules = [];
    for (var f in formations) {
      for (var m in f.modules) {
        allModules.add({
          'title': m,
          'formation': f.titre,
          'doneHours': 10,
          'assignedHours': 20,
          'progress': 0.5,
        });
      }
    }
    return allModules;
  }
}
