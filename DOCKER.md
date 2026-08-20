# Docker Documentation

## 🐳 Configuration Docker Mise à Jour

Cette application utilise Docker avec deux services : frontend Flutter et backend Node.js.

### 📋 Structure

```
Frontend (gestion_formations):
- Image: Flutter + nginx:alpine
- Build multi-stage pour compilation complète
- Port: 8080
- Santé: HTTP health check

Backend (gestion_formations_api):
- Image: node:22-alpine
- Production optimisé
- Port: 5001 (interne)
- Santé: HTTP health check
```

### 🚀 Commandes Utiles

#### Démarrer l'application
```bash
docker-compose up -d
```

Pour exposer l'application avec ngrok, ajoutez votre jeton dans `.env`, puis
démarrez le service dédié :

```bash
docker compose up -d ngrok
```

Le tunnel cible `http://host.docker.internal:8080`, ce qui évite l'erreur de
résolution `gestion_formations_app` lorsque ngrok est lancé dans un conteneur.

#### Arrêter l'application
```bash
docker-compose down
```

#### Voir les logs
```bash
# Tous les services
docker-compose logs -f

# Frontend uniquement
docker-compose logs -f gestion_formations

# Backend uniquement
docker-compose logs -f api
```

#### Reconstruire les images
```bash
docker-compose build --no-cache
```

#### Accéder à l'application
- Frontend: http://localhost:8080
- API: http://localhost:8080/api (via frontend proxy)

### 🔧 Fichiers Configurés

#### Dockerfile (Frontend)
- Multi-stage build (builder + runtime)
- Compile Flutter automatiquement
- Sert via nginx:alpine
- Health check intégré

#### Dockerfile.fast (Frontend)
- Identique au Dockerfile standard
- Optimisé pour développement rapide

#### server/Dockerfile (Backend)
- Node.js 22 Alpine
- Utilisateur non-root pour sécurité
- npm ci pour reproductibilité
- Health check intégré

#### .dockerignore
- Exclut les fichiers inutiles
- Réduit la taille des images
- Accélère les builds

#### docker-compose.yml
- Version 3.9
- Network bridge partagé
- Variables d'environnement
- Health checks configurés
- Restart policies

### 📊 Améliorations Apportées

✅ Multi-stage build pour optimisation  
✅ Health checks sur tous les services  
✅ Utilisateur non-root pour sécurité  
✅ Network dédié pour communication  
✅ .dockerignore pour réduction d'image  
✅ npm ci pour reproducibilité  
✅ Variables d'environnement configurées  
✅ Gestion des permissions correcte  

### 🔐 Sécurité

- Utilisateur `node` non-root (backend)
- Images alpine légères
- Pas de secrets en clair
- Production optimisé

### 📈 Performance

- Multi-stage build réduit la taille
- Alpine base minimise les dépendances
- .dockerignore accélère les builds
- Health checks détectent rapidement les problèmes

### ⚠️ Prérequis

- Docker & Docker Compose installés
- Suffisant d'espace disque (~3-5GB pendant le build)
- Permissions Docker correctes

### 🛠️ Troubleshooting

**Container ne démarre pas**
```bash
docker-compose logs -f gestion_formations
```

**Port déjà utilisé**
```bash
# Changer le port dans docker-compose.yml
ports:
  - "9090:80"  # Changez 8080 en 9090 par exemple
```

**Cache Docker obsolète**
```bash
docker-compose build --no-cache
```

**Réinitialiser complètement**
```bash
docker-compose down -v
docker system prune -a
docker-compose up -d
```
