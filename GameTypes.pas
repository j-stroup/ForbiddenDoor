{$MODE TP}
unit GameTypes;

interface

uses
  Crt, SysUtils, md5, Town;

const
  SAVE_FILE = 'PLAYER.DAT';

  { Hard ceiling for any gold balance so LongInt math can never wrap }
  MAX_GOLD = 2000000000;

  { Daily bank interest is 5%, but never more than this many gold per level }
  MAX_INTEREST_PER_LEVEL = 200;

  { Players idle at any prompt this long are disconnected (milliseconds) }
  IDLE_TIMEOUT_MS = 300000;

  { Crypt portal state for the current day }
  CRYPT_UNROLLED = 0;
  CRYPT_SEALED   = 1;
  CRYPT_OPEN     = 2;
  CRYPT_USED     = 3;

type
  TItem = record
    Name: string[25];
    StatBonus: Integer;
    Cost: LongInt;
  end;

  TSkill = record
    Name: string[25];
    MPCost: Integer;
    Power: Integer;
    MinLevel: Integer;
    IsHeal: Boolean;
  end;

  TPlayer = record
    Name: string[30];
    Pin: string[32];          { Salted MD5 hash of the PIN, never the PIN itself }
    Level: Integer;
    XP: LongInt;
    HP, MaxHP: Integer;
    MP, MaxMP: Integer;
    Strength: Integer;
    Gold: LongInt;
    BankGold: LongInt;
    FightsLeft: Integer;
    TavernDone: Boolean;
    BridgeDone: Boolean;
    LastPlayDay: LongInt;
    WeaponIndex: Integer;
    ArmorIndex: Integer;
    { Daily limits that must survive a reconnect }
    SysOpDone: Boolean;
    ConfessDone: Boolean;
    IronDoorDone: Boolean;
    PoorBoxDone: Boolean;
    AlleyHeat: Integer;
    CryptState: Byte;
    { Bumped on every save; detects the same warrior playing on two nodes }
    SaveCount: LongInt;
  end;

  TMonster = record
    Name: string[30];
    HP: Integer;
    Attack: Integer;
    GoldReward: Integer;
    XPReward: Integer;
  end;

const
  SKILLS: array[1..7] of TSkill = (
    (Name: 'Ember Spark';         MPCost: 5;  Power: 14;  MinLevel: 1;  IsHeal: False),
    (Name: 'Mend Wounds';         MPCost: 8;  Power: 26;  MinLevel: 2;  IsHeal: True),
    (Name: 'Frost Lance';         MPCost: 12; Power: 34;  MinLevel: 4;  IsHeal: False),
    (Name: 'Arcane Cleave';       MPCost: 18; Power: 52;  MinLevel: 6;  IsHeal: False),
    (Name: 'Greater Restoration'; MPCost: 22; Power: 75;  MinLevel: 8;  IsHeal: True),
    (Name: 'Soul Rupture';        MPCost: 30; Power: 95;  MinLevel: 11; IsHeal: False),
    (Name: 'Ashen Cataclysm';     MPCost: 45; Power: 155; MinLevel: 14; IsHeal: False)
  );

  WEAPONS: array[1..15] of TItem = (
    (Name: 'Rusty Dagger';          StatBonus: 2;   Cost: 0),
    (Name: 'Steel Fist';            StatBonus: 4;   Cost: 50),
    (Name: 'Iron Shortsword';       StatBonus: 6;   Cost: 110),
    (Name: 'Steel Broadsword';      StatBonus: 10;  Cost: 240),
    (Name: 'Ashen Greatsword';      StatBonus: 15;  Cost: 480),
    (Name: 'Heavy Claymore';        StatBonus: 21;  Cost: 850),
    (Name: 'Worm Man''s Mace';      StatBonus: 28;  Cost: 1400),
    (Name: 'Bloody Dagger of Cron'; StatBonus: 36;  Cost: 2200),
    (Name: 'Flail of Sorrow';       StatBonus: 46;  Cost: 3400),
    (Name: 'Runed Warhammer';       StatBonus: 58;  Cost: 5000),
    (Name: 'Cryptkeeper''s Scythe'; StatBonus: 72;  Cost: 7500),
    (Name: 'Starforged Halberd';    StatBonus: 88;  Cost: 11000),
    (Name: 'Wyrmfang Executioner';  StatBonus: 108; Cost: 16000),
    (Name: 'Abyssal Soulreaver';    StatBonus: 132; Cost: 23000),
    (Name: 'Blade of the First Sun';StatBonus: 160; Cost: 32000)
  );

  ARMORS: array[1..12] of TItem = (
    (Name: 'Tattered Tunic';        StatBonus: 0;  Cost: 0),
    (Name: 'Boiled Leather';        StatBonus: 2;  Cost: 55),
    (Name: 'Studded Brigandine';    StatBonus: 4;  Cost: 140),
    (Name: 'Chainmail Hauberk';     StatBonus: 7;  Cost: 320),
    (Name: 'Scale Mail';            StatBonus: 11; Cost: 650),
    (Name: 'Knight''s Plate';       StatBonus: 16; Cost: 1200),
    (Name: 'Blackened Steel Plate'; StatBonus: 22; Cost: 2100),
    (Name: 'Cryptwarden Aegis';     StatBonus: 29; Cost: 3500),
    (Name: 'Runed Mithril Coat';    StatBonus: 38; Cost: 5600),
    (Name: 'Wyrmscale Harness';     StatBonus: 48; Cost: 8800),
    (Name: 'Obsidian Bulwark';      StatBonus: 60; Cost: 13500),
    (Name: 'Aegis of South Ridge';  StatBonus: 75; Cost: 20000)
  );

  MONSTERS: array[1..24] of TMonster = (
    { Tier 1: Levels 1-2 }
    (Name: 'Rabid Timber Wolf';             HP: 20;   Attack: 5;   GoldReward: 22;   XPReward: 24),
    (Name: 'Bandit Cutthroat';              HP: 30;   Attack: 8;   GoldReward: 38;   XPReward: 38),
    (Name: 'Hollow Knight';                 HP: 44;   Attack: 11;  GoldReward: 60;   XPReward: 58),
    { Tier 2: Levels 3-4 }
    (Name: 'Ashen Wyrmling';                HP: 65;   Attack: 15;  GoldReward: 100;  XPReward: 95),
    (Name: 'Mean Looking Bird';             HP: 88;   Attack: 19;  GoldReward: 140;  XPReward: 130),
    (Name: 'Kyle';                          HP: 115;  Attack: 23;  GoldReward: 185;  XPReward: 170),
    { Tier 3: Levels 5-6 }
    (Name: 'Toxic Bear Zombie';             HP: 150;  Attack: 28;  GoldReward: 245;  XPReward: 225),
    (Name: 'Zebra Man';                     HP: 190;  Attack: 33;  GoldReward: 310;  XPReward: 285),
    (Name: 'Really Big Squirrel';           HP: 235;  Attack: 39;  GoldReward: 385;  XPReward: 355),
    { Tier 4: Levels 7-9 }
    (Name: 'Evil Shadow Demon';             HP: 290;  Attack: 46;  GoldReward: 480;  XPReward: 440),
    (Name: 'Ghost Goat';                    HP: 350;  Attack: 53;  GoldReward: 580;  XPReward: 530),
    (Name: '10k Crows in a Trenchcoat';     HP: 420;  Attack: 60;  GoldReward: 690;  XPReward: 635),
    { Tier 5: Levels 10-12 }
    (Name: 'A Guy with 6 Arms, Named Greg'; HP: 510;  Attack: 69;  GoldReward: 820;  XPReward: 760),
    (Name: 'Drunken Redneck';               HP: 610;  Attack: 78;  GoldReward: 960;  XPReward: 895),
    (Name: 'Boar God';                      HP: 725;  Attack: 88;  GoldReward: 1140; XPReward: 1060),
    { Tier 6: Levels 13-15 }
    (Name: 'Ironclad Juggernaut';           HP: 860;  Attack: 99;  GoldReward: 1350; XPReward: 1260),
    (Name: 'Bog Witch of Ashtabula';        HP: 1010; Attack: 110; GoldReward: 1600; XPReward: 1490),
    (Name: 'Skeletal Colossus';             HP: 1180; Attack: 122; GoldReward: 1880; XPReward: 1750),
    { Tier 7: Levels 16-18 }
    (Name: 'Clockwork Abomination';         HP: 1370; Attack: 135; GoldReward: 2200; XPReward: 2060),
    (Name: 'Abyssal Leviathan';             HP: 1580; Attack: 149; GoldReward: 2580; XPReward: 2420),
    (Name: 'Pale Rider of the Ridge';       HP: 1820; Attack: 164; GoldReward: 3000; XPReward: 2840),
    { Tier 8: Level 19+ }
    (Name: 'Eldritch Forest Warden';        HP: 2090; Attack: 180; GoldReward: 3500; XPReward: 3340),
    (Name: 'Dread Sovereign';               HP: 2400; Attack: 198; GoldReward: 4100; XPReward: 3920),
    (Name: 'The Ancient Ashen Wyrm';        HP: 2800; Attack: 218; GoldReward: 5200; XPReward: 4800)
  );

function GetKey: Char;
function ReadInput(MaxLen: Integer; Masked: Boolean): string;
function ReadNumber(MaxDigits: Integer; var Value: LongInt): Boolean;
function PadRight(const S: string; Width: Integer): string;
procedure AddGold(var Balance: LongInt; Delta: LongInt);
procedure Pause;
function XPForNextLevel(CurrentLevel: Integer): LongInt;
procedure SavePlayer(const P: TPlayer);
function LoginPlayer(var P: TPlayer): Boolean;
procedure CheckDailyReset(var P: TPlayer);
procedure ShowStats(const P: TPlayer);
procedure ShowLeaderboard(const CurrentPlayerName: string);
function CastCombatSkill(var P: TPlayer; const EnemyName: string; var EnemyHP: LongInt): Boolean;

implementation

var
  { Private to GameTypes: tracks which slot in PLAYER.DAT belongs to this session }
  CurrentPlayerIndex: LongInt;
  { SaveCount we expect to find on disk; a mismatch means another node saved }
  SessionSaveCount: LongInt;

{ Waits for one key. Disconnects after IDLE_TIMEOUT_MS of silence.
  Extended keys (arrows, F-keys) come back as #0; stray line feeds are ignored. }
function GetKey: Char;
var
  Waited: LongInt;
  Ch: Char;
begin
  repeat
    Waited := 0;
    while not KeyPressed do
    begin
      Delay(50);
      Inc(Waited, 50);
      if Waited >= IDLE_TIMEOUT_MS then
      begin
        WriteLn;
        TextColor(LightRed);
        WriteLn('You doze off on your feet. The town watch carts you home. (Idle disconnect)');
        TextColor(LightGray);
        Halt;
      end;
    end;

    Ch := ReadKey;
    if Ch = #0 then
    begin
      ReadKey; { Discard the scan code of an extended key }
      Ch := #0;
    end;
  until Ch <> #10;

  GetKey := Ch;
end;

{ Line input that only accepts printable ASCII, so nobody can inject
  ANSI escape codes into names, PINs, or the rumor wall. }
function ReadInput(MaxLen: Integer; Masked: Boolean): string;
var
  S: string;
  Ch: Char;
begin
  S := '';
  repeat
    Ch := GetKey;
    if (Ch = #8) or (Ch = #127) then
    begin
      if Length(S) > 0 then
      begin
        Delete(S, Length(S), 1);
        Write(#8' '#8);
      end;
    end
    else if (Ch >= ' ') and (Ch <= '~') and (Length(S) < MaxLen) then
    begin
      S := S + Ch;
      if Masked then
        Write('*')
      else
        Write(Ch);
    end;
  until Ch = #13;
  WriteLn;
  ReadInput := S;
end;

{ Reads a whole number; returns False for blank or non-numeric input.
  Keep MaxDigits at 9 or less so the value always fits in a LongInt. }
function ReadNumber(MaxDigits: Integer; var Value: LongInt): Boolean;
var
  S: string;
  Code: Integer;
begin
  S := Trim(ReadInput(MaxDigits, False));
  Value := 0;
  Code := 1;
  if S <> '' then
    Val(S, Value, Code);
  ReadNumber := (S <> '') and (Code = 0);
end;

{ Pads a string on the right with spaces (or truncates it) to an exact width }
function PadRight(const S: string; Width: Integer): string;
var
  Res: string;
begin
  Res := S;
  while Length(Res) < Width do
    Res := Res + ' ';
  if Length(Res) > Width then
    Res := Copy(Res, 1, Width);
  PadRight := Res;
end;

{ Adds (or subtracts) gold while keeping the balance between 0 and MAX_GOLD }
procedure AddGold(var Balance: LongInt; Delta: LongInt);
begin
  if (Delta > 0) and (Balance > MAX_GOLD - Delta) then
    Balance := MAX_GOLD
  else
    Balance := Balance + Delta;
  if Balance < 0 then
    Balance := 0;
end;

procedure Pause;
begin
  WriteLn;
  TextColor(DarkGray);
  Write('[Press any key to continue]');
  TextColor(LightGray);
  GetKey;
end;

function XPForNextLevel(CurrentLevel: Integer): LongInt;
begin
  { Steeper progression: Lvl 1->185, Lvl 2->540, Lvl 5->2825, Lvl 10->10400 }
  XPForNextLevel := (LongInt(CurrentLevel) * CurrentLevel * 95) + (LongInt(CurrentLevel) * 90);
end;

{ Salted hash so PLAYER.DAT never holds a readable PIN }
function HashPin(const PlayerName, PinText: string): string;
begin
  HashPin := MD5Print(MD5String(UpperCase(Trim(PlayerName)) + ':' + PinText));
end;

{ Overwrites ONLY this player's specific record slot in PLAYER.DAT.
  If another node saved this warrior since we last did, this session is
  stale, so we disconnect instead of overwriting the newer progress. }
procedure SavePlayer(const P: TPlayer);
var
  F: file of TPlayer;
  OnDisk, ToWrite: TPlayer;
  Retries: Integer;
  Opened, ReadOK: Boolean;
begin
  if CurrentPlayerIndex < 0 then
    Exit;

  Assign(F, SAVE_FILE);
  Retries := 0;
  Opened := False;

  { Retry briefly if another concurrent player has PLAYER.DAT locked }
  repeat
    {$I-} Reset(F); {$I+}
    if IOResult = 0 then
      Opened := True
    else
    begin
      Inc(Retries);
      Delay(25);
    end;
  until Opened or (Retries >= 20);

  if not Opened then
  begin
    TextColor(LightRed);
    WriteLn('*** WARNING: Your progress could not be saved (PLAYER.DAT is busy). ***');
    TextColor(LightGray);
    Exit;
  end;

  {$I-}
  Seek(F, CurrentPlayerIndex);
  Read(F, OnDisk);
  {$I+}
  ReadOK := IOResult = 0;

  if (not ReadOK) or (OnDisk.SaveCount <> SessionSaveCount) or
     (UpperCase(Trim(OnDisk.Name)) <> UpperCase(Trim(P.Name))) then
  begin
    Close(F);
    WriteLn;
    TextColor(LightRed);
    WriteLn('*** This warrior is active on another node. This session has ended. ***');
    TextColor(LightGray);
    Halt;
  end;

  ToWrite := P;
  Inc(SessionSaveCount);
  ToWrite.SaveCount := SessionSaveCount;

  Seek(F, CurrentPlayerIndex);
  Write(F, ToWrite);
  Close(F);
end;

{ Searches PLAYER.DAT by Name; returns record index (0..N-1) or -1 if not found }
function FindPlayerByName(const SearchName: string; var FoundRec: TPlayer): LongInt;
var
  F: file of TPlayer;
  TempRec: TPlayer;
  i: LongInt;
begin
  FindPlayerByName := -1;
  Assign(F, SAVE_FILE);
  {$I-} Reset(F); {$I+}
  if IOResult <> 0 then
    Exit;

  for i := 0 to FileSize(F) - 1 do
  begin
    Seek(F, i);
    Read(F, TempRec);
    if UpperCase(Trim(TempRec.Name)) = UpperCase(Trim(SearchName)) then
    begin
      FoundRec := TempRec;
      FindPlayerByName := i;
      Break;
    end;
  end;

  Close(F);
end;

{ Checks if the real-world calendar date has changed since last reset }
procedure CheckDailyReset(var P: TPlayer);
var
  Today, Interest: LongInt;
begin
  Today := Trunc(Date);

  { <> rather than > so a server clock moved backwards cannot freeze resets }
  if Today <> P.LastPlayDay then
  begin
    P.LastPlayDay := Today;
    if TodayCondition = cdStorm then
      P.FightsLeft := 4
    else
      P.FightsLeft := 5;
    P.TavernDone := False;
    P.BridgeDone := False;
    P.SysOpDone := False;
    P.ConfessDone := False;
    P.IronDoorDone := False;
    P.PoorBoxDone := False;
    P.AlleyHeat := 0;
    P.CryptState := CRYPT_UNROLLED;

    { 5% daily interest, capped per level so balances cannot snowball }
    Interest := P.BankGold div 20;
    if (P.BankGold > 0) and (Interest = 0) then
      Interest := 1;
    if Interest > MAX_INTEREST_PER_LEVEL * LongInt(P.Level) then
      Interest := MAX_INTEREST_PER_LEVEL * LongInt(P.Level);
    AddGold(P.BankGold, Interest);

    SavePlayer(P);

    ClrScr;
    TextColor(Yellow);
    WriteLn('===========================================================');
    WriteLn('             A NEW DAWN BREAKS OVER SOUTH RIDGE            ');
    WriteLn('===========================================================');
    TextColor(LightGreen);
    WriteLn('Your daily forest fights (', P.FightsLeft, '), Tavern Pit, Creek Footbridge,');
    WriteLn('crypt, chapel, and back alleys have all been reset!');
    if Interest > 0 then
      WriteLn('Your bank vault earned ', Interest, ' gold in overnight interest (Balance: ', P.BankGold, ').');
    WriteLn;
    TextColor(LightCyan);
    WriteLn('Today in South Ridge: ', ConditionName(TodayCondition));
    PrintConditionDetails(TodayCondition);
    TextColor(LightGray);
    Pause;
  end;
end;

{ Appends a brand-new player record to the end of PLAYER.DAT.
  Returns False if the save file could not be opened safely. }
function CreateNewCharacter(var P: TPlayer; const ChosenName: string): Boolean;
var
  F: file of TPlayer;
  NewPin: string;
  Existing: TPlayer;
  Retries: Integer;
  Opened: Boolean;
begin
  CreateNewCharacter := False;
  WriteLn;
  TextColor(DarkGray);
  WriteLn('(Tip: Pick a simple game PIN - never reuse a real password over Telnet.)');
  TextColor(Yellow);
  repeat
    Write('Create a PIN for ', ChosenName, ' (4-16 chars): ');
    TextColor(White);
    NewPin := Trim(ReadInput(16, True));
    TextColor(Yellow);
  until Length(NewPin) >= 4;
  TextColor(LightGray);

  { Someone may have claimed the name while we were typing the PIN }
  if FindPlayerByName(ChosenName, Existing) >= 0 then
  begin
    TextColor(LightRed);
    WriteLn('Another warrior just claimed the name "', ChosenName, '". Pick another.');
    TextColor(LightGray);
    Pause;
    Exit;
  end;

  FillChar(P, SizeOf(P), 0);
  P.Name := ChosenName;
  P.Pin := HashPin(ChosenName, NewPin);
  P.Level := 1;
  P.XP := 0;
  P.MaxHP := 50;
  P.HP := 50;
  P.MaxMP := 20;
  P.MP := 20;
  P.Strength := 10;
  P.Gold := 60;
  P.BankGold := 0;
  if TodayCondition = cdStorm then
    P.FightsLeft := 4
  else
    P.FightsLeft := 5;
  P.TavernDone := False;
  P.BridgeDone := False;
  P.LastPlayDay := Trunc(Date);
  P.WeaponIndex := 1;
  P.ArmorIndex := 1;
  P.CryptState := CRYPT_UNROLLED;
  P.SaveCount := 0;

  Assign(F, SAVE_FILE);

  { Only create a fresh file when none exists; never truncate a busy one }
  if not FileExists(SAVE_FILE) then
  begin
    {$I-} Rewrite(F); {$I+}
    Opened := IOResult = 0;
  end
  else
  begin
    Retries := 0;
    repeat
      {$I-} Reset(F); {$I+}
      Opened := IOResult = 0;
      if not Opened then
      begin
        Inc(Retries);
        Delay(25);
      end;
    until Opened or (Retries >= 20);
  end;

  if not Opened then
  begin
    TextColor(LightRed);
    WriteLn('The town registry is busy. Please try again in a moment.');
    TextColor(LightGray);
    Pause;
    Exit;
  end;

  CurrentPlayerIndex := FileSize(F);
  SessionSaveCount := 0;
  Seek(F, CurrentPlayerIndex);
  Write(F, P);
  Close(F);
  CreateNewCharacter := True;
  PostNews('A stranger named ' + ChosenName + ' wandered into South Ridge.');
end;

{ True when A should be listed above B in the rankings }
function RanksAbove(const A, B: TPlayer): Boolean;
begin
  RanksAbove := (A.Level > B.Level) or ((A.Level = B.Level) and (A.XP > B.XP));
end;

{ Shared helper used by both the Login Screen (top 5) and Town Hall of Fame (top 15).
  Streams every record and keeps only the top rows, so any number of players works. }
procedure PrintTopRankings(MaxRows: Integer; const HighlightName: string);
const
  MAX_SHOWN = 15;
var
  F: file of TPlayer;
  Top: array[1..MAX_SHOWN] of TPlayer;
  Rec: TPlayer;
  Count, i, Slot: Integer;
  WeaponName: string;
begin
  if MaxRows > MAX_SHOWN then
    MaxRows := MAX_SHOWN;

  Assign(F, SAVE_FILE);
  {$I-} Reset(F); {$I+}
  if IOResult <> 0 then
  begin
    TextColor(DarkGray);
    WriteLn('  (No champions yet - claim the throne!)');
    TextColor(LightGray);
    Exit;
  end;

  Count := 0;
  while not Eof(F) do
  begin
    Read(F, Rec);
    Slot := Count + 1;
    while (Slot > 1) and RanksAbove(Rec, Top[Slot - 1]) do
      Dec(Slot);
    if Slot <= MaxRows then
    begin
      if Count < MaxRows then
        Inc(Count);
      for i := Count downto Slot + 1 do
        Top[i] := Top[i - 1];
      Top[Slot] := Rec;
    end;
  end;
  Close(F);

  if Count = 0 then
  begin
    TextColor(DarkGray);
    WriteLn('  (No champions yet - claim the throne!)');
    TextColor(LightGray);
    Exit;
  end;

  TextColor(LightCyan);
  WriteLn('Rank  ', PadRight('Warrior', 31), 'Lvl         XP   Weapon');
  TextColor(DarkGray);
  WriteLn('----------------------------------------------------------------------------');

  for i := 1 to Count do
  begin
    if (HighlightName <> '') and
       (UpperCase(Trim(Top[i].Name)) = UpperCase(Trim(HighlightName))) then
      TextColor(LightGreen)
    else if i = 1 then
      TextColor(Yellow)
    else
      TextColor(LightGray);

    if (Top[i].WeaponIndex >= 1) and (Top[i].WeaponIndex <= High(WEAPONS)) then
      WeaponName := WEAPONS[Top[i].WeaponIndex].Name
    else
      WeaponName := '?';

    WriteLn('#', i:2, '   ',
            PadRight(Top[i].Name, 30), ' ',
            Top[i].Level:3, '  ',
            Top[i].XP:9, '   ',
            WeaponName);
  end;

  TextColor(LightGray);
end;

procedure ShowLeaderboard(const CurrentPlayerName: string);
begin
  ClrScr;
  TextColor(Yellow);
  WriteLn('===================================================================');
  WriteLn('                  HALL OF FAME - HEROES OF SOUTH RIDGE             ');
  WriteLn('===================================================================');
  PrintTopRankings(15, CurrentPlayerName);
  Pause;
end;

function LoginPlayer(var P: TPlayer): Boolean;
var
  InputName: string;
  InputPin: string;
  ExistingRec: TPlayer;
  FoundIdx: LongInt;
  Attempts: Integer;
  Choice: Char;
begin
  LoginPlayer := False;
  CurrentPlayerIndex := -1;
  SessionSaveCount := 0;

  repeat
    ClrScr;
    TextColor(LightRed);
    WriteLn('===================================================================');
    WriteLn('                         THE SOUTH RIDGE                           ');
    WriteLn('                       -------------------                         ');
    WriteLn('               This realm is still in development.                 ');
    WriteLn('        It will occasionally be wiped after an update.             ');
    WriteLn('===================================================================');
    TextColor(Yellow);
    WriteLn('--- TOP WARRIORS OF THE REALM ---');
    PrintTopRankings(5, '');
    WriteLn;
    TextColor(LightGray);
    Write('Enter your warrior''s name (or blank to quit): ');
    TextColor(White);
    InputName := Trim(ReadInput(30, False));
    TextColor(LightGray);

    if InputName = '' then
      Exit;

    FoundIdx := FindPlayerByName(InputName, ExistingRec);

    if FoundIdx >= 0 then
    begin
      Attempts := 0;
      repeat
        Inc(Attempts);
        Write('Enter PIN for ', ExistingRec.Name, ': ');
        TextColor(White);
        InputPin := Trim(ReadInput(16, True));
        TextColor(LightGray);

        if HashPin(ExistingRec.Name, InputPin) = ExistingRec.Pin then
        begin
          P := ExistingRec;
          CurrentPlayerIndex := FoundIdx;
          SessionSaveCount := ExistingRec.SaveCount;
          TextColor(LightGreen);
          WriteLn;
          WriteLn('Welcome back, ', P.Name, ' (Level ', P.Level, ')!');
          TextColor(LightGray);
          Pause;
          CheckDailyReset(P);
          LoginPlayer := True;
          Exit;
        end
        else
        begin
          TextColor(Red);
          WriteLn('Incorrect PIN (', Attempts, '/3).');
          TextColor(LightGray);
          Delay(2000); { Slows down PIN guessing }
        end;
      until Attempts >= 3;

      WriteLn('Too many failed PIN attempts. Disconnecting.');
      Delay(1000);
      Exit;
    end
    else
    begin
      WriteLn;
      TextColor(Yellow);
      Write('No warrior named "', InputName, '" exists. Create new character? [Y/N]: ');
      TextColor(LightGray);
      Choice := UpCase(GetKey);
      WriteLn(Choice);

      if Choice = 'Y' then
      begin
        if CreateNewCharacter(P, InputName) then
        begin
          TextColor(LightGreen);
          WriteLn;
          WriteLn('Character created! Entering South Ridge...');
          TextColor(LightGray);
          Pause;
          LoginPlayer := True;
          Exit;
        end;
      end;
    end;
  until False;
end;

procedure ShowStats(const P: TPlayer);
begin
  ClrScr;
  TextColor(LightCyan);
  WriteLn('=== ', P.Name, ' (Level ', P.Level, ') ===');
  TextColor(LightGray);
  WriteLn('Experience : ', P.XP, ' / ', XPForNextLevel(P.Level), ' XP');
  WriteLn('Hit Points : ', P.HP, ' / ', P.MaxHP);
  WriteLn('Magic Pts  : ', P.MP, ' / ', P.MaxMP);
  WriteLn('Strength   : ', P.Strength);
  WriteLn('Gold (Hand): ', P.Gold);
  WriteLn('Gold (Bank): ', P.BankGold);
  WriteLn('Fights Left: ', P.FightsLeft);
  WriteLn('Weapon     : ', WEAPONS[P.WeaponIndex].Name, ' (+', WEAPONS[P.WeaponIndex].StatBonus, ' Atk)');
  WriteLn('Armor      : ', ARMORS[P.ArmorIndex].Name, ' (+', ARMORS[P.ArmorIndex].StatBonus, ' Def)');
  Pause;
end;

function CastCombatSkill(var P: TPlayer; const EnemyName: string; var EnemyHP: LongInt): Boolean;
var
  i, Pick: Integer;
  EffectAmt: LongInt;
  Choice: Char;
begin
  CastCombatSkill := False;
  WriteLn;
  TextColor(LightCyan);
  WriteLn('--- Combat Skills (MP: ', P.MP, '/', P.MaxMP, ') ---');
  TextColor(LightGray);

  for i := 1 to High(SKILLS) do
  begin
    if P.Level >= SKILLS[i].MinLevel then
      WriteLn('[', i, '] ', SKILLS[i].Name, ' (', SKILLS[i].MPCost, ' MP) - Base Power: ', SKILLS[i].Power)
    else
    begin
      TextColor(DarkGray);
      WriteLn('[', i, '] Locked (Requires Level ', SKILLS[i].MinLevel, ')');
      TextColor(LightGray);
    end;
  end;
  WriteLn('[0] Cancel');
  Write('Choose skill: ');

  Choice := GetKey;
  WriteLn(Choice);

  if Choice in ['1'..'9'] then
  begin
    Pick := Ord(Choice) - Ord('0');
    if Pick > High(SKILLS) then
      Exit;

    if P.Level < SKILLS[Pick].MinLevel then
    begin
      WriteLn('You have not unlocked that skill yet.');
      Exit;
    end;

    if P.MP < SKILLS[Pick].MPCost then
    begin
      TextColor(Red);
      WriteLn('Not enough MP!');
      TextColor(LightGray);
      Exit;
    end;

    P.MP := P.MP - SKILLS[Pick].MPCost;
    EffectAmt := SKILLS[Pick].Power + Random(P.Level * 4 + 1);

    if SKILLS[Pick].IsHeal then
    begin
      if EffectAmt > P.MaxHP - P.HP then
        P.HP := P.MaxHP
      else
        P.HP := P.HP + EffectAmt;
      TextColor(LightGreen);
      WriteLn('You channel ', SKILLS[Pick].Name, ' and restore ', EffectAmt, ' HP!');
    end
    else
    begin
      EnemyHP := EnemyHP - EffectAmt;
      TextColor(LightMagenta);
      WriteLn('You unleash ', SKILLS[Pick].Name, ' on ', EnemyName, ' for ', EffectAmt, ' magic damage!');
    end;

    TextColor(LightGray);
    CastCombatSkill := True;
  end;
end;

end.
