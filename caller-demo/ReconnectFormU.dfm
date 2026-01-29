object ReconnectForm: TReconnectForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'WebSocket Reconnecting'
  ClientHeight = 150
  ClientWidth = 350
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = True
  Position = poMainFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object lblStatus: TLabel
    Left = 24
    Top = 24
    Width = 302
    Height = 28
    Alignment = taCenter
    AutoSize = False
    Caption = 'Reconnecting...'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblRetry: TLabel
    Left = 24
    Top = 64
    Width = 302
    Height = 21
    Alignment = taCenter
    AutoSize = False
    Caption = 'Attempt: 1/10'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object lblCountdown: TLabel
    Left = 24
    Top = 96
    Width = 302
    Height = 21
    Alignment = taCenter
    AutoSize = False
    Caption = 'Next retry in 5 seconds'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object ProgressTimer: TTimer
    Enabled = False
    Interval = 500
    OnTimer = ProgressTimerTimer
    Left = 160
    Top = 120
  end
end
