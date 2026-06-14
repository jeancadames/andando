$ErrorActionPreference = "Stop"

# ==========================
# Configuración
# ==========================
$SshAlias = "andando-vps"
$ApiBaseUrl = "https://api-staging.andando.do/api"
$AppUrl = "https://app-staging.andando.do"

$MobileDir = $PSScriptRoot
$RepoDir = Split-Path $MobileDir -Parent

$RemoteTempDir = "/tmp/andando-flutter-web"
$RemotePublicDir = "/var/www/andando-staging/flutter-web"

Write-Host ""
Write-Host "==> Deploy Flutter Web Staging AndanDO"
Write-Host "==> Mobile dir: $MobileDir"
Write-Host "==> Repo dir: $RepoDir"
Write-Host "==> API base URL: $ApiBaseUrl"
Write-Host ""

# ==========================
# Validaciones locales
# ==========================
if (!(Test-Path "$MobileDir\pubspec.yaml")) {
    throw "No se encontró pubspec.yaml. Ejecuta este script desde la carpeta mobile."
}

Write-Host "==> Verificando Flutter"
flutter --version

Write-Host ""
Write-Host "==> Verificando estado de Git"
$gitStatus = git -C "$RepoDir" status --porcelain

if ($gitStatus) {
    Write-Host ""
    Write-Host "ERROR: Hay cambios locales sin commit en el repo."
    Write-Host "Haz commit, stash o descarta los cambios antes de desplegar staging."
    Write-Host ""
    git -C "$RepoDir" status --short
    exit 1
}

Write-Host "==> Cambiando a main"
git -C "$RepoDir" checkout main

Write-Host "==> Actualizando main desde GitHub"
git -C "$RepoDir" pull origin main

# ==========================
# Build Flutter Web
# ==========================
Write-Host ""
Write-Host "==> Entrando a mobile"
Push-Location "$MobileDir"

Write-Host "==> Limpiando Flutter"
flutter clean

Write-Host "==> Instalando dependencias"
flutter pub get

Write-Host "==> Compilando Flutter Web para staging"
flutter build web --release --dart-define=API_BASE_URL=$ApiBaseUrl

Pop-Location

$BuildDir = "$MobileDir\build\web"

if (!(Test-Path "$BuildDir\index.html")) {
    throw "No se encontró build\web\index.html. El build web no se generó correctamente."
}

# ==========================
# Subida al VPS
# ==========================
Write-Host ""
Write-Host "==> Preparando carpeta temporal en VPS"
ssh $SshAlias "rm -rf $RemoteTempDir && mkdir -p $RemoteTempDir"

Write-Host "==> Subiendo build web al VPS"
scp -r "$BuildDir\*" "$SshAlias`:$RemoteTempDir/"

Write-Host "==> Publicando en app-staging"
ssh $SshAlias "set -e; sudo rm -rf $RemotePublicDir/*; sudo cp -r $RemoteTempDir/* $RemotePublicDir/; sudo chown -R jean:www-data $RemotePublicDir; sudo chmod -R u+rwX,g+rwX,o+rX $RemotePublicDir; rm -rf $RemoteTempDir"

# ==========================
# Prueba final
# ==========================
Write-Host ""
Write-Host "==> Probando app-staging"
curl.exe -I $AppUrl

Write-Host ""
Write-Host "==> Deploy Flutter Web staging completado"
Write-Host "==> URL: $AppUrl"