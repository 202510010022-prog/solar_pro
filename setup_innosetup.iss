[Setup]
AppName=SolarPro
AppVersion=1.0.0
AppPublisher=Solar Manager
AppPublisherURL=
AppSupportURL=
AppUpdatesURL=
DefaultDirName={autopf}\SolarPro
DefaultGroupName=SolarPro
OutputDir=installers
OutputBaseFilename=SolarPro_Setup_1.0.0
Compression=lzma
SolidCompression=yes
PrivilegesRequired=lowest
ChangesAssociations=no

[Languages]
Name: "portuguesebr"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 0,6.1

[Files]
Source: "dist\SolarPro.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\_internal\*"; DestDir: "{app}\_internal"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "dist\*.dll"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autopf}\SolarPro\SolarPro"; Filename: "{app}\SolarPro.exe"
Name: "{autodesktop}\SolarPro"; Filename: "{app}\SolarPro.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\SolarPro"; Filename: "{app}\SolarPro.exe"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\SolarPro.exe"; Description: "{cm:LaunchProgram,SolarPro}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: dirifempty; Name: "{app}"
