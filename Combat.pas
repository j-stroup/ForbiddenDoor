{$MODE TP}
unit Combat;

interface

uses
  Crt, GameTypes;

procedure EnterForest(var P: TPlayer);

implementation


procedure FightMonster(var P: TPlayer);
var
  Enemy: TMonster;
  Action: Char;
  PlayerDmg, EnemyDmg, MaxMonsterIdx: Integer;
  TurnTaken: Boolean;
begin
  case P.Level of
    1:    MaxMonsterIdx := 3;
    2:    MaxMonsterIdx := 4;
    3..5: MaxMonsterIdx := 7;
    6..9: MaxMonsterIdx := 11;
  else
    MaxMonsterIdx := 15;
  end;

  Enemy := MONSTERS[Random(MaxMonsterIdx) + 1];

  TextColor(LightRed);
  WriteLn('A ', Enemy.Name, ' emerges from the shadows!');
  TextColor(LightGray);

  repeat
    TurnTaken := False;
    WriteLn;
    WriteLn(P.Name, ' HP: ', P.HP, ' | MP: ', P.MP, '  ||  ', Enemy.Name, ' HP: ', Enemy.HP);
    Write('[A]ttack, [S]kill, or [R]un? ');
    Action := UpCase(ReadKey);
    WriteLn(Action);

    if Action = 'A' then
    begin
      PlayerDmg := Random(P.Strength) + WEAPONS[P.WeaponIndex].StatBonus + 1;
      Enemy.HP := Enemy.HP - PlayerDmg;
      TextColor(LightGreen);
      WriteLn('You swing your ', WEAPONS[P.WeaponIndex].Name, ' for ', PlayerDmg, ' damage!');
      TextColor(LightGray);
      TurnTaken := True;
    end
    else if Action = 'S' then
    begin
      TurnTaken := CastCombatSkill(P, Enemy.Name, Enemy.HP);
    end
    else if Action = 'R' then
    begin
      SavePlayer(P);
      WriteLn('You retreat back to town.');
      Pause;
      Exit;
    end;

    { Monster counterattacks only if the player completed an attack or skill and the enemy survived }
    if TurnTaken and (Enemy.HP > 0) then
    begin
      EnemyDmg := (Random(Enemy.Attack) + 1) - ARMORS[P.ArmorIndex].StatBonus;
      if EnemyDmg < 1 then
        EnemyDmg := 1;

      P.HP := P.HP - EnemyDmg;
      TextColor(LightRed);
      WriteLn('The ', Enemy.Name, ' hits you for ', EnemyDmg, ' damage!');
      TextColor(LightGray);
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

procedure EnterForest(var P: TPlayer);
var
  EventRoll, FoundGold, TrapDmg: Integer;
begin
  ClrScr;
  if P.FightsLeft <= 0 then
  begin
    WriteLn('You are exhausted. Visit the Inn to rest for tomorrow.');
    Pause;
    Exit;
  end;

  Dec(P.FightsLeft);
  EventRoll := Random(100) + 1;

  case EventRoll of
    1..10:
      begin
        FoundGold := (Random(25) + 15) * P.Level;
        P.Gold := P.Gold + FoundGold;
        TextColor(Yellow);
        WriteLn('You spot a half-buried iron lockbox beneath an old oak!');
        WriteLn('Inside, you find ', FoundGold, ' gold coins.');
        TextColor(LightGray);
        SavePlayer(P);
        Pause;
      end;

    11..18:
      begin
        TrapDmg := Random(6) + 3;
        P.HP := P.HP - TrapDmg;
        if P.HP < 1 then
          P.HP := 1;

        TextColor(LightRed);
        WriteLn('SNAP! You step into a rusted hunter''s snare hidden in the leaves!');
        WriteLn('You pry it open, taking ', TrapDmg, ' damage (HP: ', P.HP, '/', P.MaxHP, ').');
        TextColor(LightGray);
        SavePlayer(P);
        Pause;
      end;

    19..25:
      begin
        TextColor(LightGreen);
        WriteLn('A hooded forest hermit shares warm broth by a small campfire.');
        if P.HP < P.MaxHP then
        begin
          P.HP := P.MaxHP;
          WriteLn('Your strength returns! Hit points fully restored to ', P.MaxHP, '.');
        end
        else
        begin
          P.XP := P.XP + 15;
          WriteLn('You are already at full health, so she teaches you survival lore (+15 XP).');
        end;
        TextColor(LightGray);
        SavePlayer(P);
        Pause;
      end;
  else
    FightMonster(P);
  end;
end;

end.