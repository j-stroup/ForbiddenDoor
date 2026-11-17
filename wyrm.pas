{$MODE TP}
program AshenWyrm;

uses
  Crt; { Provides ClrScr, TextColor, and ReadKey for single-keypress input }

type
  { 1. Custom data structures (Records) }
  TPlayer = record
    Name: string[30];
    HP, MaxHP: Integer;
    Strength: Integer;
    Gold: LongInt;
    FightsLeft: Integer;
  end;

  TMonster = record
    Name: string[30];
    HP: Integer;
    Attack: Integer;
    GoldReward: Integer;
  end;

const
  { 2. Pre-populated constant array (Notice the 1..3 index range) }
  MONSTERS: array[1..3] of TMonster = (
    (Name: 'Rabid Timber Wolf'; HP: 18; Attack: 4;  GoldReward: 15),
    (Name: 'Bandit Cutthroat';  HP: 28; Attack: 7;  GoldReward: 35),
    (Name: 'Hollow Knight';     HP: 42; Attack: 11; GoldReward: 75)
  );

var
  Hero: TPlayer;
  QuitGame: Boolean;

{ Helper to pause until the user presses any key }
procedure Pause;
begin
  WriteLn;
  TextColor(DarkGray);
  Write('[Press any key to continue]');
  TextColor(LightGray);
  ReadKey; { Reads one key immediately without waiting for Enter }
end;

{ Initialize starting stats. Notice the 'var' keyword! }
procedure InitPlayer(var P: TPlayer);
begin
  ClrScr;
  TextColor(Yellow);
  Write('Enter your warrior''s name: '); { Two single quotes escape an apostrophe }
  TextColor(White);
  ReadLn(P.Name);

  if P.Name = '' then
    P.Name := 'Strider';

  P.MaxHP := 50;
  P.HP := 50;
  P.Strength := 10;
  P.Gold := 25;
  P.FightsLeft := 5;
end;

procedure ShowStats(const P: TPlayer);
begin
  ClrScr;
  TextColor(LightCyan);
  WriteLn('=== ', P.Name, ' ===');
  TextColor(LightGray);
  WriteLn('Hit Points : ', P.HP, ' / ', P.MaxHP);
  WriteLn('Strength   : ', P.Strength);
  WriteLn('Gold       : ', P.Gold);
  WriteLn('Fights Left: ', P.FightsLeft);
  Pause;
end;

procedure VisitHealer(var P: TPlayer);
const
  HEAL_COST = 15;
begin
  ClrScr;
  TextColor(LightGreen);
  WriteLn('--- The Apothecary ---');
  TextColor(LightGray);

  if P.HP = P.MaxHP then
    WriteLn('You are already at full health.')
  else if P.Gold < HEAL_COST then
    WriteLn('You need ', HEAL_COST, ' gold for a poultice, but only have ', P.Gold, '.')
  else
  begin
    P.Gold := P.Gold - HEAL_COST;
    P.HP := P.MaxHP;
    WriteLn('The healer tends your wounds. HP restored to ', P.MaxHP, '!');
  end;
  Pause;
end;

procedure EnterForest(var P: TPlayer);
var
  Enemy: TMonster;
  Action: Char;
  PlayerDmg, EnemyDmg: Integer;
begin
  ClrScr;
  if P.FightsLeft <= 0 then
  begin
    WriteLn('You are exhausted for today. Rest until tomorrow.');
    Pause;
    Exit; { Immediately exits the procedure }
  end;

  Dec(P.FightsLeft); { Built-in shorthand for P.FightsLeft := P.FightsLeft - 1 }

  { Pick a random monster from index 1 to 3 }
  Enemy := MONSTERS[Random(3) + 1];

  TextColor(LightRed);
  WriteLn('A ', Enemy.Name, ' steps out from the pines!');
  TextColor(LightGray);

  { Combat loop }
  repeat
    WriteLn;
    WriteLn(P.Name, ' HP: ', P.HP, '  |  ', Enemy.Name, ' HP: ', Enemy.HP);
    Write('[A]ttack or [R]un? ');
    Action := UpCase(ReadKey);
    WriteLn(Action);

    if Action = 'A' then
    begin
      { Player swings }
      PlayerDmg := Random(P.Strength) + 3;
      Enemy.HP := Enemy.HP - PlayerDmg;
      TextColor(LightGreen);
      WriteLn('You strike the ', Enemy.Name, ' for ', PlayerDmg, ' damage!');

      { Monster swings back if still alive }
      if Enemy.HP > 0 then
      begin
        EnemyDmg := Random(Enemy.Attack) + 1;
        P.HP := P.HP - EnemyDmg;
        TextColor(LightRed);
        WriteLn('The ', Enemy.Name, ' hits you for ', EnemyDmg, ' damage!');
      end;
      TextColor(LightGray);
    end
    else if Action = 'R' then
    begin
      WriteLn('You retreat back toward the town road.');
      Pause;
      Exit;
    end;
  until (Enemy.HP <= 0) or (P.HP <= 0);

  WriteLn;
  if P.HP <= 0 then
  begin
    TextColor(Red);
    WriteLn('You collapse in the dirt! A passerby drags you back to town.');
    P.HP := 1;
    P.Gold := P.Gold div 2; { 'div' performs integer division }
  end
  else
  begin
    TextColor(Yellow);
    WriteLn('Victory! You loot ', Enemy.GoldReward, ' gold.');
    P.Gold := P.Gold + Enemy.GoldReward;
  end;

  TextColor(LightGray);
  Pause;
end;

procedure TownMenu;
var
  Choice: Char;
begin
  ClrScr;
  TextColor(LightRed);
  WriteLn('====================================');
  WriteLn('     TOWN OF ASHEN RIDGE (HP: ', Hero.HP, ')');
  WriteLn('====================================');
  TextColor(LightGray);
  WriteLn('[F] Enter the Dark Forest (', Hero.FightsLeft, ' fights left)');
  WriteLn('[H] Visit the Healer (15 gold)');
  WriteLn('[V] View Warrior Stats');
  WriteLn('[Q] Quit Game');
  WriteLn;
  Write('Your choice: ');

  Choice := UpCase(ReadKey); { Convert 'f' to 'F' automatically }
  case Choice of
    'F': EnterForest(Hero);
    'H': VisitHealer(Hero);
    'V': ShowStats(Hero);
    'Q': QuitGame := True;
  end;
end;

{ === MAIN PROGRAM === }
begin
  Randomize; { Seeds the random number generator using the system clock }
  QuitGame := False;
  InitPlayer(Hero);

  repeat
    TownMenu;
  until QuitGame;

  ClrScr;
  WriteLn('Safe travels, ', Hero.Name, '.');
end.