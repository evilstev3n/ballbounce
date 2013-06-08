//
//
//

unit Unit1;

interface

uses
  Windows
  , Messages
  , SysUtils
  , Variants
  , Classes
  , Graphics
  , Controls
  , Forms
  , Dialogs
  , ExtCtrls
  , evstrutils
  , MMSystem;

type
  TItemType = (B_BALL, B_STANDARD1, B_STANDARD5, B_BATBIG1);

type
  TMyItem = record
    Mass: Integer;
    Right: Boolean;
    Up: Boolean;
    SpeedX: Integer;
    SpeedY: Integer;
    Counter: Integer;
    Limit: Integer;
    sh: TShape;
    itemtype: TItemType;
    Sound: string;
  end;

var
  ball: TMyItem;

var
  bItems: array[TItemType] of TMyItem;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    ShapeBat: TShape;
    ShapeDeath: TShape;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure initTypes;
    procedure Tick;
    procedure DrawLevel;
    function ProcessCollisions: Boolean;
    procedure MoveItem(var item: TMyItem);
    procedure MoveBat;
    procedure emitSound(name: string);
    procedure actionItemCollided(item: TMyItem);
    function isItemStopped(item: TMyItem): Boolean;
    function setItemSpeed(var item: TMyItem; x: Integer; y: Integer): Boolean;
    function checkLevelCleared: Boolean;
    procedure refreshGui;
  end;

var
  Form1: TForm1;
  elements: array of TMyItem;

const
  SND_HIT = 'sound\camera1.wav';
  SND_HIT2 = 'sound\voice_busy.wav';
  SND_HIT3 = 'sound\warning.wav';
  SND_PING1 = 'sound\p1.wav';
  SND_PING2 = 'sound\p2.wav';
  SND_PING3 = 'sound\p3.wav';

var
  TestRect: TRect;
var
  DestRect: TRect;

var
  sX: Integer = 0; // px orizzontale
  sY: Integer = 0; // px verticale
  sl: TStringList;

type
  TLevel = record
    num: Integer;
    name: string;
    balls: Integer;
    map: array of TMyItem;
  end;
var
  level: TLevel;
  balls: Integer = 0;

implementation

{$R *.dfm}

procedure TForm1.initTypes;
begin
  {}
  bItems[B_STANDARD1].Limit := 1;
  bItems[B_STANDARD1].sh := TShape.Create(Self);
  with bItems[B_STANDARD1].sh do
  begin
    Brush.Color := clLime;
  end;
  {}
  bItems[B_STANDARD5].Limit := 5;
  bItems[B_STANDARD5].sh := TShape.Create(Self);
  with bItems[B_STANDARD5].sh do
  begin
    Brush.Color := clGreen;
  end;
  {}
  bItems[B_BATBIG1].Limit := 1;
  bItems[B_BATBIG1].sh := TShape.Create(Self);
  with bItems[B_BATBIG1].sh do
  begin
    Brush.Color := clRed;
  end;
end;

function TForm1.isItemStopped(item: TMyItem): Boolean;
begin
  Result := False;
  if (item.SpeedX = 0) and (item.SpeedY = 0) then
  begin
    Result := True;
  end;
end;

function TForm1.setItemSpeed(var item: TMyItem; x: Integer; y: Integer): Boolean;
begin
  item.SpeedX := x;
  item.SpeedY := y;

  Result := True;
end;

procedure TForm1.emitSound(name: string);
begin
  if FileExists(name) then
  begin
    sndPlaySound(PChar(name),
      SND_ASYNC
      //SND_NODEFAULT or SND_ASYNC or SND_LOOP
      );
  end;
end;

procedure TForm1.actionItemCollided(item: TMyItem);
begin
  //
  if item.itemtype = B_BATBIG1 then
  begin
    {incrementa il bat}
    ShapeBat.Width := ShapeBat.Width + ((ShapeBat.Width * 20) div 100);
  end;
end;

function TForm1.ProcessCollisions: Boolean;
var
  jj: Integer;
  kk: Integer;

  procedure reverseBall;
  begin
    ball.Up := not ball.Up;
    ball.Right := not ball.Right;
  end;
begin
  Result := False;
  // se collide
  // bat
  if IntersectRect(TestRect, ball.sh.BoundsRect, ShapeBat.BoundsRect) then
  begin
    Result := True;
    ball.Up := True;
    //reverseBall;
    //
    emitSound(SND_PING1); //SND_HIT);
  end;

  // palla con elementi
  for jj := 0 to Length(elements) - 1 do
  begin
    if elements[jj].sh <> nil then
    begin

      // collisione elementi con palla
      if IntersectRect(TestRect, ball.sh.BoundsRect, elements[jj].sh.BoundsRect) then
      begin
        Result := True;

        elements[jj].Right := ball.Right;
        elements[jj].Up := ball.Up;
        reverseBall;

        // incremento le volte in cui collido
        Inc(elements[jj].Counter);

        // rendo l'item mobile
        (*
        elements[jj].Speed := 1 * elements[jj].Counter;
        if elements[jj].Speed > 50 then
          elements[jj].Speed := 2;
          *)

        actionItemCollided(elements[jj]);

        if (elements[jj].Counter >= elements[jj].Limit) then
        begin
          // elimino l'item
          elements[jj].sh.Free;
          elements[jj].sh := nil;
        end;

        Form1.Canvas.Brush.Color := clLime;
        Form1.Canvas.TextOut(0, jj * 17, IntToStr(jj) + '->' + IntToStr(elements[jj].Counter));

        emitSound(SND_HIT2);

        if checkLevelCleared = True then
          showmessage('Livello teminato');

      end; {fine collisione palla}

      // collisione palla con death
      if IntersectRect(TestRect, ball.sh.BoundsRect, ShapeDeath.BoundsRect) then
      begin
        Result := True;
        setItemSpeed(ball, 0, 0);
        Dec(balls);
      end; {fine collisione death}

      // collisione elementi con elementi
      for kk := 0 to Length(elements) - 1 do
      begin
        if (elements[jj].sh <> nil) and (elements[kk].sh <> nil) then
        begin
          if IntersectRect(TestRect, elements[kk].sh.BoundsRect, elements[jj].sh.BoundsRect) then
          begin
            //
            elements[kk].Right := elements[jj].Right;
            elements[kk].Up := elements[jj].Up;

            // inverto
            //elements[jj].Right := not elements[jj].Right;
            //elements[jj].Up := not elements[jj].Up;

            // incremento le volte in cui collido
            //Inc(elements[kk].Counter);
            //

            //elements[kk].Speed := 1 * elements[kk].Counter;
            //if elements[kk].Speed > 50 then
              //elements[kk].Speed := 2;
          end;
        end; {ciclo collisione elementi con elementi}
      end;

    end; //ciclo elementi

  end;
end;

function TForm1.checkLevelCleared: Boolean;
var
  ii: Integer;
begin
  Result := True;
  for ii := 0 to length(elements) do
  begin
    if (elements[ii].sh <> nil) then
    begin
      Result := False;
    end;
  end;
end;

procedure TForm1.DrawLevel;
var
  jj: Integer;
  ii: Integer;
  tmp: string;
  v: TArray;
begin
  sl.LoadFromFile('levels\0.txt');

  balls := 3;

  //SetLength(level.map, sl.Count);
  SetLength(elements, sl.Count);

  for jj := 0 to sl.Count - 1 do
  begin
    tmp := sl.Strings[jj];
    v := explode(',', tmp, 0);

    with elements[jj] do
    begin
      Counter := 0;
      SpeedX := 0;
      SpeedY := 0;
      //Limit := StrToInt(v[2]);

      if v[2] = 'STANDARD1' then
      begin
        itemtype := B_STANDARD1;
      end;

      if v[2] = 'STANDARD5' then
      begin
        itemtype := B_STANDARD5;
      end;

      if v[2] = 'BATBIG1' then
      begin
        itemtype := B_BATBIG1;
      end;

      Limit := bItems[itemtype].Limit;

      sh := TShape.Create(Self);
      with sh do
      begin
        Parent := Self;
        Width := 10;
        Height := 10;
        Shape := stCircle;
        Brush.Color := bItems[itemtype].sh.Brush.Color;
        Left := StrToInt(v[0]);
        Top := StrToInt(v[1]);
        BringToFront;
      end;

    end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);

begin
  Form1.Caption := 'BOX';
  Form1.Color := clBlack;

  //
  initTypes;
  //
  // crea palla
  //
  with ball do
  begin
    Counter := 0;
    SpeedX := 0;
    SpeedY := 0;
    itemtype := B_BALL;
    sh := TShape.Create(Self);
    with sh do
    begin
      Parent := Self;
      Width := 20;
      Height := 20;
      Shape := stCircle;
      Left := (Form1.Width div 2) - (sh.Width div 2);
      Top := 50;
      BringToFront;
    end;
  end;

  //
  DrawLevel;
  //
  refreshGui;
end;

procedure TForm1.MoveBat;
begin
  //
  if GetKeyState(VK_LEFT) < 0 then
    if ShapeBat.Left > 0 then
      ShapeBat.SetBounds(ShapeBat.Left - 5, ShapeBat.Top, ShapeBat.Width, ShapeBat.Height);

  if GetKeyState(VK_RIGHT) < 0 then
    if ShapeBat.Left + ShapeBat.Width <= Form1.Width then
      ShapeBat.SetBounds(ShapeBat.Left + 5, ShapeBat.Top, ShapeBat.Width, ShapeBat.Height);

  // se la palla ferma allora
  if isItemStopped(ball) then
  begin
    ball.sh.Left := ShapeBat.Left + (ShapeBat.Width div 2) - (ball.sh.Width div 2);
    ball.sh.Top := ShapeBat.Top - ball.sh.Height;
  end;

  //sleep(15);
end;

procedure TForm1.MoveItem(var item: TMyItem);
begin
  if item.sh <> nil then
  begin

    if item.Up = True then
    begin
      item.sh.Top := item.sh.Top - item.SpeedY
    end
    else
    begin
      item.sh.Top := item.sh.Top + item.SpeedY;
    end;

    // hit top
    if item.sh.Top <= 0 then
    begin
      item.Up := False;
    end;
    // hit bottom
    if (item.sh.Top + item.sh.Height) >= Form1.Height then
    begin
      item.Up := True;
    end;

    // ------------------------------------------

    if item.Right = True then
      item.sh.Left := item.sh.Left + item.SpeedX
    else
      item.sh.Left := item.sh.Left - item.SpeedX;

    // hit left
    if item.sh.Left <= 0 then
      item.Right := True;
    // hit right
    if (item.sh.Left + item.sh.Width) >= Form1.Width then
      item.Right := False;

  end;

  //Form1.Caption := Format('%d,%d', [item.sh.Left, item.sh.Top]);
end;

procedure TForm1.refreshGui;
begin
  Caption := 'Vite: ' + IntToStr(balls);
end;

procedure TForm1.Tick;
var
  jj: Integer;
begin
  if GetAsyncKeyState(VK_ESCAPE) < 0 then
    Application.Terminate;

  if isItemStopped(ball) then
  begin
    //
    if GetAsyncKeyState(VK_UP) < 0 then
    begin
    if balls > 0 then    
      setItemSpeed(ball, 5, 5);
    end;
  end;

  // muovo palla
  MoveItem(ball);

  // muovo bat
  MoveBat;

  // muovo elementi

  for jj := 0 to Length(elements) - 1 do
  begin
    if elements[jj].SpeedX > 0 then
    begin
      // muovo resto elementi
      MoveItem(elements[jj]);
    end;
  end;

  if ProcessCollisions = True then
  begin
    refreshGui;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Tick;
end;

initialization
  sl := TStringList.Create;

end.

