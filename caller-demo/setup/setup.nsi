; Caller Application Installer
; NSIS Script for Production Deployment

;--------------------------------
; Include Modern UI
!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "Sections.nsh"

;--------------------------------
; General Settings
Name "Caller Queue Management System"
OutFile "CallerSetup.exe"
Unicode True

; Default installation directory
InstallDir "$PROGRAMFILES\Caller"

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\Caller" "Install_Dir"

; Request application privileges for Windows Vista/7/8/10/11
RequestExecutionLevel admin

; Compression
SetCompressor /SOLID lzma

;--------------------------------
; Version Information
VIProductVersion "1.0.0.0"
VIAddVersionKey "ProductName" "Caller Queue Management System"
VIAddVersionKey "CompanyName" "TCP{CODE}"
VIAddVersionKey "FileDescription" "Queue Management Caller Application"
VIAddVersionKey "FileVersion" "1.0.0.0"
VIAddVersionKey "ProductVersion" "1.0.0.0"
VIAddVersionKey "LegalCopyright" "© 2024 TCP{CODE}"

;--------------------------------
; Interface Settings
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

;--------------------------------
; Pages
!insertmacro MUI_PAGE_WELCOME

!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\Caller.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch Caller Queue Management System"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
; Languages
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Thai"

;--------------------------------
; Installer Sections

Section "Caller Application (required)" SecMain
  SectionIn RO
  
  ; Set output path to the installation directory
  SetOutPath $INSTDIR
  
  ; Main application files
  File "..\Win32\Debug\Caller.exe"
  File "..\config.ini.template"

  
  ; Report template files
  File "..\Win32\Debug\*.rtm"
  
  ; Check if config.ini exists, if not copy from template
  IfFileExists "$INSTDIR\config.ini" config_exists
    CopyFiles "$INSTDIR\config.ini.template" "$INSTDIR\config.ini"
  config_exists:
  
  ; Set write permissions on config.ini for Users group
  ; This allows the application to write to config.ini without admin rights
  DetailPrint "Setting write permissions for config.ini..."
  ; First, set directory permissions so new files inherit proper permissions
  ; (OI) = Object Inherit, (CI) = Container Inherit, M = Modify
  ExecWait 'icacls "$INSTDIR" /grant "Users:(OI)(CI)M"' $0
  ; Then, explicitly grant modify permissions to Users group on config.ini
  ; M = Modify permission (allows read, write, delete)
  ExecWait 'icacls "$INSTDIR\config.ini" /grant "Users:M"' $0
  
  ; Create application data directory
  CreateDirectory "$APPDATA\Caller"
  CreateDirectory "$APPDATA\Caller\Logs"
  CreateDirectory "$APPDATA\Caller\Reports"
  
  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\Caller "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Caller" "DisplayName" "Caller Queue Management System"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Caller" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Caller" "DisplayIcon" "$INSTDIR\Caller.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Caller" "Publisher" "TCP{CODE}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Caller" "DisplayVersion" "1.0.0"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Caller" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Caller" "NoRepair" 1
  
  ; Get installation size
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Caller" "EstimatedSize" "$0"
  
  WriteUninstaller "uninstall.exe"
SectionEnd

Section "Desktop Shortcut" SecDesktop
  CreateShortcut "$DESKTOP\Caller.lnk" "$INSTDIR\Caller.exe" "" "$INSTDIR\Caller.exe" 0
SectionEnd

Section "Start Menu Shortcuts" SecStartMenu
  CreateDirectory "$SMPROGRAMS\Caller"
  CreateShortcut "$SMPROGRAMS\Caller\Caller.lnk" "$INSTDIR\Caller.exe" "" "$INSTDIR\Caller.exe" 0
  CreateShortcut "$SMPROGRAMS\Caller\Configuration.lnk" "$INSTDIR\config.ini" "" "" 0
  CreateShortcut "$SMPROGRAMS\Caller\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortcut "$SMPROGRAMS\Caller\README.lnk" "$INSTDIR\README.md" "" "" 0
SectionEnd

Section "Auto Start with Windows" SecAutoStart
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "Caller" "$INSTDIR\Caller.exe"
SectionEnd

Section "Visual C++ Redistributable" SecVCRedist
  ; Check if Visual C++ Redistributable 2015-2022 is already installed
  ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86" "Installed"
  IntCmp $0 1 vcredist_installed
  
  DetailPrint "Checking and installing Visual C++ Redistributable 2015-2022..."
  SetOutPath "$TEMP"
  File "vc_redist.x86.exe"
  ExecWait "$TEMP\vc_redist.x86.exe /quiet /norestart"
  Delete "$TEMP\vc_redist.x86.exe"
  
  vcredist_installed:
SectionEnd

;--------------------------------
; Section Descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecMain} "Main application files (required)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} "Create desktop shortcut"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecStartMenu} "Create Start Menu shortcuts"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecAutoStart} "Start application automatically with Windows"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecVCRedist} "Install Visual C++ Redistributable (required for some components)"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
; Installer Functions

Function .onInit
  ; Check if application is already running
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "CallerInstaller") i .r1 ?e'
  Pop $R0
  StrCmp $R0 0 +3
    MessageBox MB_OK|MB_ICONEXCLAMATION "The installer is already running"
    Abort
    
  ; Check for existing installation
  ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Caller" "UninstallString"
  StrCmp $R0 "" done
  
  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \
  "Caller is already installed. $\n$\nClick `OK` to uninstall the old version or `Cancel` to abort this installation." \
  IDOK uninst
  Abort
  
  uninst:
    ClearErrors
    ExecWait '$R0 _?=$INSTDIR'
    
    IfErrors no_remove_uninstaller done
      Delete $R0
      RMDir $INSTDIR
    no_remove_uninstaller:
  
  done:
    ; Check if VC++ Redist is already installed, then automatically deselect the Section
    ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86" "Installed"
    IntCmp $0 1 0 +2
      !insertmacro UnselectSection ${SecVCRedist}
FunctionEnd

Function .onInstSuccess
  ; Create token file for production deployment
  FileOpen $0 "$INSTDIR\production.token" w
  FileWrite $0 "PRODUCTION_DEPLOYMENT"
  FileClose $0
  
  ; Set file attributes to hidden
  SetFileAttributes "$INSTDIR\production.token" HIDDEN
FunctionEnd

;--------------------------------
; Uninstaller Section

Section "Uninstall"
  ; Check if application is running
  FindWindow $0 "" "Caller Queue Management System"
  StrCmp $0 0 notRunning
    MessageBox MB_OK|MB_ICONSTOP "Caller is currently running. Please close the application first."
    Abort
  notRunning:
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Caller"
  DeleteRegKey HKLM SOFTWARE\Caller
  DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "Caller"
  
  ; Remove files and uninstaller
  Delete $INSTDIR\Caller.exe
  Delete $INSTDIR\config.ini.template
  Delete $INSTDIR\README.md
  Delete $INSTDIR\production.token
  Delete $INSTDIR\uninstall.exe
  
  ; Remove report template files
  Delete $INSTDIR\*.rtm
  
  ; Ask user if they want to keep configuration and logs
  MessageBox MB_YESNO "Do you want to keep configuration files and logs?" IDYES KeepConfig
    Delete $INSTDIR\config.ini
    RMDir /r "$APPDATA\Caller"
  KeepConfig:
  
  ; Remove shortcuts
  Delete "$DESKTOP\Caller.lnk"
  Delete "$SMPROGRAMS\Caller\*.*"
  RMDir "$SMPROGRAMS\Caller"
  
  ; Remove installation directory and all its contents
  RMDir /r "$INSTDIR"
SectionEnd

;--------------------------------
; Uninstaller Functions

Function un.onInit
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure you want to completely remove Caller and all of its components?" IDYES +2
  Abort
FunctionEnd

Function un.onUninstSuccess
  HideWindow
  MessageBox MB_ICONINFORMATION|MB_OK "Caller has been successfully removed from your computer."
FunctionEnd

;--------------------------------
; Custom Functions