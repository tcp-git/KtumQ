object frmDisplay: TfrmDisplay
  Left = 0
  Top = 0
  Caption = 'Queue Terminal Display'
  ClientHeight = 600
  ClientWidth = 800
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWhite
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  WindowState = wsMaximized
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 800
    Height = 80
    Align = alTop
    Color = clBlack
    TabOrder = 0
    object lblTitle: TLabel
      Left = 1
      Top = 1
      Width = 798
      Height = 78
      Align = alClient
      Alignment = taCenter
      Caption = 'Queue Display System'
      Color = clBlack
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Layout = tlCenter
      ExplicitWidth = 265
      ExplicitHeight = 29
    end
  end
  object pnlGrid: TPanel
    Left = 0
    Top = 80
    Width = 600
    Height = 400
    Align = alClient
    Color = clBlack
    TabOrder = 1
  end
  object pnlScrollingText: TPanel
    Left = 0
    Top = 480
    Width = 800
    Height = 120
    Align = alBottom
    Color = clBlack
    TabOrder = 2
    object lblScrollingText: TLabel
      Left = 1
      Top = 1
      Width = 798
      Height = 118
      Align = alClient
      Alignment = taCenter
      Caption = 'Welcome to Queue System'
      Color = clBlack
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clYellow
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Layout = tlCenter
      ExplicitWidth = 190
      ExplicitHeight = 19
    end
  end
  object pnlStatus: TPanel
    Left = 600
    Top = 80
    Width = 200
    Height = 400
    Align = alRight
    Color = clBlack
    TabOrder = 3
    object lblConnectionStatus: TLabel
      Left = 10
      Top = 10
      Width = 180
      Height = 13
      Caption = 'Connection: Disconnected'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object memoErrorLog: TMemo
      Left = 10
      Top = 35
      Width = 180
      Height = 355
      Color = clBlack
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -9
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object tmrBlink: TTimer
    Interval = 500
    OnTimer = tmrBlinkTimer
    Left = 720
    Top = 16
  end
  object tmrScroll: TTimer
    Interval = 100
    OnTimer = tmrScrollTimer
    Left = 720
    Top = 48
  end
  object tmrStopBlink: TTimer
    Enabled = False
    Interval = 3000
    OnTimer = tmrStopBlinkTimer
    Left = 720
    Top = 80
  end
end
