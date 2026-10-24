@echo off
chcp 65001 >nul
mode con:cols=85 lines=25

:: =========================
:: Konfigurasi
:: =========================
set "workdir=%~dp0"
set "folder=%USERPROFILE%\Downloads"

if exist "%workdir%lokasi.txt" (
    for /f "usebackq delims=" %%A in ("%workdir%lokasi.txt") do (
        if not "%%A"=="" set "folder=%%A"
    )
)

if "%folder:~-1%"=="\" set "folder=%folder:~0,-1%"

set "PATH=%workdir%ffmpeg\bin;%workdir%node;%PATH%"

:: =========================
:: Menu
:: =========================
:menu
cls
echo ========================================
echo      Rapikan File Lama YouTube
echo ========================================
echo Folder: %folder%
echo.
echo [1] Remux semua .webm jadi .mkv (tanpa re-encode)
echo [2] Embed tanggal + thumbnail ke file MKV lama
echo [3] Embed tanggal + thumbnail ke file MP4 lama (format -r)
echo [4] Cari URL otomatis dari nama file (isi urls.txt)
echo [5] Set "Date modified" + awalan tanggal di tag title (file yang sudah diproses)
echo [6] Bersihkan thumbnail dobel di file MKV (akibat opsi 2 dijalankan 2x)
echo [Q] Keluar
echo.
echo Opsi 2 butuh urls\urls.txt, opsi 3 butuh urls\urls_mp4.txt (satu URL per baris).
echo.
set /p pilih=Pilih: 

if /I "%pilih%"=="1" goto :remux
if /I "%pilih%"=="2" (
    set "fmt=mkv"
    set "urlfile=urls.txt"
    goto :embed
)
if /I "%pilih%"=="3" (
    set "fmt=mp4"
    set "urlfile=urls_mp4.txt"
    goto :embed
)
if /I "%pilih%"=="4" goto :cari
if /I "%pilih%"=="5" goto :tanggal
if /I "%pilih%"=="6" goto :bersih
if /I "%pilih%"=="q" exit /b
goto :menu


:: =========================
:: 1. webm -> mkv
:: =========================
:remux
echo.
echo Semua .webm di folder ini (termasuk subfolder) akan dijadikan .mkv,
echo lalu file .webm aslinya dihapus kalau remux berhasil.
set /p yakin=Lanjut? (y/n): 
if /I not "%yakin%"=="y" goto :menu
echo.

for /r "%folder%" %%F in (*.webm) do (
    echo Remux: "%%~nxF"
    ffmpeg -hide_banner -loglevel error -n -i "%%F" -map 0 -c copy "%%~dpnF.mkv" && (del "%%F" & echo   OK) || echo   GAGAL atau sudah ada .mkv, dilewati
)

echo.
echo Selesai.
pause
goto :menu


:: =========================
:: 6. Bersihkan thumbnail dobel (MKV)
:: =========================
:bersih
if not exist "%workdir%bersihkan_thumb.ps1" (
    echo.
    echo [ERROR] bersihkan_thumb.ps1 tidak ditemukan di folder script.
    pause
    goto :menu
)
echo.
echo Memeriksa dulu semua .mkv di folder ini (file belum diubah)...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%workdir%bersihkan_thumb.ps1" -Folder "%folder%" -WorkDir "%workdir%." -DryRun
echo.
echo Pembersihan menulis ulang file (tanpa re-encode), Date modified tetap dijaga.
set /p yakin=Bersihkan file yang terdaftar di atas? (y/n): 
if /I not "%yakin%"=="y" goto :menu
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%workdir%bersihkan_thumb.ps1" -Folder "%folder%" -WorkDir "%workdir%."
echo.
pause
goto :menu


:: =========================
:: 5. Set Date modified dari tag date
:: =========================
:tanggal
if not exist "%workdir%scripts\set_tanggal.ps1" (
    echo.
    echo [ERROR] scripts\set_tanggal.ps1 tidak ditemukan.
    pause
    goto :menu
)
echo.
echo Untuk semua file di folder ini (termasuk subfolder):
echo - Date modified diubah sesuai tag date (tanggal upload, jam 12:00)
echo - Tag title mkv/mp4 diberi awalan tanggal (YYYY-MM-DD - judul), tanpa
echo   re-encode. File yang title-nya sudah berawalan tanggal dilewati.
echo File tanpa tag date dilewati. Menulis ulang tiap file butuh ruang kosong
echo sebesar file terbesar dan waktu beberapa detik per file.
set /p yakin=Lanjut? (y/n): 
if /I not "%yakin%"=="y" goto :menu
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%workdir%scripts\set_tanggal.ps1" -Folder "%folder%" -WorkDir "%workdir%." -SetTitle
echo.
pause
goto :menu


:: =========================
:: 4. Cari URL otomatis
:: =========================
:cari
if not exist "%workdir%scripts\cari_url.ps1" (
    echo.
    echo [ERROR] scripts\cari_url.ps1 tidak ditemukan.
    pause
    goto :menu
)
echo.
echo Script akan mencari tiap file di YouTube dan mencocokkan judul + durasi.
echo Hasil di folder urls: urls.txt (mkv/webm), urls_mp4.txt (mp4), urls_ragu.txt, urls_tidak_ketemu.txt
echo urls.txt dan urls_mp4.txt lama akan di-backup jadi .bak
echo Jalankan opsi 1 dulu kalau masih ada .webm. Proses ~5 detik per file.
set /p yakin=Lanjut? (y/n): 
if /I not "%yakin%"=="y" goto :menu
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%workdir%scripts\cari_url.ps1" -Folder "%folder%" -WorkDir "%workdir%." -OutDir "%workdir%urls"
echo.
pause
goto :menu


:: =========================
:: 2 / 3. Embed tanggal + thumbnail
:: =========================
:embed
if not exist "%workdir%urls\%urlfile%" (
    echo.
    echo [ERROR] urls\%urlfile% tidak ditemukan.
    pause
    goto :menu
)

set "cookie_opt="
if exist "%workdir%cookies.txt" set cookie_opt=--cookies "%workdir%cookies.txt"

echo.
echo PENTING: URL di %urlfile% harus video yang file-nya SUDAH ada di folder.
echo Kalau file tidak ketemu, yt-dlp akan download video itu dari awal.
set /p yakin=Lanjut? (y/n): 
if /I not "%yakin%"=="y" goto :menu
echo.

yt-dlp.exe --js-runtimes node -f "bv*+ba/b" --merge-output-format %fmt% --embed-metadata --parse-metadata "%%(upload_date>%%Y-%%m-%%d)s - %%(title)s:%%(meta_title)s" --embed-thumbnail --convert-thumbnails png --postprocessor-args "ThumbnailsConvertor+ffmpeg_o:-c:v png -vf crop=iw:iw*9/16" %cookie_opt% --output "%folder%\%%(title)s.%%(ext)s" --cache-dir "%folder%\cache" --batch-file "%workdir%urls\%urlfile%"

if exist "%workdir%bersihkan_thumb.ps1" (
    echo.
    echo Memeriksa thumbnail dobel...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%workdir%bersihkan_thumb.ps1" -Folder "%folder%" -WorkDir "%workdir%." -SinceMinutes 1440
)

if exist "%workdir%scripts\set_tanggal.ps1" (
    echo.
    echo Mengatur Date modified sesuai tanggal upload...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%workdir%scripts\set_tanggal.ps1" -Folder "%folder%" -WorkDir "%workdir%." -SinceMinutes 1440
)

echo.
echo Selesai.
pause
goto :menu