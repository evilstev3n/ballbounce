object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 535
  ClientWidth = 643
  Color = clBtnFace
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
  object ShapeBat: TShape
    Left = 296
    Top = 504
    Width = 56
    Height = 11
  end
  object ShapeDeath: TShape
    Left = 0
    Top = 521
    Width = 643
    Height = 14
    Align = alBottom
  end
  object Timer1: TTimer
    Interval = 1
    OnTimer = Timer1Timer
    Left = 16
    Top = 16
  end
end
