import 'package:flutter/material.dart';
import 'package:gestion_formations/Services/poles_d_services.dart';
import 'package:gestion_formations/config/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestion_formations/Pages/Login/sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomPage extends StatelessWidget {
  const WelcomPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: isMobile
            ? _buildMobileLayout(context)
            : _buildDesktopLayout(context),
      ),
    );
  }

  // MOBILE LAYOUT - Clean responsive layout
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildLogo(),
          const SizedBox(height: 36),
          _buildHeader(),
          const SizedBox(height: 40),
          _buildServiceCardsMobile(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // DESKTOP LAYOUT - Professional modern layout
  Widget _buildDesktopLayout(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width < 1200 ? 40.0 : 80.0;
    final verticalPadding = size.width < 1200 ? 48.0 : 64.0;

    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1280),
          padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Center the logo above the title and make it larger on desktop
                    Center(child: _buildLogo(180)),
                    const SizedBox(height: 28),
                    Text(
                      'M@LI-NTIC',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Plateforme intelligente de gestion de formations, prestations & incubation.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w400,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.heroGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppTheme.heroShadow,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignInPage(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Accéder à mon espace',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: size.width < 1200 ? 40 : 64),
              Expanded(flex: 5, child: _buildServicesListDesktop(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo([double size = 120]) {
    final padding = (size / 8).clamp(8.0, 24.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: AppTheme.softShadow,
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Image.asset(
            'images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'M@LI-NTIC',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Plateforme intelligente de gestion de formations',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // DESKTOP SERVICES LIST
  Widget _buildServicesListDesktop(BuildContext context) {
    final services = [
      {
        'title': 'Formations',
        'subtitle': 'Explorez nos programmes de formation en ligne & présentiel',
        'icon': Icons.school_rounded,
        'color': AppTheme.primary,
        'gradient': AppTheme.primaryGradient,
        'action': () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignInPage()),
          );
        },
      },
      {
        'title': 'Prestations',
        'subtitle': 'Découvrez nos services professionnels sur-mesure',
        'icon': Icons.handshake_rounded,
        'color': AppTheme.orangeAccent,
        'gradient': AppTheme.orangeGradient,
        'action': () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return poleDialog(
                context,
                'Prestations',
                'Ce pôle permettra de gérer les offres de services, les demandes clients, les devis et le suivi des prestations M@LI-NTIC.',
              );
            },
          );
        },
      },
      {
        'title': 'e-Commerce',
        'subtitle': 'Parcourez notre catalogue complet de matériel et logiciels',
        'icon': Icons.shopping_cart_rounded,
        'color': AppTheme.indigoAccent,
        'gradient': AppTheme.accentGradient,
        'action': () async {
          await launchUrl(Uri.parse('https://malintic.com/'));
        },
      },
      {
        'title': 'Incubator',
        'subtitle': 'Accompagnement et accélération de startups et projets innovants',
        'icon': Icons.lightbulb_rounded,
        'color': AppTheme.success,
        'gradient': AppTheme.successGradient,
        'action': () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return poleDialog(
                context,
                'Incubator',
                'Ce pôle accompagnera les porteurs de projets : candidatures, mentorat, ressources et suivi d’incubation.',
              );
            },
          );
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(services.length, (index) {
        final service = services[index];
        final color = service['color'] as Color;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: service['action'] as VoidCallback,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: service['gradient'] as LinearGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          service['icon'] as IconData,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service['title'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              service['subtitle'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.chevron_right_rounded, color: color, size: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // MOBILE SERVICE CARDS
  Widget _buildServiceCardsMobile(BuildContext context) {
    final services = [
      {
        'title': 'Formations',
        'subtitle': 'Programmes en ligne & présentiel, gestion des parcours et inscriptions',
        'icon': Icons.school_rounded,
        'gradient': AppTheme.primaryGradient,
        'action': () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignInPage()),
          );
        },
      },
      {
        'title': 'Prestations',
        'subtitle': 'Offres, devis et suivi des missions de prestations IT',
        'icon': Icons.handshake_rounded,
        'gradient': AppTheme.orangeGradient,
        'action': () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return poleDialog(
                context,
                'Prestations',
                'Cette fonctionnalité est en cours de développement. Restez à l\'écoute pour les mises à jour futures !',
              );
            },
          );
        },
      },
      {
        'title': 'e-Commerce',
        'subtitle': 'Boutique en ligne, produits informatiques et commandes',
        'icon': Icons.shopping_cart_rounded,
        'gradient': AppTheme.accentGradient,
        'action': () async {
          await launchUrl(Uri.parse('https://malintic.com/'));
        },
      },
      {
        'title': 'Incubator',
        'subtitle': 'Accompagnement des porteurs de projets et startups',
        'icon': Icons.lightbulb_rounded,
        'gradient': AppTheme.successGradient,
        'action': () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return poleDialog(
                context,
                'Incubator',
                'Cette fonctionnalité est en cours de développement. Restez à l\'écoute pour les mises à jour futures !',
              );
            },
          );
        },
      },
    ];

    return Column(
      children: [
        ...List.generate(services.length, (index) {
          final service = services[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: AppTheme.cardShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: service['action'] as VoidCallback,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: service['gradient'] as LinearGradient,
                          ),
                          child: Icon(
                            service['icon'] as IconData,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service['title'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                service['subtitle'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppTheme.heroShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInPage()),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Se Connecter à la Plateforme',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

