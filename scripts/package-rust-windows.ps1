param([switch]$SkipBuild)
$ErrorActionPreference = 'Stop'
$RootDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ReleaseRoot = Join-Path $RootDir 'release'
$PackageDir = Join-Path $ReleaseRoot 'rust-windows'
$Manifest = Join-Path $RootDir 'rust\Cargo.toml'

function Assert-NativeSuccess([string]$Action) {
    if ($LASTEXITCODE -ne 0) { throw "$Action failed (exit $LASTEXITCODE)" }
}
function Resolve-InnoSetupCompiler {
    $Command = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
    if ($Command) { return $Command.Source }
    foreach ($Base in @(${env:ProgramFiles(x86)}, ${env:ProgramFiles})) {
        if ($Base) {
            $Candidate = Join-Path $Base 'Inno Setup 6\ISCC.exe'
            if (Test-Path $Candidate -PathType Leaf) { return $Candidate }
        }
    }
    throw 'Install Inno Setup 6 (ISCC.exe) to create the Windows installer.'
}
Push-Location $RootDir
try {
    $MetadataText = & cargo metadata --locked --no-deps --format-version 1 --manifest-path $Manifest
    Assert-NativeSuccess 'cargo metadata'
    $Metadata = $MetadataText | ConvertFrom-Json
    $Version = ($Metadata.packages | Where-Object { $_.name -eq 'vela-desktop' }).version
    if (-not $Version -or $Version -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid Rust package version' }
    if (-not $SkipBuild) {
        & rustup target add x86_64-pc-windows-msvc
        Assert-NativeSuccess 'rustup target add'
        # Bundle a self-contained MSVC application; do not require a separate VC runtime installer.
        $PreviousRustFlags = $env:RUSTFLAGS
        try {
            $env:RUSTFLAGS = "$PreviousRustFlags -C target-feature=+crt-static".Trim()
            & cargo build --manifest-path $Manifest --locked --release --target x86_64-pc-windows-msvc -p vela-desktop
            Assert-NativeSuccess 'Rust Windows build'
        } finally { $env:RUSTFLAGS = $PreviousRustFlags }
    }
    if (Test-Path $PackageDir) { Remove-Item $PackageDir -Recurse -Force }
    New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null
    Copy-Item (Join-Path $RootDir 'rust\target\x86_64-pc-windows-msvc\release\vela.exe') (Join-Path $PackageDir 'vela.exe')
    & python (Join-Path $RootDir 'rust\packaging\runtime.py') windows --destination $PackageDir
    Assert-NativeSuccess 'Windows runtime preparation'
    Copy-Item (Join-Path $RootDir 'rust\packaging\licenses') (Join-Path $PackageDir 'licenses') -Recurse
    & python (Join-Path $RootDir 'rust\packaging\notices.py') --destination (Join-Path $PackageDir 'licenses') --target x86_64-pc-windows-msvc
    Assert-NativeSuccess 'Cargo and font notice collection'
    Copy-Item (Join-Path $RootDir 'rust\packaging\THIRD_PARTY.md') $PackageDir
    Copy-Item (Join-Path $RootDir 'rust\packaging\runtime-lock.json') $PackageDir
    Copy-Item (Join-Path $RootDir 'rust\packaging\vela.ico') $PackageDir

    $PreviousMpv = $env:VELA_MPV_LIBRARY
    try {
        $env:VELA_MPV_LIBRARY = Join-Path $PackageDir 'libmpv-2.dll'
        & cargo test --manifest-path $Manifest --locked -p vela-player --test runtime -- --ignored
        Assert-NativeSuccess 'Packaged Windows libmpv smoke test'
    } finally { $env:VELA_MPV_LIBRARY = $PreviousMpv }

    $InstallerName = "vela-windows-v$Version-setup"
    $InstallerPath = Join-Path $ReleaseRoot "$InstallerName.exe"
    $SetupScript = Join-Path $ReleaseRoot 'rust-windows-installer.iss'
    @"
#define MyAppName "Vela"
#define MyAppVersion "$Version"
[Setup]
AppId={{81E24D76-145B-4AA1-A4DC-2871AE31A2AD}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=Vela
DefaultDirName={autopf}\Vela
DefaultGroupName=Vela
DisableProgramGroupPage=yes
OutputDir=$ReleaseRoot
OutputBaseFilename=$InstallerName
SetupIconFile=$RootDir\rust\packaging\vela.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\vela.ico
CloseApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
Source: "$PackageDir\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[InstallDelete]
Type: filesandordirs; Name: "{app}\data"
Type: files; Name: "{app}\flutter_windows.dll"
Type: files; Name: "{app}\file_selector_windows_plugin.dll"
Type: files; Name: "{app}\media_kit_video_plugin.dll"
Type: files; Name: "{app}\media_kit_libs_windows_video_plugin.dll"
Type: files; Name: "{app}\screen_retriever_windows_plugin.dll"
Type: files; Name: "{app}\window_manager_plugin.dll"
Type: files; Name: "{app}\url_launcher_windows_plugin.dll"
Type: files; Name: "{app}\libEGL.dll"
Type: files; Name: "{app}\libGLESv2.dll"
Type: files; Name: "{app}\vk_swiftshader.dll"
Type: files; Name: "{app}\vulkan-1.dll"
Type: files; Name: "{app}\d3dcompiler_47.dll"

[Icons]
Name: "{group}\Vela"; Filename: "{app}\vela.exe"; IconFilename: "{app}\vela.ico"
Name: "{autodesktop}\Vela"; Filename: "{app}\vela.exe"; IconFilename: "{app}\vela.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\vela.exe"; Description: "Launch Vela"; Flags: nowait postinstall skipifsilent
"@ | Set-Content -Path $SetupScript -Encoding UTF8
    & (Resolve-InnoSetupCompiler) $SetupScript
    Assert-NativeSuccess 'Inno Setup installer build'
    if (-not (Test-Path $InstallerPath -PathType Leaf)) { throw 'Installer output was not created' }
    $Hash = (Get-FileHash $InstallerPath -Algorithm SHA256).Hash.ToLowerInvariant()
    "$Hash  $InstallerName.exe" | Set-Content (Join-Path $ReleaseRoot "SHA256SUMS-windows-v$Version.txt") -Encoding ascii
    Write-Host "Created $InstallerPath"
} finally { Pop-Location }
