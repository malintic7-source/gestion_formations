import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_formations/Models/user.dart';
import 'package:gestion_formations/Pages/Admin/inscriptions.dart';

void main() {
  group('inscription fallback helpers', () {
    test('uses inscription data when the user document is missing', () {
      final result = resolveInscriptionUserData(null, {
        'prenom': 'Aminata',
        'nom': 'Diallo',
        'email': 'aminata@example.com',
        'telephone': '770000000',
      });

      expect(result['prenom'], 'Aminata');
      expect(result['nom'], 'Diallo');
      expect(result['email'], 'aminata@example.com');
      expect(result['telephone'], '770000000');
    });

    test('prefers the user document when it is available', () {
      final result = resolveInscriptionUserData({
        'prenom': 'Jean',
        'nom': 'Dupont',
        'email': 'jean@example.com',
        'telephone': '771234567',
      }, {
        'prenom': 'Aminata',
        'nom': 'Diallo',
        'email': 'aminata@example.com',
        'telephone': '770000000',
      });

      expect(result['prenom'], 'Jean');
      expect(result['nom'], 'Dupont');
      expect(result['email'], 'jean@example.com');
      expect(result['telephone'], '771234567');
    });

    test('builds a student profile payload from inscription data', () {
      final result = buildStudentUserDataFromInscription({
        'prenom': 'Aminata',
        'nom': 'Diallo',
        'email': 'aminata@example.com',
        'telephone': '770000000',
      }, 'student_123');

      expect(result['id'], 'student_123');
      expect(result['email'], 'aminata@example.com');
      expect(result['role'], UserRole.etudiant.toString());
      expect(result['estActif'], isTrue);
    });
  });
}
