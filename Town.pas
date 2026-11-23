{$MODE TP}
unit Town;

{ Town-wide state shared by every player: the daily condition and the news.
  The condition is derived from the calendar date, so every node agrees on
  it without sharing a file. The news lives in NEWS.TXT (today) and
  NEWSOLD.TXT (yesterday). }

interface

uses
  Crt, SysUtils;

type
  TCondition = (cdClear, cdBloodMoon, cdFog, cdFestival, cdAllSouls,
                cdStorm, cdHolyDay, cdCarnival);

function ConditionOnDay(Day: LongInt): TCondition;
function TodayCondition: TCondition;
function ConditionName(C: TCondition): string;
function ConditionShort(C: TCondition): string;
procedure PrintConditionDetails(C: TCondition);
procedure PostNews(const Headline: string);
procedure PrintNews(MaxLines: Integer);
function DayHash(Day, Salt: LongInt): LongInt;
function GetChampion: string;
procedure SetChampion(const Name: string);

implementation

const
  NEWS_FILE     = 'NEWS.TXT';
  CHAMPION_FILE = 'CHAMPION.TXT';
  OLD_NEWS_FILE = 'NEWSOLD.TXT';
  DAY_TAG       = '#DAY ';
  MAX_NEWS_SHOWN = 20;

  COND_NAMES: array[TCondition] of string[20] = (
    'Clear Skies',
    'Blood Moon',
    'Thick Fog',
    'Harvest Festival',
    'All Souls'' Night',
    'Lightning Storm',
    'Holy Day',
    'Traveling Carnival'
  );

  COND_SHORT: array[TCondition] of string[40] = (
    'an ordinary day',
    'fiercer beasts, richer spoils',
    'hidden alleys and trails',
    'shop and Inn discounts',
    'the crypt portal stirs',
    'fewer fights, wilder trails',
    'cheap tithes and meditation',
    'high-stakes bone dice'
  );

  COND_DETAIL1: array[TCondition] of string[76] = (
    'Clear skies over the ridge. An ordinary day in South Ridge.',
    'A blood moon hangs low. Forest beasts are 25% tougher and hit harder,',
    'Thick fog rolls in off the creek. Alley searches draw less attention,',
    'The Harvest Festival is on! Weapons and armor are 15% off,',
    'All Souls'' Night. The crypt portal is sure to open tonight,',
    'A lightning storm lashes the ridge. Only 4 forest fights today, but the',
    'A holy day at the Parish Chapel. Tithes are half price',
    'A traveling carnival is in town. Crooked Finger doubles his house limit,'
  );

  COND_DETAIL2: array[TCondition] of string[76] = (
    '',
    'but they drop 50% more gold and XP.',
    'and bandits beyond the footbridge can''t find you.',
    'and rooms at the Inn are half price.',
    'and its guardians carry 25% more gold.',
    'trails beyond the creek run longer and rare finds are more common.',
    'and meditation costs only 3 MP.',
    'and boxcars pay five times the bet.'
  );

{ Scrambles the day number so conditions look random but are the same on
  every node. Clear Skies gets two of the nine slots so it is the most common. }
function ConditionForDay(Day: LongInt): TCondition;
var
  H: Int64;
  Slot: Integer;
begin
  H := (Int64(Day) * 2654435761) mod 4294967296;
  H := H xor (H shr 15);
  H := (H * 1597334677) mod 4294967296;
  H := H xor (H shr 13);
  Slot := H mod 9;
  if Slot <= 1 then
    ConditionForDay := cdClear
  else
    ConditionForDay := TCondition(Slot - 1);
end;

{ The condition for any calendar day (Trunc of a TDateTime) }
function ConditionOnDay(Day: LongInt): TCondition;
var
  C: TCondition;
begin
  C := ConditionForDay(Day);
  { Never the same special condition two days running }
  if (C <> cdClear) and (C = ConditionForDay(Day - 1)) then
    C := cdClear;
  ConditionOnDay := C;
end;

{ A scrambled number (0..2^31-1) for a calendar day. Different salts give
  unrelated sequences, so each feature can draw its own shared daily roll. }
function DayHash(Day, Salt: LongInt): LongInt;
var
  H: Int64;
begin
  H := (Int64(Day) * 40503 + Int64(Salt) * 2246822519) mod 4294967296;
  if H < 0 then
    H := H + 4294967296;
  H := H xor (H shr 16);
  H := (H * 2654435761) mod 4294967296;
  H := H xor (H shr 13);
  H := (H * 1597334677) mod 4294967296;
  H := H xor (H shr 16);
  DayHash := H and $7FFFFFFF;
end;

{ Name of the reigning Champion of the Ridge, or '' if the Wyrm is unbested }
function GetChampion: string;
var
  F: Text;
  L: string;
begin
  GetChampion := '';
  if not FileExists(CHAMPION_FILE) then
    Exit;
  Assign(F, CHAMPION_FILE);
  {$I-} Reset(F); {$I+}
  if IOResult <> 0 then
    Exit;
  L := '';
  if not Eof(F) then
    ReadLn(F, L);
  Close(F);
  GetChampion := Trim(L);
end;

procedure SetChampion(const Name: string);
var
  F: Text;
  Retries: Integer;
  Opened: Boolean;
begin
  Assign(F, CHAMPION_FILE);
  Retries := 0;
  repeat
    {$I-} Rewrite(F); {$I+}
    Opened := IOResult = 0;
    if not Opened then
    begin
      Inc(Retries);
      Delay(25);
    end;
  until Opened or (Retries >= 20);
  if not Opened then
    Exit;
  WriteLn(F, Name);
  WriteLn(F, FormatDateTime('yyyy-mm-dd hh:nn', Now));
  Close(F);
end;

function TodayCondition: TCondition;
begin
  TodayCondition := ConditionOnDay(Trunc(Date));
end;

function ConditionName(C: TCondition): string;
begin
  ConditionName := COND_NAMES[C];
end;

function ConditionShort(C: TCondition): string;
begin
  ConditionShort := COND_SHORT[C];
end;

procedure PrintConditionDetails(C: TCondition);
begin
  TextColor(LightGray);
  WriteLn('  ', COND_DETAIL1[C]);
  if COND_DETAIL2[C] <> '' then
    WriteLn('  ', COND_DETAIL2[C]);
end;

{ Returns the day stamped on a news file's first line, or -1 if none }
function FileNewsDay(const FileName: string): LongInt;
var
  F: Text;
  L: string;
  D: LongInt;
  Code: Integer;
begin
  FileNewsDay := -1;
  if not FileExists(FileName) then
    Exit;

  Assign(F, FileName);
  {$I-} Reset(F); {$I+}
  if IOResult <> 0 then
    Exit;

  if not Eof(F) then
  begin
    ReadLn(F, L);
    if Copy(L, 1, Length(DAY_TAG)) = DAY_TAG then
    begin
      Val(Copy(L, Length(DAY_TAG) + 1, 20), D, Code);
      if Code = 0 then
        FileNewsDay := D;
    end;
  end;
  Close(F);
end;

{ Starts a fresh front page when the date changes, keeping yesterday's issue }
procedure RollNewsDay(Today: LongInt);
var
  F: Text;
  CurrentDay: LongInt;
begin
  CurrentDay := FileNewsDay(NEWS_FILE);
  if CurrentDay = Today then
    Exit;

  if FileExists(NEWS_FILE) then
  begin
    if FileExists(OLD_NEWS_FILE) then
      DeleteFile(OLD_NEWS_FILE);
    if CurrentDay = Today - 1 then
      RenameFile(NEWS_FILE, OLD_NEWS_FILE)
    else
      DeleteFile(NEWS_FILE); { Older than yesterday: nobody needs it }
  end;

  Assign(F, NEWS_FILE);
  {$I-} Rewrite(F); {$I+}
  if IOResult <> 0 then
    Exit;
  WriteLn(F, DAY_TAG, Today);
  Close(F);
end;

procedure PostNews(const Headline: string);
var
  F: Text;
  Retries: Integer;
  Opened: Boolean;
begin
  RollNewsDay(Trunc(Date));

  Assign(F, NEWS_FILE);
  Retries := 0;
  repeat
    {$I-} Append(F); {$I+}
    Opened := IOResult = 0;
    if not Opened then
    begin
      Inc(Retries);
      Delay(25);
    end;
  until Opened or (Retries >= 20);

  if not Opened then
    Exit; { News is nice to have; never block the game over it }

  WriteLn(F, FormatDateTime('hh:nn', Now), ' ', Headline);
  Close(F);
end;

{ Writes S word-wrapped to Width columns; continuation lines are indented }
procedure WriteWrapped(const S: string; Width, Indent: Integer);
var
  Rest: string;
  Cut: Integer;
begin
  Rest := S;
  while Length(Rest) > Width do
  begin
    Cut := Width + 1;
    while (Cut > 1) and (Rest[Cut] <> ' ') do
      Dec(Cut);
    if Cut <= 1 then
    begin
      WriteLn(Copy(Rest, 1, Width));
      Rest := Copy(Rest, Width + 1, 255);
    end
    else
    begin
      WriteLn(Copy(Rest, 1, Cut - 1));
      Rest := Copy(Rest, Cut + 1, 255);
    end;
    Write(StringOfChar(' ', Indent));
  end;
  WriteLn(Rest);
end;

{ Prints the newest MaxLines headlines of one news file; returns how many }
function PrintNewsFile(const FileName: string; MaxLines: Integer): Integer;
var
  F: Text;
  L: string;
  Recent: array[0..MAX_NEWS_SHOWN - 1] of string;
  Total, First, i: LongInt;
begin
  PrintNewsFile := 0;
  if MaxLines > MAX_NEWS_SHOWN then
    MaxLines := MAX_NEWS_SHOWN;
  if MaxLines <= 0 then
    Exit;

  Assign(F, FileName);
  {$I-} Reset(F); {$I+}
  if IOResult <> 0 then
    Exit;

  Total := 0;
  while not Eof(F) do
  begin
    ReadLn(F, L);
    if (L <> '') and (Copy(L, 1, Length(DAY_TAG)) <> DAY_TAG) then
    begin
      Recent[Total mod MaxLines] := L;
      Inc(Total);
    end;
  end;
  Close(F);

  if Total > MaxLines then
    First := Total - MaxLines
  else
    First := 0;

  for i := First to Total - 1 do
  begin
    L := Recent[i mod MaxLines];
    TextColor(DarkGray);
    Write('  ', Copy(L, 1, 5), '  ');
    TextColor(LightGray);
    WriteWrapped(Copy(L, 7, 255), 69, 9);
  end;

  PrintNewsFile := Total - First;
end;

procedure PrintNews(MaxLines: Integer);
var
  Today: LongInt;
  Shown: Integer;
  YesterdayFile: string;
begin
  Today := Trunc(Date);
  Shown := 0;

  TextColor(Yellow);
  WriteLn('--- Today''s Headlines ---');
  if FileNewsDay(NEWS_FILE) = Today then
    Shown := PrintNewsFile(NEWS_FILE, MaxLines);
  if Shown = 0 then
  begin
    TextColor(DarkGray);
    WriteLn('  No news yet today. Go make some!');
  end;

  { A thin front page gets padded with yesterday's headlines }
  if Shown < 5 then
  begin
    YesterdayFile := '';
    if FileNewsDay(NEWS_FILE) = Today - 1 then
      YesterdayFile := NEWS_FILE
    else if FileNewsDay(OLD_NEWS_FILE) = Today - 1 then
      YesterdayFile := OLD_NEWS_FILE;

    if YesterdayFile <> '' then
    begin
      WriteLn;
      TextColor(Yellow);
      WriteLn('--- Yesterday ---');
      PrintNewsFile(YesterdayFile, 5);
    end;
  end;

  TextColor(LightGray);
end;

end.
