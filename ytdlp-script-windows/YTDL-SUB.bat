@echo off

:: =========================
:: Konfigurasi Tampilan CMD
:: =========================
mode con:cols=85 lines=25

:: =========================
:: Konfigurasi Direktori
:: =========================
set "workdir=%~dp0"

set "cache=%USERPROFILE%\Downloads"

if exist "%workdir%lokasi.txt" (
    for /f "usebackq delims=" %%A in ("%workdir%lokasi.txt") do (
        if not "%%A"=="" set "cache=%%A"
    )
)

if "%cache:~-1%"=="\" set "cache=%cache:~0,-1%"

if not exist "%cache%" mkdir "%cache%"

:: File cookie (opsional)
set cookie_path=%workdir%cookies.txt

:: File encoder (WAJIB lowercase)
set encoder_file=%workdir%encoder.txt


:: =========================
:: Deteksi Encoder
:: =========================
if not exist "%encoder_file%" (
    echo [ERROR] encoder.txt tidak ditemukan!
    echo Isi dengan: nvidia / amd / intel / cpu / remux
    pause
    exit /b
)

set /p encoder=<"%encoder_file%"

if not "%encoder%"=="nvidia" if not "%encoder%"=="amd" if not "%encoder%"=="intel" if not "%encoder%"=="cpu" if not "%encoder%"=="remux"  (
    echo [ERROR] Encoder tidak valid!
    echo Gunakan hanya: nvidia / cpu / remux
    pause
    exit /b
)

:: =========================
:: Menu Utama
:: =========================
:start_program
cls
echo ========================================
echo           YouTube Downloader
echo        Script by Johanes Steven
echo ========================================
echo Tekan U untuk update yt-dlp
echo.
echo Gunakan format biasa untuk menyimpan file original
echo Gunakan format -r untuk kompatibilitas video editing
echo.
echo [ENCODER] %encoder%

if exist "%cookie_path%" (
    echo [STATUS] Cookie Terdeteksi
) else (
    echo [STATUS] Cookie TIDAK Terdeteksi
)

echo.
echo 360p, 480p, 720p, 1080p, 1440p, 2160p
echo 360p-r, 480p-r, 720p-r, 1080p-r, 1440p-r, 2160p-r
echo MP3, WAV
echo.

set /P type=Save as:

if "%type%"=="" (
    echo Error: Tipe download tidak boleh kosong.
    pause
    goto :start_program
)

:: =========================
:: Update yt-dlp
:: =========================
if /I "%type%"=="u" (
    echo Memperbarui yt-dlp...
    yt-dlp.exe -U
    echo.
    echo Tekan tombol apapun untuk kembali ke menu utama...
    pause >nul
    goto :start_program
)


:: =========================
:: Konversi input ke lowercase
:: =========================
set "type_lower=%type%"
set "type_lower=%type_lower:A=a%"
set "type_lower=%type_lower:B=b%"
set "type_lower=%type_lower:C=c%"
set "type_lower=%type_lower:D=d%"
set "type_lower=%type_lower:E=e%"
set "type_lower=%type_lower:F=f%"
set "type_lower=%type_lower:G=g%"
set "type_lower=%type_lower:H=h%"
set "type_lower=%type_lower:I=i%"
set "type_lower=%type_lower:J=j%"
set "type_lower=%type_lower:K=k%"
set "type_lower=%type_lower:L=l%"
set "type_lower=%type_lower:M=m%"
set "type_lower=%type_lower:N=n%"
set "type_lower=%type_lower:O=o%"
set "type_lower=%type_lower:P=p%"
set "type_lower=%type_lower:Q=q%"
set "type_lower=%type_lower:R=r%"
set "type_lower=%type_lower:S=s%"
set "type_lower=%type_lower:T=t%"
set "type_lower=%type_lower:U=u%"
set "type_lower=%type_lower:V=v%"
set "type_lower=%type_lower:W=w%"
set "type_lower=%type_lower:X=x%"
set "type_lower=%type_lower:Y=y%"
set "type_lower=%type_lower:Z=z%"

:: =========================
:: Dispatcher Encoder
:: =========================
if "%encoder%"=="nvidia" goto :encoder_nvidia
if "%encoder%"=="cpu"    goto :encoder_cpu
if "%encoder%"=="remux"  goto :encoder_remux

goto :encoder_done


:: =========================
:: ENCODER NVIDIA (NVENC)
:: =========================
:encoder_nvidia
if "%type_lower%"=="mp3" (
    set config_params=-x --audio-format mp3
) else if "%type_lower%"=="wav" (
    set config_params=-x --audio-format wav
) else if "%type_lower%"=="360p" (
    set config_params=-f "bestvideo[height<=360]+bestaudio/best[height<=360]" --merge-output-format mkv
) else if "%type_lower%"=="480p" (
    set config_params=-f "bestvideo[height<=480]+bestaudio/best[height<=480]" --merge-output-format mkv
) else if "%type_lower%"=="720p" (
    set config_params=-f "bestvideo[height<=720]+bestaudio/best[height<=720]" --merge-output-format mkv
) else if "%type_lower%"=="1080p" (
    set config_params=-f "bestvideo[height<=1080]+bestaudio/best[height<=1080]" --merge-output-format mkv
) else if "%type_lower%"=="1440p" (
    set config_params=-f "bestvideo[height<=1440]+bestaudio/best[height<=1440]" --merge-output-format mkv
) else if "%type_lower%"=="2160p" (
    set config_params=-f "bestvideo[height<=2160]+bestaudio/best[height<=2160]" --merge-output-format mkv
) else if "%type_lower%"=="360p-r" (
    set config_params=-f "bestvideo[height<=360]+bestaudio/best[height<=360]/best" --merge-output-format mp4 --postprocessor-args "Merger+ffmpeg_o:-c:v hevc_nvenc -qp 22 -c:a aac -b:a 320k"
) else if "%type_lower%"=="480p-r" (
    set config_params=-f "bestvideo[height<=480]+bestaudio/best[height<=480]/best" --merge-output-format mp4 --postprocessor-args "Merger+ffmpeg_o:-c:v hevc_nvenc -qp 22 -c:a aac -b:a 320k"
) else if "%type_lower%"=="720p-r" (
    set config_params=-f "bestvideo[height<=720]+bestaudio/best[height<=720]/best" --merge-output-format mp4 --postprocessor-args "Merger+ffmpeg_o:-c:v hevc_nvenc -qp 22 -c:a aac -b:a 320k"
) else if "%type_lower%"=="1080p-r" (
    set config_params=-f "bestvideo[height<=1080]+bestaudio/best[height<=1080]/best" --merge-output-format mp4 --postprocessor-args "Merger+ffmpeg_o:-c:v hevc_nvenc -qp 20 -c:a aac -b:a 320k"
) else if "%type_lower%"=="1440p-r" (
    set config_params=-f "bestvideo[height<=1440]+bestaudio/best[height<=1440]/best" --merge-output-format mp4 --postprocessor-args "Merger+ffmpeg_o:-c:v hevc_nvenc -qp 18 -c:a aac -b:a 320k"
) else if "%type_lower%"=="2160p-r" (
    set config_params=-f "bestvideo[height<=2160]+bestaudio/best[height<=2160]/best" --merge-output-format mp4 --postprocessor-args "Merger+ffmpeg_o:-c:v hevc_nvenc -qp 18 -c:a aac -b:a 320k"

) else (
    echo Tipe download tidak valid.
    pause
    goto :start_program
)
goto :encoder_done


:: =========================
:: ENCODER CPU
:: =========================
:encoder_cpu
if "%type_lower%"=="mp3" (
    set config_params=-x --audio-format mp3
) else if "%type_lower%"=="wav" (
    set config_params=-x --audio-format wav
) else if "%type_lower%"=="360p" (
    set config_params=-f "bestvideo[height<=360]+bestaudio/best[height<=360]" --merge-output-format mkv
) else if "%type_lower%"=="480p" (
    set config_params=-f "bestvideo[height<=480]+bestaudio/best[height<=480]" --merge-output-format mkv
) else if "%type_lower%"=="720p" (
    set config_params=-f "bestvideo[height<=720]+bestaudio/best[height<=720]" --merge-output-format mkv
) else if "%type_lower%"=="1080p" (
    set config_params=-f "bestvideo[height<=1080]+bestaudio/best[height<=1080]" --merge-output-format mkv
) else if "%type_lower%"=="1440p" (
    set config_params=-f "bestvideo[height<=1440]+bestaudio/best[height<=1440]" --merge-output-format mkv
) else if "%type_lower%"=="2160p" (
    set config_params=-f "bestvideo[height<=2160]+bestaudio/best[height<=2160]" --merge-output-format mkv
) else if "%type_lower%"=="360p-r" (
    set config_params=-f "bestvideo[height<=360]+bestaudio/best[height<=360]/best" --merge-output-format mp4 --postprocessor-args "Merger+ffmpeg_o:-c:v libx265 -qp 22 -c:a aac -b:a 320k"
) else if "%type_lower%"=="480p-r" (
    set config_params=-f "bestvideo[height<=480]+bestaudio/best[height<=480]/best" --merge-output-format mp4 --postprocessor-args "Merger+ffmpeg_o:-c:v libx265 -qp 22 -c:a aac -b:a 320k"
) else if "%type_lower%"=="720p-r" (
    set config_params=-f "bestvideo[height<=720]+bestaudio/best[height<=720]/best" --merge-output-format mp4 --postprocessor-args "Merger+ffmpeg_o:-c:v libx265 -qp 22 -c:a aac -b:a 320k"
) else if "%type_lower%"=="1080p-r" (
    set config_params=-f "bestvideo[height<=1080]+bestaudio/best[height<=1080]/best" --merge-output-format mp4 --postprocessor-args "Merger+ffmpeg_o:-c:v libx265 -qp 20 -c:a aac -b:a 320k"
) else if "%type_lower%"=="1440p-r" (
    set config_params=-f "bestvideo[height<=1440]+bestaudio/best[height<=1440]/best" --merge-output-format mp4 --postprocessor-args "Merger+ffmpeg_o:-c:v libx265 -qp 18 -c:a aac -b:a 320k"
) else if "%type_lower%"=="2160p-r" (
    set config_params=-f "bestvideo[height<=2160]+bestaudio/best[height<=2160]/best" --merge-output-format mp4 --postprocessor-args "Merger+ffmpeg_o:-c:v libx265 -qp 18 -c:a aac -b:a 320k"

) else (
    echo Tipe download tidak valid.
    pause
    goto :start_program
)
goto :encoder_done


:: =========================
:: ENCODER REMUX
:: =========================
:encoder_remux
if "%type_lower%"=="mp3" (
    set config_params=-x --audio-format mp3
) else if "%type_lower%"=="wav" (
    set config_params=-x --audio-format wav
) else if "%type_lower%"=="360p" (
    set config_params=-f "bestvideo[height<=360]+bestaudio/best[height<=360]" --merge-output-format mkv
) else if "%type_lower%"=="480p" (
    set config_params=-f "bestvideo[height<=480]+bestaudio/best[height<=480]" --merge-output-format mkv
) else if "%type_lower%"=="720p" (
    set config_params=-f "bestvideo[height<=720]+bestaudio/best[height<=720]" --merge-output-format mkv
) else if "%type_lower%"=="1080p" (
    set config_params=-f "bestvideo[height<=1080]+bestaudio/best[height<=1080]" --merge-output-format mkv
) else if "%type_lower%"=="1440p" (
    set config_params=-f "bestvideo[height<=1440]+bestaudio/best[height<=1440]" --merge-output-format mkv
) else if "%type_lower%"=="2160p" (
    set config_params=-f "bestvideo[height<=2160]+bestaudio/best[height<=2160]" --merge-output-format mkv
) else if "%type_lower%"=="360p-r" (
    set config_params=-f "bestvideo[height<=360]+bestaudio/best[height<=360]/best" --remux-video mp4
) else if "%type_lower%"=="480p-r" (
    set config_params=-f "bestvideo[height<=480]+bestaudio/best[height<=480]/best" --remux-video mp4
) else if "%type_lower%"=="720p-r" (
    set config_params=-f "bestvideo[height<=720]+bestaudio/best[height<=720]/best" --remux-video mp4
) else if "%type_lower%"=="1080p-r" (
    set config_params=-f "bestvideo[height<=1080]+bestaudio/best[height<=1080]/best" --remux-video mp4
) else if "%type_lower%"=="1440p-r" (
    set config_params=-f "bestvideo[height<=1440]+bestaudio/best[height<=1440]/best" --remux-video mp4
) else if "%type_lower%"=="2160p-r" (
    set config_params=-f "bestvideo[height<=2160]+bestaudio/best[height<=2160]/best" --remux-video mp4
) else (
    echo Tipe download tidak valid.
    pause
    goto :start_program
)
goto :encoder_done


:: =========================
:: Encoder Selesai
:: =========================
:encoder_done


:: =========================
:: Embed Thumbnail + Metadata (termasuk upload date)
:: =========================
set extra=--embed-metadata --embed-thumbnail --convert-thumbnails png --postprocessor-args "ThumbnailsConvertor+ffmpeg_o:-c:v png -vf crop=iw:iw*9/16"
:: WAV tidak mendukung thumbnail
set extra_title=--parse-metadata "%%(upload_date>%%Y-%%m-%%d)s - %%(title)s:%%(meta_title)s"
if "%type_lower%"=="wav" set "extra=--embed-metadata"
:: Awalan tanggal di tag title (hanya untuk video, bukan mp3/wav)
if not "%type_lower%"=="wav" if not "%type_lower%"=="mp3" set extra=%extra% %extra_title%
set config_params=%config_params% %extra%


:: =========================
:: Cookie
:: =========================
if exist "%cookie_path%" (
    set config_params=%config_params% --cookies "%cookie_path%"
)


:: =========================
:: Input URL
:: =========================
echo.
echo Masukkan URL satu per satu, ketik "done" untuk mulai download.

:: Hapus daftar URL sisa dari sesi sebelumnya (mis. kalau sempat di-Ctrl+C)
if exist "%temp%\url_list.txt" del "%temp%\url_list.txt"

:download_loop
set /P url=Enter URL: 

if "%url%"=="done" goto :start_download
if "%url%"=="" (
    echo URL tidak boleh kosong.
    goto :download_loop
)

echo %url%>>"%temp%\url_list.txt"
goto :download_loop


:: =========================
:: Proses Download
:: =========================
:start_download
if not exist "%temp%\url_list.txt" (
    echo Tidak ada URL dimasukkan.
    pause
    goto :start_program
)

set "PATH=%workdir%ffmpeg\bin;%workdir%node;%PATH%"

yt-dlp.exe --js-runtimes node %config_params% --output "%cache%\%%(channel,uploader|Unknown)s\%%(title)s.%%(ext)s" --cache-dir "%cache%\cache" --batch-file "%temp%\url_list.txt"

del "%temp%\url_list.txt"

if errorlevel 1 (
    echo Download gagal.
    pause
    goto :start_program
)

if exist "%workdir%scripts\set_tanggal.ps1" (
    echo.
    echo Mengatur Date modified sesuai tanggal upload...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%workdir%scripts\set_tanggal.ps1" -Folder "%cache%" -WorkDir "%workdir%." -SinceMinutes 1440
)

echo.
echo Download sukses!
pause
goto :start_program