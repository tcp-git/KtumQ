object frmSettings: TfrmSettings
  Left = 0
  Top = 0
  Caption = 'Connection Settings'
  ClientHeight = 480
  ClientWidth = 500
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 500
    Height = 422
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object lblStatus: TLabel
      Left = 10
      Top = 360
      Width = 36
      Height = 13
      Caption = 'Ready'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGreen
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object gbDatabase: TGroupBox
      Left = 10
      Top = 10
      Width = 480
      Height = 180
      Caption = 'Database Settings'
      TabOrder = 0
      object lblServer: TLabel
        Left = 15
        Top = 25
        Width = 32
        Height = 13
        Caption = 'Server'
      end
      object lblPort: TLabel
        Left = 250
        Top = 25
        Width = 20
        Height = 13
        Caption = 'Port'
      end
      object lblDatabase: TLabel
        Left = 15
        Top = 55
        Width = 46
        Height = 13
        Caption = 'Database'
      end
      object lblUsername: TLabel
        Left = 15
        Top = 85
        Width = 48
        Height = 13
        Caption = 'Username'
      end
      object lblPassword: TLabel
        Left = 250
        Top = 85
        Width = 46
        Height = 13
        Caption = 'Password'
      end
      object lblTimeout: TLabel
        Left = 15
        Top = 115
        Width = 95
        Height = 13
        Caption = 'Connection Timeout'
      end
      object edtServer: TEdit
        Left = 70
        Top = 22
        Width = 150
        Height = 21
        TabOrder = 0
        Text = 'localhost'
      end
      object edtPort: TEdit
        Left = 280
        Top = 22
        Width = 80
        Height = 21
        TabOrder = 1
        Text = '3307'
      end
      object edtDatabase: TEdit
        Left = 70
        Top = 52
        Width = 150
        Height = 21
        TabOrder = 2
        Text = 'queue_system'
      end
      object edtUsername: TEdit
        Left = 70
        Top = 82
        Width = 150
        Height = 21
        TabOrder = 3
        Text = 'root'
      end
      object edtPassword: TEdit
        Left = 305
        Top = 82
        Width = 150
        Height = 21
        PasswordChar = '*'
        TabOrder = 4
        Text = 'saas'
      end
      object edtTimeout: TEdit
        Left = 120
        Top = 112
        Width = 80
        Height = 21
        TabOrder = 5
        Text = '30'
      end
      object btnTestDB: TButton
        Left = 380
        Top = 140
        Width = 75
        Height = 25
        Caption = 'Test DB'
        TabOrder = 6
        OnClick = btnTestDBClick
      end
    end
    object gbWebSocket: TGroupBox
      Left = 10
      Top = 200
      Width = 480
      Height = 150
      Caption = 'WebSocket Settings'
      TabOrder = 1
      object lblServerIP: TLabel
        Left = 15
        Top = 25
        Width = 45
        Height = 13
        Caption = 'Server IP'
      end
      object lblServerPort: TLabel
        Left = 250
        Top = 25
        Width = 55
        Height = 13
        Caption = 'Server Port'
      end
      object lblAutoReconnect: TLabel
        Left = 15
        Top = 55
        Width = 77
        Height = 13
        Caption = 'Auto Reconnect'
      end
      object lblReconnectInterval: TLabel
        Left = 250
        Top = 55
        Width = 92
        Height = 13
        Caption = 'Reconnect Interval'
      end
      object edtServerIP: TEdit
        Left = 70
        Top = 22
        Width = 150
        Height = 21
        TabOrder = 0
        Text = '0.0.0.0'
      end
      object edtServerPort: TEdit
        Left = 315
        Top = 22
        Width = 80
        Height = 21
        TabOrder = 1
        Text = '8081'
      end
      object chkAutoReconnect: TCheckBox
        Left = 100
        Top = 54
        Width = 97
        Height = 17
        Caption = 'Enabled'
        Checked = True
        State = cbChecked
        TabOrder = 2
      end
      object edtReconnectInterval: TEdit
        Left = 355
        Top = 52
        Width = 80
        Height = 21
        TabOrder = 3
        Text = '5000'
      end
      object btnTestWS: TButton
        Left = 380
        Top = 115
        Width = 75
        Height = 25
        Caption = 'Test WS'
        TabOrder = 4
        OnClick = btnTestWSClick
      end
    end
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 422
    Width = 500
    Height = 58
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnOK: TButton
      Left = 250
      Top = 10
      Width = 75
      Height = 30
      Caption = 'OK'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 335
      Top = 10
      Width = 75
      Height = 30
      Cancel = True
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = btnCancelClick
    end
    object btnReset: TButton
      Left = 169
      Top = 10
      Width = 75
      Height = 30
      Caption = 'Reset'
      TabOrder = 2
      OnClick = btnResetClick
    end
  end
end
