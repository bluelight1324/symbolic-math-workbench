; Inno Setup installer for mathdot
; Task 101 — rebranded installer (app is now called "mathdot")
; Supports Windows 7 SP1 and later

#define MyAppName "mathdot"
#define MyAppVersion "1.3.0"
#define MyAppPublisher "bluelight1324"
#define MyAppURL "https://github.com/bluelight1324/symbolic-math-workbench"
#define MyAppExeName "Godot.exe"
#define SourceDir "app"

[Setup]
; New AppId (distinct from the old "Symbolic Math Workbench" product) so the
; rebranded app installs cleanly side-by-side / as its own product.
AppId={{2D7B6E4A-1C3F-4A9E-8D2B-7F5A1C9E3B40}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=LICENSE.txt
OutputDir=.\installers
OutputBaseFilename=mathdot-{#MyAppVersion}-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\bin\{#MyAppExeName}
ArchitecturesInstallIn64BitMode=x64
MinVersion=0,6.1sp1

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Full installation"
Name: "compact"; Description: "Compact installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: "app"; Description: "mathdot (Godot + REDUCE)"; Types: full compact custom; Flags: fixed
Name: "samples"; Description: "Sample notebooks"; Types: full custom; Flags: checkablealone
Name: "docs"; Description: "Documentation and task guides"; Types: full custom; Flags: checkablealone

[Files]
; Project files. The bundled Godot runtime (installed below as bin\Godot.exe)
; runs this project directly; the .godot caches are shipped too (see task 102).
Source: "{#SourceDir}\project.godot"; DestDir: "{app}"; Components: app; Flags: ignoreversion
Source: "{#SourceDir}\scripts\*"; DestDir: "{app}\scripts"; Components: app; Flags: ignoreversion recursesubdirs
Source: "{#SourceDir}\scenes\*"; DestDir: "{app}\scenes"; Components: app; Flags: ignoreversion recursesubdirs
Source: "{#SourceDir}\autoload\*"; DestDir: "{app}\autoload"; Components: app; Flags: ignoreversion recursesubdirs
Source: "{#SourceDir}\icon.svg"; DestDir: "{app}"; Components: app; Flags: ignoreversion
; Task 268 — bundled math font (STIX Two Math, SIL OFL) loaded at runtime for
; guaranteed math-symbol coverage; ship its OFL licence alongside.
Source: "{#SourceDir}\fonts\*"; DestDir: "{app}\fonts"; Components: app; Flags: ignoreversion recursesubdirs

; Task 102 — ship the .godot script-class / import cache so the project's
; `class_name` types (NotebookView, IconMenuBar, ColorConfig, ...) and the
; MathEngine autoload resolve at runtime. A project RUN does NOT regenerate
; this cache, so WITHOUT it every class_name reference fails to compile and the
; app launches to a blank gray screen. The machine-specific editor/ subfolder
; (which holds absolute dev paths) is excluded.
Source: "{#SourceDir}\.godot\*"; DestDir: "{app}\.godot"; Excludes: "editor\*"; Components: app; Flags: ignoreversion recursesubdirs createallsubdirs

; REDUCE CAS binaries (from tools/reduce)
Source: "tools\reduce\bin\*"; DestDir: "{app}\reduce\bin"; Components: app; Flags: ignoreversion recursesubdirs
Source: "tools\reduce\lib\*"; DestDir: "{app}\reduce\lib"; Components: app; Flags: ignoreversion recursesubdirs

; Godot runtime (from tools/godot) — installed as bin\Godot.exe
Source: "tools\godot\Godot_v4.6.3-stable_win64.exe"; DestDir: "{app}\bin"; DestName: "Godot.exe"; Components: app; Flags: ignoreversion

; Sample notebooks (optional)
Source: "{#SourceDir}\notebooks_sample\*"; DestDir: "{userdocs}\{#MyAppName}\notebooks"; Components: samples; Flags: ignoreversion recursesubdirs

; Documentation
Source: "*.md"; DestDir: "{app}\docs"; Components: docs; Flags: ignoreversion
Source: "task*.md"; DestDir: "{app}\docs\tasks"; Components: docs; Flags: ignoreversion recursesubdirs
Source: "README.md"; DestDir: "{app}"; Components: docs; Flags: ignoreversion

; License
Source: "LICENSE.txt"; DestDir: "{app}"; Components: app; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\bin\Godot.exe"; Parameters: "--path ""{app}"" --run"; WorkingDir: "{app}"; IconIndex: 0
Name: "{group}\Open Sample Notebooks"; Filename: "{userdocs}\{#MyAppName}\notebooks"; Components: samples
Name: "{group}\Documentation"; Filename: "{app}\docs\README.md"; Components: docs
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\bin\Godot.exe"; Parameters: "--path ""{app}"" --run"; WorkingDir: "{app}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; OnlyBelowVersion: 6.1

[Run]
Filename: "{app}\bin\Godot.exe"; Parameters: "--path ""{app}"" --run"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: shellexec postinstall skipifsilent; WorkingDir: "{app}"

[InstallDelete]
; Task 102 — on upgrade, clear the old editor cache (machine-specific, never
; shipped) but KEEP the shipped script-class / import cache that we install.
Type: filesandordirs; Name: "{app}\.godot\editor"
; Clean up old files if upgrading
Type: files; Name: "{app}\*.cfg"
Type: dirifempty; Name: "{app}\scenes"
Type: dirifempty; Name: "{app}\scripts"

[UninstallDelete]
; Remove the (empty) user notebooks folder on uninstall if the user emptied it
Type: dirifempty; Name: "{userdocs}\{#MyAppName}"
