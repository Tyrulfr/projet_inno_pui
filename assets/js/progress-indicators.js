/**
 * Indicateurs de progression : barre du module en cours + 6 ronds (un par module) pour la formation.
 * Lit les grains complétés depuis localStorage (clé: projet_inno_progress).
 * Si un token apprenant (URL ?token=...) et une API sont configurés (window.PROGRESS_API_BASE),
 * la progression est aussi enregistrée et lue depuis Directus via cette API.
 * À inclure sur chaque page avec data-module et data-grain sur <body>.
 */
(function () {
    var STORAGE_KEY = 'projet_inno_progress';
    var STORAGE_KEY_TOKEN = 'projet_inno_apprenant_token';

    var MODULES = [
        { id: 'module1', name: 'M1', grains: ['grain1','grain2','grain3','grain4','grain5','grain6','grain7','grain8','grain9','grain10','grain11','grain12','grain13','grain14','grain15','grain16','grain17','grain18','grain_exp21'] },
        { id: 'module2', name: 'M2', grains: ['sommaire_module2'] },
        { id: 'module3', name: 'M3', grains: ['sommaire_module3','temoignage_silvia'] },
        { id: 'module4', name: 'M4', grains: ['sommaire_module4'] },
        { id: 'module5', name: 'M5', grains: ['sommaire_module5'] },
        { id: 'module6', name: 'M6', grains: ['sommaire_module6'] }
    ];
    /** Grains par séquence (module 1) pour afficher la coche "séquence terminée" */
    var SEQUENCE_GRAINS = [
        ['grain1','grain2','grain3','grain4','grain5'],
        ['grain6','grain7','grain8','grain9','grain10','grain11','grain12','grain13','grain_exp21'],
        ['grain14','grain15','grain16','grain17','grain18']
    ];

    /** Token apprenant (lien direct) : lu depuis l’URL au premier passage, puis localStorage. */
    function getApprenantToken() {
        return localStorage.getItem(STORAGE_KEY_TOKEN) || '';
    }

    function getCompleted() {
        try {
            var raw = localStorage.getItem(STORAGE_KEY);
            return raw ? JSON.parse(raw) : [];
        } catch (e) { return []; }
    }

    function setCompleted(completed) {
        try {
            localStorage.setItem(STORAGE_KEY, JSON.stringify(completed));
        } catch (e) { return; }
    }

    function getModuleProgress(moduleId, completed) {
        var mod = MODULES.find(function (m) { return m.id === moduleId; });
        if (!mod) return 0;
        var done = mod.grains.filter(function (g) { return completed.indexOf(g) !== -1; }).length;
        return mod.grains.length > 0 ? Math.round((done / mod.grains.length) * 100) : 0;
    }

    function getCurrentModule() {
        var body = document.body;
        return (body && body.getAttribute('data-module')) || 'module1';
    }

    function getFormationProgress(completed) {
        var total = 0;
        MODULES.forEach(function (m) { total += m.grains.length; });
        return total > 0 ? Math.round((completed.length / total) * 100) : 0;
    }

    /** Marque un grain comme complété (localStorage + API Directus si token et API configurés). */
    function markGrainCompleted(grainId) {
        if (!grainId) return;
        var completed = getCompleted();
        if (completed.indexOf(grainId) !== -1) return;
        completed.push(grainId);
        setCompleted(completed);
        if (window.progressIndicatorsRefresh) window.progressIndicatorsRefresh();
        var apiBase = window.PROGRESS_API_BASE;
        var token = getApprenantToken();
        if (apiBase && token) {
            var moduleId = getCurrentModule();
            fetch(apiBase.replace(/\/$/, '') + '/api/progress', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ token: token, grain_id: grainId, module_id: moduleId })
            }).catch(function () {});
        }
    }

    /** Marque le grain courant (data-grain sur body) comme complété. */
    window.markCurrentGrainCompleted = function () {
        var body = document.body;
        var grainId = body && body.getAttribute('data-grain');
        if (grainId) markGrainCompleted(grainId);
    };

    /** API pour la page Ma progression : données agrégées (localStorage ou futur Moodle) */
    window.getProgressData = function () {
        var completed = getCompleted();
        var formationPct = getFormationProgress(completed);
        var byModule = {};
        MODULES.forEach(function (m) {
            byModule[m.id] = getModuleProgress(m.id, completed);
        });
        var totalGrains = 0;
        MODULES.forEach(function (m) { totalGrains += m.grains.length; });
        return {
            completed: completed,
            modules: MODULES,
            formationPct: formationPct,
            byModule: byModule,
            totalGrains: totalGrains,
            completedCount: completed.length
        };
    };

    function render() {
        var container = document.getElementById('progress-widget');
        if (!container) return;

        var completed = getCompleted();
        var currentModule = getCurrentModule();
        var modulePct = getModuleProgress(currentModule, completed);
        var modLabel = (MODULES.find(function (m) { return m.id === currentModule; }) || {}).name || currentModule;

        container.innerHTML =
            '<div class="progress-row">' +
            '  <span class="progress-label">Module en cours (' + modLabel + ')</span>' +
            '  <div class="bar-container"><div class="bar-fill" style="width:' + modulePct + '%"></div></div>' +
            '  <span class="bar-pct">' + modulePct + '%</span>' +
            '</div>' +
            '<div class="progress-row progress-row-circles">' +
            '  <span class="progress-label">Formation</span>' +
            '  <div class="modules-circles">' +
            MODULES.map(function (m) {
                var pct = getModuleProgress(m.id, completed);
                var isCurrent = m.id === currentModule;
                return '<div class="module-circle-wrap' + (isCurrent ? ' current' : '') + '" title="' + m.id + ': ' + pct + '%">' +
                    '<div class="module-circle"><div class="module-circle-fill" style="height:' + pct + '%"></div></div>' +
                    '<span class="module-circle-label">' + m.name + '</span></div>';
            }).join('') +
            '  </div>' +
            '</div>';
    }

    /** Affiche une coche sur les grains et séquences complétés (sommaires). */
    function applyCompletedMarks() {
        var completed = getCompleted();
        document.querySelectorAll('.grain-card[id]').forEach(function (card) {
            var id = card.getAttribute('id');
            if (completed.indexOf(id) !== -1) {
                card.classList.add('completed');
                if (!card.querySelector('.grain-card-badge')) {
                    var badge = document.createElement('div');
                    badge.className = 'grain-card-badge';
                    badge.setAttribute('aria-label', 'Terminé');
                    badge.innerHTML = '<i class="fa-solid fa-check"></i>';
                    card.appendChild(badge);
                }
            }
        });
        document.querySelectorAll('.sequence-card').forEach(function (card, index) {
            if (index >= SEQUENCE_GRAINS.length) return;
            var grains = SEQUENCE_GRAINS[index];
            var allDone = grains.every(function (g) { return completed.indexOf(g) !== -1; });
            if (allDone) {
                card.classList.add('completed');
                if (!card.querySelector('.sequence-card-badge')) {
                    var badge = document.createElement('div');
                    badge.className = 'sequence-card-badge';
                    badge.setAttribute('aria-label', 'Séquence terminée');
                    badge.innerHTML = '<i class="fa-solid fa-check"></i>';
                    card.appendChild(badge);
                }
            }
        });
    }

    /** Lit le token dans l’URL (?token=...) et le stocke pour les visites suivantes. */
    function captureTokenFromUrl() {
        try {
            var params = new URLSearchParams(window.location.search);
            var token = params.get('token');
            if (token) {
                localStorage.setItem(STORAGE_KEY_TOKEN, token);
                if (window.history && window.history.replaceState) {
                    params.delete('token');
                    var newSearch = params.toString();
                    var newUrl = window.location.pathname + (newSearch ? '?' + newSearch : '') + window.location.hash;
                    window.history.replaceState({}, '', newUrl);
                }
            }
        } catch (e) {}
    }

    /** Charge la progression depuis l’API (Directus) si token + PROGRESS_API_BASE, puis met à jour l’affichage. */
    function fetchProgressFromApi(done) {
        var apiBase = window.PROGRESS_API_BASE;
        var token = getApprenantToken();
        if (!apiBase || !token) { if (done) done(); return; }
        var url = apiBase.replace(/\/$/, '') + '/api/progress?token=' + encodeURIComponent(token);
        fetch(url)
            .then(function (r) { return r.ok ? r.json() : null; })
            .then(function (data) {
                if (data && Array.isArray(data.completed)) setCompleted(data.completed);
            })
            .catch(function () {})
            .then(function () { if (done) done(); });
    }

    function init() {
        captureTokenFromUrl();
        fetchProgressFromApi(function () {
            render();
            applyCompletedMarks();
        });
        window.addEventListener('storage', function () { render(); applyCompletedMarks(); });
        window.progressIndicatorsRefresh = function () { render(); applyCompletedMarks(); };
        window.getApprenantToken = getApprenantToken;
        // En mode invité/direct : au clic sur "Terminer ce grain", marquer le grain courant comme complété
        var grainId = document.body && document.body.getAttribute('data-grain');
        if (grainId) {
            document.querySelectorAll('.btn-validate').forEach(function (btn) {
                btn.addEventListener('click', function () {
                    setTimeout(function () { window.markCurrentGrainCompleted(); }, 400);
                });
            });
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
