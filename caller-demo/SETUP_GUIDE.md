# Caller Application Setup Guide

## Overview
This guide explains how to create a production installer for the Caller Queue Management System.

## Setup Directory Structure

The `setup/` directory contains all necessary files for creating a Windows installer:

```
caller_new/setup/
├── setup.nsi              - NSIS installer script
├── build_installer.bat    - Windows batch build script
├── build_installer.ps1    - PowerShell build script
├── LICENSE.txt            - Software license agreement
├── vc_redist.x86.exe      - Visual C++ Redistributable
└── INSTALLER_README.md    - Detailed installer documentation
```

## Quick Start

1. **Build the Delphi Project**
   ```
   - Open Caller.dproj in Delphi
   - Build the project (Ctrl+F9)
   - Ensure Caller.exe is created in Win32\Debug\
   ```

2. **Install NSIS**
   - Download from: https://nsis.sourceforge.io/Download
   - Install and ensure makensis.exe is in your PATH

3. **Create the Installer**
   ```cmd
   cd setup
   build_installer.bat
   ```
   
   Or using PowerShell:
   ```powershell
   cd setup
   .\build_installer.ps1
   ```

## Installer Features

- **Complete Installation**: Installs Caller.exe, configuration template, and documentation
- **Smart Upgrades**: Detects existing installations and preserves user settings
- **Optional Components**: Desktop shortcuts, Start Menu entries, auto-start
- **Dependencies**: Includes Visual C++ Redistributable
- **Clean Uninstall**: Removes all components with option to preserve user data

## Output

The build process creates `CallerSetup.exe` - a self-contained installer ready for distribution.

## Customization

Edit `setup/setup.nsi` to customize:
- Company information
- Version numbers
- Installation paths
- Component descriptions

## Testing

Always test the installer on a clean system before distribution:
1. Install the application
2. Verify all components work correctly
3. Test the uninstaller
4. Check that user configurations are preserved during upgrades

## Distribution

The `CallerSetup.exe` file is completely self-contained and can be distributed via:
- Web download
- Email attachment
- USB drive
- Network share

For more detailed information, see `setup/INSTALLER_README.md`.