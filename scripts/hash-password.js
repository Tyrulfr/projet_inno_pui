/**
 * Hash un mot de passe en bcrypt (même algo que api/auth/login.js).
 * Appelé par creer-apprenant-direct.ps1 pour enregistrer le mdp dans Directus sans déployer l'API.
 * Usage : node scripts/hash-password.js "le_mot_de_passe"
 * Sortie : le hash sur stdout (une ligne).
 */
var bcrypt = require('bcryptjs');
var password = process.argv[2];
if (!password) {
  process.stderr.write('Usage: node hash-password.js "mot_de_passe"\n');
  process.exit(1);
}
var hash = bcrypt.hashSync(password, 10);
console.log(hash);
