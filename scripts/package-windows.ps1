$ErrorActionPreference = 'Stop'

$RootDir = Resolve-Path (Join-Path $PSScriptRoot '..')
$BuildRelease = Join-Path $RootDir 'build\windows\x64\runner\Release'
$ReleaseRoot = Join-Path $RootDir 'release'
$PackageDir = Join-Path $ReleaseRoot 'vela-windows'
$ZipPath = Join-Path $ReleaseRoot 'vela-windows.zip'

Push-Location $RootDir
try {
    flutter pub get
    flutter build windows

    if (-not (Test-Path $BuildRelease -PathType Container)) {
        throw "Expected Windows release folder not found: $BuildRelease"
    }

    if (Test-Path $PackageDir) {
        Remove-Item $PackageDir -Recurse -Force
    }

    New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null
    Copy-Item -Path (Join-Path $BuildRelease '*') -Destination $PackageDir -Recurse -Force

    if (Test-Path $ZipPath) {
        Remove-Item $ZipPath -Force
    }

    Compress-Archive -Path (Join-Path $PackageDir '*') -DestinationPath $ZipPath -Force
    Write-Host "Created $ZipPath"
}
finally {
    Pop-Location
}
