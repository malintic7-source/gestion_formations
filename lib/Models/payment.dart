// Removed Firestore import (migrating off Firebase)

enum PaymentStatus { enAttente, effectue, echoue }

enum PaymentMethod { carte, virement, especes }

class Payment {
  final String id;
  final String inscriptionId;
  final String etudiantId;
  final String formationId;
  final double montant;
  final PaymentStatus status;
  final PaymentMethod methode;
  final DateTime dateCreation;
  final DateTime? dateEffectuation;
  final String? referenceTransaction;
  final String? motifEchec;

  Payment({
    required this.id,
    required this.inscriptionId,
    required this.etudiantId,
    required this.formationId,
    required this.montant,
    required this.status,
    required this.methode,
    required this.dateCreation,
    this.dateEffectuation,
    this.referenceTransaction,
    this.motifEchec,
  });

  factory Payment.fromMap(Map<String, dynamic> data, String id) {
    PaymentStatus parseStatus(String statusStr) {
      if (statusStr.contains('effectue')) {
        return PaymentStatus.effectue;
      }
      if (statusStr.contains('echoue')) {
        return PaymentStatus.echoue;
      }
      return PaymentStatus.enAttente;
    }

    PaymentMethod parseMethod(String methodStr) {
      if (methodStr.contains('virement')) {
        return PaymentMethod.virement;
      }
      if (methodStr.contains('especes')) {
        return PaymentMethod.especes;
      }
      return PaymentMethod.carte;
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Payment(
      id: id,
      inscriptionId: data['inscriptionId'] ?? '',
      etudiantId: data['etudiantId'] ?? '',
      formationId: data['formationId'] ?? '',
      montant: (data['montant'] ?? 0).toDouble(),
      status: parseStatus(data['status']?.toString() ?? 'PaymentStatus.enAttente'),
      methode: parseMethod(data['methode']?.toString() ?? 'PaymentMethod.carte'),
      dateCreation: parseDate(data['dateCreation']) ?? DateTime.now(),
      dateEffectuation: parseDate(data['dateEffectuation']),
      referenceTransaction: data['referenceTransaction'],
      motifEchec: data['motifEchec'],
    );
  }

  factory Payment.fromFirestore(dynamic doc) {
    if (doc is Map<String, dynamic>) {
      return Payment.fromMap(doc, doc['id'] ?? '');
    }
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Payment.fromMap(data, doc.id ?? '');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inscriptionId': inscriptionId,
      'etudiantId': etudiantId,
      'formationId': formationId,
      'montant': montant,
      'status': status.toString(),
      'methode': methode.toString(),
      'dateCreation': dateCreation.toIso8601String(),
      'dateEffectuation': dateEffectuation?.toIso8601String(),
      'referenceTransaction': referenceTransaction,
      'motifEchec': motifEchec,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();
}
