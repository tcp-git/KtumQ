object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Caller'
  ClientHeight = 524
  ClientWidth = 286
  Color = clWhite
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Kanit'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 16
  object lblServiceCounter: TLabel
    Left = 11
    Top = 7
    Width = 70
    Height = 22
    Caption = #3594#3656#3629#3591#3610#3619#3636#3585#3634#3619':'
    Font.Charset = ANSI_CHARSET
    Font.Color = 8404992
    Font.Height = -15
    Font.Name = 'Kanit Light'
    Font.Style = []
    ParentFont = False
  end
  object lblSelectedCounter: TLabel
    Left = 11
    Top = 26
    Width = 82
    Height = 19
    Caption = #3594#3656#3629#3591': '#3618#3633#3591#3652#3617#3656#3648#3621#3639#3629#3585
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlue
    Font.Height = -13
    Font.Name = 'Kanit ExtraLight'
    Font.Style = []
    ParentFont = False
  end
  object lblBarcodeInput: TLabel
    Left = 8
    Top = 48
    Width = 108
    Height = 29
    Caption = #3626#3649#3585#3609#3648#3619#3637#3618#3585#3588#3636#3623':'
    Font.Charset = ANSI_CHARSET
    Font.Color = 5395026
    Font.Height = -19
    Font.Name = 'Kanit'
    Font.Style = []
    ParentFont = False
  end
  object lblPriorityBarcodeInput: TLabel
    Left = 8
    Top = 84
    Width = 106
    Height = 24
    Caption = #3626#3649#3585#3609#3588#3636#3623#3619#3629#3609#3634#3609':'
    Font.Charset = ANSI_CHARSET
    Font.Color = clRed
    Font.Height = -16
    Font.Name = 'Kanit'
    Font.Style = []
    ParentFont = False
  end
  object lblManualCall: TLabel
    Left = 8
    Top = 115
    Width = 107
    Height = 24
    Caption = #3648#3619#3637#3618#3585#3604#3657#3623#3618#3605#3609#3648#3629#3591':'
    Font.Charset = ANSI_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'Kanit'
    Font.Style = []
    ParentFont = False
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 505
    Width = 286
    Height = 19
    Panels = <
      item
        Alignment = taCenter
        Text = 'DB'
        Width = 100
      end
      item
        Alignment = taCenter
        Text = 'WS'
        Width = 100
      end
      item
        Alignment = taCenter
        Text = 'V2.3'
        Width = 50
      end>
  end
  object btnConfig: TButton
    Left = 8
    Top = 340
    Width = 70
    Height = 21
    Caption = #3605#3633#3657#3591#3588#3656#3634
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Kanit'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    TabStop = False
    OnClick = btnConfigClick
    OnDragDrop = btnConfigDragDrop
  end
  object btnResetDaily: TButton
    Left = 203
    Top = 340
    Width = 70
    Height = 21
    Caption = 'Refresh'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Kanit'
    Font.Style = []
    ParentFont = False
    TabOrder = 9
    TabStop = False
    OnClick = btnResetDailyClick
  end
  object btnTestSend: TButton
    Left = 107
    Top = 340
    Width = 70
    Height = 21
    Caption = #3607#3604#3626#3629#3610#3626#3656#3591
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Kanit'
    Font.Style = []
    ParentFont = False
    TabOrder = 10
    TabStop = False
    OnClick = btnTestSendClick
  end
  object cmbServiceCounter: TComboBox
    Left = 170
    Top = 12
    Width = 98
    Height = 27
    Style = csDropDownList
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Kanit'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnChange = cmbServiceCounterChange
  end
  object edtBarcodeInput: TEdit
    Left = 119
    Top = 47
    Width = 116
    Height = 30
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Kanit'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    OnKeyPress = edtBarcodeInputKeyPress
  end
  object edtPriorityBarcodeInput: TEdit
    Left = 119
    Top = 83
    Width = 116
    Height = 30
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Kanit'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    OnKeyPress = edtPriorityBarcodeInputKeyPress
  end
  object btnCallRoom1: TButton
    Left = 9
    Top = 142
    Width = 262
    Height = 42
    Caption = #3618#3634#3617#3634#3585#13#10#3619#3629':0 '#3606#3633#3604#3652#3611':-'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Kanit ExtraLight'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    OnClick = btnCallRoom1Click
  end
  object btnCallRoom2: TButton
    Left = 9
    Top = 192
    Width = 262
    Height = 42
    Caption = #3618#3634#3609#3657#3629#3618#13#10#3619#3629':0 '#3606#3633#3604#3652#3611':-'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Kanit ExtraLight'
    Font.Style = []
    ParentFont = False
    TabOrder = 6
    OnClick = btnCallRoom2Click
  end
  object btnCallRoom3: TButton
    Left = 9
    Top = 242
    Width = 262
    Height = 42
    Caption = #3652#3617#3656#3617#3637#3618#3634#13#10#3619#3629':0 '#3606#3633#3604#3652#3611':-'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Kanit ExtraLight'
    Font.Style = []
    ParentFont = False
    TabOrder = 7
    OnClick = btnCallRoom3Click
  end
  object btnCallRoom4: TButton
    Left = 9
    Top = 292
    Width = 262
    Height = 42
    Caption = #3618#3634#3586#3629#3585#3656#3629#3609' '#13#10#3619#3629':0 '#3606#3633#3604#3652#3611':-'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Kanit ExtraLight'
    Font.Style = []
    ParentFont = False
    TabOrder = 8
    OnClick = btnCallRoom4Click
  end
  object memoDebug: TMemo
    Left = 0
    Top = 377
    Width = 286
    Height = 128
    TabStop = False
    Align = alBottom
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 11
  end
  object btnBarcodeInput: TButton
    Left = 238
    Top = 47
    Width = 30
    Height = 30
    Caption = 'OK'
    TabOrder = 12
    TabStop = False
    OnClick = btnBarcodeInputClick
  end
  object btnPriorityBarcodeInput: TButton
    Left = 238
    Top = 83
    Width = 30
    Height = 30
    Caption = 'OK'
    TabOrder = 13
    TabStop = False
    OnClick = btnPriorityBarcodeInputClick
  end
  object Button1: TButton
    Left = 267
    Top = 119
    Width = 58
    Height = 17
    Caption = 'Debug'
    TabOrder = 14
    TabStop = False
    Visible = False
    OnClick = Button1Click
  end
  object UniConnection1: TUniConnection
    ProviderName = 'MySQL'
    Left = 96
    Top = 620
  end
  object UniQuery1: TUniQuery
    Connection = UniConnection1
    Left = 136
    Top = 620
  end
  object MySQLUniProvider1: TMySQLUniProvider
    Left = 112
    Top = 588
  end
  object sgcWebSocketClient1: TsgcWebSocketClient
    Port = 80
    ConnectTimeout = 0
    ReadTimeout = -1
    WriteTimeout = 0
    TLS = False
    Proxy.Enabled = False
    Proxy.Port = 8080
    Proxy.ProxyType = pxyHTTP
    HeartBeat.Enabled = False
    HeartBeat.Interval = 300
    HeartBeat.Timeout = 0
    IPVersion = Id_IPv4
    OnConnect = sgcWebSocketClient1Connect
    OnDisconnect = sgcWebSocketClient1Disconnect
    OnError = sgcWebSocketClient1Error
    Authentication.Enabled = False
    Authentication.URL.Enabled = True
    Authentication.Session.Enabled = False
    Authentication.Basic.Enabled = False
    Authentication.Token.Enabled = False
    Authentication.Token.AuthName = 'Bearer'
    Extensions.DeflateFrame.Enabled = False
    Extensions.DeflateFrame.WindowBits = 15
    Extensions.PerMessage_Deflate.Enabled = False
    Extensions.PerMessage_Deflate.ClientMaxWindowBits = 15
    Extensions.PerMessage_Deflate.ClientNoContextTakeOver = False
    Extensions.PerMessage_Deflate.MemLevel = 9
    Extensions.PerMessage_Deflate.ServerMaxWindowBits = 15
    Extensions.PerMessage_Deflate.ServerNoContextTakeOver = False
    Options.CleanDisconnect = False
    Options.FragmentedMessages = frgOnlyBuffer
    Options.Parameters = '/'
    Options.RaiseDisconnectExceptions = True
    Options.ValidateUTF8 = False
    Specifications.Drafts.Hixie76 = False
    Specifications.RFC6455 = True
    NotifyEvents = neAsynchronous
    LogFile.Enabled = False
    QueueOptions.Binary.Level = qmNone
    QueueOptions.Ping.Level = qmNone
    QueueOptions.Text.Level = qmNone
    WatchDog.Attempts = 0
    WatchDog.Enabled = False
    WatchDog.Interval = 10
    Throttle.BitsPerSec = 0
    Throttle.Enabled = False
    LoadBalancer.Enabled = False
    LoadBalancer.Port = 0
    TLSOptions.VerifyCertificate = False
    TLSOptions.VerifyDepth = 0
    TLSOptions.Version = tlsUndefined
    TLSOptions.IOHandler = iohOpenSSL
    TLSOptions.OpenSSL_Options.APIVersion = oslAPI_1_0
    TLSOptions.OpenSSL_Options.LibPath = oslpNone
    TLSOptions.OpenSSL_Options.UnixSymLinks = oslsSymLinksDefault
    TLSOptions.SChannel_Options.CertStoreName = scsnMY
    TLSOptions.SChannel_Options.CertStorePath = scspStoreCurrentUser
    Left = 56
    Top = 596
  end
  object RefreshTimer: TTimer
    Enabled = False
    OnTimer = RefreshTimerTimer
    Left = 56
    Top = 620
  end
  object JvAppInstances1: TJvAppInstances
    Left = 160
    Top = 584
  end
end
