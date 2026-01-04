---
layout: default
title: "PROJET INNO | Portail apprenant"
---


<section class="hero">
  <h1>Portail<br><span style="color: var(--orange);">Apprenant</span></h1>
  <p class="subtitle">Accède rapidement à tes ressources.</p>

  <div class="cards-container cards-3">
    <div class="card" onclick="window.location.href='{{ '/pages/apprenant/cours/index.html' | relative_url }}'">
      <i class="fa-solid fa-book-open icon concepteur-icon" aria-hidden="true"></i>
      <h3>Cours</h3>
      <p>Modules, grains, activités et parcours.</p>
      <span class="btn btn-primary">Ouvrir</span>
    </div>

    <div class="card" onclick="window.location.href='{{ '/pages/apprenant/gazette/index.html' | relative_url }}'">
      <i class="fa-solid fa-newspaper icon user-icon" aria-hidden="true"></i>
      <h3>Gazette</h3>
      <p>Actualités, annonces, nouveautés du projet.</p>
      <span class="btn btn-outline">Lire</span>
    </div>

    <div class="card" onclick="window.location.href='{{ '/pages/apprenant/dico/index.html' | relative_url }}'">
      <i class="fa-solid fa-book icon concepteur-icon" aria-hidden="true"></i>
      <h3>Dico</h3>
      <p>Définitions, concepts, glossaire.</p>
      <span class="btn btn-outline">Consulter</span>
    </div>
  </div>
</section>

<footer>&copy; 2026 Projet Inno - V 1.0</footer>



