# Qui fait quoi : site (Git) et Directus

Document pour ne plus se perdre entre le site et Directus.

---

## En une phrase

**L’apprenant utilise uniquement le site (contenu sur Git / GitHub Pages). Le suivi et la progression sont enregistrés dans Directus (vous ne voyez que l’admin côté Directus).**

---

## 1. Où est le contenu (parcours, modules, grains) ?

| Où | Qui | Quoi |
|----|-----|------|
| **Site inno_pui** (Git, ex. GitHub Pages) | **Apprenant** | Pages HTML du parcours : sommaires, capsules (grain1, grain2…), bouton « Terminer ce grain », page Ma progression. C’est là qu’il lit, clique, fait les modules. |
| Directus | **Personne pour le contenu** | Directus ne contient pas les pages du parcours. Il ne sert pas à afficher les modules. |

Donc : **les modules, le parcours, tout ce que l’apprenant voit et manipule = sur le site (Git).** L’apprenant ne va jamais sur Directus.

---

## 2. Où est le suivi / la progression ?

| Où | Qui | Quoi |
|----|-----|------|
| **Directus** (base de données) | **Admin** (vous) | Tables **apprenants** (qui est l’apprenant, origin, external_user_id, email) et **progress** (quels grains il a complétés, à quelle date). C’est le « suivi » et la « progression » à long terme. |
| **Site inno_pui** | **Apprenant** | Aujourd’hui : la progression peut être stockée en **localStorage** (temporaire, sur son navigateur). À faire : que le site **envoie** la progression vers Directus (et la **lit** depuis Directus) quand l’apprenant a un token (lien reçu par l’admin). |

Donc : **le suivi et la progression doivent être inscrits dans Directus.** Aujourd’hui le site peut tout garder en localStorage ; il faut ajouter l’envoi / la lecture avec Directus.

---

## 3. Qui utilise quoi ?

| Acteur | Utilise le site (Git) | Utilise Directus |
|--------|------------------------|------------------|
| **Apprenant** | Oui. Il ouvre le lien (ex. tyrulfr.github.io/.../portal.html?token=...), fait le parcours, clique « Terminer ce grain », voit Ma progression. | Non. Il ne se connecte pas à Directus. |
| **Admin (vous)** | Optionnel (pour tester le parcours). | Oui. Vous créez les apprenants (creer-apprenant-direct.bat → appelle Directus), vous consultez les données (apprenants, progress) dans l’interface Directus. |

---

## 4. Ce qui est fait vs ce qui reste à faire

**Déjà en place**
- Site (Git) : parcours, grains, bouton « Terminer ce grain », indicateurs de progression (barres, ronds), page Ma progression.
- Progression **en localStorage** : quand l’apprenant clique « Terminer ce grain », c’est enregistré dans le navigateur (pas encore dans Directus).
- Directus : collections **apprenants** et **progress** (modèle multi-origine).
- Script admin : créer un apprenant dans Directus et générer un lien (token) vers le **site** (pas vers Directus).

**À faire pour que la progression soit inscrite dans Directus**
- Côté **site** (JavaScript) :  
  - Si l’URL contient `?token=...`, le garder (ex. en sessionStorage) pour la session.  
  - Quand l’apprenant complète un grain : en plus du localStorage, appeler l’API **Directus** (ou un petit backend) pour **créer/mettre à jour** un enregistrement dans **progress** (lié à l’apprenant identifié par le token).  
  - Au chargement des pages (sommaires, Ma progression) : **lire** la progression depuis Directus (pour cet apprenant) et l’afficher (barres, ronds).  
- Ainsi : **l’apprenant manipule toujours les modules sur le site (Git), et le suivi / la progression sont bien inscrits dans Directus.**

---

## 5. Schéma récapitulatif

```
[ Apprenant ]
     |
     |  Ouvre le lien (site + token)
     v
[ Site inno_pui (Git / GitHub Pages) ]
     |  Parcours, grains, "Terminer ce grain", Ma progression
     |
     |  À faire : envoyer / lire la progression (avec le token)
     v
[ Directus ]
     |  apprenants (qui est-il) + progress (quels grains complétés)
     ^
     |  Admin : crée les apprenants, consulte les données
[ Admin (vous) ]
```

Vous avez bien compris : **l’apprenant manipule les modules sur le Git (site), et le suivi / la progression doivent être inscrits dans Directus.** La prochaine étape technique est de faire en sorte que le site envoie et lit cette progression dans Directus quand l’apprenant a un token.
