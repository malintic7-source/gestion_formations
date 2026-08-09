# 📱 Gestion-Formations

Plateforme de gestion de formations ultra-responsive avec système de rôles avancé.

## 🎯 Caractéristiques

### 🔐 Système de Rôles
- **Admin**: Accès complet - Créer utilisateurs, formations, gérer inscriptions
- **Formateur**: Gérer les étudiants, statistiques, emploi du temps
- **Étudiant**: Consulter formations, s'inscrire, suivre progression

### 📱 Responsive Design
- **Mobile**: Drawer navigation pour une meilleure UX
- **Desktop**: Sidebar permanent + contenu fluide
- Adaptation automatique du layout selon la taille de l'écran

### 🎨 Design
- **Couleurs corporate**: Bleu primaire (#0066CC) + Accent Orange (#FF6B35)
- **Thème clean et pro**: Material Design 3
- **Animations fluides**: Avec animate_do
- **Typographie**: Google Fonts (Poppins)

## 📁 Structure du Projet

```
lib/
├── config/
│   └── theme.dart                 # Thème centralisé
├── Models/
│   ├── user.dart                  # Modèle utilisateur
│   ├── formation.dart             # Modèle formation
│   ├── inscription.dart           # Modèle inscription
│   └── payment.dart               # Modèle paiement
├── Services/
│   ├── auth_provider.dart         # Gestion authentification
│   └── db_services.dart           # Services Firebase
├── Pages/
│   ├── Login/
│   │   ├── welcom_page.dart
│   │   └── sign_in.dart
│   ├── Admin/
│   │   ├── dashboard.dart
│   │   ├── users.dart
│   │   └── formations.dart
│   ├── Formateur/
│   │   └── dashboard.dart
│   ├── Student/
│   │   ├── dashboard.dart
│   │   └── formations.dart
│   ├── Common/
│   │   └── profile.dart
│   ├── INSCRIPTIONS/
│   │   └── formulaire.dart
│   ├── Screens/
│   │   └── notifications.dart
│   └── home_screen.dart           # Écran principal
└── Widgets/
    └── main_layout.dart           # Layout responsive
```

## 🚀 Fonctionnalités par Rôle

### Admin
- 📊 Dashboard avec statistiques
- 👥 Gestion des utilisateurs (créer, modifier, supprimer)
- 📚 Gestion des formations (créer, éditer, publier)
- 👨‍🏫 Gestion des formateurs
- 💳 Suivi des paiements
- 📝 Validation des inscriptions étudiants

### Formateur
- 📊 Dashboard personnel
- 👥 Gestion des étudiants (consulter, contacter)
- 📈 Statistiques des formations
- ⏰ Emploi du temps
- 👤 Profil

### Étudiant
- 📊 Dashboard (progression, formations actives)
- 📚 Consulter formations disponibles
- 📝 Formulaire d'inscription avec paiement
- 📋 Suivi des inscriptions (en attente, acceptée, etc.)
- 👤 Profil
- 📢 Notifications

## 🎓 Flux d'Inscription Étudiant

1. **Accueil**: Étudiant remplit formulaire d'inscription
2. **Infos Personnelles**: Saisit ses données
3. **Paiement**: Choisit méthode de paiement
4. **Confirmation**: Inscription créée, en attente de validation admin
5. **Validation**: Admin valide l'inscription
6. **Accès**: Étudiant peut accéder à son compte

## 🏗️ Architecture

### Authentication
- Firebase Auth intégré
- AuthProvider pour gestion des rôles
- Vérification automatique des permissions

### Database
- Firestore pour stockage
- Modèles fortement typés
- Synchronisation en temps réel

### UI/UX
- Material Design 3
- AppTheme centralisé
- MainLayout réutilisable
- Responsive sur tous les appareils

## 🎨 Palette de Couleurs

| Couleur | Code | Usage |
|---------|------|-------|
| Primary | #0066CC | Boutons, textes importants |
| Dark Primary | #0052A3 | Hover states |
| Accent | #FF6B35 | Highlights, statistiques |
| Success | #00B341 | Confirmations |
| Warning | #FFA500 | Alertes |
| Error | #E53935 | Erreurs |
| Background | #F8F9FA | Fond |
| Surface | #FFFFFF | Cards, formulaires |

## 📝 Notes de Développement

### Pages à Compléter
- [ ] Gestion des Formateurs (Admin)
- [ ] Paiements (Admin)
- [ ] Gestion des Étudiants (Formateur)
- [ ] Statistiques (Formateur)
- [ ] Emploi du Temps (Formateur)
- [ ] Système de notifications

### Intégrations Firebase
- Cloud Firestore
- Firebase Auth
- Firebase Messaging
- Cloud Storage (pour images)

### Prochaines Étapes
1. Implémenter authentification Firebase complète
2. Ajouter validations formulaires
3. Intégrer paiement (Stripe, PayPal)
4. Ajouter système de notifications
5. Tests unitaires et d'intégration
6. Déploiement en production

## 🔒 Sécurité

- Validation des rôles côté client et serveur
- Vérification des permissions avant affichage
- Firestore Security Rules à mettre en place
- Hashage des mots de passe (Firebase Auth)

## 📞 Support

Pour toute question ou problème, consulter la documentation Firebase officielle.
