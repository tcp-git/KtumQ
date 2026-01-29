object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Queue Caller Application'
  ClientHeight = 600
  ClientWidth = 800
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnlGrid: TPanel
    Left = 8
    Top = 8
    Width = 400
    Height = 300
    TabOrder = 0
  end
  object pnlControls: TPanel
    Left = 8
    Top = 320
    Width = 784
    Height = 80
    TabOrder = 1
    object btnFirst: TButton
      Left = 16
      Top = 16
      Width = 75
      Height = 25
      Caption = 'First'
      TabOrder = 0
      OnClick = btnFirstClick
    end
    object btnNext: TButton
      Left = 104
      Top = 16
      Width = 75
      Height = 25
      Caption = 'Next'
      TabOrder = 1
      OnClick = btnNextClick
    end
    object btnPrev: TButton
      Left = 192
      Top = 16
      Width = 75
      Height = 25
      Caption = 'Previous'
      TabOrder = 2
      OnClick = btnPrevClick
    end
    object btnLast: TButton
      Left = 280
      Top = 16
      Width = 75
      Height = 25
      Caption = 'Last'
      TabOrder = 3
      OnClick = btnLastClick
    end
    object btnSend: TButton
      Left = 400
      Top = 16
      Width = 100
      Height = 25
      Caption = 'Send Selected'
      TabOrder = 4
      OnClick = btnSendClick
    end
    object btnSettings: TButton
      Left = 520
      Top = 16
      Width = 75
      Height = 25
      Caption = 'Settings'
      TabOrder = 5
      OnClick = btnSettingsClick
    end
  end
  object pnlStatus: TPanel
    Left = 420
    Top = 8
    Width = 372
    Height = 300
    TabOrder = 2
    object lblDBStatus: TLabel
      Left = 10
      Top = 10
      Width = 97
      Height = 13
      Caption = 'DB: Disconnected'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblWSStatus: TLabel
      Left = 10
      Top = 30
      Width = 100
      Height = 13
      Caption = 'WS: Disconnected'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object memoErrorLog: TMemo
      Left = 10
      Top = 55
      Width = 352
      Height = 235
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object StatusBar: TPanel
    Left = 0
    Top = 580
    Width = 800
    Height = 20
    Align = alBottom
    Caption = 'Ready'
    TabOrder = 3
  end
  object JvAppInstances1: TJvAppInstances
    Left = 600
    Top = 456
  end
end
