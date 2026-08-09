import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestion_formations/Models/user.dart';
import 'package:gestion_formations/Pages/Login/welcom_page.dart';
import 'package:gestion_formations/Services/auth_provider.dart';
import 'package:gestion_formations/Services/notifications_services.dart';
import 'package:gestion_formations/config/theme.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final int? selectedIndex;
  final Function(int)? onNavigationChanged;
  final List<NavigationItem> navigationItems;
  final User? user;

  const MainLayout({
    super.key,
    required this.child,
    required this.title,
    this.selectedIndex = 0,
    this.onNavigationChanged,
    required this.navigationItems,
    this.user,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _notificationAnimationController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex ?? 0;
    _notificationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _notificationAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;
    final isTablet = size.width >= 768 && size.width < 1100;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        // slightly larger header to fit the bigger logo and profile brand
        toolbarHeight: isMobile ? 44 : 54,
        titleSpacing: isMobile ? 0 : 8,
        // larger left logo area for better visibility
        leadingWidth: isMobile ? 60 : 92,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        // apply stronger blue-red gradient from theme
        flexibleSpace: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.logoRed, AppTheme.primary, AppTheme.logoRed],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ],
        ),
        leading: isMobile
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'images/logo.png',
                      fit: BoxFit.contain,
                      width: isMobile ? 56 : 76,
                      height: isMobile ? 56 : 76,
                    ),
                  ),
                ),
              ),
        title: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: size.width - (isMobile ? 120 : 160)),
          child: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: StreamBuilder<List<dynamic>>(
              stream: _getUnreadNotificationsStream(),
              builder: (context, snapshot) {
                final unreadCount = _countUnreadNotifications(snapshot.data ?? []);
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                      onPressed: () => _navigateToNotifications(),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: AnimatedBuilder(
                          animation: _notificationAnimationController,
                          builder: (context, child) {
                            return Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppTheme.error,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.error.withValues(
                                      alpha: Curves.easeInOut.transform(_notificationAnimationController.value) * 0.4,
                                    ),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4, top: 2, bottom: 2),
            child: GestureDetector(
              onTap: () {
                final profileIndex = widget.navigationItems.indexWhere(
                  (item) => item.label.toLowerCase().contains('profil'),
                );
                if (profileIndex >= 0) {
                  setState(() => _selectedIndex = profileIndex);
                  widget.onNavigationChanged?.call(profileIndex);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'images/logo.png',
                        fit: BoxFit.contain,
                        width: 40,
                        height: 40,
                        color: AppTheme.primary,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.user?.nomComplet.isNotEmpty == true
                        ? widget.user!.nomComplet.split(' ').first
                        : 'Profil',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: isMobile ? _buildDrawer(context) : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(context, isTablet: isTablet),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: isMobile ? 0 : 16,
                right: 16,
                top: 16,
                bottom: 16,
              ),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 228),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              boxShadow: AppTheme.cardShadow,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.user?.nomComplet.isNotEmpty == true ? widget.user!.nomComplet[0].toUpperCase() : 'U',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.user?.nomComplet ?? 'Utilisateur',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.user?.role.toString().split('.').last.toUpperCase() ?? 'ROLE',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: widget.navigationItems.length,
              itemBuilder: (context, index) {
                final item = widget.navigationItems[index];
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Ink(
                    decoration: isSelected
                        ? BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primary.withValues(alpha: 0.12),
                                AppTheme.indigoAccent.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      leading: Icon(
                        item.icon,
                        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                        size: 22,
                      ),
                      title: Text(
                        item.label,
                        style: GoogleFonts.poppins(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      selected: isSelected,
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        widget.onNavigationChanged?.call(index);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: AppTheme.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final nav = Navigator.of(context);
                  await AuthProvider().logout();
                  if (!mounted) return;
                  nav.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const WelcomPage()),
                    (route) => false,
                  );
                },
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 22),
                  title: Text(
                    'Déconnexion',
                    style: GoogleFonts.poppins(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {required bool isTablet}) {
    final width = MediaQuery.of(context).size.width;
    final sidebarWidth = width < 900 ? 72.0 : width < 1100 ? 110.0 : 220.0;
    final showLabel = sidebarWidth >= 110;
    final showUserInfo = sidebarWidth >= 160;

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
      ),
      child: Column(
        children: [
          Container(
            height: showUserInfo ? 122 : 64,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              boxShadow: AppTheme.softShadow,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CircleAvatar(
                      radius: showLabel ? 28 : 18,
                      backgroundColor: Colors.white,
                      child: Text(
                        widget.user?.nomComplet.isNotEmpty == true ? widget.user!.nomComplet[0].toUpperCase() : 'U',
                        style: GoogleFonts.poppins(
                          fontSize: showLabel ? 22 : 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                ),
                if (showUserInfo) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.user?.nomComplet ?? 'Utilisateur',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.user?.role.toString().split('.').last.toUpperCase() ?? 'ROLE',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: widget.navigationItems.length,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              itemBuilder: (context, index) {
                final item = widget.navigationItems[index];
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Tooltip(
                    message: item.label,
                    child: Ink(
                        decoration: isSelected
                            ? BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(12),
                              )
                            : null,
                        child: ListTile(
                        dense: true,
                        contentPadding: showLabel
                            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 2)
                            : const EdgeInsets.symmetric(horizontal: 8),
                        minLeadingWidth: 0,
                                leading: Icon(
                                  item.icon,
                                  // on colored sidebar, use white icons by default
                                  color: isSelected ? AppTheme.accent : Colors.white,
                                  size: showLabel ? 18 : 22,
                                ),
                        title: showLabel
                            ? Text(
                                item.label,
                                style: GoogleFonts.poppins(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppTheme.accent : Colors.white,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        selected: isSelected,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          setState(() => _selectedIndex = index);
                          widget.onNavigationChanged?.call(index);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Tooltip(
              message: 'Déconnexion',
              child: Material(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final nav = Navigator.of(context);
                    await AuthProvider().logout();
                    if (!mounted) return;
                    nav.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const WelcomPage()),
                      (route) => false,
                    );
                  },
                  child: ListTile(
                    dense: true,
                    contentPadding: showLabel ? const EdgeInsets.symmetric(horizontal: 10) : const EdgeInsets.symmetric(horizontal: 8),
                    minLeadingWidth: 0,
                    leading: Icon(Icons.logout_rounded, color: AppTheme.error, size: showLabel ? 20 : 22),
                    title: showLabel
                        ? Text(
                            'Déconnexion',
                            style: GoogleFonts.poppins(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<dynamic>> _getUnreadNotificationsStream() {
    if (widget.user == null) return Stream.value([]);
    return NotificationsService().watchNotificationsForUser(
      userId: widget.user!.id,
      userEmail: widget.user!.email,
      userRole: widget.user!.role.toString(),
    );
  }

  int _countUnreadNotifications(List<dynamic> notifications) {
    int count = 0;
    for (final notif in notifications) {
      if (notif.readBy != null && notif.readBy is List) {
        if (!notif.readBy.contains(widget.user?.id)) {
          count++;
        }
      }
    }
    return count;
  }

  void _navigateToNotifications() {
    final notificationIndex = widget.navigationItems.indexWhere(
      (item) => item.label.toLowerCase().contains('notification'),
    );
    if (notificationIndex >= 0) {
      setState(() => _selectedIndex = notificationIndex);
      widget.onNavigationChanged?.call(notificationIndex);
    }
  }
}

class NavigationItem {
  final String label;
  final IconData icon;

  NavigationItem({required this.label, required this.icon});
}

