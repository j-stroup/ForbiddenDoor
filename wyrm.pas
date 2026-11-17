{$MODE TP}
program AshenWyrm;

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

  TPlayer = record
    Name: string[30];
    Level: Integer;       { New: Current character level }
    XP: LongInt;          { New: Accumulated experience points }
    HP, MaxHP: Integer;
    Strength: Integer;
    Gold: LongInt;
    FightsLeft: Integer;
    WeaponIndex: Integer;
    ArmorIndex: Integer;
  end;

  TMonster = record
    Name: string[30];
    HP: Integer;
    Attack: Integer;
    GoldReward: Integer;
    XPReward: Integer;    { New: XP granted on defeat }
  end;

const
  WEAPONS: array[1..4] of TItem = (
    (Name: 'Rusty Dagger';       StatBonus: 2;  Cost: 0),
    (Name: 'Iron Shortsword';    StatBonus: 5;  Cost: 50),
    (Name: 'Steel Broadsword';   StatBonus: 10; Cost: 150),
    (Name: 'Ashen Greatsword';   StatBonus: 18; Cost: 400)
  );

  ARMORS: array[1..4] of TItem = (
    (Name: 'Tattered Tunic';     StatBonus: 0;  Cost: 0),
    (Name: 'Boiled Leather';     StatBonus: 2;  Cost: 45),
    (Name: 'Chainmail Hauberk';  StatBonus: 5;  Cost: 140),
    (Name: 'Knight''s Plate';    StatBonus: 9;  Cost: 375)
  );

  MONSTERS: array[1..4] of TMonster = (
    (Name: 'Rabid Timber Wolf'; HP: 18; Attack: 5;  GoldReward: 20;  XPReward: 25),
    (Name: 'Bandit Cutthroat';  HP: 30; Attack: 9;  GoldReward: 45;  XPReward: 50),
    (Name: 'Hollow Knight';     HP: 48; Attack: 14; GoldReward: 95;  XPReward: 110),
    (Name: 'Ashen Wyrmling';    HP: 75; Attack: 20; GoldReward: 220; XPReward: 250)
  );

var
  Hero: TPlayer;
  QuitGame: Boolean;

procedure Pause;
begin
  WriteLn;
  TextColor(DarkGray);
  Write('[Press any key to continue]');
  TextColor(LightGray);
  ReadKey;
end;

{ === GAME FORMULA FUNCTIONS === }

{ A 'function' computes and returns a single value }
function XPForNextLevel(CurrentLevel: Integer): LongInt;
begin
  { Level 1 -> 100 XP, Level 2 -> 250 XP, Level 3 -> 450 XP, etc. }
  XPForNextLevel := (CurrentLevel * 100) + ((CurrentLevel - 1) * 50);
end;

{ === BINARY FILE PERSISTENCE === }

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

  {$I-}
  Reset(F);
  {$I+}

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
  P.Strength := 10;
  P.Gold := 60;
  P.FightsLeft := 5;
  P.WeaponIndex := 1;
  P.ArmorIndex := 1;

  SavePlayer(P);
end;

{ === CHARACTER, TRAINING & SHOPS === }

procedure ShowStats(const P: TPlayer);
begin
  ClrScr;
  TextColor(LightCyan);
  WriteLn('=== ', P.Name, ' (Level ', P.Level, ') ===');
  TextColor(LightGray);
  WriteLn('Experience : ', P.XP, ' / ', XPForNextLevel(P.Level), ' XP');
  WriteLn('Hit Points : ', P.HP, ' / ', P.MaxHP);
  WriteLn('Strength   : ', P.Strength);
  WriteLn('Gold       : ', P.Gold);
  WriteLn('Fights Left: ', P.FightsLeft);
  WriteLn('Weapon     : ', WEAPONS[P.WeaponIndex].Name, ' (+', WEAPONS[P.WeaponIndex].StatBonus, ' Atk)');
  WriteLn('Armor      : ', ARMORS[P.ArmorIndex].Name, ' (+', ARMORS[P.ArmorIndex].StatBonus, ' Def)');
  Pause;
end;

procedure VisitTrainer(var P: TPlayer);
var
  Needed: LongInt;
begin
  ClrScr;
  Needed := XPForNextLevel(P.Level);

  TextColor(LightMagenta);
  WriteLn('--- Master Vane''s Training Grounds ---');
  TextColor(LightGray);
  WriteLn('Current Level : ', P.Level);
  WriteLn('Current XP    : ', P.XP, ' / ', Needed);
  WriteLn;

  if P.XP < Needed then
  begin
    WriteLn('Master Vane sizes you up and shakes his head.');
    WriteLn('"You need ', Needed - P.XP, ' more experience before I can train you."');
  end
  else
  begin
    Inc(P.Level);
    P.MaxHP := P.MaxHP + 15;
    P.HP := P.MaxHP;
    P.Strength := P.Strength + 4;
    SavePlayer(P);

    TextColor(Yellow);
    WriteLn('*** LEVEL UP! You are now Level ', P.Level, '! ***');
    TextColor(LightGreen);
    WriteLn('Max HP increased by +15 (now ', P.MaxHP, ') and fully restored!');
    WriteLn('Strength increased by +4 (now ', P.Strength, ')!');
    TextColor(LightGray);
  end;
  Pause;
end;

procedure VisitWeaponShop(var P: TPlayer);
var
  i, Pick: Integer;
  Choice: Char;
begin
  ClrScr;
  TextColor(LightCyan);
  WriteLn('--- The Blacksmith (Your Gold: ', P.Gold, ') ---');
  TextColor(LightGray);
  WriteLn('Equipped: ', WEAPONS[P.WeaponIndex].Name);
  WriteLn;

  for i := 2 to 4 do
    WriteLn('[', i, '] ', WEAPONS[i].Name, ' (+', WEAPONS[i].StatBonus, ' Atk) - ', WEAPONS[i].Cost, ' gold');

  WriteLn('[0] Leave Shop');
  WriteLn;
  Write('Select a weapon to buy: ');
  Choice := ReadKey;
  WriteLn(Choice);

  if Choice in ['2'..'4'] then
  begin
    Pick := Ord(Choice) - Ord('0');

    if Pick <= P.WeaponIndex then
      WriteLn('You already own that weapon or better!')
    else if P.Gold < WEAPONS[Pick].Cost then
      WriteLn('You do not have enough gold.')
    else
    begin
      P.Gold := P.Gold - WEAPONS[Pick].Cost;
      P.WeaponIndex := Pick;
      SavePlayer(P);
      TextColor(LightGreen);
      WriteLn('You equip the ', WEAPONS[Pick].Name, '!');
      TextColor(LightGray);
    end;
    Pause;
  end;
end;

procedure VisitArmorShop(var P: TPlayer);
var
  i, Pick: Integer;
  Choice: Char;
begin
  ClrScr;
  TextColor(LightCyan);
  WriteLn('--- The Armorer (Your Gold: ', P.Gold, ') ---');
  TextColor(LightGray);
  WriteLn('Equipped: ', ARMORS[P.ArmorIndex].Name);
  WriteLn;

  for i := 2 to 4 do
    WriteLn('[', i, '] ', ARMORS[i].Name, ' (+', ARMORS[i].StatBonus, ' Def) - ', ARMORS[i].Cost, ' gold');

  WriteLn('[0] Leave Shop');
  WriteLn;
  Write('Select armor to buy: ');
  Choice := ReadKey;
  WriteLn(Choice);

  if Choice in ['2'..'4'] then
  begin
    Pick := Ord(Choice) - Ord('0');

    if Pick <= P.ArmorIndex then
      WriteLn('You already own that armor or better!')
    else if P.Gold < ARMORS[Pick].Cost then
      WriteLn('You do not have enough gold.')
    else
    begin
      P.Gold := P.Gold - ARMORS[Pick].Cost;
      P.ArmorIndex := Pick;
      SavePlayer(P);
      TextColor(LightGreen);
      WriteLn('You strap on the ', ARMORS[Pick].Name, '!');
      TextColor(LightGray);
    end;
    Pause;
  end;
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
    WriteLn('You need ', HEAL_COST, ' gold, but only have ', P.Gold, '.')
  else
  begin
    P.Gold := P.Gold - HEAL_COST;
    P.HP := P.MaxHP;
    SavePlayer(P);
    WriteLn('Your wounds close. HP restored to ', P.MaxHP, '!');
  end;
  Pause;
end;

procedure RestAtInn(var P: TPlayer);
begin
  ClrScr;
  P.FightsLeft := 5;
  P.HP := P.MaxHP;
  SavePlayer(P);
  TextColor(Yellow);
  WriteLn('You sleep until dawn. HP and daily forest fights restored!');
  TextColor(LightGray);
  Pause;
end;

{ === COMBAT === }

procedure EnterForest(var P: TPlayer);
var
  Enemy: TMonster;
  Action: Char;
  PlayerDmg, EnemyDmg, MaxMonsterIdx: Integer;
begin
  ClrScr;
  if P.FightsLeft <= 0 then
  begin
    WriteLn('You are exhausted. Visit the Inn to rest for tomorrow.');
    Pause;
    Exit;
  end;

  Dec(P.FightsLeft);

  { Unlock the 4th monster once the player reaches Level 2 }
  if P.Level >= 2 then
    MaxMonsterIdx := 4
  else
    MaxMonsterIdx := 3;

  Enemy := MONSTERS[Random(MaxMonsterIdx) + 1];

  TextColor(LightRed);
  WriteLn('A ', Enemy.Name, ' emerges from the shadows!');
  TextColor(LightGray);

  repeat
    WriteLn;
    WriteLn(P.Name, ' HP: ', P.HP, '  |  ', Enemy.Name, ' HP: ', Enemy.HP);
    Write('[A]ttack or [R]un? ');
    Action := UpCase(ReadKey);
    WriteLn(Action);

    if Action = 'A' then
    begin
      PlayerDmg := Random(P.Strength) + WEAPONS[P.WeaponIndex].StatBonus + 1;
      Enemy.HP := Enemy.HP - PlayerDmg;
      TextColor(LightGreen);
      WriteLn('You swing your ', WEAPONS[P.WeaponIndex].Name, ' for ', PlayerDmg, ' damage!');

      if Enemy.HP > 0 then
      begin
        EnemyDmg := (Random(Enemy.Attack) + 1) - ARMORS[P.ArmorIndex].StatBonus;
        if EnemyDmg < 1 then
          EnemyDmg := 1;

        P.HP := P.HP - EnemyDmg;
        TextColor(LightRed);
        WriteLn('The ', Enemy.Name, ' hits you for ', EnemyDmg, ' damage!');
      end;
      TextColor(LightGray);
    end
    else if Action = 'R' then
    begin
      SavePlayer(P);
      WriteLn('You retreat back to town.');
      Pause;
      Exit;
    end;
  until (Enemy.HP <= 0) or (P.HP <= 0);

  WriteLn;
  if P.HP <= 0 then
  begin
    TextColor(Red);
    WriteLn('You fall in battle! A merchant hauls you back to town.');
    P.HP := 1;
    P.Gold := P.Gold div 2;
  end
  else
  begin
    TextColor(Yellow);
    WriteLn('Victory! You claim ', Enemy.GoldReward, ' gold and ', Enemy.XPReward, ' XP.');
    P.Gold := P.Gold + Enemy.GoldReward;
    P.XP := P.XP + Enemy.XPReward;

    if P.XP >= XPForNextLevel(P.Level) then
    begin
      TextColor(LightMagenta);
      WriteLn('You have enough XP to level up! Visit the [T]raining Grounds in town.');
    end;
  end;

  SavePlayer(P);
  TextColor(LightGray);
  Pause;
end;

{ === MAIN LOOP === }

procedure TownMenu;
var
  Choice: Char;
begin
  ClrScr;
  TextColor(LightRed);
  WriteLn('==================================================');
  WriteLn(' TOWN OF SOUTH RIDGE | Lvl ', Hero.Level, ' | HP: ', Hero.HP, '/', Hero.MaxHP);
  WriteLn('==================================================');
  TextColor(LightGray);
  WriteLn('[F] Dark Forest (', Hero.FightsLeft, ' fights left)');
  WriteLn('[T] Training Grounds (XP: ', Hero.XP, '/', XPForNextLevel(Hero.Level), ')');
  WriteLn('[W] Weapon Shop (Blacksmith)');
  WriteLn('[A] Armor Shop (Armorer)');
  WriteLn('[H] Healer (15 gold)');
  WriteLn('[I] Inn (Rest & Reset Fights)');
  WriteLn('[V] View Warrior Stats');
  WriteLn('[Q] Save & Quit');
  WriteLn;
  Write('Your choice: ');

  Choice := UpCase(ReadKey);
  case Choice of
    'F': EnterForest(Hero);
    'T': VisitTrainer(Hero);
    'W': VisitWeaponShop(Hero);
    'A': VisitArmorShop(Hero);
    'H': VisitHealer(Hero);
    'I': RestAtInn(Hero);
    'V': ShowStats(Hero);
    'Q': begin
           SavePlayer(Hero);
           QuitGame := True;
         end;
  end;
end;

begin
  Randomize;
  QuitGame := False;

  if LoadPlayer(Hero) then
  begin
    ClrScr;
    TextColor(LightGreen);
    WriteLn('Welcome back, ', Hero.Name, ' (Level ', Hero.Level, ')!');
    TextColor(LightGray);
    Pause;
  end
  else
    InitPlayer(Hero);

  repeat
    TownMenu;
  until QuitGame;

  ClrScr;
  WriteLn('Progress saved to ', SAVE_FILE, '. Safe travels, ', Hero.Name, '.');
end.