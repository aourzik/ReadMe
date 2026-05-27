# ReadMe 📚

Application mobile de bibliothèque personnelle & sociale.

**Stack :**
- **Front** : Flutter (iOS / Android)
- **Back** : Bun.js + ElysiaJS
- **BDD** : PostgreSQL via Prisma
- **Auth** : JWT (bcrypt)
- **Covers** : Google Books API

---

## Structure

```
readme_app/
├── front/          → App Flutter
│   ├── lib/
│   │   ├── core/
│   │   │   ├── models/         # Book, User, Loan
│   │   │   ├── services/       # ApiService, GoogleBooksService
│   │   │   ├── theme/          # AppTheme, AppColors, AppText
│   │   │   └── widgets/        # BookCard, BookCover, MainShell…
│   │   ├── features/
│   │   │   ├── auth/           # Welcome, Login, Register
│   │   │   ├── onboarding/     # 3 étapes
│   │   │   ├── library/        # Bibliothèque (liste + grille)
│   │   │   ├── book_detail/    # Fiche livre + modal de prêt
│   │   │   ├── add_book/       # Recherche Google Books
│   │   │   ├── social/         # Amis + biblio d'un ami
│   │   │   ├── loans/          # Carnet des prêts
│   │   │   └── profile/        # Profil + stats
│   │   └── main.dart
│   ├── assets/
│   │   ├── fonts/              # Cormorant Garamond (4 fichiers .ttf)
│   │   └── images/             # logo_readme.png
│   └── pubspec.yaml
├── back/           → API Bun.js + ElysiaJS
│   ├── src/
│   │   ├── routes/             # auth, books, loans, friends, users
│   │   ├── middleware/         # JWT auth
│   │   └── utils/              # prisma client, seed
│   ├── prisma/schema.prisma
│   ├── package.json
│   ├── Dockerfile
│   └── .env.example
└── docker-compose.yml
```

---

## Lancer le projet

### 1. Backend

```bash
cd back
cp .env.example .env
# Édite DATABASE_URL et JWT_SECRET dans .env

# Avec Docker (recommandé)
cd ..
docker-compose up -d

# Ou manuellement (nécessite PostgreSQL local)
cd back
bun install
bunx prisma db push
bun run db:seed      # données de test
bun run dev
```

### 2. Frontend Flutter

```bash
cd front

# Installe les fonts (voir assets/fonts/README.md)

flutter pub get
flutter run
```

> Pour cibler iOS : `flutter run -d ios`  
> Pour Android : `flutter run -d android`

### Variables d'environnement backend

| Variable | Description | Exemple |
|---|---|---|
| `DATABASE_URL` | URL PostgreSQL | `postgresql://user:pass@localhost:5432/readme_db` |
| `JWT_SECRET` | Clé secrète JWT (min 32 chars) | `change-me-in-production` |
| `PORT` | Port d'écoute | `3000` |

### Comptes de test (après seed)

| Email | Mot de passe |
|---|---|
| alice@readme.app | password123 |
| bob@readme.app   | password123 |

---

## API endpoints

| Méthode | Route | Description |
|---|---|---|
| POST | `/api/auth/register` | Créer un compte |
| POST | `/api/auth/login` | Se connecter |
| GET | `/api/books` | Mes livres |
| POST | `/api/books` | Ajouter un livre |
| PATCH | `/api/books/:id` | Modifier un livre |
| DELETE | `/api/books/:id` | Supprimer |
| GET | `/api/loans` | Mes prêts |
| POST | `/api/loans` | Créer un prêt |
| PATCH | `/api/loans/:id/return` | Marquer rendu |
| GET | `/api/friends` | Mes amis |
| POST | `/api/friends/request` | Envoyer demande |
| PATCH | `/api/friends/requests/:id/accept` | Accepter |
| GET | `/api/friends/:id/books` | Livres d'un ami |
| GET | `/api/users/me` | Mon profil |
| PATCH | `/api/users/me` | Modifier profil |
| GET | `/api/users/search?q=` | Chercher utilisateurs |

Swagger disponible sur `http://localhost:3000/swagger`

---

## Design system

- **Typo display** : Cormorant Garamond (italic, w500)
- **Typo corps** : Manrope
- **Fond clair** : `#fdf6ed` · Accent : `#f5d3d7` (rose poudré)
- **Fond sombre** : `#0a0d12` · Accent : `#d4a5ab` (rose désaturé)
- **Cards** : rectangle, couverture 1/3 gauche, info 2/3 droite
- **Tab bar** : pill flottant

