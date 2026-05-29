$ErrorActionPreference = 'Stop'

$RootDir = Resolve-Path (Join-Path $PSScriptRoot '..')
$BuildRelease = Join-Path $RootDir 'build\windows\x64\runner\Release'
$ReleaseRoot = Join-Path $RootDir 'release'
$PackageDir = Join-Path $ReleaseRoot 'vela-windows'
$InstallerDir = Join-Path $ReleaseRoot 'vela-windows-installer'
$PubspecPath = Join-Path $RootDir 'pubspec.yaml'
$VersionLine = Select-String -Path $PubspecPath -Pattern '^version:\s*(.+)$' | Select-Object -First 1
if (-not $VersionLine) {
    throw "Could not read app version from $PubspecPath"
}
$AppVersion = ($VersionLine.Matches[0].Groups[1].Value -split '\+')[0]
$InstallerVersion = if ($env:VELA_RELEASE_VERSION) {
    ($env:VELA_RELEASE_VERSION).TrimStart('v', 'V')
}
else {
    $AppVersion
}
$InstallerBaseName = "vela-windows-v$InstallerVersion-setup"
$InstallerPath = Join-Path $ReleaseRoot "$InstallerBaseName.exe"

function Resolve-InnoSetupCompiler {
    $Command = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
    if ($Command) {
        return $Command.Source
    }

    $Candidates = @(
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
        (Join-Path ${env:ProgramFiles} 'Inno Setup 6\ISCC.exe')
    )

    foreach ($Candidate in $Candidates) {
        if ($Candidate -and (Test-Path $Candidate -PathType Leaf)) {
            return $Candidate
        }
    }

    throw 'Inno Setup 6 was not found. Install it on Windows, for example with: winget install JRSoftware.InnoSetup'
}

Push-Location $RootDir
try {
    flutter pub get
    dart run scripts/verify_version_sync.dart
    flutter build windows

    if (-not (Test-Path $BuildRelease -PathType Container)) {
        throw "Expected Windows release folder not found: $BuildRelease"
    }

    if (Test-Path $PackageDir) {
        Remove-Item $PackageDir -Recurse -Force
    }

    New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null
    Copy-Item -Path (Join-Path $BuildRelease '*') -Destination $PackageDir -Recurse -Force

    if (Test-Path $InstallerDir) {
        Remove-Item $InstallerDir -Recurse -Force
    }

    New-Item -ItemType Directory -Path $InstallerDir -Force | Out-Null

    if (Test-Path $InstallerPath) {
        Remove-Item $InstallerPath -Force
    }

    $SetupScript = Join-Path $InstallerDir 'vela.iss'
    $EscapedBuildRelease = $BuildRelease -replace '\\', '\\'
    $EscapedReleaseRoot = $ReleaseRoot -replace '\\', '\\'

    @"
#define MyAppName "Vela"
#define MyAppVersion "$AppVersion"
#define MyAppPublisher "Vela"
#define MyAppExeName "vela.exe"

[Setup]
AppId={{81E24D76-145B-4AA1-A4DC-2871AE31A2AD}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Vela
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=$EscapedReleaseRoot
OutputBaseFilename=$InstallerBaseName
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
Source: "$EscapedBuildRelease\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
"@ | Set-Content -Path $SetupScript -Encoding UTF8

    $Iscc = Resolve-InnoSetupCompiler
    & $Iscc $SetupScript

    if (-not (Test-Path $InstallerPath -PathType Leaf)) {
        throw "Expected Windows installer was not created: $InstallerPath"
    }

    Write-Host "Created $InstallerPath"
}
finally {
    Pop-Location
}
