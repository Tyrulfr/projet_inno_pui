---
layout: default
title: Accueil
---

<section class="hero">
  <h1>OSER POUR<br><span style="color: var(--orange);">INNOVER</span></h1>
  <p class="subtitle">Plateforme collaborative d'ingénierie pédagogique et de formation.</p>

  <div class="cards-container">
    <div class="card" onclick="window.location.href='{% link dashboard.md %}'">
      <i class="fa-solid fa-pen-ruler icon concepteur-icon"></i>
      <h3>Concepteur</h3>
      <p>Gestion de projet, Backstage et Outils.</p>
      <span class="btn btn-primary">Gérer le projet</span>
    </div>

    <div class="card" onclick="window.location.href='{% link pages/apprenant/cours/portal.md %}'">
      <i class="fa-solid fa-rocket icon user-icon"></i>
      <h3>Apprenant</h3>
      <p>Modules interactifs et parcours gamifié.</p>
      <span class="btn btn-outline">Commencer</span>
    </div>
  </div>
</section>

