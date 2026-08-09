import 'package:flutter/material.dart';
import 'package:gestion_formations/Models/user.dart';
import 'package:gestion_formations/Pages/Admin/dashboard.dart';
import 'package:gestion_formations/Pages/Admin/formations.dart';
import 'package:gestion_formations/Pages/Admin/formateurs.dart';
import 'package:gestion_formations/Pages/Admin/etudiants.dart';
import 'package:gestion_formations/Pages/Admin/inscriptions.dart';
import 'package:gestion_formations/Pages/Admin/paiements.dart';
import 'package:gestion_formations/Pages/Admin/users.dart';
import 'package:gestion_formations/Pages/Common/profile.dart';
import 'package:gestion_formations/Pages/Formateur/dashboard.dart';
import 'package:gestion_formations/Pages/Formateur/etudiants.dart';
import 'package:gestion_formations/Pages/Formateur/schedule.dart';
import 'package:gestion_formations/Pages/Screens/notifications.dart';
import 'package:gestion_formations/Pages/Student/dashboard.dart';
import 'package:gestion_formations/Pages/Student/formations.dart';
import 'package:gestion_formations/Pages/Student/schedule.dart';
import 'package:gestion_formations/Widgets/main_layout.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  late List<NavigationItem> navigationItems;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    navigationItems = _getNavigationItems();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: _getPageTitle(),
      selectedIndex: _selectedIndex,
      navigationItems: navigationItems,
      user: widget.user,
      onNavigationChanged: (index) {
        setState(() => _selectedIndex = index);
      },
      child: _buildSelectedPage(),
    );
  }

  List<NavigationItem> _getNavigationItems() {
    switch (widget.user.role) {
      case UserRole.admin:
        return [
          NavigationItem(label: 'Dashboard', icon: Icons.dashboard),
          NavigationItem(label: 'Utilisateurs', icon: Icons.people),
          NavigationItem(label: 'Étudiants', icon: Icons.school),
          NavigationItem(label: 'Formations', icon: Icons.book),
          NavigationItem(label: 'Formateurs', icon: Icons.person_outline),
          NavigationItem(label: 'Inscriptions', icon: Icons.assignment),
          NavigationItem(label: 'Paiements', icon: Icons.payment),
          NavigationItem(label: 'Notifications', icon: Icons.notifications),
          NavigationItem(label: 'Profil', icon: Icons.account_circle),
        ];
      case UserRole.formateur:
        return [
          NavigationItem(label: 'Dashboard', icon: Icons.dashboard),
          NavigationItem(label: 'Étudiants', icon: Icons.people),
          NavigationItem(label: 'Emploi du temps', icon: Icons.schedule),
          NavigationItem(label: 'Notifications', icon: Icons.notifications),
          NavigationItem(label: 'Profil', icon: Icons.account_circle),
        ];
      case UserRole.etudiant:
        return [
          NavigationItem(label: 'Dashboard', icon: Icons.dashboard),
          NavigationItem(label: 'Mes formations', icon: Icons.school),
          NavigationItem(label: 'Emploi du temps', icon: Icons.schedule),
          NavigationItem(label: 'Notifications', icon: Icons.notifications),
          NavigationItem(label: 'Profil', icon: Icons.account_circle),
        ];
    }
  }

  String _getPageTitle() {
    final titles = {
      UserRole.admin: [
        'Dashboard',
        'Gestion des Utilisateurs',
        'Gestion des Étudiants',
        'Gestion des Formations',
        'Gestion des Formateurs',
        'Gestion des Inscriptions',
        'Gestion des Paiements',
        'Notifications',
        'Mon Profil',
      ],
      UserRole.formateur: [
        'Dashboard',
        'Mes Étudiants',
        'Emploi du Temps',
        'Notifications',
        'Mon Profil',
      ],
      UserRole.etudiant: [
        'Dashboard',
        'Mes Formations',
        'Mon Emploi du Temps',
        'Notifications',
        'Mon Profil',
      ],
    };

    return titles[widget.user.role]?[_selectedIndex] ?? 'Page';
  }

  Widget _buildSelectedPage() {
    switch (widget.user.role) {
      case UserRole.admin:
        return _buildAdminPage();
      case UserRole.formateur:
        return _buildFormateurPage();
      case UserRole.etudiant:
        return _buildEtudiantPage();
    }
  }

  Widget _buildAdminPage() {
    switch (_selectedIndex) {
      case 0:
        return AdminDashboard(user: widget.user);
      case 1:
        return AdminUsers();
      case 2:
        return AdminEtudiants();
      case 3:
        return AdminFormations();
      case 4:
        return AdminFormateurs();
      case 5:
        return AdminInscriptions();
      case 6:
        return AdminPaiements();
      case 7:
        return NotificationsPage(user: widget.user);
      case 8:
        return ProfilePage(user: widget.user);
      default:
        return SizedBox();
    }
  }

  Widget _buildFormateurPage() {
    switch (_selectedIndex) {
      case 0:
        return FormateurDashboard(user: widget.user);
      case 1:
        return FormateurEtudiants(user: widget.user);
      case 2:
        return FormateurSchedule(user: widget.user);
      case 3:
        return NotificationsPage(user: widget.user);
      case 4:
        return ProfilePage(user: widget.user);
      default:
        return SizedBox();
    }
  }

  Widget _buildEtudiantPage() {
    switch (_selectedIndex) {
      case 0:
        return StudentDashboard(user: widget.user);
      case 1:
        return StudentFormations(user: widget.user);
      case 2:
        return StudentSchedule(user: widget.user);
      case 3:
        return NotificationsPage(user: widget.user);
      case 4:
        return ProfilePage(user: widget.user);
      default:
        return SizedBox();
    }
  }
}
