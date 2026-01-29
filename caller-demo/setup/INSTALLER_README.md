# Caller Installer Setup

This directory contains the NSIS installer script and build tools for creating a production-ready installer for the Caller Queue Management System.

## Files Created

- `setup.nsi` - Main NSIS installer script
- `LICENSE.txt` - Software license agreement
- `build_installer.bat` - Windows batch script to build installer
- `build_installer.ps1` - PowerShell script to build installer
- `INSTALLER_README.md` - This documentation file

## Prerequisites

1. **NSIS (Nullsoft Scriptable Install System)**
   - Download from: https://nsis.sourceforge.io/Download
   - Install and ensure `makensis.exe` is in your PATH

2. **Built Application**
   - Ensure `Caller.exe` exists in `Win32\Debug\` directory
   - Build your Delphi project first before creating installer

## Building the Installer

### Method 1: Using Batch Script
```cmd
build_installer.bat
```

### Method 2: Using PowerShell
```powershell
.\build_installer.ps1
```

### Method 3: Manual NSIS Compilation
```cmd
makensis setup.nsi
```

## Installer Features

### Core Installation
- Installs main application (`Caller.exe`)
- Creates configuration template (`config.ini.template`)
- Copies documentation (`README.md`)
- Creates application data directories
- Registers application in Windows registry

### Optional Components
- **Desktop Shortcut** - Creates desktop shortcut
- **Start Menu Shortcuts** - Creates Start Menu folder with shortcuts
- **Auto Start** - Starts application with Windows
- **Visual C++ Redistributable** - Installs required runtime (if needed)

### Production Token
- Creates hidden `production.token` file with timestamp
- Indicates production deployment status
- Used for licensing and deployment tracking

### Smart Installation
- Detects existing installations and offers upgrade
- Preserves user configuration during upgrades
- Checks for running application before installation
- Validates system requirements

## Installer Output

The build process creates `CallerSetup.exe` - a self-contained installer that includes:
- Application executable
- Configuration templates
- Documentation
- Uninstaller
- Registry entries
- Shortcuts

## Uninstaller Features

- Detects running application
- Removes all installed files
- Cleans registry entries
- Offers to preserve user configuration
- Removes shortcuts and Start Menu entries

## Customization

### Company Information
Edit these sections in `setup.nsi`:
```nsis
VIAddVersionKey "CompanyName" "Your Company Name"
VIAddVersionKey "LegalCopyright" "© 2024 Your Company Name"
```

### Version Information
Update version numbers:
```nsis
VIProductVersion "1.0.0.0"
WriteRegStr HKLM "..." "DisplayVersion" "1.0.0"
```

### Installation Directory
Change default installation path:
```nsis
InstallDir "$PROGRAMFILES\Caller"
```

## Deployment Notes

1. **Test Installation**
   - Always test the installer on a clean system
   - Verify all components install correctly
   - Test uninstallation process

2. **Digital Signing** (Recommended)
   - Sign the installer with a code signing certificate
   - Prevents Windows security warnings
   - Builds user trust

3. **Distribution**
   - The installer is self-contained
   - No additional files needed for distribution
   - Can be distributed via web, email, or physical media

## Troubleshooting

### Common Issues

1. **"makensis not found"**
   - Install NSIS and add to PATH
   - Restart command prompt after installation

2. **"Caller.exe not found"**
   - Build the Delphi project first
   - Ensure output is in `Win32\Debug\` directory

3. **Permission Errors**
   - Run build script as Administrator
   - Check file permissions

### Build Logs
- NSIS provides detailed compilation logs
- Check for warnings or errors during build
- Verify all files are included correctly

## Security Considerations

- The installer requires Administrator privileges
- Creates registry entries in HKLM
- Installs to Program Files (protected directory)
- Production token helps track legitimate installations

## Application-Specific Notes

### Caller Application Features
- Queue calling and management system
- WebSocket connectivity for real-time updates
- MySQL database integration via UniDAC
- Multi-language support (English/Thai)
- Auto-reconnect functionality

### Configuration Requirements
- MySQL database connection settings
- WebSocket server configuration
- Service channel assignments
- Queue type management settings

### Dependencies
- UniDAC components for MySQL connectivity
- sgcWebSocket components for real-time communication
- Visual C++ Redistributable (included in installer)

## Integration with Queue System

The Caller application integrates with:
- **Database**: MySQL queue management database
- **WebSocket Server**: Real-time communication server
- **Dispenser Application**: Queue dispensing counterpart
- **Terminal Display**: Queue status display system

Ensure all system components are properly configured before deployment.