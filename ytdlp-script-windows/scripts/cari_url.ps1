param(
    [Parameter(Mandatory=$true)][string]$Folder,
    [Parameter(Mandatory=$true)][string]$WorkDir,
    [string]$OutDir          # folder untuk file urls*.txt (default: sama dengan WorkDir)
)

if (-not $OutDir) { $OutDir = $WorkDir }
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

[Console]::OutputEncoding = [Text.Encoding]::UTF8
$OutputEncoding = [Text.Encoding]::UTF8
$utf8 = New-Object Text.UTF8Encoding($false)
$inv  = [Globalization.CultureInfo]::InvariantCulture
$flt  = [Globalization.NumberStyles]::Float

$ytdlp = Join-Path $WorkDir 'yt-dlp.exe'
if (-not (Test-Path -LiteralPath $ytdlp)) { $ytdlp = 'yt-dlp' }
$ffprobe = Join-Path $WorkDir 'ffmpeg\bin\ffprobe.exe'
if (-not (Test-Path -LiteralPath $ffprobe)) { $ffprobe = 'ffprobe' }
$cookie = Join-Path $WorkDir 'cookies.txt'

$tolerance = 3   # selisih durasi maksimal (detik)

function Get-Norm([string]$s) {
    return [regex]::Replace($s.ToLowerInvariant(), '[^\p{L}\p{N}]', '')
}

$files = Get-ChildItem -LiteralPath $Folder -Recurse -File |
    Where-Object { $_.Extension -in '.mkv', '.mp4', '.webm' } |
    Sort-Object FullName

$total   = @($files).Count
$mkvUrls = New-Object System.Collections.Generic.List[string]
$mp4Urls = New-Object System.Collections.Generic.List[string]
$seen    = New-Object System.Collections.Generic.HashSet[string]
$ragu    = New-Object System.Collections.Generic.List[string]
$miss    = New-Object System.Collections.Generic.List[string]
$i = 0

foreach ($f in $files) {
    $i++
    $title = $f.BaseName
    Write-Host ("[{0}/{1}] {2}" -f $i, $total, $title)

    # durasi file lokal
    $durRaw = & $ffprobe -v error -show_entries format=duration -of csv=p=0 -i $f.FullName 2>$null
    $fileDur = 0.0
    $okDur = [double]::TryParse(([string]($durRaw | Select-Object -First 1)).Trim(), $flt, $inv, [ref]$fileDur)
    if (-not $okDur -or $fileDur -le 0) {
        Write-Host '   -> durasi file tidak terbaca, dilewati' -ForegroundColor Yellow
        $miss.Add($f.Name + '   (durasi file tidak terbaca)')
        continue
    }

    # cari di YouTube (5 hasil teratas)
    $ytArgs = @("ytsearch5:$title", '--flat-playlist', '--no-warnings', '--print', '%(id)s|||%(duration)s|||%(title)s')
    if (Test-Path -LiteralPath $cookie) { $ytArgs += @('--cookies', $cookie) }
    $lines = & $ytdlp @ytArgs 2>$null

    $cands = @()
    foreach ($l in $lines) {
        $p = ([string]$l) -split '\|\|\|', 3
        if ($p.Count -eq 3) {
            $d = 0.0
            $has = [double]::TryParse($p[1].Trim(), $flt, $inv, [ref]$d)
            $cands += [pscustomobject]@{ Id = $p[0].Trim(); Dur = $d; HasDur = $has; Title = $p[2] }
        }
    }

    $nt = Get-Norm $title
    $sure = $null
    $maybe = $null
    foreach ($c in $cands) {
        $nm = Get-Norm $c.Title
        $titleOk = ($nm -eq $nt) -or ($nt.Length -ge 10 -and $nm.Length -ge 10 -and ($nm.Contains($nt) -or $nt.Contains($nm)))
        $durOk = $c.HasDur -and ([math]::Abs($c.Dur - $fileDur) -le $tolerance)
        if ($titleOk -and $durOk) { $sure = $c; break }
        if (-not $maybe -and ($durOk -or ($titleOk -and -not $c.HasDur))) { $maybe = $c }
    }

    if ($sure) {
        $url = 'https://www.youtube.com/watch?v=' + $sure.Id
        Write-Host "   -> COCOK  $url" -ForegroundColor Green
        if ($seen.Add($url)) {
            if ($f.Extension -eq '.mp4') { $mp4Urls.Add($url) } else { $mkvUrls.Add($url) }
        }
    }
    elseif ($maybe) {
        $url = 'https://www.youtube.com/watch?v=' + $maybe.Id
        Write-Host "   -> RAGU   $url" -ForegroundColor Yellow
        $ragu.Add('FILE     : ' + $f.Name)
        $ragu.Add('KANDIDAT : ' + $maybe.Title)
        $ragu.Add('URL      : ' + $url)
        $ragu.Add('')
    }
    else {
        Write-Host '   -> tidak ketemu' -ForegroundColor Red
        $miss.Add($f.Name)
    }

    Start-Sleep -Seconds 1
}

# simpan hasil (urls.txt lama di-backup dulu)
$old = Join-Path $OutDir 'urls.txt'
if (Test-Path -LiteralPath $old) { Copy-Item -LiteralPath $old -Destination (Join-Path $OutDir 'urls.txt.bak') -Force }
$oldMp4 = Join-Path $OutDir 'urls_mp4.txt'
if (Test-Path -LiteralPath $oldMp4) { Copy-Item -LiteralPath $oldMp4 -Destination (Join-Path $OutDir 'urls_mp4.txt.bak') -Force }

[IO.File]::WriteAllLines((Join-Path $OutDir 'urls.txt'), $mkvUrls, $utf8)
[IO.File]::WriteAllLines((Join-Path $OutDir 'urls_mp4.txt'), $mp4Urls, $utf8)
[IO.File]::WriteAllLines((Join-Path $OutDir 'urls_ragu.txt'), $ragu, $utf8)
[IO.File]::WriteAllLines((Join-Path $OutDir 'urls_tidak_ketemu.txt'), $miss, $utf8)

Write-Host ''
Write-Host '================ RINGKASAN ================'
Write-Host ("Total file         : {0}" -f $total)
Write-Host ("Cocok (mkv/webm)   : {0}  -> urls.txt" -f $mkvUrls.Count)
Write-Host ("Cocok (mp4)        : {0}  -> urls_mp4.txt" -f $mp4Urls.Count)
Write-Host ("Ragu (cek manual)  : {0}  -> urls_ragu.txt" -f ($ragu.Count / 4))
Write-Host ("Tidak ketemu       : {0}  -> urls_tidak_ketemu.txt" -f $miss.Count)
