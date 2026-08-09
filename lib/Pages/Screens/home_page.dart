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

          //CONTENU PRINCIPALE DE LA PAGE
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(),
                //Contenu
                ///////////////////////////////////....
                //Footer de la page de bienvenue
                footer(),
              ],
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
}
