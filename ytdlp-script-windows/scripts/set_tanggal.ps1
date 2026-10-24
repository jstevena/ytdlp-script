param(
    [Parameter(Mandatory=$true)][string]$Folder,
    [Parameter(Mandatory=$true)][string]$WorkDir,
    [int]$SinceMinutes = 0,   # 0 = semua file; >0 = hanya file yang diubah dalam N menit terakhir
    [switch]$SetTitle         # juga beri awalan tanggal pada tag title (mkv/mp4), tanpa re-encode
)

[Console]::OutputEncoding = [Text.Encoding]::UTF8

$ffprobe = Join-Path $WorkDir 'ffmpeg\bin\ffprobe.exe'
if (-not (Test-Path -LiteralPath $ffprobe)) { $ffprobe = 'ffprobe' }
$ffmpeg = Join-Path $WorkDir 'ffmpeg\bin\ffmpeg.exe'
if (-not (Test-Path -LiteralPath $ffmpeg)) { $ffmpeg = 'ffmpeg' }

$files = Get-ChildItem -LiteralPath $Folder -Recurse -File |
    Where-Object { $_.Extension -in '.mkv', '.mp4', '.webm', '.mp3' }

if ($SinceMinutes -gt 0) {
    $cut = (Get-Date).AddMinutes(-$SinceMinutes)
    $files = $files | Where-Object { $_.LastWriteTime -ge $cut }
}

$total = @($files).Count
$done = 0; $same = 0; $none = 0; $titled = 0; $tfail = 0; $i = 0

foreach ($f in $files) {
    $i++
    $out = & $ffprobe -v error -show_entries format_tags -of default=nw=1 -i $f.FullName 2>$null
    $tags = ($out -join "`n")
    $m = [regex]::Match($tags, '(?im)^TAG:date=(\d{4})-?(\d{2})-?(\d{2})')

    if (-not $m.Success) {
        $none++
        Write-Host ("[{0}/{1}] tidak ada tag date: {2}" -f $i, $total, $f.Name) -ForegroundColor Yellow
        continue
    }

    try {
        $dt = [datetime]::new([int]$m.Groups[1].Value, [int]$m.Groups[2].Value, [int]$m.Groups[3].Value, 12, 0, 0)
    } catch {
        $none++
        Write-Host ("[{0}/{1}] tanggal tidak valid: {2}" -f $i, $total, $f.Name) -ForegroundColor Yellow
        continue
    }

    # awalan tanggal pada tag title (hanya mkv/mp4; dilewati kalau sudah berawalan tanggal)
    if ($SetTitle -and $f.Extension -in '.mkv', '.mp4') {
        $tm = [regex]::Match($tags, '(?im)^TAG:title=(.*)$')
        if ($tm.Success) { $cur = $tm.Groups[1].Value.TrimEnd("`r") } else { $cur = $f.BaseName }

        if ($cur -notmatch '^\d{4}-\d{2}-\d{2} - ') {
            $newTitle = ('{0}-{1}-{2} - {3}' -f $m.Groups[1].Value, $m.Groups[2].Value, $m.Groups[3].Value, $cur)
            $tmp = Join-Path $f.DirectoryName ('__tmp_title' + $f.Extension)
            if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }

            # Windows PowerShell 5.1: tanda kutip ganda di dalam argumen harus di-escape manual
            $arg = 'title=' + $newTitle.Replace('"', '\"')
            & $ffmpeg -hide_banner -loglevel error -y -i $f.FullName -map 0 -c copy -metadata $arg $tmp 2>$null

            if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $tmp) -and ((Get-Item -LiteralPath $tmp).Length -gt 0)) {
                Move-Item -LiteralPath $tmp -Destination $f.FullName -Force
                $titled++
                $f.Refresh()
            } else {
                $tfail++
                Write-Host ("[{0}/{1}] GAGAL ubah title: {2}" -f $i, $total, $f.Name) -ForegroundColor Red
                if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
            }
        }
    }

    if ([math]::Abs(($f.LastWriteTime - $dt).TotalMinutes) -lt 1) {
        $same++
        continue
    }

    [IO.File]::SetLastWriteTime($f.FullName, $dt)
    $done++
    Write-Host ("[{0}/{1}] {2:yyyy-MM-dd}  {3}" -f $i, $total, $dt, $f.Name) -ForegroundColor Green
}

Write-Host ''
Write-Host ("Date modified diubah: {0} | Sudah sesuai: {1} | Tanpa tag date: {2} | Total diperiksa: {3}" -f $done, $same, $none, $total)
if ($SetTitle) { Write-Host ("Title diberi awalan tanggal: {0} | Gagal: {1}" -f $titled, $tfail) }
