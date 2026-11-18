{$MODE TP}
unit GameTypes;

interface

uses
  Crt;

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
    Level: Integer;
    XP: LongInt;
    HP, MaxHP: Integer;
    MP, MaxMP: Integer;
    Strength: Integer;
    Gold: LongInt;
    BankGold: LongInt;
    FightsLeft: Integer;
    TavernDone: Boolean;
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
    (Name: 'Ember Spark';        MPCost: 5;  Power: 14;  MinLevel: 1;  IsHeal: False),
    (Name: 'Mend Wounds';        MPCost: 8;  Power: 26;  MinLevel: 2;  IsHeal: True),
    (Name: 'Frost Lance';        MPCost: 12; Power: 34;  MinLevel: 4;  IsHeal: False),
    (Name: 'Arcane Cleave';      MPCost: 18; Power: 52;  MinLevel: 6;  IsHeal: False),
    (Name: 'Greater Restoration';MPCost: 22; Power: 75;  MinLevel: 8;  IsHeal: True),
    (Name: 'Soul Rupture';       MPCost: 30; Power: 95;  MinLevel: 11; IsHeal: False),
    (Name: 'Ashen Cataclysm';    MPCost: 45; Power: 155; MinLevel: 14; IsHeal: False)
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
    (Name: 'Runed Warhammmer';      StatBonus: 58;  Cost: 5000),
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
    (Name: 'Rabid Timber Wolf';             HP: 16;   Attack: 4;  GoldReward: 20;   XPReward: 25),
    (Name: 'Bandit Cutthroat';              HP: 24;   Attack: 6;  GoldReward: 35;   XPReward: 40),
    (Name: 'Hollow Knight';                 HP: 34;   Attack: 8;  GoldReward: 55;   XPReward: 65),
    { Tier 2: Levels 3-4 }
    (Name: 'Ashen Wyrmling';                HP: 48;   Attack: 11; GoldReward: 95;   XPReward: 105),
    (Name: 'Mean Looking Bird';             HP: 64;   Attack: 14; GoldReward: 130;  XPReward: 140),
    (Name: 'Kyle';                          HP: 82;   Attack: 17; GoldReward: 175;  XPReward: 185),
    { Tier 3: Levels 5-6 }
    (Name: 'Toxic Bear Zombie';             HP: 105;  Attack: 20; GoldReward: 230;  XPReward: 240),
    (Name: 'Zebra Man';                     HP: 130;  Attack: 24; GoldReward: 290;  XPReward: 300),
    (Name: 'Really Big Squirrel';           HP: 160;  Attack: 28; GoldReward: 360;  XPReward: 375),
    { Tier 4: Levels 7-9 }
    (Name: 'Evil Shadow Demon';             HP: 195;  Attack: 33; GoldReward: 450;  XPReward: 465),
    (Name: 'Ghost Goat';                    HP: 235;  Attack: 38; GoldReward: 540;  XPReward: 560),
    (Name: '10k Crows in a Trenchcoat';     HP: 280;  Attack: 43; GoldReward: 640;  XPReward: 670),
    { Tier 5: Levels 10-12 }
    (Name: 'A Guy with 6 Arms, Named Greg'; HP: 340;  Attack: 49; GoldReward: 760;  XPReward: 800),
    (Name: 'Drunken Redneck';               HP: 405;  Attack: 55; GoldReward: 890;  XPReward: 940),
    (Name: 'Boar God';                      HP: 480;  Attack: 62; GoldReward: 1050; XPReward: 1120),
    { Tier 6: Levels 13-15 }
    (Name: 'Ironclad Juggernaut';           HP: 565;  Attack: 69; GoldReward: 1250; XPReward: 1340),
    (Name: 'Bog Witch of Ashtabula';        HP: 660;  Attack: 77; GoldReward: 1480; XPReward: 1580),
    (Name: 'Skeletal Colossus';             HP: 765;  Attack: 85; GoldReward: 1720; XPReward: 1850),
    { Tier 7: Levels 16-18 }
    (Name: 'Clockwork Abomination';         HP: 885;  Attack: 94; GoldReward: 2020; XPReward: 2200),
    (Name: 'Abyssal Leviathan';             HP: 1020; Attack: 104;GoldReward: 2380; XPReward: 2600),
    (Name: 'Pale Rider of the Ridge';       HP: 1170; Attack: 114;GoldReward: 2780; XPReward: 3050),
    { Tier 8: Level 19+ }
    (Name: 'Eldritch Forest Warden';        HP: 1340; Attack: 125;GoldReward: 3250; XPReward: 3600),
    (Name: 'Dread Sovereign';               HP: 1530; Attack: 137;GoldReward: 3850; XPReward: 4250),
    (Name: 'The Ancient Ashen Wyrm';        HP: 1780; Attack: 150;GoldReward: 4800; XPReward: 5300)
  );

procedure Pause;
function XPForNextLevel(CurrentLevel: Integer): LongInt;
procedure SavePlayer(const P: TPlayer);
function LoadPlayer(var P: TPlayer): Boolean;
procedure InitPlayer(var P: TPlayer);
procedure ShowStats(const P: TPlayer);
function CastCombatSkill(var P: TPlayer; const EnemyName: string; var EnemyHP: Integer): Boolean;

implementation

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
  { Lvl 1->105, Lvl 2->320, Lvl 5->1625, Lvl 10->6000 }
  XPForNextLevel := (LongInt(CurrentLevel) * CurrentLevel * 55) + (CurrentLevel * 50);
end;

procedure SavePlayer(const P: TPlayer);
var
  F: file of TPlayer;
begin
  Assign(F, SAVE_FILE);
  Rewrite(F);
  Write(F, P);
  Close(F);
end;

function LoadPlayer(var P: TPlayer): Boolean;
var
  F: file of TPlayer;
begin
  LoadPlayer := False;
  Assign(F, SAVE_FILE);
  {$I-} Reset(F); {$I+}
  if IOResult = 0 then
  begin
    if not Eof(F) then
    begin
      Read(F, P);
      LoadPlayer := True;
    end;
    Close(F);
  end;
end;

procedure InitPlayer(var P: TPlayer);
begin
  ClrScr;
  TextColor(Yellow);
  Write('No save file found. Enter your warrior''s name: ');
  TextColor(White);
  ReadLn(P.Name);

  if P.Name = '' then
    P.Name := 'Strider';

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
  P.WeaponIndex := 1;
  P.ArmorIndex := 1;

  SavePlayer(P);
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
    { Scale skill power with both base power and player level }
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