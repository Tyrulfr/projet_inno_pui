# Backend dédié : ce que vous gardez et ce qui est automatisé

Court résumé pour clarifier ce que fait le backend dédié par rapport à Directus et à Moodle.

---

## 1. Vous gardez bien la base Directus

- La **base de données** (PostgreSQL ou MySQL sur Scaleway) reste **la même** que celle que Directus utilise.
- **Directus** continue à s’y connecter : vous ouvrez Directus pour **voir et éditer** les données (apprenants, progression) comme aujourd’hui.
- Le **backend dédié** est un petit programme qui se connecte **à cette même base** pour :
  - créer ou retrouver le profil d’un apprenant,
  - enregistrer l’avancement (grains complétés),
  - plus tard envoyer des infos vers Moodle.

Donc : **une seule base**, utilisée à la fois par **Directus** (interface admin) et par le **backend** (automatisation pour les apprenants et Moodle). Rien ne remplace Directus ; il reste votre outil pour manipuler les données.

---

## 2. Automatisation et centralisation

Oui : avec un backend dédié, la logique est **automatisée et centralisée** dans un seul programme :

- **Réception** : quand un apprenant ouvre le mini-site depuis Moodle (LTI ou iframe), Moodle envoie son identifiant au backend.
- **Profil** : le backend crée ou récupère son profil dans la base (sur Scaleway) à partir de cet id. Pas de formulaire d’inscription à remplir côté mini-site.
- **Progression** : le backend enregistre les grains complétés pour cet apprenant.
- **Remontée** : le backend peut envoyer à Moodle la complétion ou la note pour cet apprenant.

Tout cela est géré au **même endroit** (le backend), sans que vous ayez à cliquer dans Directus pour chaque nouvel apprenant.

---

## 3. « Inscription » : qui fait quoi ?

Il faut distinguer deux choses :

| Où | Qui fait quoi |
|----|----------------|
| **Dans Moodle** | L’**inscription** au cours / à la formation se fait **dans Moodle** : l’apprenant est inscrit au cours Moodle (par un formateur, par auto-inscription, etc.). C’est Moodle qui gère la liste des inscrits. |
| **Dans votre mini-site (Scaleway)** | Dès qu’un apprenant **inscrit dans Moodle** ouvre votre mini-site, le backend **reçoit son identifiant Moodle**, crée **automatiquement** un profil pour lui dans votre base (s’il n’existe pas encore) et enregistre ensuite toute sa progression. Il n’y a pas de « formulaire d’inscription » à remplir sur le mini-site : le profil est créé à partir des infos envoyées par Moodle. |

En résumé :
- **Inscription à la formation** = toujours dans **Moodle** (c’est Moodle qui sait qui suit la formation).
- **Création du profil** dans votre base (Scaleway) = **automatique** : le backend récupère les infos envoyées par Moodle (id, éventuellement nom, email selon LTI) et crée ou retrouve le profil. Vous n’avez pas à « inscrire » les gens à la main dans Directus pour qu’ils aient un profil.

---

## 4. Communication avec Moodle pour chaque apprenant

Oui : pour **chaque** apprenant Moodle qui suit votre formation, le backend peut :

- **À l’entrée** : recevoir l’identifiant (et éventuellement nom, email) envoyé par Moodle quand l’apprenant ouvre le mini-site, et créer ou récupérer son profil.
- **Pendant / à la fin** : envoyer vers Moodle les données de progression ou la note (complétion du module, score, etc.) pour que Moodle affiche l’avancement ou la note dans le cours.

Donc : **un flux par apprenant** : Moodle envoie qui il est → le backend gère le profil et la progression → le backend renvoie à Moodle ce qu’il faut pour le suivi.

---

## 5. En une phrase

**Avec un backend dédié, vous gardez votre base Directus ; le backend utilise la même base, automatise la création du profil à partir de l’identifiant Moodle et centralise la réception des infos (Moodle → Scaleway) et l’envoi des données (Scaleway → Moodle) pour chaque apprenant qui suit votre formation.** L’inscription au cours reste dans Moodle ; la « création du profil » dans votre système est automatique dès que l’apprenant ouvre le mini-site.
