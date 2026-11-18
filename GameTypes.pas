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
  SKILLS: array[1..3] of TSkill = (
    (Name: 'Ember Spark';   MPCost: 5;  Power: 16; MinLevel: 1; IsHeal: False),
    (Name: 'Mend Wounds';   MPCost: 8;  Power: 28; MinLevel: 2; IsHeal: True),
    (Name: 'Arcane Cleave'; MPCost: 14; Power: 42; MinLevel: 4; IsHeal: False)
  );

  WEAPONS: array[1..9] of TItem = (
    (Name: 'Rusty Dagger';          StatBonus: 2;  Cost: 0),
    (Name: 'Steel Fist';            StatBonus: 4;  Cost: 40),
    (Name: 'Iron Shortsword';       StatBonus: 5;  Cost: 50),
    (Name: 'Steel Broadsword';      StatBonus: 10; Cost: 150),
    (Name: 'Ashen Greatsword';      StatBonus: 18; Cost: 400),
    (Name: 'Broadsword';            StatBonus: 24; Cost: 500),
    (Name: 'Worm Man''s Mace';      StatBonus: 30; Cost: 800),
    (Name: 'Bloody Dagger of Cron'; StatBonus: 45; Cost: 1000),
    (Name: 'Flail of Sorrow';       StatBonus: 80; Cost: 1600)
  );

  ARMORS: array[1..4] of TItem = (
    (Name: 'Tattered Tunic';     StatBonus: 0;  Cost: 0),
    (Name: 'Boiled Leather';     StatBonus: 2;  Cost: 45),
    (Name: 'Chainmail Hauberk';  StatBonus: 5;  Cost: 140),
    (Name: 'Knight''s Plate';    StatBonus: 9;  Cost: 375)
  );

  MONSTERS: array[1..15] of TMonster = (
    (Name: 'Rabid Timber Wolf';             HP: 18;  Attack: 5;  GoldReward: 20;   XPReward: 25),
    (Name: 'Bandit Cutthroat';              HP: 30;  Attack: 9;  GoldReward: 45;   XPReward: 50),
    (Name: 'Hollow Knight';                 HP: 48;  Attack: 14; GoldReward: 95;   XPReward: 110),
    (Name: 'Ashen Wyrmling';                HP: 75;  Attack: 20; GoldReward: 220;  XPReward: 250),
    (Name: 'Mean Looking Bird';             HP: 90;  Attack: 20; GoldReward: 250;  XPReward: 280),
    (Name: 'Kyle';                          HP: 115; Attack: 20; GoldReward: 270;  XPReward: 320),
    (Name: 'Toxic Bear Zombie';             HP: 130; Attack: 20; GoldReward: 340;  XPReward: 360),
    (Name: 'Zebra Man';                     HP: 155; Attack: 20; GoldReward: 380;  XPReward: 4000),
    (Name: 'Really Big Squirrel';           HP: 180; Attack: 20; GoldReward: 450;  XPReward: 450),
    (Name: 'Evil Shadow Demon';             HP: 180; Attack: 20; GoldReward: 2300; XPReward: 550),
    (Name: 'Ghost Goat';                    HP: 240; Attack: 20; GoldReward: 520;  XPReward: 650),
    (Name: '10k Crows in a Trenchcoat';     HP: 300; Attack: 20; GoldReward: 580;  XPReward: 750),
    (Name: 'A Guy with 6 Arms, Named Greg'; HP: 450; Attack: 20; GoldReward: 640;  XPReward: 850),
    (Name: 'Drunken Redneck';               HP: 560; Attack: 20; GoldReward: 700;  XPReward: 1000),
    (Name: 'Boar God';                      HP: 700; Attack: 20; GoldReward: 400;  XPReward: 1600)
  );

procedure Pause;
function XPForNextLevel(CurrentLevel: Integer): LongInt;
procedure SavePlayer(const P: TPlayer);
function LoadPlayer(var P: TPlayer): Boolean;
procedure InitPlayer(var P: TPlayer);
procedure ShowStats(const P: TPlayer);

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
  XPForNextLevel := (CurrentLevel * 100) + ((CurrentLevel - 1) * 50);
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

end.