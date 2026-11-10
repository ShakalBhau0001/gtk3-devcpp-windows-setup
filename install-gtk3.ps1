$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = "SilentlyContinue"

$dest = "C:\gtk"
$zip  = "$env:TEMP\gtk3.zip"

Write-Host "Searching gvsbuild releases for a GTK3 x64 zip..."
$releases = Invoke-RestMethod "https://api.github.com/repos/wingtk/gvsbuild/releases?per_page=50" -Headers @{ "User-Agent" = "PowerShell" }

$asset = $null
foreach ($r in $releases) {
    foreach ($a in $r.assets) {
        if ($a.name -like "GTK3_Gvsbuild_*_x64.zip") { $asset = $a; break }
    }
    if ($asset) { break }
}

if (-not $asset) {
    Write-Host "No GTK3 zip found in the latest 50 releases." -ForegroundColor Red
    Write-Host "Open https://github.com/wingtk/gvsbuild/releases and look at older releases."
    return
}

Write-Host "Downloading $($asset.name) ..."
Invoke-WebRequest $asset.browser_download_url -OutFile $zip
Write-Host "Extracting to $dest (this takes a few minutes)..."
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Expand-Archive -Path $zip -DestinationPath $dest -Force

# If the zip had one extra top folder, move its contents up
if (-not (Test-Path "$dest\include")) {
    $inner = Get-ChildItem $dest -Directory | Select-Object -First 1
    if ($inner -and (Test-Path "$($inner.FullName)\include")) {
        Get-ChildItem $inner.FullName | Move-Item -Destination $dest -Force
    }
}

# Add C:\gtk\bin to your user PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*C:\gtk\bin*") {
    [Environment]::SetEnvironmentVariable("Path", "C:\gtk\bin;" + $userPath, "User")
    Write-Host "Added C:\gtk\bin to PATH (restart Dev-C++ after this)."
}

# Check that the folders you need exist
$need = @(
 "include","include\gtk-3.0","include\glib-2.0","lib\glib-2.0\include",
 "include\pango-1.0","include\cairo","include\gdk-pixbuf-2.0",
 "include\atk-1.0","include\harfbuzz"
)
foreach ($n in $need) {
    if (Test-Path "$dest\$n") { Write-Host "OK      $dest\$n" -ForegroundColor Green }
    else { Write-Host "MISSING $dest\$n" -ForegroundColor Red }
}

# Detect the real .lib file names and build the linker line
$libs = @(
 @("gtk-3.lib","gtk-3.0.lib"), @("gdk-3.lib","gdk-3.0.lib"),
 @("gio-2.0.lib"), @("gobject-2.0.lib"), @("glib-2.0.lib"),
 @("cairo.lib"), @("pango-1.0.lib"), @("pangocairo-1.0.lib"),
 @("gdk_pixbuf-2.0.lib"), @("intl.lib")
)
$flags = "-LC:/gtk/lib"
foreach ($group in $libs) {
    foreach ($name in $group) {
        if (Test-Path "$dest\lib\$name") { $flags += " -l:$name"; break }
    }
}
Write-Host ""
Write-Host "LINKER LINE FOR DEV-C++:" -ForegroundColor Yellow
Write-Host $flags
