# Cree une icone .ico a partir de "Visuel Osez pour Innover.png" et la place sur le Bureau
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$imgPath = Join-Path $projectRoot "assets\image\Visuel Osez pour Innover.png"
$icoName = "OserPourInnover.ico"
$icoInProject = Join-Path $projectRoot "assets\image\$icoName"
$desktop = [Environment]::GetFolderPath("Desktop")
$icoOnDesktop = Join-Path $desktop $icoName

if (-not (Test-Path $imgPath)) {
    Write-Host "Image introuvable : $imgPath"
    pause
    exit 1
}

Add-Type -AssemblyName System.Drawing
try {
    $img = [System.Drawing.Bitmap]::FromFile($imgPath)
    $icon = [System.Drawing.Icon]::FromHandle($img.GetHicon())
    $fs = [System.IO.File]::Create($icoInProject)
    $icon.Save($fs)
    $fs.Close()
    $icon.Dispose()
    $img.Dispose()
    Copy-Item $icoInProject $icoOnDesktop -Force
    Write-Host "Icone creee sur le Bureau : $icoOnDesktop"
    Write-Host "Copie dans le projet : $icoInProject"
} catch {
    Write-Host "Erreur : $_"
}
pause
