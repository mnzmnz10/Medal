<#
.SYNOPSIS
    Medal kliplerini C: diskinden Google Drive'a (G:) parça parça taşır.

.DESCRIPTION
    - En eski kliplerden başlayarak taşır, klasör yapısını korur.
    - C: diskinde boş alan -MinFreeGB altına düşerse veya bu çalıştırmada
      -BatchGB kadar veri taşındıysa durur. Drive yüklemeyi bitirince
      scripti tekrar çalıştırın; kaldığı yerden devam eder.
    - Medal açıksa çalışmaz.

.EXAMPLE
    # Önce deneme: hiçbir şey taşımadan ne yapacağını gösterir
    .\Move-MedalClips.ps1 -WhatIf

.EXAMPLE
    # Küçük bir test (2 GB), sonra Medal'da kliplerin göründüğünü kontrol edin
    .\Move-MedalClips.ps1 -BatchGB 2

.EXAMPLE
    # 7 günden eski klipleri 40 GB'lık gruplar halinde taşı
    .\Move-MedalClips.ps1 -OlderThanDays 7 -BatchGB 40
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Source = 'C:\Medal\Clips',
    [string]$Destination,
    [double]$BatchGB = 40,
    [double]$MinFreeGB = 30,
    [int]$OlderThanDays = 0
)

$ErrorActionPreference = 'Stop'

if (-not $Destination) {
    # Drive'ın Türkçe ve İngilizce klasör adlarını dene
    $candidates = 'G:\Drive''ım', 'G:\My Drive'
    $root = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $root) {
        throw "Google Drive klasörü bulunamadı (G:\Drive'ım veya G:\My Drive). -Destination ile yolu verin."
    }
    $Destination = Join-Path $root 'Medal\Clips'
}

if (-not (Test-Path -LiteralPath $Source)) {
    throw "Kaynak klasör yok: $Source"
}

if (Get-Process -Name 'Medal*' -ErrorAction SilentlyContinue) {
    throw 'Medal açık. Sistem tepsisinden tamamen kapatıp tekrar deneyin.'
}

$sourceDrive = (Get-Item -LiteralPath $Source).PSDrive.Name
function Get-FreeGB { (Get-PSDrive -Name $sourceDrive).Free / 1GB }

$cutoff = (Get-Date).AddDays(-$OlderThanDays)
$files = Get-ChildItem -LiteralPath $Source -Recurse -File |
    Where-Object { $_.LastWriteTime -lt $cutoff } |
    Sort-Object LastWriteTime

$totalGB = ($files | Measure-Object Length -Sum).Sum / 1GB
Write-Host ("Taşınacak: {0} dosya, {1:N1} GB -> {2}" -f $files.Count, $totalGB, $Destination)
Write-Host ("{0}: boş alan {1:N1} GB" -f $sourceDrive, (Get-FreeGB))

$movedBytes = 0
$movedCount = 0
$sourceRoot = (Get-Item -LiteralPath $Source).FullName.TrimEnd('\')

foreach ($file in $files) {
    if ($movedBytes / 1GB -ge $BatchGB) {
        Write-Host "Grup sınırına ($BatchGB GB) ulaşıldı."
        break
    }
    # Drive dosyayı önce C: üzerindeki önbelleğe kopyaladığı için boş alanı koru
    if ((Get-FreeGB) - ($file.Length / 1GB) -lt $MinFreeGB) {
        Write-Host "$sourceDrive`: boş alan $MinFreeGB GB sınırına yaklaştı."
        break
    }

    $relative = $file.FullName.Substring($sourceRoot.Length).TrimStart('\')
    $target = Join-Path $Destination $relative
    $targetDir = Split-Path $target -Parent

    if (Test-Path -LiteralPath $target) {
        Write-Warning "Hedefte zaten var, atlandı: $relative"
        continue
    }

    if ($PSCmdlet.ShouldProcess($relative, 'Google Drive''a taşı')) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Move-Item -LiteralPath $file.FullName -Destination $target
        Write-Host ("  {0:N0} MB  {1}" -f ($file.Length / 1MB), $relative)
    }
    $movedBytes += $file.Length
    $movedCount++
}

Write-Host ''
Write-Host ("Bitti: {0} dosya, {1:N1} GB taşındı." -f $movedCount, ($movedBytes / 1GB))
if ($movedCount -lt $files.Count) {
    Write-Host 'Kalan dosyalar var. Drive simgesinde yükleme bitince scripti tekrar çalıştırın.'
}
