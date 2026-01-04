"Accueil | PROJET INNO"

<section class="hero">
<h1>Bienvenue sur



<span style="color: var(--orange);">Projet Inno</span></h1>
<p class="subtitle">Sélectionnez votre profil pour accéder à votre espace personnalisé.</p>

<div class="cards-container">

<!-- Carte Profil Apprenant -->
<div class="card" onclick="window.location.href='{{ '/pages/apprenant/portal.html' | relative_url }}'">
  <i class="fa-solid fa-user-graduate icon user-icon"></i>
  <h3>Apprenant</h3>
  <p>Accédez à vos parcours de formation, vos cours et votre gazette personnalisée.</p>
  <span class="btn btn-violet">Entrer</span>
</div>

<!-- Carte Profil Concepteur -->
<div class="card" onclick="window.location.href='{{ '/pages/concepteur/portal.html' | relative_url }}'">
  <i class="fa-solid fa-pen-nib icon concepteur-icon"></i>
  <h3>Concepteur</h3>
  <p>Gérez les contenus, créez de nouveaux grains et suivez les statistiques du projet.</p>
  <span class="btn btn-orange">Entrer</span>
</div>


</div>
</section>

