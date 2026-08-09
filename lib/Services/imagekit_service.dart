import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class ImageKitService {
  // Configuration imgBB
  static const String _apiKey = '1d42a7301463682a06eabf22f69781c0';
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  Future<String?> pickAndUploadImage() async {
    try {
      debugPrint('Début de la sélection d\'image...');
      
      // Sélectionner une image avec withData pour le web
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Important pour le web
      );

      debugPrint('Résultat du picker: $result');

      if (result == null || result.files.isEmpty) {
        debugPrint('Aucun fichier sélectionné ou annulé');
        return null;
      }

      final platformFile = result.files.first;
      debugPrint('PlatformFile: name=${platformFile.name}, size=${platformFile.size}');
      
      // Vérifier si on est sur le web (path est null)
      if (kIsWeb) {
        debugPrint('Cas web détecté (kIsWeb), utilisation des bytes...');
        // Cas web: utiliser les bytes directement
        if (platformFile.bytes != null) {
          debugPrint('Bytes disponibles: ${platformFile.bytes!.length}');
          return await uploadImageFromBytes(platformFile.bytes!);
        }
        debugPrint('Aucun bytes disponibles');
        return null;
      }

      // Cas mobile/desktop: vérifier si path est disponible
      if (platformFile.path == null) {
        debugPrint('Path est null mais pas sur web, erreur inattendue');
        return null;
      }

      // Cas mobile/desktop: utiliser le path
      final filePath = platformFile.path!;
      debugPrint('Chemin du fichier: $filePath');
      
      final file = File(filePath);
      debugPrint('Fichier créé: ${file.path}, existe: ${file.exists()}');

      if (!file.existsSync()) {
        debugPrint('Le fichier n\'existe pas sur le disque');
        throw Exception('Fichier introuvable: $filePath');
      }

      return await uploadImage(file);
    } catch (e) {
      debugPrint('Erreur lors de la sélection de l\'image: $e');
      rethrow;
    }
  }

  Future<String?> uploadImageFromBytes(List<int> bytes) async {
    try {
      debugPrint('=== DÉBUT UPLOAD IMAGE (BYTES) imgBB ===');
      debugPrint('Taille des bytes: ${bytes.length} bytes');
      
      // Convertir les bytes en base64
      final base64Image = base64Encode(bytes);
      debugPrint('Base64 encodé, longueur: ${base64Image.length}');

      // Préparer la requête
      final uri = Uri.parse(_uploadUrl);
      final request = http.MultipartRequest('POST', uri);
      
      request.fields['key'] = _apiKey;
      request.fields['image'] = base64Image;
      
      debugPrint('Envoi de la requête à imgBB...');
      final response = await request.send();
      debugPrint('Statut de la réponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('Upload réussi!');
        final responseBody = await response.stream.bytesToString();
        debugPrint('Réponse brute: $responseBody');
        final jsonData = jsonDecode(responseBody);
        
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final imageUrl = jsonData['data']['url'];
          debugPrint('URL de l\'image: $imageUrl');
          return imageUrl;
        } else {
          throw Exception('Erreur imgBB: ${jsonData['error']['message']}');
        }
      } else {
        debugPrint('Erreur HTTP: ${response.statusCode}');
        final errorBody = await response.stream.bytesToString();
        debugPrint('Corps de l\'erreur: $errorBody');
        throw Exception('Erreur upload imgBB: ${response.statusCode} - $errorBody');
      }
    } catch (e, stackTrace) {
      debugPrint('=== ERREUR UPLOAD (BYTES) imgBB ===');
      debugPrint('Erreur: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('=== FIN ERREUR ===');
      rethrow;
    }
  }

  Future<String?> uploadImage(File file) async {
    try {
      debugPrint('=== DÉBUT UPLOAD IMAGE imgBB ===');
      debugPrint('Fichier: ${file.path}');
      debugPrint('Taille du fichier: ${file.lengthSync()} bytes');
      
      // Lire le fichier et convertir en base64
      final fileBytes = await file.readAsBytes();
      debugPrint('Bytes lus: ${fileBytes.length} bytes');
      
      final base64Image = base64Encode(fileBytes);
      debugPrint('Base64 encodé, longueur: ${base64Image.length}');

      // Préparer la requête
      final uri = Uri.parse(_uploadUrl);
      final request = http.MultipartRequest('POST', uri);
      
      request.fields['key'] = _apiKey;
      request.fields['image'] = base64Image;
      
      debugPrint('Envoi de la requête à imgBB...');
      final response = await request.send();
      debugPrint('Statut de la réponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('Upload réussi!');
        final responseBody = await response.stream.bytesToString();
        debugPrint('Réponse brute: $responseBody');
        final jsonData = jsonDecode(responseBody);
        
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final imageUrl = jsonData['data']['url'];
          debugPrint('URL de l\'image: $imageUrl');
          return imageUrl;
        } else {
          throw Exception('Erreur imgBB: ${jsonData['error']['message']}');
        }
      } else {
        debugPrint('Erreur HTTP: ${response.statusCode}');
        final errorBody = await response.stream.bytesToString();
        debugPrint('Corps de l\'erreur: $errorBody');
        throw Exception('Erreur upload imgBB: ${response.statusCode} - $errorBody');
      }
    } catch (e, stackTrace) {
      debugPrint('=== ERREUR UPLOAD imgBB ===');
      debugPrint('Erreur: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('=== FIN ERREUR ===');
      rethrow;
    }
  }
}
