// Removed Firestore import for Docker migration

enum FormationType { enligne, presentielle, mixte }

enum FormationStatus { programmee, enCours, terminee }

enum ImageFormat { carre, vertical }

class Horaire {
  final String jour;
  final String heureDebut;
  final String heureFin;

  Horaire({
    required this.jour,
    required this.heureDebut,
    required this.heureFin,
  });

  factory Horaire.fromMap(Map<String, dynamic> map) {
    return Horaire(
      jour: map['jour'] ?? '',
      heureDebut: map['heureDebut'] ?? '',
      heureFin: map['heureFin'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jour': jour,
      'heureDebut': heureDebut,
      'heureFin': heureFin,
    };
  }
}

class Formation {
  final String id;
  final String titre;
  final String description;
  final List<String> modules;
  final List<String> modulesBonus;
  final String? imageUrl;
  final ImageFormat? imageFormat;
  final List<String> formateurIds;
  final double prix;
  final double? prixEnLigne;
  final FormationType type;
  final FormationStatus status;
  final int dureeSemaines;
  final String? dureeHeures;
  final List<Horaire> horaires;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final DateTime dateCreation;
  final int? capaciteMax;
  final int? nombreInscrits;
  final bool estStage;
  final int? maxModulesParEtudiant;

  Formation({
    required this.id,
    required this.titre,
    required this.description,
    required this.modules,
    this.modulesBonus = const [],
    this.imageUrl,
    this.imageFormat,
    required this.formateurIds,
    required this.prix,
    this.prixEnLigne,
    required this.type,
    required this.status,
    required this.dureeSemaines,
    this.dureeHeures,
    required this.horaires,
    this.dateDebut,
    this.dateFin,
    required this.dateCreation,
    this.capaciteMax,
    this.nombreInscrits = 0,
    this.estStage = false,
    this.maxModulesParEtudiant,
  });

  factory Formation.fromMap(Map<String, dynamic> data, String id) {
    FormationType parseType(String typeStr) {
      if (typeStr.contains('presentielle')) {
        return FormationType.presentielle;
      }
      if (typeStr.contains('mixte')) {
        return FormationType.mixte;
      }
      return FormationType.enligne;
    }

    FormationStatus parseStatus(String statusStr) {
      if (statusStr.contains('enCours')) {
        return FormationStatus.enCours;
      }
      if (statusStr.contains('terminee')) {
        return FormationStatus.terminee;
      }
      return FormationStatus.programmee;
    }

    ImageFormat? parseImageFormat(String? formatStr) {
      if (formatStr == null) return null;
      if (formatStr.contains('carre')) return ImageFormat.carre;
      if (formatStr.contains('vertical')) return ImageFormat.vertical;
      return null;
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Formation(
      id: id,
      titre: data['titre'] ?? '',
      description: data['description'] ?? '',
      modules: List<String>.from(data['modules'] ?? []),
      modulesBonus: List<String>.from(data['modulesBonus'] ?? []),
      imageUrl: data['imageUrl'],
      imageFormat: parseImageFormat(data['imageFormat']),
      formateurIds: List<String>.from(data['formateurIds'] ?? []),
      prix: (data['prix'] ?? 0).toDouble(),
      prixEnLigne: data['prixEnLigne']?.toDouble(),
      type: parseType(data['type']?.toString() ?? 'FormationType.enligne'),
      status: parseStatus(data['status']?.toString() ?? 'FormationStatus.programmee'),
      dureeSemaines: data['dureeSemaines'] ?? 0,
      dureeHeures: data['dureeHeures'],
      horaires: (data['horaires'] as List?)
              ?.map((h) => Horaire.fromMap(h as Map<String, dynamic>))
              .toList() ??
          [],
      dateDebut: parseDate(data['dateDebut']),
      dateFin: parseDate(data['dateFin']),
      dateCreation: parseDate(data['dateCreation']) ?? DateTime.now(),
      capaciteMax: data['capaciteMax'],
      nombreInscrits: data['nombreInscrits'] ?? 0,
      estStage: data['estStage'] ?? false,
      maxModulesParEtudiant: data['maxModulesParEtudiant'],
    );
  }

  factory Formation.fromFirestore(dynamic doc) {
    if (doc is Map<String, dynamic>) {
      return Formation.fromMap(doc, doc['id'] ?? '');
    }
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Formation.fromMap(data, doc.id ?? '');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'modules': modules,
      'modulesBonus': modulesBonus,
      'imageUrl': imageUrl,
      'imageFormat': imageFormat?.toString(),
      'formateurIds': formateurIds,
      'prix': prix,
      'prixEnLigne': prixEnLigne,
      'type': type.toString(),
      'status': status.toString(),
      'dureeSemaines': dureeSemaines,
      'dureeHeures': dureeHeures,
      'horaires': horaires.map((h) => h.toMap()).toList(),
      'dateDebut': dateDebut?.toIso8601String(),
      'dateFin': dateFin?.toIso8601String(),
      'dateCreation': dateCreation.toIso8601String(),
      'capaciteMax': capaciteMax,
      'nombreInscrits': nombreInscrits,
      'estStage': estStage,
      'maxModulesParEtudiant': maxModulesParEtudiant,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Formation && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
