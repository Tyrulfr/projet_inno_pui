# Ajoute le widget progression aux pages HTML qui ne l'ont pas.
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$assetsPath = "..\..\..\..\..\assets"
$module1Path = Join-Path $projectRoot "pages\apprenant\cours\sensibilisation\module1"

$grainFiles = @("grain4","grain5","grain6","grain7","grain8","grain9","grain10","grain11","grain12","grain13","grain14","grain15","grain16","grain17","grain18","grain_exp21")
foreach ($g in $grainFiles) {
    $f = Join-Path $module1Path "$g.html"
    if (-not (Test-Path $f)) { continue }
    $content = Get-Content $f -Raw -Encoding UTF8
    if ($content -match "progress-indicators\.css") { continue }
    $content = $content -replace '(\s*)</style>\r?\n</head>\r?\n<body>', "`$1</style>`n    <link rel=`"stylesheet`" href=`"../../../../../assets/css/progress-indicators.css`">`n</head>`n<body data-module=`"module1`" data-grain=`"$g`">"
    $content = $content -replace '(</nav>)\r?\n\r?\n(\s*)(<!-- Contenu Principal -->\r?\n\s*<div class="content-container">)', "`$1`n    <div id=`"progress-widget`" class=`"progress-widget`"></div>`n`n`$2`$3"
    $content = $content -replace '(</nav>)\r?\n\r?\n(\s*<div class="content-container">)', "`$1`n    <div id=`"progress-widget`" class=`"progress-widget`"></div>`n`n`$2"
    $content = $content -replace '(\s*)</script>\r?\n</body>', "`$1</script>`n    <script src=`"../../../../../assets/js/progress-indicators.js`"></script>`n</body>"
    [System.IO.File]::WriteAllText($f, $content, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Updated $g.html"
}

$seqFiles = @("sommaire_sequence1","sommaire_sequence2","sommaire_sequence3")
foreach ($s in $seqFiles) {
    $f = Join-Path $module1Path "$s.html"
    if (-not (Test-Path $f)) { continue }
    $content = Get-Content $f -Raw -Encoding UTF8
    if ($content -match "progress-indicators\.css") { continue }
    $content = $content -replace '(\s*)</style>\r?\n</head>\r?\n<body>', "`$1</style>`n    <link rel=`"stylesheet`" href=`"../../../../../assets/css/progress-indicators.css`">`n</head>`n<body data-module=`"module1`">"
    $content = $content -replace '(</nav>)\r?\n\r?\n(\s*<div)', "`$1`n    <div id=`"progress-widget`" class=`"progress-widget`"></div>`n`n`$2"
    $content = $content -replace '(\s*)</script>\r?\n</body>', "`$1</script>`n    <script src=`"../../../../../assets/js/progress-indicators.js`"></script>`n</body>"
    [System.IO.File]::WriteAllText($f, $content, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Updated $s.html"
}
Write-Host "Done module1."
