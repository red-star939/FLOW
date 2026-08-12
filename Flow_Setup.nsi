Unicode true

; FLOW NSIS Installer Script
; Auto-extract, Desktop & Start Menu Shortcuts, Registry Uninstaller

!define PRODUCT_NAME "FLOW"
!define PRODUCT_VERSION "1.4"
!define PRODUCT_PUBLISHER "HONG_ST"
!define PRODUCT_WEB_SITE "https://github.com/red-star939/FLOW"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\launcher.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\"

SetCompressor /SOLID lzma

!include "MUI2.nsh"

!define MUI_ABORTWARNING
!define MUI_ICON "flowicon\flowicon.ico"
!define MUI_UNICON "flowicon\flowicon.ico"

; Installer Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\launcher.exe"
!define MUI_FINISHPAGE_RUN_TEXT "FLOW 바로 실행하기"
!insertmacro MUI_PAGE_FINISH

; Uninstaller Pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "Korean"
!insertmacro MUI_LANGUAGE "English"

Name "${PRODUCT_NAME} v${PRODUCT_VERSION}"
OutFile "Flow_Setup_v1.4.exe"
InstallDir "$LOCALAPPDATA\Programs\FLOW"
ShowInstDetails show
ShowUnInstDetails show

Section "MainSection" SEC01
  SetOutPath "$INSTDIR"
  SetOverwrite ifnewer
  File /r "dist\*.*"

  ; Create Shortcuts
  CreateDirectory "$SMPROGRAMS\FLOW"
  CreateShortCut "$SMPROGRAMS\FLOW\FLOW.lnk" "$INSTDIR\launcher.exe" "" "$INSTDIR\flowicon\flowicon.ico"
  CreateShortCut "$DESKTOP\FLOW.lnk" "$INSTDIR\launcher.exe" "" "$INSTDIR\flowicon\flowicon.ico"
SectionEnd

Section -Post
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\launcher.exe"
  WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "DisplayName" "FLOW (개인 가계부 프로그램)"
  WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\flowicon\flowicon.ico"
  WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
SectionEnd

Section Uninstall
  Delete "$DESKTOP\FLOW.lnk"
  RMDir /r "$SMPROGRAMS\FLOW"

  RMDir /r "$INSTDIR\flowicon"
  RMDir /r "$INSTDIR\plugins"
  RMDir /r "$INSTDIR\qml"
  RMDir /r "$INSTDIR\tls"
  Delete "$INSTDIR\*.dll"
  Delete "$INSTDIR\Flow.exe"
  Delete "$INSTDIR\launcher.exe"
  Delete "$INSTDIR\updater.exe"
  Delete "$INSTDIR\version.json"
  Delete "$INSTDIR\Uninstall.exe"

  RMDir "$INSTDIR"

  DeleteRegKey HKCU "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKCU "${PRODUCT_DIR_REGKEY}"
SectionEnd