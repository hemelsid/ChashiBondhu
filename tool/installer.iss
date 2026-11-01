; Inno Setup script for the PC (Windows) version of চাষিবন্ধু.
; Built in CI:  ISCC.exe /DAppVersion=0.3.N tool\installer.iss
; Installs for the current user only (no admin needed).

#ifndef AppVersion
  #define AppVersion "0.3.0"
#endif

[Setup]
AppId={{6C2B1E7A-3F4D-4E8B-9A51-C0A11B0D7F21}
AppName=চাষিবন্ধু
AppVersion={#AppVersion}
AppVerName=চাষিবন্ধু {#AppVersion}
AppPublisher=hemelsid
AppPublisherURL=https://github.com/hemelsid/ChashiBondhu
DefaultDirName={localappdata}\Programs\Chashibondhu
DefaultGroupName=চাষিবন্ধু
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\out
OutputBaseFilename=Chashibondhu-Windows-Setup
SetupIconFile=..\branding\windows\app_icon.ico
UninstallDisplayIcon={app}\chashibondhu.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Tasks]
Name: "desktopicon"; Description: "ডেস্কটপে আইকন রাখুন"; Flags: checkedonce

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\চাষিবন্ধু"; Filename: "{app}\chashibondhu.exe"
Name: "{userdesktop}\চাষিবন্ধু"; Filename: "{app}\chashibondhu.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\chashibondhu.exe"; Description: "চাষিবন্ধু চালু করুন"; Flags: nowait postinstall skipifsilent
