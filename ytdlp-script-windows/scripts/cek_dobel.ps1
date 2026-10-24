param(
    [string]$Folder
)

[Console]::OutputEncoding = [Text.Encoding]::UTF8

$root = Split-Path -Parent $PSScriptRoot   # folder induk (tempat bat, ffmpeg, lokasi.txt)
$ffprobe = Join-Path $root 'ffmpeg\bin\ffprobe.exe'
if (-not (Test-Path -LiteralPath $ffprobe)) { $ffprobe = 'ffprobe' }

# folder default: dari lokasi.txt (sama seperti script lain), kalau tidak ada pakai Downloads
if (-not $Folder) {
    $Folder = Join-Path $env:USERPROFILE 'Downloads'
    $lok = Join-Path $root 'lokasi.txt'
    if (Test-Path -LiteralPath $lok) {
        $l = Get-Content -LiteralPath $lok -Encoding UTF8 | Where-Object { $_.Trim() } | Select-Object -Last 1
        if ($l) { $Folder = $l.Trim() }
    }
}

Write-Host "Memeriksa mkv di: $Folder"
Write-Host ''

$files = Get-ChildItem -LiteralPath $Folder -Recurse -File -Filter *.mkv
$total = @($files).Count
$bad = 0
$i = 0

foreach ($f in $files) {
    $i++
    $names = & $ffprobe -v error -show_entries stream_tags=filename -of csv=p=0 -i $f.FullName 2>$null
    $covers = @($names | Where-Object { $_ -match '^cover\.' }).Count
    $title = & $ffprobe -v error -show_entries format_tags=title -of default=nw=1:nk=1 -i $f.FullName 2>$null | Select-Object -First 1
    $dblTitle = $title -match '^\d{4}-\d{2}-\d{2} - \d{4}-\d{2}-\d{2} - '

    if ($covers -gt 1 -or $dblTitle) {
        $bad++
        Write-Host ("[{0}/{1}] BERMASALAH: {2}" -f $i, $total, $f.FullName) -ForegroundColor Red
        Write-Host ("    cover={0}  title={1}" -f $covers, $title)
    }
}

Write-Host ''
Write-Host ("Selesai. Diperiksa: {0} | Bermasalah: {1}" -f $total, $bad)
