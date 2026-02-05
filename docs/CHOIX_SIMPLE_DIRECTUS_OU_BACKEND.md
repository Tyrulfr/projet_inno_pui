# Quelle solution est la plus simple ? Directus API ou backend dédié ?

Ce document explique **en termes simples** la différence entre les deux options, et ce que ça change pour les échanges avec Moodle (descente des données vers Scaleway, remontée vers Moodle).

---

## 1. C’est quoi une « API » ?

En pratique, une **API** c’est une **porte d’entrée** que quelqu’un (un programme, un site) ouvre pour que d’autres puissent **demander des infos** ou **envoyer des infos** de façon standard.

- **Demander** : « Donne-moi la liste des grains complétés pour l’apprenant X » → l’API répond avec les données.
- **Envoyer** : « Enregistre que l’apprenant X a complété le grain 8 » → l’API enregistre ça en base.

Vos pages HTML (le « front ») ont besoin de ça : **demander** l’avancement et **envoyer** quand un grain est terminé. Qui répond à ces demandes ? Soit **Directus** (son API intégrée), soit **votre propre petit programme** (backend dédié).

---

## 2. Directus API : c’est quoi ?

**Directus** est déjà installé sur votre serveur et branché à votre base de données. En plus de l’interface où vous cliquez pour voir/éditer les données, Directus **expose une API** toute faite sur les tables (collections) de cette base.

- Vous créez dans Directus les tables (ou collections) : par ex. **Apprenants**, **Progress**.
- Directus génère automatiquement des URLs du type :  
  `https://votre-directus.fr/items/apprenants`, `https://votre-directus.fr/items/progress`.
- Votre **mini-site** (les pages HTML + un peu de JavaScript) appelle ces URLs pour **lire** ou **écrire** des lignes (ex. « ajouter une ligne dans Progress »).

**En résumé** : pas de programme à écrire côté serveur pour « exposer une API ». Directus fait déjà le lien entre « requête HTTP » et « base de données ». Vous configurez les **droits** (qui peut lire/écrire quoi) dans Directus.

---

## 3. Backend dédié : c’est quoi ?

Un **backend dédié** = un **petit programme à vous** (par ex. en Node.js avec Express) qui tourne sur le serveur et qui :

- se connecte **à la même base de données** que Directus (celle sur Scaleway) ;
- expose **vos propres URLs** (routes), par ex. `GET /api/progress`, `POST /api/progress` ;
- contient **toute la logique** dans du code : « si on reçoit un identifiant Moodle, créer ou récupérer le profil », « enregistrer ce grain comme complété », etc.

Directus reste là pour **vous** (admin) : vous ouvrez Directus pour voir ou modifier les données. Mais c’est **votre backend** que le mini-site appelle, pas l’API Directus.

**En résumé** : vous avez un programme en plus à développer et à faire tourner, mais vous contrôlez exactement ce qu’il fait (création de profil, règles métier, préparation des données pour Moodle, etc.).

---

## 4. Pourquoi choisir l’une ou l’autre ?

| | **API Directus** | **Backend dédié** |
|---|------------------|-------------------|
| **Simplicité technique** | Moins de pièces : pas de serveur d’API à coder ni à déployer. Vous utilisez ce que Directus offre déjà. | Une pièce en plus : il faut écrire et héberger le backend. |
| **Qui fait la logique ?** | La logique doit être soit dans le **front** (JavaScript), soit limitée à ce que Directus permet (règles, permissions). Créer un « profil » à partir d’un id Moodle peut demander des astuces (ex. appeler l’API pour « créer si n’existe pas » depuis le front). | Toute la logique est dans **votre code** : « reçois l’id Moodle → crée ou récupère le profil → renvoie l’avancement ». Plus clair si vous aimez tout centraliser. |
| **Remontée vers Moodle** | Le **front** ou un **script** doit appeler Moodle (ou LTI) pour envoyer la note/complétion. Directus ne parle pas à Moodle ; il ne fait que stocker les données. | Le **backend** peut appeler Moodle (LTI Outcomes, services web) au moment où vous le décidez (ex. quand un module est terminé). Tout au même endroit. |
| **Descente depuis Moodle** | Moodle envoie l’identifiant (LTI ou iframe). Le **front** reçoit cet id et appelle l’API Directus pour créer/lire le profil et l’avancement. Possible, mais il faut bien gérer « créer le profil à la première visite » (ex. une requête « create if not exists » ou équivalent). | Le **backend** reçoit l’id (via LTI ou token). Il crée ou récupère le profil en base, renvoie un token ou une session au front. Le front n’a pas à savoir « comment » le profil est créé. |

**En très court** :  
- **Directus API** = plus simple en nombre de composants (pas de backend à maintenir), mais la logique « profil + Moodle » est à gérer dans le front ou via des contournements.  
- **Backend dédié** = un composant de plus, mais **descente** (création de profil à partir de l’id Moodle) et **remontée** (envoi vers Moodle) peuvent être centralisées dans un seul programme, ce qui peut être plus simple à raisonner.

---

## 5. Descente des données : Moodle → serveur Scaleway (identifiant, profil)

**Ce que vous imaginez est bon** : l’apprenant est inscrit dans Moodle ; quand il ouvre le mini-site (depuis Moodle, via LTI ou iframe), **Moodle envoie son identifiant** (id utilisateur Moodle) au mini-site. Ce flux, c’est la **descente**.

- **Où ça se passe ?**  
  - Soit la **page du mini-site** reçoit l’id (dans l’URL ou via un formulaire LTI en POST).  
  - Soit un **backend** reçoit le lancement LTI (avec l’id) et renvoie la page au navigateur.

- **Création du profil sur Scaleway** :  
  - **Avec Directus API** : le front (ou un petit script) appelle l’API Directus pour « créer un apprenant avec cet id Moodle s’il n’existe pas », puis lit/écrit l’avancement. La base est sur Scaleway ; Directus y est connecté, donc le « profil » est bien une ligne en base sur Scaleway.  
  - **Avec backend dédié** : le backend reçoit l’id Moodle, crée ou récupère la ligne en base (même base Scaleway, même table), et renvoie au front ce qu’il faut (ex. token, avancement). Le profil est toujours créé sur la base Scaleway ; c’est juste le **programme** qui fait la création qui change (Directus vs votre backend).

Donc dans les deux cas, **l’identifiant Moodle sert à créer/trouver le profil sur le serveur Scaleway** (dans la BDD que Directus utilise). La différence est **qui** fait l’étape « créer si nécessaire » : le front en parlant à l’API Directus, ou le backend dédié.

---

## 6. Remontée des données : serveur Scaleway → Moodle (avancement, note)

Là, on envoie **vers Moodle** des infos (complétion, note, etc.) pour que Moodle affiche la progression ou la note dans le cours.

- **Avec Directus API** : Directus **ne contacte pas Moodle**. C’est soit le **front** (JavaScript) qui appelle l’API Moodle (si vous exposez un service web ou une URL), soit un **petit script/cron** qui lit dans Directus (ou la base) et envoie vers Moodle. Donc la remontée est à construire en plus, mais possible.  
- **Avec backend dédié** : le **même backend** qui gère profils et progression peut aussi appeler Moodle (LTI Outcomes ou services web) quand un module est terminé ou quand vous le décidez. Tout est au même endroit.

Donc : **remontée possible dans les deux cas** ; avec un backend dédié, elle est souvent plus simple à intégrer (tout dans un seul programme).

---

## 7. Quelle solution est « la plus simple » pour vous ?

- **Vous voulez le moins de code et le moins de serveurs à gérer**  
  → Partir sur **l’API Directus** : pas de backend dédié. Vous créez les collections dans Directus, vous écrivez un peu de JavaScript dans vos pages pour appeler l’API Directus (lire/écrire l’avancement, et si possible « créer le profil » à la première visite). La descente (id Moodle → profil) se fait depuis le front ; la remontée (vers Moodle) sera à ajouter (front ou petit script).

- **Vous voulez que toute la logique (profil, progression, Moodle) soit au même endroit et que ce soit facile à faire évoluer**  
  → **Backend dédié** : un seul programme qui reçoit l’id Moodle, crée le profil sur Scaleway, enregistre la progression, et plus tard peut envoyer les données à Moodle. Un peu plus de mise en place au début, mais ensuite les échanges avec Moodle (descente et remontée) sont centralisés.

En résumé :  
- **Directus API** = plus simple en « nombre de briques », logique un peu plus éclatée (front + éventuellement script pour Moodle).  
- **Backend dédié** = une brique en plus (votre API), mais **descente** (id Moodle → profil sur Scaleway) et **remontée** (Scaleway → Moodle) plus faciles à gérer et à expliquer dans un seul schéma.

Si vous me dites si vous préférez « le moins de composants possible » ou « tout au même endroit pour Moodle », on peut détailler la solution étape par étape (ex. « avec Directus uniquement, voilà les 3 étapes » ou « avec un petit backend, voilà les 3 étapes »).
