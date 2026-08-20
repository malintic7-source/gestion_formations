import 'package:flutter/material.dart';
import 'package:gestion_formations/Widgets/footer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestion_formations/config/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width > 1200 ? 1100.0 : width * 0.95;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 5,
        shadowColor: AppTheme.primary.withValues(alpha: 0.18),
        leading: const SizedBox.shrink(),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(8, 0), // décale légèrement vers la droite
              child: Image.asset(
                'images/logo.png',
                width: 72,
                height: 72,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Accueil',
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          //notifications
          GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Stack(
                children: [
                  //Icon
                  Icon(Icons.notifications, color: AppTheme.primary, size: 30),
                  //Badge
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      padding: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),

                      child: Center(
                        child: Text(
                          '+9',
                          style: TextStyle(color: Colors.white, fontSize: 9.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          //Menu
          IconButton(
            style: IconButton.styleFrom(
              elevation: 5,
              shadowColor: Colors.black.withValues(alpha: 0.12),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.12), width: 1),
              fixedSize: const Size(25, 25),
            ),
            onPressed: () {},
            icon: Icon(Icons.menu, color: AppTheme.primary, size: 20),
          ),
        ],
      ),
      body: Stack(
        children: [
          //Bg image
          Center(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'images/logo.png',
                fit: BoxFit.fill,
                width: double.infinity,
              ),
            ),
          ),

          //CONTENU PRINCIPAL DE LA PAGE
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue sur Malintic',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Accédez rapidement à vos tableaux de bord, formations et notifications depuis un espace clair et professionnel.',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          _buildStatCard('Formations', '120'),
                          const SizedBox(width: 16),
                          _buildStatCard('Utilisateurs', '86'),
                        ],
                      ),
                      const SizedBox(height: 32),
                      footer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        shape: CircleBorder(),
        hoverColor: AppTheme.accent,
        focusColor: Colors.white,
        backgroundColor: AppTheme.primary,
        child: Icon(Icons.support_agent, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 32,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
