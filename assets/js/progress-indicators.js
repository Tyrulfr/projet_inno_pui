/**
 * Indicateurs de progression : barre du module en cours + 6 ronds (un par module) pour la formation.
 * Lit les grains complétés depuis localStorage (clé: projet_inno_progress).
 * À inclure sur chaque page avec data-module et data-grain sur <body>.
 */
(function () {
    var STORAGE_KEY = 'projet_inno_progress';

    var MODULES = [
        { id: 'module1', name: 'M1', grains: ['grain1','grain2','grain3','grain4','grain5','grain6','grain7','grain8','grain9','grain10','grain11','grain12','grain13','grain14','grain15','grain16','grain17','grain18','grain_exp21'] },
        { id: 'module2', name: 'M2', grains: ['sommaire_module2'] },
        { id: 'module3', name: 'M3', grains: ['sommaire_module3','temoignage_silvia'] },
        { id: 'module4', name: 'M4', grains: ['sommaire_module4'] },
        { id: 'module5', name: 'M5', grains: ['sommaire_module5'] },
        { id: 'module6', name: 'M6', grains: ['sommaire_module6'] }
    ];

    function getCompleted() {
        try {
            var raw = localStorage.getItem(STORAGE_KEY);
            return raw ? JSON.parse(raw) : [];
        } catch (e) { return []; }
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

    /** Marque un grain comme complété (localStorage). Pour apprenant direct / invité. */
    function markGrainCompleted(grainId) {
        if (!grainId) return;
        var completed = getCompleted();
        if (completed.indexOf(grainId) !== -1) return;
        completed.push(grainId);
        try {
            localStorage.setItem(STORAGE_KEY, JSON.stringify(completed));
        } catch (e) { return; }
        if (window.progressIndicatorsRefresh) window.progressIndicatorsRefresh();
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

    function init() {
        render();
        window.addEventListener('storage', render);
        window.progressIndicatorsRefresh = render;
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
