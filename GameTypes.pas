{$MODE TP}
unit GameTypes;

interface

uses
  Crt, SysUtils;

const
  SAVE_FILE = 'PLAYER.DAT';

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
    Pin: string[16];      { New: Simple character PIN for login }
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
    WeaponIndex: Integer;
    ArmorIndex: Integer;
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

procedure Pause;
function XPForNextLevel(CurrentLevel: Integer): LongInt;
procedure SavePlayer(const P: TPlayer);
function LoginPlayer(var P: TPlayer): Boolean;
procedure ShowStats(const P: TPlayer);
procedure ShowLeaderboard(const CurrentPlayerName: string);
function CastCombatSkill(var P: TPlayer; const EnemyName: string; var EnemyHP: Integer): Boolean;

implementation

var
  { Private to GameTypes: tracks which slot in PLAYER.DAT belongs to this session }
  CurrentPlayerIndex: LongInt;

procedure Pause;
begin
  WriteLn;
  TextColor(DarkGray);
  Write('[Press any key to continue]');
  TextColor(LightGray);
  ReadKey;
end;

function XPForNextLevel(CurrentLevel: Integer): LongInt;
begin
  { Steeper progression: Lvl 1->185, Lvl 2->540, Lvl 5->2825, Lvl 10->10400 }
  XPForNextLevel := (LongInt(CurrentLevel) * CurrentLevel * 95) + (CurrentLevel * 90);
end;

{ Overwrites ONLY this player's specific record slot in PLAYER.DAT }
procedure SavePlayer(const P: TPlayer);
var
  F: file of TPlayer;
  Retries: Integer;
begin
  if CurrentPlayerIndex < 0 then
    Exit;

  Assign(F, SAVE_FILE);
  Retries := 0;

  { Retry briefly if another concurrent player has PLAYER.DAT locked }
  repeat
    {$I-} Reset(F); {$I+}
    if IOResult = 0 then
    begin
      Seek(F, CurrentPlayerIndex);
      Write(F, P);
      Close(F);
      Exit;
    end;
    Inc(Retries);
    Delay(25);
  until Retries >= 20;
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

{ Appends a brand-new player record to the end of PLAYER.DAT }
procedure CreateNewCharacter(var P: TPlayer; const ChosenName: string);
var
  F: file of TPlayer;
  NewPin: string[16];
begin
  WriteLn;
  TextColor(DarkGray);
  WriteLn('(Tip: Pick a simple game PIN—never reuse a real password over Telnet.)');
  TextColor(Yellow);
  repeat
    Write('Create a PIN for ', ChosenName, ' (4-16 chars): ');
    TextColor(White);
    ReadLn(NewPin);
    NewPin := Trim(NewPin);
    TextColor(Yellow);
  until Length(NewPin) >= 4;

  P.Name := ChosenName;
  P.Pin := NewPin;
  P.Level := 1;
  P.XP := 0;
  P.MaxHP := 50;
  P.HP := 50;
  P.MaxMP := 20;
  P.MP := 20;
  P.Strength := 10;
  P.Gold := 60;
  P.BankGold := 0;
  P.FightsLeft := 5;
  P.TavernDone := False;
  P.BridgeDone := False;
  P.WeaponIndex := 1;
  P.ArmorIndex := 1;

  Assign(F, SAVE_FILE);
  {$I-} Reset(F); {$I+}
  if IOResult <> 0 then
    Rewrite(F); { First character ever created on this server }

  CurrentPlayerIndex := FileSize(F);
  Seek(F, CurrentPlayerIndex);
  Write(F, P);
  Close(F);
end;

{ Handles title login / character creation; returns False if login fails }
{ Shared helper used by both the Login Screen (top 5) and Town Hall of Fame (top 15) }
procedure PrintTopRankings(MaxRows: Integer; const HighlightName: string);
const
  MAX_ROSTER = 100;
var
  F: file of TPlayer;
  Roster: array[1..MAX_ROSTER] of TPlayer;
  Temp: TPlayer;
  Count, i, j, DisplayLimit: Integer;
begin
  Assign(F, SAVE_FILE);
  {$I-} Reset(F); {$I+}
  if IOResult <> 0 then
  begin
    TextColor(DarkGray);
    WriteLn('  (No champions yet—claim the throne!)');
    TextColor(LightGray);
    Exit;
  end;

  Count := 0;
  while (not Eof(F)) and (Count < MAX_ROSTER) do
  begin
    Inc(Count);
    Read(F, Roster[Count]);
  end;
  Close(F);

  if Count = 0 then
  begin
    TextColor(DarkGray);
    WriteLn('  (No champions yet—claim the throne!)');
    TextColor(LightGray);
    Exit;
  end;

  { Sort descending by Level, then XP }
  for i := 1 to Count - 1 do
  begin
    for j := i + 1 to Count do
    begin
      if (Roster[j].Level > Roster[i].Level) or
         ((Roster[j].Level = Roster[i].Level) and (Roster[j].XP > Roster[i].XP)) then
      begin
        Temp := Roster[i];
        Roster[i] := Roster[j];
        Roster[j] := Temp;
      end;
    end;
  end;

  TextColor(LightCyan);
  WriteLn('Rank  Warrior                 Lvl     XP         Weapon');
  TextColor(DarkGray);
  WriteLn('-------------------------------------------------------------------');

  DisplayLimit := Count;
  if DisplayLimit > MaxRows then
    DisplayLimit := MaxRows;

  for i := 1 to DisplayLimit do
  begin
    if (HighlightName <> '') and
       (UpperCase(Trim(Roster[i].Name)) = UpperCase(Trim(HighlightName))) then
      TextColor(LightGreen)
    else if i = 1 then
      TextColor(Yellow)
    else
      TextColor(LightGray);

    WriteLn('#', i:2, '   ',
            Roster[i].Name:22, '  ',
            Roster[i].Level:3, '  ',
            Roster[i].XP:9, '   ',
            WEAPONS[Roster[i].WeaponIndex].Name);
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
  InputName: string[30];
  InputPin: string[16];
  ExistingRec: TPlayer;
  FoundIdx: LongInt;
  Attempts: Integer;
  Choice: Char;
begin
  LoginPlayer := False;
  CurrentPlayerIndex := -1;

  repeat
    ClrScr;
    TextColor(LightRed);
    WriteLn('===================================================================');
    WriteLn('               REALM OF THE ASHEN WYRM - SOUTH RIDGE               ');
    WriteLn('===================================================================');
    TextColor(Yellow);
    WriteLn('--- TOP WARRIORS OF THE REALM ---');
    PrintTopRankings(5, '');
    WriteLn;
    TextColor(LightGray);
    Write('Enter your warrior''s name (or blank to quit): ');
    TextColor(White);
    ReadLn(InputName);
    InputName := Trim(InputName);
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
        ReadLn(InputPin);
        TextColor(LightGray);

        if Trim(InputPin) = ExistingRec.Pin then
        begin
          P := ExistingRec;
          CurrentPlayerIndex := FoundIdx;
          TextColor(LightGreen);
          WriteLn;
          WriteLn('Welcome back, ', P.Name, ' (Level ', P.Level, ')!');
          TextColor(LightGray);
          Pause;
          LoginPlayer := True;
          Exit;
        end
        else
        begin
          TextColor(Red);
          WriteLn('Incorrect PIN (', Attempts, '/3).');
          TextColor(LightGray);
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
      Choice := UpCase(ReadKey);
      WriteLn(Choice);

      if Choice = 'Y' then
      begin
        CreateNewCharacter(P, InputName);
        TextColor(LightGreen);
        WriteLn;
        WriteLn('Character created! Entering South Ridge...');
        TextColor(LightGray);
        Pause;
        LoginPlayer := True;
        Exit;
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

function CastCombatSkill(var P: TPlayer; const EnemyName: string; var EnemyHP: Integer): Boolean;
var
  i, Pick, EffectAmt: Integer;
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

  Choice := ReadKey;
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
      P.HP := P.HP + EffectAmt;
      if P.HP > P.MaxHP then
        P.HP := P.MaxHP;
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