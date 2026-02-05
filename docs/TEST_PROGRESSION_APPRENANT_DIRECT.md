# Tester la progression pour un apprenant direct (hors Moodle, hors FunMooc)

Ce guide décrit comment vérifier que la progression fonctionne pour un utilisateur **invité** (accès direct au site, sans LMS).

---

## Ce qui a été mis en place

- **Stockage** : la progression est enregistrée dans le **navigateur** (localStorage, clé `projet_inno_progress`). Aucune connexion Directus ni Moodle pour ce test.
- **Enregistrement** : quand l’apprenant clique sur **« Terminer ce grain »** (ou « Terminer la leçon ») sur une page grain, le grain est ajouté à la liste des grains complétés.
- **Affichage** : la barre « Module en cours » et les 6 ronds « Formation » se mettent à jour sur chaque page ; la page **Ma progression** (depuis le portail) affiche le détail.

---

## Étapes pour tester

1. **Ouvrir le site en mode invité**  
   Ouvrez le mini-site (fichiers locaux ou hébergement) **sans** passer par Moodle ni FunMooc.  
   Exemple : `index.html` → **Espace Apprenant·e·s** → **Sensibilisation** (ou directement une page du module 1).

2. **Parcourir quelques grains du module 1**  
   Par exemple : Sommaire Module 1 → Séquence 1 → ouvrir **Capsule 1** (grain1).

3. **Cliquer sur « Terminer la leçon » ou « Terminer ce grain »**  
   Sur grain1 il y a un quiz ; choisir la bonne réponse puis valider, puis cliquer sur le bouton de fin.  
   Sur d’autres grains, le bouton « Terminer ce grain » peut être en bas de page.

4. **Vérifier la progression**  
   - Les **barres et ronds** en haut des pages doivent afficher un pourcentage > 0 (ex. Module en cours M1, et un rond M1 qui se remplit).  
   - Aller au **portail apprenant** → **Ma progression** : vous devez voir la barre « Formation globale » et le détail par module (M1, etc.) refléter les grains complétés.

5. **Tester sur plusieurs grains**  
   Enchaîner plusieurs capsules (grain1, grain2, …), cliquer sur « Terminer » à chaque fois. La progression doit augmenter (nombre de grains complétés, pourcentages).

---

## Points importants

- **Un seul appareil / navigateur** : comme tout est en localStorage, la progression est liée à ce navigateur. Changer de navigateur ou de machine = une autre « session » (progression vide ou différente).
- **Pas de compte** : aucun login ; l’apprenant direct est identifié implicitement par le navigateur.
- **Directus** : pour ce test, **aucune configuration Directus** n’est nécessaire. La synchro avec Directus (apprenants `origin = 'direct'` + progression en base) pourra être ajoutée plus tard (API + identifiant invité type UUID en cookie).

---

## En cas de problème

- **La progression reste à 0 %**  
  Vérifier que les pages grains ont bien le script `progress-indicators.js` chargé et que le `<body>` a les attributs `data-module` et `data-grain` (ex. `data-grain="grain1"`).  
  Vérifier que vous cliquez bien sur le bouton « Terminer ce grain » / « Terminer la leçon » (classe `.btn-validate`).

- **La page Ma progression est vide ou ne se met pas à jour**  
  Recharger la page après avoir terminé au moins un grain. Vérifier que `progress-indicators.js` est chargé sur la page Ma progression.

- **Réinitialiser la progression (test)**  
  Dans la console du navigateur (F12) :  
  `localStorage.removeItem('projet_inno_progress');`  
  puis recharger la page.
