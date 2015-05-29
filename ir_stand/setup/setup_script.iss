; Script generated by the Inno Script Studio Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "IR Stand"
#define MyAppVersion "1.0.145"
#define MyAppPublisher "Belarusian State University of Informatics and Radioelectronics (BSUIR)"
#define MyAppURL "http://www.bsuir.by/"
#define MyAppExeName "ir_stand.m"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{9D908CF2-B9D9-4EE8-A28D-A64355184665}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\BSUIR\{#MyAppName}
DefaultGroupName=BSUIR\{#MyAppName}
AllowNoIcons=yes
OutputDir=.
OutputBaseFilename={#MyAppName}_setup_{#MyAppVersion}
SetupIconFile=bsuir_logo.ico
Compression=lzma
SolidCompression=yes

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\*.m"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\*.fig"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\*.mexw32"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\*.mexw64"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\ir_stand_config.xml"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\bsuir_logo.png"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\ir_stand_description.doc"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\sls\*"; DestDir: "{app}\sls"; Flags: ignoreversion recursesubdirs
Source: "..\icons\*"; DestDir: "{app}\icons"; Flags: ignoreversion recursesubdirs
Source: "..\xml_io_tools\*"; DestDir: "{app}\xml_io_tools"; Flags: ignoreversion recursesubdirs
Source: "bsuir_logo.ico"; DestDir: "{app}"; Flags: ignoreversion
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "matlab.exe"; WorkingDir: "{app}"; IconFilename: "{app}\bsuir_logo.ico"; IconIndex: 0; Parameters: "-nodisplay -nosplash -nodesktop -r ""uiwait(ir_stand);exit"""
Name: "{group}\������� �������� ��������� � ��������� ��������� {#MyAppName}"; Filename: "{app}\ir_stand_description.doc"
Name: "{commondesktop}\{#MyAppName}"; Filename: "matlab.exe"; WorkingDir: "{app}"; IconFilename: "{app}\bsuir_logo.ico"; IconIndex: 0; Parameters: "-nodisplay -nosplash -nodesktop -r ""uiwait(ir_stand);exit"""; Tasks: desktopicon

[Run]
Filename: "matlab.exe"; Parameters: "-nodisplay -nosplash -nodesktop -r ""uiwait(ir_stand());exit"""; WorkingDir: "{app}"; Flags: postinstall skipifsilent; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"
