<div align="center">

# Find Me 🛍️

<img src="find_me_pfe_front/assets/images/find_me.PNG" alt="FINDME" width="240"/>

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-18%2B-339933?logo=node.js&logoColor=white)
![Express](https://img.shields.io/badge/Express-4-000000?logo=express&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-Mongoose-47A248?logo=mongodb&logoColor=white)
![IA](https://img.shields.io/badge/IA-LLM%20%2B%20MongoDB-DF9A4F)
![Tests](https://img.shields.io/badge/tests-48%20passing-3F7D4E)

<img src="docs/screenshots/00-overview.png" alt="Aperçu de Find Me" width="100%"/>

</div>

**Find Me** est une application mobile e-commerce développée dans le cadre d'un
stage de fin d'études (Licence Génie Logiciel & SI, ESSTHS Sousse) au sein de la
société **Dot-IT**. Elle centralise la recherche de produits en boutiques
physiques pour offrir aux consommateurs une expérience d'achat fluide, rapide
et intuitive.

L'application a ensuite été enrichie d'une **couche d'intelligence artificielle** : un styliste IA conversationnel, des recommandations personnalisées et explicables, et une géolocalisation des articles en boutique (voir [Nouveautés : Find Me IA](#-nouveautés--find-me-ia)).

---

## 🎬 Démo

<div align="center">
  <img src="docs/demo/findme_demo.gif" alt="Démo de l'application FINDME" width="380"/>
  <br/>
  <sub>Démo complète en 73 s : <a href="docs/demo/findme_demo.mp4">findme_demo.mp4</a></sub>
</div>

---

## 🎯 Objectifs principaux

- **Recherche intelligente** : par nom, catégorie, scan de code-barres/QR
  code, ou reconnaissance vocale, avec filtres (prix, marque, couleur, taille,
  région) et tri (prix, rating, nom).
- **Assistance instantanée** : chatbot intégré pour guider l'utilisateur
  dans sa recherche.
- **Géolocalisation** : localisation des points de vente les plus proches
  via OpenStreetMap.
- **Personnalisation** : liste de favoris, évaluation des produits,
  notifications de promotions.
- **Back-office admin** : gestion des produits, marques, catégories,
  boutiques et promotions.

---

## ✨ Nouveautés : Find Me IA

### Le besoin métier
Acheter un vêtement précis reste compliqué : les catalogues des enseignes sont éparpillés, on ne sait pas **quelle boutique proche** a l'article, et une recherche classique ne comprend pas une demande comme *« une robe chic pour un mariage, moins de 150 TND, près de Sousse »*.

### Ce que l'IA apporte

| Pour le client | Pour les enseignes |
|---|---|
| Une demande en langage naturel → les bons articles | Visibilité de tout le catalogue, boutique par boutique |
| Achat dans le budget, sans surprise | Trafic vers les boutiques physiques (« Get Directions ») |
| Conseils de style personnalisés (Style DNA) | Données de tendance : recherches, vues, favoris |
| Alertes de baisse de prix | Promotions mises en avant |

> **Principe de confiance :** le LLM ne décide jamais quels produits existent. Il comprend la demande et rédige la réponse ; **produits, prix, boutiques, distances et disponibilités viennent toujours de MongoDB**. Une réponse qui cite un prix inexistant est rejetée automatiquement.

### Nouvelles fonctionnalités

| | Fonctionnalité | Ce que fait l'utilisateur |
|---|---|---|
| 🤖 | **Styliste IA** (remplace l'ancien chatbot à intentions fixes) | Décrit son besoin en français, anglais ou darija, affine (« moins cher », « taille M », « plus chic »), reçoit des cartes produits, une tenue complète et les boutiques proches |
| 🏠 | **Accueil personnalisé** | For You, Trending, New in, petits budgets, promos — classés selon son profil |
| 🔎 | **Discover** | Catalogue filtré avec tri « Best match » (% de compatibilité expliqué) |
| 🧬 | **Style DNA & Style Quiz** | Découvre son profil de style (ex. *Easygoing Casual*) calculé à partir de ses goûts |
| 👗 | **Complete the Look & garde-robe** | Obtient une tenue harmonisée autour d'un article et l'enregistre |
| 📍 | **Géolocalisation des articles** | Voit sur une carte les boutiques qui vendent l'article (disponibilité vérifiée ou à confirmer), la distance et l'itinéraire ; GPS ou ville choisie |
| 📷 | **Recherche par photo** | Prend en photo un vêtement pour trouver des articles similaires |
| 🔔 | **Alertes de prix** | Est prévenu quand un article suivi baisse de prix |
| 👤 | **Profil** | Modifie nom, photo et mot de passe ; mode sombre |

---

## 📱 Captures d'écran

| Splash | Onboarding | Connexion | Accueil |
|:-:|:-:|:-:|:-:|
| <img src="docs/screenshots/01-splash.png" width="200"/> | <img src="docs/screenshots/02-onboarding.png" width="200"/> | <img src="docs/screenshots/03-login.png" width="200"/> | <img src="docs/screenshots/04-home.png" width="200"/> |
| **For You** | **Discover** | **Garde-robe** | **Wishlist** |
| <img src="docs/screenshots/05-for-you.png" width="200"/> | <img src="docs/screenshots/06-discover.png" width="200"/> | <img src="docs/screenshots/07-wardrobe.png" width="200"/> | <img src="docs/screenshots/08-wishlist.png" width="200"/> |
| **Profil** | **Edit Profile** | **Boutiques proches** | **Choix de la ville** |
| <img src="docs/screenshots/09-profile.png" width="200"/> | <img src="docs/screenshots/10-edit-profile.png" width="200"/> | <img src="docs/screenshots/11-nearby-stores.png" width="200"/> | <img src="docs/screenshots/12-choose-location.png" width="200"/> |
| **Notifications** | **Mode sombre** | **Recherche vocale** | **Recherche par photo** |
| <img src="docs/screenshots/13-notifications.png" width="200"/> | <img src="docs/screenshots/14-dark-mode.png" width="200"/> | <img src="docs/screenshots/15-voice-search.png" width="200"/> | <img src="docs/screenshots/18-find-similar.png" width="200"/> |
| **Styliste IA** | **Résultats & chips** | **Complete the look** | |
| <img src="docs/screenshots/16-ai-stylist.png" width="200"/> | <img src="docs/screenshots/17-stylist-results.png" width="200"/> | <img src="docs/screenshots/19-complete-look.png" width="200"/> | |

---

## 🛠️ Stack technique

| Couche | Technologie |
|---|---|
| Frontend mobile | Flutter (Dart) — `flutter_map`, `geolocator`, `speech_to_text`, `image_picker`, `flutter_animate`, `shimmer`, `google_fonts` |
| Backend | Node.js / Express.js — JWT, bcrypt, Multer, Nodemailer (OTP) |
| Base de données | MongoDB (Mongoose) |
| Stockage médias | Cloudinary |
| Cartographie | OpenStreetMap (tuiles) · OSRM (itinéraires) |
| Intelligence artificielle | LLM via API compatible OpenAI ou Anthropic (Groq `llama-3.3-70b-versatile` par défaut), modèle vision pour la recherche photo, repli par règles sans clé |
| Tests | `node:test` — 48 tests sans base ni clé API |

## 🏗️ Architecture

- Architecture **3-tiers** (Présentation / Métier / Données)
- Modèle **MVC** côté application
- API **REST** pour la communication client-serveur
- Méthodologie **Agile Scrum** (6 sprints)
- **Services IA** côté métier : compréhension (LLM), recommandation, géolocalisation

```mermaid
flowchart LR
  subgraph App["📱 Flutter (Android · iOS · Web)"]
    UI[Écrans UI] --> API[FindMeApi / ApiClient]
    GEO[LocationService<br/>GPS ou ville]
  end
  API -- REST + JWT --> EX[Express API]
  subgraph Back["🖥️ Node.js / Express"]
    EX --> CHAT[chatService]
    EX --> RECO[recommendationService<br/>score explicable]
    CHAT --> NLU[Compréhension<br/>LLM → JSON · repli règles]
    CHAT --> RECO
    RECO --> GEOS[geoService<br/>Haversine · disponibilité]
  end
  NLU <--> LLM[(LLM<br/>Groq · OpenAI · Gemini · Claude)]
  RECO <--> DB[(MongoDB)]
  EX --> CDN[(Cloudinary<br/>images)]
  App -. tuiles / itinéraire .-> OSM[(OpenStreetMap · OSRM)]
```

**Parcours d'une demande au styliste :**
`message → LLM (extraction des critères) → validation contre le vocabulaire réel → fusion avec le contexte de la conversation → recherche MongoDB → score & diversification → disponibilité en boutique + distance → réponse rédigée par le LLM → garde-fou prix → cartes produits, carte des boutiques, réponses rapides`

### Score de recommandation (explicable)

```
Score = 0.30·Catégorie + 0.20·Style/couleur + 0.15·Budget + 0.15·Préférences + 0.10·Note + 0.10·Tendance
```

Chaque produit affiche son **% de compatibilité** et les raisons (« dans ton budget », « ta couleur préférée »…).

---

### Organisation du code Flutter

```
find_me_pfe_front/lib
├── core/api_config.dart      # URL du serveur (un seul endroit)
├── theme/app_theme.dart      # palette crème / caramel / brun, typographies
├── data/                     # ApiClient (JWT, multipart), FindMeApi, modèles
├── ui/
│   ├── home/  discover/  favorites/  outfits/  alerts/  search/
│   ├── stylist/              # chatbot IA interactif
│   ├── geo/                  # carte unique, cartes boutiques, position GPS/ville
│   ├── profile/              # My Profile, Edit Profile, Style DNA, quiz
│   └── widgets/              # composants réutilisables (ProductCard…)
├── Auth/  Core/  Services/   # pages et services historiques (login, scanner…)
└── main.dart · main_screen.dart
```

---

## 🔌 API principale

Base URL : `http://localhost:5000` · authentification `Authorization: Bearer <token>`

| Domaine | Endpoints |
|---|---|
| **Auth & profil** | `POST /auth/signup` · `POST /auth/otp` · `POST /auth/login` · `POST /auth/forgetPassword` · `GET /auth/me` · `PUT /auth/updateProfile` · `PUT /auth/changePassword` · `GET /auth/getFavorites` · `PUT /auth/addToFavorites` |
| **Styliste IA** | `POST /chatbot` `{message, sessionId?, location?, action?}` · `GET /chatbot/sessions/:id` · `PATCH /chatbot/sessions/:id/criteria` · `DELETE /chatbot/sessions/:id` |
| **Recommandations** | `GET /recommendations/home` · `/for-you` · `/trending` · `/budget?max=` · `/discover` · `/similar/:id` · `/complete-look/:id` · `/explain/:id` · `POST /recommendations/feedback` |
| **Géolocalisation** | `GET /recommendations/stores?lat=&lng=` · `/nearby-products?lat=&lng=&radiusKm=&query=` · `/nearby-shops/:id` · `/places` |
| **Recherche** | `POST /search/visual` (photo) · `POST /products/searchProductsWithFilter` · `GET /products/getProductByBarCode` |
| **Personnalisation** | `GET /preferences/style-dna` · `PUT /preferences` · `POST /interactions` |
| **Garde-robe & alertes** | `GET/POST /outfits` · `DELETE /outfits/:id` · `GET/POST /alerts` · `PUT /alerts/seen` · `DELETE /alerts/:id` |
| **Catalogue** | `/products` · `/shops` · `/brands` · `/categories` · `/discounts` · `/notifications` |

<details>
<summary>Exemple : « le premier près de moi »</summary>

```http
POST /chatbot
{
  "message": "the first one near me",
  "sessionId": "…",
  "location": { "lat": 35.8256, "lng": 10.6084, "label": "Sousse", "source": "manual" }
}
```
Réponse (extrait) : `nearby.results[]` (produit + boutiques triées par distance, `verified: true` si la boutique et le produit se référencent mutuellement), `nearby.radiusKm`, `quickReplies: ["Élargir à 50 km", …]`.
</details>

---

## 🚀 Lancer le projet

### Backend
```bash
cd find_me_pfe_back
npm install
cp .env.example .env        # MongoDB, NET_SECRET, Cloudinary, Gmail, LLM_*
npm test                    # 48 tests
npm run dev                 # http://localhost:5000
```

Variables LLM (exemple Groq, gratuit) :
```env
LLM_PROVIDER=openai
LLM_BASE_URL=https://api.groq.com/openai/v1
LLM_API_KEY=your-key
LLM_MODEL=llama-3.3-70b-versatile
```
Sans clé, le styliste fonctionne en mode règles (FR / EN / darija).

### Application Flutter
```bash
cd find_me_pfe_front
flutter pub get
flutter run -d chrome --web-browser-flag="--window-size=412,915"   # Web
flutter run                                                         # Android / iOS




---

<div align="center">
<sub>Stage de fin d'études · Licence Génie Logiciel & SI · ESSTHS Sousse · <b>Dot-IT</b> — enrichi d'une couche IA</sub>
</div>
