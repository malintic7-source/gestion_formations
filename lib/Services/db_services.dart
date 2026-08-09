import 'dart:async';
import 'package:gestion_formations/Models/user.dart';
import 'package:gestion_formations/Models/formation.dart';
import 'package:gestion_formations/Models/inscription.dart';
import 'package:gestion_formations/Models/payment.dart';
import 'package:gestion_formations/Models/notification.dart';

class LocalDataService {
  static final LocalDataService _instance = LocalDataService._internal();
  factory LocalDataService() => _instance;

  LocalDataService._internal() {
    _initInitialData();
  }

  // Reactive Data Controllers
  final _usersController = StreamController<List<User>>.broadcast();
  final _formationsController = StreamController<List<Formation>>.broadcast();
  final _inscriptionsController = StreamController<List<Inscription>>.broadcast();
  final _paymentsController = StreamController<List<Payment>>.broadcast();
  final _notificationsController = StreamController<List<AppNotification>>.broadcast();

  // Internal Storage Lists
  final List<User> _users = [];
  final List<Formation> _formations = [];
  final List<Inscription> _inscriptions = [];
  final List<Payment> _payments = [];
  final List<AppNotification> _notifications = [];

  void _initInitialData() {
    // 1. Initial Users
    _users.addAll([
      User(
        id: 'admin_1',
        email: 'admin@mali-ntic.ml',
        nom: 'Diallo',
        prenom: 'Mamadou',
        phone: '+223 70 00 11 22',
        role: UserRole.admin,
        password: '00000000',
        estActif: true,
        dateCreation: DateTime.now().subtract(const Duration(days: 30)),
      ),
      User(
        id: 'formateur_1',
        email: 'formateur@mali-ntic.ml',
        nom: 'Traoré',
        prenom: 'Ousmane',
        phone: '+223 76 33 44 55',
        role: UserRole.formateur,
        password: '00000000',
        estActif: true,
        dateCreation: DateTime.now().subtract(const Duration(days: 20)),
      ),
      User(
        id: 'etudiant_1',
        email: 'etudiant@mali-ntic.ml',
        nom: 'Touré',
        prenom: 'Fatoumata',
        phone: '+223 66 55 44 33',
        role: UserRole.etudiant,
        password: '00000000',
        estActif: true,
        dateCreation: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ]);

    // 2. Initial Formations
    _formations.addAll([
      Formation(
        id: 'form_1',
        titre: 'Développement Mobile Flutter',
        description: 'Apprenez à créer des applications iOS et Android performantes et réactives avec Flutter et Dart.',
        modules: ['Bases de Dart', 'Widgets et UI Material 3', 'Gestion d\'état', 'Intégration API REST'],
        formateurIds: ['formateur_1'],
        prix: 150000,
        prixEnLigne: 120000,
        type: FormationType.mixte,
        status: FormationStatus.enCours,
        dureeSemaines: 8,
        dureeHeures: '40h',
        horaires: [Horaire(jour: 'Samedi', heureDebut: '09:00', heureFin: '13:00')],
        dateDebut: DateTime.now().subtract(const Duration(days: 5)),
        dateFin: DateTime.now().add(const Duration(days: 50)),
        dateCreation: DateTime.now().subtract(const Duration(days: 15)),
        capaciteMax: 20,
        nombreInscrits: 1,
      ),
      Formation(
        id: 'form_2',
        titre: 'Développement Web Fullstack React & Node.js',
        description: 'Formation complète pour concevoir des applications web modernes et évolutives.',
        modules: ['HTML5/CSS3/JavaScript ES6', 'React.js Fundamentals', 'Node.js & Express', 'MongoDB'],
        formateurIds: ['formateur_1'],
        prix: 180000,
        prixEnLigne: 140000,
        type: FormationType.enligne,
        status: FormationStatus.programmee,
        dureeSemaines: 10,
        dureeHeures: '60h',
        horaires: [Horaire(jour: 'Lundi & Mercredi', heureDebut: '18:00', heureFin: '20:30')],
        dateDebut: DateTime.now().add(const Duration(days: 10)),
        dateFin: DateTime.now().add(const Duration(days: 80)),
        dateCreation: DateTime.now().subtract(const Duration(days: 10)),
        capaciteMax: 25,
        nombreInscrits: 0,
      ),
    ]);

    // 3. Initial Inscriptions & Payments
    _inscriptions.add(
      Inscription(
        id: 'insc_1',
        etudiantId: 'etudiant_1',
        formationId: 'form_1',
        status: InscriptionStatus.acceptee,
        dateInscription: DateTime.now().subtract(const Duration(days: 4)),
        paiementId: 'pay_1',
        paiementEffectue: true,
        dateAcceptation: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      ),
    );

    _payments.add(
      Payment(
        id: 'pay_1',
        inscriptionId: 'insc_1',
        etudiantId: 'etudiant_1',
        formationId: 'form_1',
        montant: 120000,
        status: PaymentStatus.effectue,
        methode: PaymentMethod.virement,
        dateCreation: DateTime.now().subtract(const Duration(days: 4)),
        dateEffectuation: DateTime.now().subtract(const Duration(days: 4)),
        referenceTransaction: 'VIR-2026-00128',
      ),
    );

    // 4. Initial Notifications
    _notifications.add(
      AppNotification(
        id: 'notif_1',
        title: 'Bienvenue sur M@LI-NTIC',
        description: 'Découvrez vos cours et suivez vos inscriptions facilement.',
        senderId: 'admin_1',
        senderEmail: 'admin@mali-ntic.ml',
        targetRoles: ['etudiant', 'formateur', 'admin'],
        targetUserIds: [],
        audience: ['all'],
        readBy: [],
        reminderCount: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );
  }

  // --- USERS ---
  Stream<List<User>> watchUsers() async* {
    yield List.unmodifiable(_users);
    yield* _usersController.stream;
  }

  List<User> getUsers() => List.unmodifiable(_users);

  User? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<User> addUser(User user) async {
    _users.removeWhere((u) => u.id == user.id);
    _users.add(user);
    _usersController.add(List.unmodifiable(_users));
    return user;
  }

  Future<void> setUserActive(String userId, bool isActive) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final old = _users[index];
      _users[index] = User(
        id: old.id,
        email: old.email,
        nom: old.nom,
        prenom: old.prenom,
        phone: old.phone,
        role: old.role,
        photoUrl: old.photoUrl,
        estActif: isActive,
        dateCreation: old.dateCreation,
        dateModification: DateTime.now(),
      );
      _usersController.add(List.unmodifiable(_users));
    }
  }

  // --- FORMATIONS ---
  Stream<List<Formation>> watchFormations() async* {
    yield List.unmodifiable(_formations);
    yield* _formationsController.stream;
  }

  List<Formation> getFormations() => List.unmodifiable(_formations);

  Future<void> addFormation(Formation formation) async {
    _formations.removeWhere((f) => f.id == formation.id);
    _formations.add(formation);
    _formationsController.add(List.unmodifiable(_formations));
  }

  Future<void> updateFormation(Formation formation) async {
    final index = _formations.indexWhere((f) => f.id == formation.id);
    if (index != -1) {
      _formations[index] = formation;
    } else {
      _formations.add(formation);
    }
    _formationsController.add(List.unmodifiable(_formations));
  }

  Future<void> deleteFormation(String id) async {
    _formations.removeWhere((f) => f.id == id);
    _formationsController.add(List.unmodifiable(_formations));
  }

  // --- INSCRIPTIONS ---
  Stream<List<Inscription>> watchInscriptions() async* {
    yield List.unmodifiable(_inscriptions);
    yield* _inscriptionsController.stream;
  }

  List<Inscription> getInscriptions() => List.unmodifiable(_inscriptions);

  Inscription? getInscriptionById(String id) {
    try {
      return _inscriptions.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Inscription> createInscription({
    required String etudiantId,
    required String formationId,
    required double montant,
    required PaymentMethod methode,
    String? prenom,
    String? nom,
    String? email,
    String? telephone,
    String? description,
    List<String>? modules,
    String? typeFormation,
  }) async {
    final inscId = 'insc_${DateTime.now().millisecondsSinceEpoch}';
    final payId = 'pay_${DateTime.now().millisecondsSinceEpoch}';

    final newPay = Payment(
      id: payId,
      inscriptionId: inscId,
      etudiantId: etudiantId,
      formationId: formationId,
      montant: montant,
      status: PaymentStatus.effectue,
      methode: methode,
      dateCreation: DateTime.now(),
      dateEffectuation: DateTime.now(),
      referenceTransaction: 'REF-${DateTime.now().millisecondsSinceEpoch}',
    );

    final newInsc = Inscription(
      id: inscId,
      etudiantId: etudiantId,
      formationId: formationId,
      status: InscriptionStatus.enAttente,
      dateInscription: DateTime.now(),
      paiementId: payId,
      paiementEffectue: true,
      prenom: prenom,
      nom: nom,
      email: email,
      telephone: telephone,
      description: description,
      modules: modules,
      typeFormation: typeFormation,
    );

    _payments.add(newPay);
    _inscriptions.add(newInsc);

    _paymentsController.add(List.unmodifiable(_payments));
    _inscriptionsController.add(List.unmodifiable(_inscriptions));

    return newInsc;
  }

  Formation? getFormationById(String id) {
    try {
      return _formations.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateInscriptionStatus(String id, String statusStr, {String? motifRejet}) async {
    final index = _inscriptions.indexWhere((i) => i.id == id);
    if (index != -1) {
      final old = _inscriptions[index];
      InscriptionStatus status = InscriptionStatus.enAttente;
      if (statusStr == 'valide' || statusStr == 'acceptee') {
        status = InscriptionStatus.acceptee;
      } else if (statusStr == 'rejete' || statusStr == 'rejetee') {
        status = InscriptionStatus.rejetee;
      }

      _inscriptions[index] = Inscription(
        id: old.id,
        etudiantId: old.etudiantId,
        formationId: old.formationId,
        status: status,
        dateInscription: old.dateInscription,
        paiementId: old.paiementId,
        paiementEffectue: old.paiementEffectue,
        dateAcceptation: status == InscriptionStatus.acceptee ? DateTime.now().toIso8601String() : old.dateAcceptation,
        motifRejet: motifRejet ?? old.motifRejet,
      );
      _inscriptionsController.add(List.unmodifiable(_inscriptions));
    }
  }

  Future<void> updateInscriptionPaymentStatus(String inscriptionId, bool paiementEffectue) async {
    final index = _inscriptions.indexWhere((i) => i.id == inscriptionId);
    if (index == -1) return;

    final old = _inscriptions[index];
    _inscriptions[index] = Inscription(
      id: old.id,
      etudiantId: old.etudiantId,
      formationId: old.formationId,
      status: old.status,
      dateInscription: old.dateInscription,
      paiementId: old.paiementId,
      paiementEffectue: paiementEffectue,
      dateAcceptation: old.dateAcceptation,
      motifRejet: old.motifRejet,
      prenom: old.prenom,
      nom: old.nom,
      email: old.email,
      telephone: old.telephone,
      description: old.description,
      modules: old.modules,
      typeFormation: old.typeFormation,
    );
    _inscriptionsController.add(List.unmodifiable(_inscriptions));
  }

  // --- PAYMENTS ---
  Stream<List<Payment>> watchPayments() async* {
    yield List.unmodifiable(_payments);
    yield* _paymentsController.stream;
  }

  List<Payment> getPayments() => List.unmodifiable(_payments);

  Future<void> addPayment(Payment payment) async {
    _payments.add(payment);
    _paymentsController.add(List.unmodifiable(_payments));
  }

  Future<void> updatePaymentStatus(String id, String statusStr) async {
    final index = _payments.indexWhere((p) => p.id == id);
    if (index == -1) return;

    final old = _payments[index];

    PaymentStatus newStatus = old.status;
    if (statusStr == 'valide' || statusStr == 'effectue' || statusStr == 'effectué' || statusStr == 'effectue') {
      newStatus = PaymentStatus.effectue;
    } else if (statusStr == 'incomplet' || statusStr == 'echoue' || statusStr == 'échoué') {
      newStatus = PaymentStatus.echoue;
    } else if (statusStr == 'en_attente' || statusStr == 'enAttente' || statusStr == 'en_attente') {
      newStatus = PaymentStatus.enAttente;
    }

    final updated = Payment(
      id: old.id,
      inscriptionId: old.inscriptionId,
      etudiantId: old.etudiantId,
      formationId: old.formationId,
      montant: old.montant,
      status: newStatus,
      methode: old.methode,
      dateCreation: old.dateCreation,
      dateEffectuation: newStatus == PaymentStatus.effectue ? DateTime.now() : old.dateEffectuation,
      referenceTransaction: old.referenceTransaction ?? 'REF-${DateTime.now().millisecondsSinceEpoch}',
      motifEchec: old.motifEchec,
      motif: old.motif,
    );

    _payments[index] = updated;
    _paymentsController.add(List.unmodifiable(_payments));

    if (updated.inscriptionId.isNotEmpty) {
      await updateInscriptionPaymentStatus(updated.inscriptionId, updated.status == PaymentStatus.effectue);
    }
  }

  // --- NOTIFICATIONS ---
  Stream<List<AppNotification>> watchNotifications() async* {
    yield List.unmodifiable(_notifications);
    yield* _notificationsController.stream;
  }

  List<AppNotification> getNotifications() => List.unmodifiable(_notifications);

  Future<void> addNotification(AppNotification notif) async {
    _notifications.add(notif);
    _notificationsController.add(List.unmodifiable(_notifications));
  }

  Future<void> markNotificationRead(String notifId, String userId) async {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index != -1) {
      final old = _notifications[index];
      if (!old.readBy.contains(userId)) {
        final updatedReadBy = List<String>.from(old.readBy)..add(userId);
        _notifications[index] = AppNotification(
          id: old.id,
          title: old.title,
          description: old.description,
          imageUrl: old.imageUrl,
          senderId: old.senderId,
          senderEmail: old.senderEmail,
          targetRoles: old.targetRoles,
          targetUserIds: old.targetUserIds,
          audience: old.audience,
          readBy: updatedReadBy,
          reminderCount: old.reminderCount,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
        );
        _notificationsController.add(List.unmodifiable(_notifications));
      }
    }
  }

  Future<void> updateModuleDoneHours(String userId, String formationId, String moduleTitle, int delta) async {
    // Local memory state stub
  }
}
