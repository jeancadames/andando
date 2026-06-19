$ErrorActionPreference = "Stop"

# Hace que PowerShell 7 detenga el script si un comando nativo falla.
# En Windows PowerShell 5.1 no siempre aplica, por eso también usamos Invoke-Step.
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $true
}

function Invoke-Step {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Description,

        [Parameter(Mandatory = $true)]
        [scriptblock] $Command
    )

    Write-Host ""
    Write-Host "==> $Description"

    & $Command

    if ($LASTEXITCODE -ne 0) {
        throw "Falló el paso: $Description. Exit code: $LASTEXITCODE"
    }
}

# ==========================
# Configuración
# ==========================
$SshAlias = "andando-vps"
$ApiBaseUrl = "https://api-staging.andando.do/api"
$AppUrl = "https://app-staging.andando.do"

$MobileDir = $PSScriptRoot
$RepoDir = Split-Path $MobileDir -Parent

$BuildDir = Join-Path $MobileDir "build\web"
$LocalArchive = Join-Path $RepoDir "app-staging-web.tar.gz"

$RemoteArchive = "/tmp/app-staging-web.tar.gz"
$RemoteTempDir = "/tmp/andando-flutter-web"
$RemotePublicDir = "/var/www/andando-staging/flutter-web"

Write-Host ""
Write-Host "==> Deploy Flutter Web Staging AndanDO"
Write-Host "==> Mobile dir: $MobileDir"
Write-Host "==> Repo dir: $RepoDir"
Write-Host "==> API base URL: $ApiBaseUrl"
Write-Host "==> App URL: $AppUrl"
Write-Host ""

# ==========================
# Validaciones locales
# ==========================
if (!(Test-Path (Join-Path $MobileDir "pubspec.yaml"))) {
    throw "No se encontró pubspec.yaml. Este script debe estar dentro de la carpeta mobile."
}

if (Test-Path $LocalArchive) {
    Write-Host "==> Eliminando paquete local anterior"
    Remove-Item $LocalArchive -Force
}

Invoke-Step "Verificando Flutter" {
    flutter --version
}

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

Invoke-Step "Cambiando a main" {
    git -C "$RepoDir" checkout main
}

Invoke-Step "Actualizando main desde GitHub" {
    git -C "$RepoDir" pull origin main
}

# ==========================
# Build Flutter Web
# ==========================
Push-Location "$MobileDir"

try {
    Invoke-Step "Limpiando Flutter" {
        flutter clean
    }

    Invoke-Step "Instalando dependencias" {
        flutter pub get
    }

    Invoke-Step "Compilando Flutter Web para staging" {
        flutter build web --release --dart-define=API_BASE_URL=$ApiBaseUrl
    }
}
finally {
    Pop-Location
}

if (!(Test-Path (Join-Path $BuildDir "index.html"))) {
    throw "No se encontró build\web\index.html. El build web no se generó correctamente."
}

if (!(Test-Path (Join-Path $BuildDir "main.dart.js"))) {
    throw "No se encontró build\web\main.dart.js. El build web no se generó correctamente."
}

if (!(Test-Path (Join-Path $BuildDir "firebase-messaging-sw.js"))) {
    throw "No se encontró build\web\firebase-messaging-sw.js. Revisa que exista en mobile\web\firebase-messaging-sw.js."
}

# Archivo de verificación para confirmar que staging recibió este deploy.
$DeployStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$DeployStampFile = Join-Path $BuildDir "deploy-version.txt"
"staging deploy: $DeployStamp" | Out-File -FilePath $DeployStampFile -Encoding utf8 -Force

# ==========================
# Empaquetado
# ==========================
Write-Host ""
Write-Host "==> Creando paquete local: $LocalArchive"

Push-Location "$BuildDir"

try {
    tar -czf "$LocalArchive" .
}
finally {
    Pop-Location
}

if (!(Test-Path $LocalArchive)) {
    throw "No se creó el paquete local app-staging-web.tar.gz."
}

# ==========================
# Subida al VPS
# ==========================
Invoke-Step "Preparando carpeta temporal en VPS" {
    ssh $SshAlias "rm -rf $RemoteTempDir $RemoteArchive && mkdir -p $RemoteTempDir"
}

Invoke-Step "Subiendo paquete al VPS" {
    scp "$LocalArchive" "$SshAlias`:$RemoteArchive"
}

Invoke-Step "Publicando en app-staging" {
    ssh $SshAlias "set -e; sudo mkdir -p $RemotePublicDir; sudo rm -rf $RemotePublicDir/*; sudo tar -xzf $RemoteArchive -C $RemotePublicDir; sudo chown -R jean:www-data $RemotePublicDir; sudo chmod -R u+rwX,g+rwX,o+rX $RemotePublicDir; rm -rf $RemoteTempDir $RemoteArchive"
}

# ==========================
# Verificaciones remotas
# ==========================
Invoke-Step "Verificando archivos publicados en VPS" {
    ssh $SshAlias "test -f $RemotePublicDir/index.html && test -f $RemotePublicDir/main.dart.js && test -f $RemotePublicDir/firebase-messaging-sw.js && test -f $RemotePublicDir/deploy-version.txt"
}

Write-Host ""
Write-Host "==> Versión publicada en VPS"
ssh $SshAlias "cat $RemotePublicDir/deploy-version.txt"

Write-Host ""
Write-Host "==> Probando app-staging"
curl.exe -I $AppUrl

Write-Host ""
Write-Host "==> Probando service worker FCM"
curl.exe -I "$AppUrl/firebase-messaging-sw.js"

Write-Host ""
Write-Host "==> Verificando que main.dart.js contiene device-tokens"
ssh $SshAlias "grep -q 'device-tokens' $RemotePublicDir/main.dart.js && echo 'OK: main.dart.js contiene device-tokens'"

# ==========================
# Limpieza local
# ==========================
if (Test-Path $LocalArchive) {
    Write-Host ""
    Write-Host "==> Eliminando paquete local temporal"
    Remove-Item $LocalArchive -Force
}

Write-Host ""
Write-Host "==> Deploy Flutter Web staging completado correctamente"
Write-Host "==> URL: $AppUrl"