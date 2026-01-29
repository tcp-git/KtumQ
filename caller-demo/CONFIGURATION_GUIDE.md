# Configuration Management - Caller Application

## Overview
The Caller application uses the same configuration file format as the Dispenser application (`config.ini`). This allows both applications to share database and WebSocket settings.

## Configuration File Location
The configuration file is located at: `config.ini` (in the same directory as the executable)

## Configuration File Format
```ini
[Database]
Host=localhost
Port=3306
Username=root
Password=
DatabaseName=queue_system

[WebSocket]
ServerURL=localhost
Port=8080
```

## Features Implemented

### 1. Configuration Form (ConfigFormU)
- **Database Settings Panel**:
  - Host: Database server address
  - Port: Database server port (default: 3306)
  - Username: Database username
  - Password: Database password (masked input)
  - Database Name: Name of the database
  - Test Connection Button: Tests database connectivity

- **WebSocket Settings Panel**:
  - Server URL: WebSocket server address
  - Port: WebSocket server port (default: 8080)
  - Test Connection Button: Tests WebSocket connectivity

- **Action Buttons**:
  - Save: Saves configuration to config.ini
  - Cancel: Closes form without saving

### 2. Configuration Access
- Configuration button added to MainForm (top-right corner)
- Clicking the button opens the configuration form
- After saving configuration, the application automatically:
  - Closes existing connections
  - Reloads configuration from file
  - Reconnects to database and WebSocket
  - Updates connection status display

### 3. Configuration Persistence
- Configuration is saved to `config.ini` using INI file format
- Configuration is loaded automatically when:
  - Application starts (MainForm.FormCreate)
  - User saves new configuration (after clicking Save button)

### 4. Connection Testing
- Database connection can be tested before saving
- WebSocket connection can be tested before saving
- Test results are displayed in message boxes

## Requirements Validation

This implementation satisfies the following requirements:

- **Requirement 5.1**: Configuration form displays database connection fields (Host, Port, Username, Password, Database Name)
- **Requirement 5.2**: Configuration form displays WebSocket connection fields (Server URL, Port)
- **Requirement 5.3**: Test database connection button validates connectivity
- **Requirement 5.4**: Test WebSocket connection button validates connectivity
- **Requirement 5.5**: Configuration is persisted to local INI file

## Usage

1. Launch the Caller application
2. Click the "ตั้งค่า" (Configuration) button in the top-right corner
3. Enter or modify database and WebSocket settings
4. Click "ทดสอบ" (Test) buttons to verify connections
5. Click "บันทึก" (Save) to save configuration
6. Application will automatically reconnect with new settings

## Shared Configuration with Dispenser

Both Caller and Dispenser applications use the same `config.ini` file format. This means:
- You can copy the config.ini file between applications
- Both applications can run on the same machine and share configuration
- Changes made in one application's configuration will be available to the other

## Error Handling

- If config.ini doesn't exist, default values are used
- If database connection fails, error message is displayed
- If WebSocket connection fails, error message is displayed
- Application continues to function even if connections fail (with appropriate status indicators)
