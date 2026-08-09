import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestion_formations/config/theme.dart';
import 'package:gestion_formations/Models/user.dart';
import 'package:gestion_formations/Services/db_services.dart';
import 'package:gestion_formations/Widgets/chart_widgets.dart';

class AdminDashboard extends StatefulWidget {
  final User user;

  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
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
    final isMobile = MediaQuery.of(context).size.width < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          SizedBox(height: 24),
          _buildStatsGrid(isMobile),
          SizedBox(height: 32),
          _buildRecentActivities(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.28),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue sur votre espace',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.user.prenom,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contrôlez les formations, les utilisateurs et les inscriptions avec rapidité.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.55,
                        color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.dashboard_customize_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dynamicAspectRatio = isMobile 
        ? (screenWidth < 360 ? 1.05 : 1.25)
        : (screenWidth < 1100 ? 1.25 : 1.5);

    return StreamBuilder<List<User>>(
      stream: _db.watchUsers(),
      builder: (context, userSnapshot) {
        final users = userSnapshot.data ?? [];
        final formateurs = users.where((u) => u.role == UserRole.formateur).length;
        final etudiants = users.where((u) => u.role == UserRole.etudiant).length;

        final totalFormations = _db.getFormations().length;
        final totalNotifications = _db.getNotifications().length;

        return GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: dynamicAspectRatio,
          children: [
            _buildStatCardWithChart(
              title: 'Formateurs',
              value: '$formateurs',
              icon: Icons.person_rounded,
              colors: const [AppTheme.primary, AppTheme.primaryDark],
              thisMonth: formateurs,
              lastMonth: 0,
            ),
            _buildStatCardWithChart(
              title: 'Etudiants',
              value: '$etudiants',
              icon: Icons.school_rounded,
              colors: const [AppTheme.indigoAccent, AppTheme.purpleAccent],
              thisMonth: etudiants,
              lastMonth: 0,
            ),
            _buildStatCardWithChart(
              title: 'Formations',
              value: '$totalFormations',
              icon: Icons.book_rounded,
              colors: const [AppTheme.success, AppTheme.successDark],
              thisMonth: totalFormations,
              lastMonth: 0,
            ),
            _buildStatCardWithChart(
              title: 'Notifications',
              value: '$totalNotifications',
              icon: Icons.notifications_rounded,
              colors: const [AppTheme.orangeAccent, AppTheme.warningDark],
              thisMonth: totalNotifications,
              lastMonth: 0,
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, Map<String, int>>> _getMonthlyComparison() async {
    return {
      'formateurs': {'current': _db.getUsers().where((u) => u.role == UserRole.formateur).length, 'last': 0},
      'etudiants': {'current': _db.getUsers().where((u) => u.role == UserRole.etudiant).length, 'last': 0},
      'formations': {'current': _db.getFormations().length, 'last': 0},
      'notifications': {'current': _db.getNotifications().length, 'last': 0},
    };
  }

  Widget _buildLoadingGrid(bool isMobile) {
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: List.generate(
        4,
        (index) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.primary),
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCardWithChart({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> colors,
    required int thisMonth,
    required int lastMonth,
  }) {
    final percentage = lastMonth > 0
        ? ((thisMonth - lastMonth) / lastMonth * 100).toStringAsFixed(0)
        : '0';
    final isPositive = thisMonth >= lastMonth;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(colors: colors),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colors[0].withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colors[0],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MiniLineChart(
                      data: [lastMonth.toDouble(), thisMonth.toDouble()],
                      colors: colors,
                      height: 46,
                      width: 72,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? colors[0].withValues(alpha: 0.12)
                            : const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 12,
                            color: isPositive ? colors[0] : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$percentage%',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isPositive ? colors[0] : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activités Récentes',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Dernières 24 heures',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 16),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _getRecentActivities(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                  strokeWidth: 2,
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final activities = snapshot.data!;
            return ListView.builder(
              itemCount: activities.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _getActivityColors(
                                    activity['type']),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getActivityIcon(activity['type']),
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity['title'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 3),
                                Text(
                                  activity['description'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            activity['time'],
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.black38,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              size: 48,
              color: Colors.black12,
            ),
            SizedBox(height: 12),
            Text(
              'Aucune activité',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getRecentActivities() async {
    final List<Map<String, dynamic>> activities = [];
    final users = _db.getUsers();
    for (var u in users) {
      activities.add({
        'title': u.role == UserRole.formateur ? 'Nouveau formateur' : 'Nouvel étudiant',
        'description': u.nomComplet,
        'time': 'Aujourd\'hui',
        'type': 'user',
        'timestamp': u.dateCreation.millisecondsSinceEpoch,
      });
    }

    final formations = _db.getFormations();
    for (var f in formations) {
      activities.add({
        'title': 'Nouvelle formation',
        'description': f.titre,
        'time': 'Récemment',
        'type': 'formation',
        'timestamp': f.dateCreation.millisecondsSinceEpoch,
      });
    }

    activities.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
    return activities.take(15).toList();
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  IconData _getActivityIcon(String type) {
    if (type == 'user_formateur') return Icons.person_add_rounded;
    if (type == 'user_etudiant') return Icons.person_rounded;
    if (type == 'formation') return Icons.book_rounded;
    if (type == 'notification') return Icons.notifications_rounded;
    return Icons.info_rounded;
  }

  List<Color> _getActivityColors(String type) {
    if (type == 'user_formateur') {
      return [AppTheme.primary, AppTheme.primaryDark];
    } else if (type == 'user_etudiant') {
      return [Color(0xFF06B6D4), Color(0xFF0891B2)];
    } else if (type == 'formation') {
      return [Color(0xFF10B981), Color(0xFF059669)];
    } else if (type == 'notification') {
      return [Color(0xFFF59E0B), Color(0xFFD97706)];
    }
    return [AppTheme.primary, AppTheme.primaryDark];
  }
}
