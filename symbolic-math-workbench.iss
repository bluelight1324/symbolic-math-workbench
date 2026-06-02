; Inno Setup installer for Symbolic Math Workbench
; Generated for v1.1.0 release
; Supports Windows 7 SP1 and later

#define MyAppName "Symbolic Math Workbench"
#define MyAppVersion "1.1.0"
#define MyAppPublisher "bluelight1324"
#define MyAppURL "https://github.com/bluelight1324/symbolic-math-workbench"
#define MyAppExeName "Godot_v4.6.3-stable_win64.exe"
#define SourceDir "app"

[Setup]
AppId={{8A9F2C8B-4E5F-4D8A-9B7C-3F1E2D4A5B6C}
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
OutputBaseFilename=Symbolic-Math-Workbench-{#MyAppVersion}-Setup
; SetupIconFile=icon.ico  (commented out - icon.ico not provided)
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesInstallIn64BitMode=x64
MinVersion=0,6.1sp1

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Full installation"
Name: "compact"; Description: "Compact installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: "app"; Description: "Symbolic Math Workbench (Godot + REDUCE)"; Types: full compact custom; Flags: fixed
Name: "samples"; Description: "Sample notebooks"; Types: full custom; Flags: checkablealone
Name: "docs"; Description: "Documentation and task guides"; Types: full custom; Flags: checkablealone

[Files]
; Main executable and project files
Source: "{#SourceDir}\project.godot"; DestDir: "{app}"; Components: app; Flags: ignoreversion
Source: "{#SourceDir}\scripts\*"; DestDir: "{app}\scripts"; Components: app; Flags: ignoreversion recursesubdirs
Source: "{#SourceDir}\scenes\*"; DestDir: "{app}\scenes"; Components: app; Flags: ignoreversion recursesubdirs
Source: "{#SourceDir}\autoload\*"; DestDir: "{app}\autoload"; Components: app; Flags: ignoreversion recursesubdirs

; REDUCE CAS binaries (from tools/reduce)
Source: "tools\reduce\bin\*"; DestDir: "{app}\reduce\bin"; Components: app; Flags: ignoreversion recursesubdirs
Source: "tools\reduce\lib\*"; DestDir: "{app}\reduce\lib"; Components: app; Flags: ignoreversion recursesubdirs

; Godot executable (from tools/godot)
Source: "tools\godot\Godot_v4.6.3-stable_win64.exe"; DestDir: "{app}\bin"; DestName: "Godot.exe"; Components: app; Flags: ignoreversion

; Sample notebooks (optional)
Source: "{#SourceDir}\notebooks_sample\*"; DestDir: "{userdocs}\Symbolic Math Workbench\notebooks"; Components: samples; Flags: ignoreversion recursesubdirs

; Documentation
Source: "*.md"; DestDir: "{app}\docs"; Components: docs; Flags: ignoreversion
Source: "task*.md"; DestDir: "{app}\docs\tasks"; Components: docs; Flags: ignoreversion recursesubdirs
Source: "README.md"; DestDir: "{app}"; Components: docs; Flags: ignoreversion

; License
Source: "LICENSE.txt"; DestDir: "{app}"; Components: app; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\bin\Godot.exe"; Parameters: "--path ""{app}"" --run"; WorkingDir: "{app}"; IconIndex: 0
Name: "{group}\Open Sample Notebooks"; Filename: "{userdocs}\Symbolic Math Workbench\notebooks"; Components: samples
Name: "{group}\Documentation"; Filename: "{app}\docs\README.md"; Components: docs
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\bin\Godot.exe"; Parameters: "--path ""{app}"""; WorkingDir: "{app}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; OnlyBelowVersion: 6.1

[Run]
Filename: "{app}\bin\Godot.exe"; Parameters: "--path ""{app}"" --run"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: shellexec postinstall skipifsilent; WorkingDir: "{app}"

[InstallDelete]
; Clean up old files if upgrading
Type: files; Name: "{app}\*.cfg"
Type: dirifempty; Name: "{app}\scenes"
Type: dirifempty; Name: "{app}\scripts"

[UninstallDelete]
; Remove user data directories on uninstall (optional - user can keep them)
Type: dirifempty; Name: "{userdocs}\Symbolic Math Workbench"

; [Code] section removed - not required for basic installer
; Custom wizard text can be added in future versions if needed
