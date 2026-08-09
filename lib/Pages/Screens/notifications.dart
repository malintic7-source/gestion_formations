import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestion_formations/Models/notification.dart';
import 'package:gestion_formations/Models/user.dart';
import 'package:gestion_formations/Services/auth_provider.dart';
import 'package:gestion_formations/Services/notifications_services.dart';
import 'package:gestion_formations/config/theme.dart';
// invoice and pdf helper imports removed (unused)

class NotificationsPage extends StatefulWidget {
  final User user;

  const NotificationsPage({super.key, required this.user});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with TickerProviderStateMixin {
  final NotificationsService _notificationsService = NotificationsService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _audienceController = TextEditingController();
  final List<String> _selectedRoles = [];
  final Set<String> _selectedUserIds = {};
  AppNotification? _editingNotification;
  String _sortBy = 'Date';
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: Duration(milliseconds: 600), vsync: this)..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _audienceController.dispose();
    super.dispose();
  }

  bool get isAdmin => widget.user.role == UserRole.admin;

  @override
  Widget build(BuildContext context) {
    if (isAdmin) {
      return _buildAdminLayout();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: FadeTransition(
        opacity: _fadeController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Restez informé des mises à jour',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24),
            _buildStudentNotificationList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 860;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppPadding.md : AppPadding.lg,
                vertical: AppPadding.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAdminHeader(context, isMobile),
                  SizedBox(height: AppPadding.lg),
                  _buildNotificationList(context, isMobile),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminHeader(BuildContext context, bool isMobile) {
    return FadeTransition(
      opacity: _fadeController,
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
                      'Notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Gérez vos messages internes en toute clarté.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: AppPadding.md),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _cancelEditing();
                        _showNotificationDialog();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.add_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Nouvelle',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentNotificationList(BuildContext context) {
    final notificationsStream = _notificationsService.watchNotificationsForUser(
      userId: widget.user.id,
      userEmail: widget.user.email,
      userRole: widget.user.role.toString(),
    );

    return StreamBuilder<List<AppNotification>>(
      stream: notificationsStream,
      builder: (context, snapshot) {
        debugPrint('🔍 StreamBuilder state: ${snapshot.connectionState}');
        debugPrint('🔍 Has data: ${snapshot.hasData}');
        debugPrint('🔍 Has error: ${snapshot.hasError}');
        if (snapshot.hasError) {
          debugPrint('🔍 Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.notifications_off_outlined, size: 56, color: AppTheme.textSecondary),
                  SizedBox(height: 14),
                  Text(
                    'Aucune notification',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + (index * 60)),
                builder: (context, anim, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - anim)),
                    child: Opacity(
                      opacity: anim,
                      child: _buildStudentNotificationCard(context, notifications[index]),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStudentNotificationCard(BuildContext context, AppNotification notification) {
    final isRead = notification.readBy.contains(widget.user.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showNotificationDetails(notification),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isRead ? Colors.transparent : AppTheme.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty)
                Stack(
                  children: [
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Image.network(
                        notification.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Icon(Icons.notifications, color: Colors.white, size: 48),
                        ),
                      ),
                    ),
                    if (!isRead)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      notification.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12),
                    // Bouton Télécharger facture si applicable
                    if (notification.title.contains('Paiement') || notification.title.contains('Inscription'))
                      GestureDetector(
                        onTap: () => _downloadInvoice(notification),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primary, AppTheme.primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Télécharger facture',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FutureBuilder<User?>(
                          future: _lookupUser(notification.senderId),
                          builder: (context, snapshot) {
                            final senderName = snapshot.data != null
                                ? '${snapshot.data!.prenom} ${snapshot.data!.nom}'
                                : 'Admin';
                            return Text(
                              senderName,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                        Text(
                          _formatDate(notification.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (!isRead) ...[
                      SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                await _markRead(notification.id);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 9),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Marquer comme lu',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  Future<void> _showNotificationDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        final isMobile = MediaQuery.of(context).size.width < 760;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              _editingNotification == null ? 'Nouvelle notification' : 'Modifier la notification',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? 520 : 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: AppPadding.sm,
                      runSpacing: AppPadding.sm,
                      children: [
                        _buildRoleChip('admin'),
                        _buildRoleChip('formateur'),
                        _buildRoleChip('etudiant'),
                      ],
                    ),
                    SizedBox(height: AppPadding.lg),
                    StreamBuilder<List<User>>(
                      stream: AuthProvider().watchUsers(),
                      builder: (context, snapshot) {
                        final users = snapshot.data ?? [];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Utilisateurs spécifiques',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: users.take(20).map((user) {
                                final isSelected = _selectedUserIds.contains(user.id);
                                return FilterChip(
                                  label: Text(user.nomComplet),
                                  selected: isSelected,
                                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                                  checkmarkColor: AppTheme.primary,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedUserIds.add(user.id);
                                      } else {
                                        _selectedUserIds.remove(user.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: AppPadding.lg),
                    _buildNotificationTextField('Titre', _titleController),
                    SizedBox(height: AppPadding.lg),
                    _buildNotificationTextField('Description', _descriptionController, maxLines: 4),
                    SizedBox(height: AppPadding.lg),
                    _buildNotificationTextField('URL image (optionnel)', _imageUrlController),
                    SizedBox(height: AppPadding.lg),
                    _buildNotificationTextField('Courriels séparés par virgule (optionnel)', _audienceController),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _editingNotification = null;
                  _resetForm();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Annuler',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
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
                      await _sendNotification();
                      if (mounted) Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        _editingNotification == null ? 'Envoyer' : 'Mettre à jour',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() {});
  }

  Widget _buildRoleChip(String role) {
    final selected = _selectedRoles.contains(role);
    return ChoiceChip(
      label: Text(
        role.toUpperCase(),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      selectedColor: AppTheme.primary,
      onSelected: (value) {
        setState(() {
          if (value) {
            _selectedRoles.add(role);
          } else {
            _selectedRoles.remove(role);
          }
        });
      },
    );
  }

  Widget _buildNotificationTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }


  Future<void> _sendNotification() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final imageUrl = _imageUrlController.text.trim().isEmpty
        ? null
        : _imageUrlController.text.trim();
    final audience = _audienceController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (title.isEmpty || description.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Titre et description sont requis.')),
      );
      return;
    }

    if (_selectedRoles.isEmpty &&
        _selectedUserIds.isEmpty &&
        audience.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sélectionnez au moins un rôle, un utilisateur ou un email.',
          ),
        ),
      );
      return;
    }

    try {
      if (_editingNotification == null) {
        await _notificationsService.createNotification(
          title: title,
          description: description,
          imageUrl: imageUrl,
          senderId: widget.user.id,
          senderEmail: widget.user.email,
          targetRoles: _selectedRoles.map((r) => 'UserRole.$r').toList(),
          targetUserIds: _selectedUserIds.toList(),
          audience: audience,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Notification envoyée.')));
      } else {
        await _notificationsService.updateNotification(
          notificationId: _editingNotification!.id,
          title: title,
          description: description,
          imageUrl: imageUrl,
          targetRoles: _selectedRoles.map((r) => 'UserRole.$r').toList(),
          targetUserIds: _selectedUserIds.toList(),
          audience: audience,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Notification mise à jour.')));
        _editingNotification = null;
      }
      _resetForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  void _resetForm() {
    setState(() {
      _selectedRoles.clear();
      _selectedUserIds.clear();
      _titleController.clear();
      _descriptionController.clear();
      _imageUrlController.clear();
      _audienceController.clear();
    });
  }

  Widget _buildNotificationList(BuildContext context, bool isMobile) {
    final notificationsStream = isAdmin
        ? _notificationsService.watchAllNotifications()
        : _notificationsService.watchNotificationsForUser(
            userId: widget.user.id,
            userEmail: widget.user.email,
            userRole: widget.user.role.toString(),
          );

    return StreamBuilder<List<AppNotification>>(
      stream: notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data ?? [];
        var filtered = notifications.where((notification) {
          final query = _searchController.text.trim().toLowerCase();
          if (query.isEmpty) return true;
          return notification.title.toLowerCase().contains(query) ||
              notification.description.toLowerCase().contains(query);
        }).toList();

        if (isAdmin) {
          _sortNotifications(filtered);
        }

        if (filtered.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: EdgeInsets.all(AppPadding.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 64,
                  color: AppTheme.textSecondary,
                ),
                SizedBox(height: AppPadding.lg),
                Text(
                  'Aucune notification pour le moment',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }

        final cardWidth = isMobile ? double.infinity : 520.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminToolbar(context, isMobile),
            SizedBox(height: AppPadding.lg),
            Wrap(
              spacing: AppPadding.lg,
              runSpacing: AppPadding.lg,
              children: filtered.map((notification) {
                return SizedBox(
                  width: cardWidth,
                  child: _buildNotificationCardAdmin(context, notification),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdminToolbar(BuildContext context, bool isMobile) {
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
      child: Padding(
        padding: EdgeInsets.all(AppPadding.lg),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchField(),
                  SizedBox(height: AppPadding.md),
                  _buildToolbarControls(context),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildSearchField()),
                  SizedBox(width: AppPadding.lg),
                  _buildToolbarControls(context),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Rechercher une notification...',
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
    );
  }

  Widget _buildToolbarControls(BuildContext context) {
    return Wrap(
      spacing: AppPadding.md,
      runSpacing: AppPadding.md,
      alignment: WrapAlignment.end,
      children: [
        DropdownButton<String>(
          value: _sortBy,
          items: ['Date', 'Vues']
              .map((value) => DropdownMenuItem(value: value, child: Text(value)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _sortBy = value);
          },
        ),
      ],
    );
  }

  void _sortNotifications(List<AppNotification> notifications) {
    if (_sortBy == 'Vues') {
      notifications.sort((a, b) => b.readBy.length.compareTo(a.readBy.length));
    } else {
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  Widget _buildNotificationCardAdmin(
    BuildContext context,
    AppNotification notification,
  ) {
    notification.readBy.contains(widget.user.id);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showNotificationDetails(notification),
          child: Padding(
            padding: EdgeInsets.all(AppPadding.lg),
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
                            notification.title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            notification.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isAdmin)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
                        onSelected: (value) {
                          if (value == 'modifier') {
                            _beginEditNotification(notification);
                          } else if (value == 'supprimer') {
                            _confirmDeleteNotification(notification);
                          } else if (value == 'rappeler') {
                            _confirmRemindNotification(notification);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'modifier',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Modifier'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'rappeler',
                            child: Row(
                              children: [
                                Icon(Icons.notifications_active_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Rappeler non lus'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'supprimer',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Supprimer', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (notification.imageUrl != null &&
                    notification.imageUrl!.isNotEmpty) ...[
                  SizedBox(height: AppPadding.lg),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      notification.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 180,
                      errorBuilder: (_, _, _) => Container(
                        color: AppTheme.surfaceVariant,
                        height: 180,
                        child: Center(child: Icon(Icons.broken_image_rounded)),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: AppPadding.lg),
                _buildSenderInfo(notification),
                SizedBox(height: AppPadding.lg),
                Wrap(
                  spacing: AppPadding.sm,
                  runSpacing: AppPadding.sm,
                  children: [
                    _buildChip(
                      '${notification.readBy.length} vues',
                      AppTheme.primary,
                      onTap: () => _showViewsDialog(notification),
                    ),
                    if (isAdmin)
                      _buildChip(
                        '${notification.targetRoles.length} rôles',
                        AppTheme.primaryDark,
                        onTap: () => _showRolesDialog(notification),
                      ),
                    if (isAdmin)
                      FutureBuilder<int>(
                        future: _countNotificationRecipients(notification),
                        builder: (context, snapshot) {
                          final countLabel = snapshot.connectionState == ConnectionState.done
                              ? '${snapshot.data ?? 0} destinataires'
                              : 'Destinataires...';
                          return _buildChip(
                            countLabel,
                            Color(0xFF10B981),
                            onTap: () => _showRecipientsDialog(notification),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color, {VoidCallback? onTap}) {
    final child = Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppPadding.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
      ),
    );
    return onTap != null ? InkWell(onTap: onTap, child: child) : child;
  }

  Widget _buildSenderInfo(AppNotification notification) {
    return FutureBuilder<User?>(
      future: _lookupUser(notification.senderId),
      builder: (context, snapshot) {
        final senderName = snapshot.data != null
            ? '${snapshot.data!.prenom} ${snapshot.data!.nom}'
            : notification.senderEmail;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envoyé par $senderName',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
            ),
            SizedBox(height: 4),
            Text(
              'Date d\'envoi : ${notification.createdAt.toLocal().day}/${notification.createdAt.toLocal().month}/${notification.createdAt.toLocal().year}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
            ),
          ],
        );
      },
    );
  }

  Future<User?> _lookupUser(String userId) async {
    final users = await AuthProvider().watchUsers().first;
    for (final user in users) {
      if (user.id == userId) {
        return user;
      }
    }
    return null;
  }

  Future<List<User>> _loadUsersByIds(List<String> ids) async {
    final users = await AuthProvider().watchUsers().first;
    return users.where((user) => ids.contains(user.id)).toList();
  }

  Future<int> _countNotificationRecipients(AppNotification notification) async {
    final users = await AuthProvider().watchUsers().first;
    final normalizedAudience = notification.audience
        .map((email) => email.trim().toLowerCase())
        .where((email) => email.isNotEmpty)
        .toSet();
    final roleUserIds = users
        .where((user) => notification.targetRoles.contains(user.role.toString()))
        .map((user) => user.id)
        .toSet();
    final explicitUserIds = notification.targetUserIds.toSet();
    final audienceUserIds = users
        .where((user) => normalizedAudience.contains(user.email.trim().toLowerCase()))
        .map((user) => user.id)
        .toSet();
    final uniqueUserIds = <String>{}
      ..addAll(roleUserIds)
      ..addAll(explicitUserIds)
      ..addAll(audienceUserIds);
    final unmatchedAudienceEmails = normalizedAudience
        .where((email) => users.every((user) => user.email.trim().toLowerCase() != email))
        .toSet()
        .length;
    return uniqueUserIds.length + unmatchedAudienceEmails;
  }

  Future<void> _showRecipientsDialog(AppNotification notification) async {
    final users = await AuthProvider().watchUsers().first;
    final normalizedAudience = notification.audience
        .map((email) => email.trim().toLowerCase())
        .where((email) => email.isNotEmpty)
        .toSet();

    final roleUsers = users.where((user) => notification.targetRoles.contains(user.role.toString())).toList();
    final explicitUsers = users.where((user) => notification.targetUserIds.contains(user.id)).toList();
    final audienceUsers = users
        .where((user) => normalizedAudience.contains(user.email.trim().toLowerCase()))
        .toList();

    final mergedUsers = <String, User>{};
    for (final user in roleUsers) {
      mergedUsers[user.id] = user;
    }
    for (final user in explicitUsers) {
      mergedUsers[user.id] = user;
    }
    for (final user in audienceUsers) {
      mergedUsers[user.id] = user;
    }

    final allMatchedEmails = users.map((user) => user.email.trim().toLowerCase()).toSet();
    final extraAudienceEmails = notification.audience
        .where((email) => !allMatchedEmails.contains(email.trim().toLowerCase()))
        .toList();
    final unresolvedUserIds = notification.targetUserIds
        .where((id) => !mergedUsers.containsKey(id))
        .toList();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        final roleLabels = notification.targetRoles.map((role) => role.replaceFirst('UserRole.', '')).toList();
        final hasRecipients = roleLabels.isNotEmpty || mergedUsers.isNotEmpty || extraAudienceEmails.isNotEmpty || unresolvedUserIds.isNotEmpty;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Destinataires ciblés',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (roleLabels.isNotEmpty) ...[
                  Text(
                    'Rôles ciblés :',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: AppPadding.sm),
                  ...roleLabels.map((label) => Text('- ${label.toUpperCase()}')),
                  SizedBox(height: AppPadding.lg),
                ],
                if (mergedUsers.isNotEmpty) ...[
                  Text(
                    'Destinataires :',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: AppPadding.sm),
                  ...mergedUsers.values.map((user) => Text('${user.nomComplet} — ${user.email}')),
                  SizedBox(height: AppPadding.lg),
                ],
                if (unresolvedUserIds.isNotEmpty) ...[
                  Text(
                    'Utilisateurs non résolus :',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: AppPadding.sm),
                  ...unresolvedUserIds.map((id) => Text(id)),
                  SizedBox(height: AppPadding.lg),
                ],
                if (extraAudienceEmails.isNotEmpty) ...[
                  Text(
                    'Emails ciblés :',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: AppPadding.sm),
                  ...extraAudienceEmails.map((email) => Text(email)),
                  SizedBox(height: AppPadding.lg),
                ],
                if (!hasRecipients)
                  Text('Aucun destinataire défini.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRolesDialog(AppNotification notification) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rôles ciblés',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: notification.targetRoles.isEmpty
                ? [Text('Aucun rôle sélectionné.')]
                : notification.targetRoles.map((role) => Text(role.replaceFirst('UserRole.', ''))).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showViewsDialog(AppNotification notification) async {
    final viewers = await _loadUsersByIds(notification.readBy);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Personnes ayant vu',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: viewers.isNotEmpty
                ? viewers.map((user) => Text('${user.nomComplet} — ${user.email}')).toList()
                : [Text('Aucun aperçu enregistré.')],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotificationDetails(AppNotification notification) async {
    if (!isAdmin && !notification.readBy.contains(widget.user.id)) {
      await _notificationsService.markNotificationRead(
        notificationId: notification.id,
        userId: widget.user.id,
      );
    }
    if (!mounted) return;

    if (isAdmin) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(notification.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notification.imageUrl != null &&
                    notification.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppPadding.md),
                      child: Image.network(
                        notification.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppTheme.surfaceVariant,
                          height: 150,
                          child: Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                  ),
                Text(notification.description),
                SizedBox(height: AppPadding.lg),
                _buildSenderInfo(notification),
                SizedBox(height: AppPadding.lg),
                Text(
                  'Vues: ${notification.readBy.length}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fermer'),
            ),
          ],
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      notification.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 180,
                      errorBuilder: (_, _, _) => Container(
                        color: AppTheme.surfaceVariant,
                        height: 180,
                        child: Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty)
                  SizedBox(height: 16),
                Text(
                  notification.title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  notification.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 18),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<User?>(
                        future: _lookupUser(notification.senderId),
                        builder: (context, snapshot) {
                          final senderName = snapshot.data != null
                              ? '${snapshot.data!.prenom} ${snapshot.data!.nom}'
                              : 'Admin';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Envoyé par',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                senderName,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Date d\'envoi',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18),
              ],
            ),
          ),
        ),
      );
      if (mounted) setState(() {});
    }
  }

  void _beginEditNotification(AppNotification notification) {
    _editingNotification = notification;
    _titleController.text = notification.title;
    _descriptionController.text = notification.description;
    _imageUrlController.text = notification.imageUrl ?? '';
    _audienceController.text = notification.audience.join(', ');
    _selectedRoles
      ..clear()
      ..addAll(notification.targetRoles.map((role) => role.replaceFirst('UserRole.', '')));
    _selectedUserIds
      ..clear()
      ..addAll(notification.targetUserIds);
    _showNotificationDialog();
  }

  void _cancelEditing() {
    setState(() {
      _editingNotification = null;
      _resetForm();
    });
  }

  Future<void> _confirmDeleteNotification(AppNotification notification) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Supprimer la notification',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer cette notification ?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(true),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Supprimer',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteNotification(notification.id);
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationsService.deleteNotification(notificationId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Notification supprimée.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _confirmRemindNotification(AppNotification notification) async {
    final unreadUserIds = notification.targetUserIds
        .where((id) => !notification.readBy.contains(id))
        .toList();
    if (unreadUserIds.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aucun destinataire explicite non lu à rappeler.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rappeler les destinataires',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Envoyer un rappel aux ${unreadUserIds.length} destinataires non lus ?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
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
                onTap: () => Navigator.of(context).pop(true),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Envoyer le rappel',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _remindNotification(notification, unreadUserIds);
    }
  }

  Future<void> _remindNotification(
    AppNotification notification,
    List<String> unreadUserIds,
  ) async {
    try {
      await _notificationsService.remindNotification(
        notificationId: notification.id,
        targetUserIds: unreadUserIds,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rappel envoyé pour ${unreadUserIds.length} destinataires.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _markRead(String notificationId) async {
    await _notificationsService.markNotificationRead(
      notificationId: notificationId,
      userId: widget.user.id,
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _downloadInvoice(AppNotification notification) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📄 Génération du reçu en cours...')),
      );
    } catch (e) {
      debugPrint('❌ Erreur facture: $e');
    }
  }
}
