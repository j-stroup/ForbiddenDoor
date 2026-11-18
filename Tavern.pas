{$MODE TP}
unit Tavern;

interface

uses
  Crt, GameTypes;

procedure VisitTavern(var P: TPlayer);

implementation

const
  BRAWLERS: array[1..5] of string[30] = (
    'One-Eyed Butcher',
    'Disgraced Pit Fighter',
    'Iron-Jawed Dockworker',
    'Scarred Mercenary Captain',
    'The Undefeated Swede'
  );

  RUMORS: array[1..4] of string[75] = (
    'Word is a massive wyrm nests deep beyond the northern ridge...',
    'Old man Pritchard swears he saw 10,000 crows wearing a wool coat.',
    'The Apothecary waters down his poultices, though they still work.',
    'Keep your gold in the South Ridge vault—bandits love unconscious heroes.'
  );

procedure RunTavernBrawl(var P: TPlayer);
var
  OpponentName: string[30];
  OppHP, OppAttack, GoldPot, XPPot: Integer;
  PlayerDmg, OppDmg: Integer;
  Action: Char;
begin
  ClrScr;
  if P.TavernDone then
  begin
    WriteLn('The pit is empty for tonight. Rest at the Inn before challenging again.');
    Pause;
    Exit;
  end;

  OpponentName := BRAWLERS[Random(5) + 1];

  { Scale the challenger dynamically to stay dangerous at any player level }
  OppHP := 35 + (P.Level * 22);
  OppAttack := 7 + (P.Level * 4);
  GoldPot := 90 * P.Level;
  XPPot := 85 * P.Level;

  TextColor(LightRed);
  WriteLn('=== THE TAVERN PIT ===');
  TextColor(LightGray);
  WriteLn('Tonight''s champion is ', OpponentName, '!');
  WriteLn('Estimated Threat -> HP: ', OppHP, ' | Attack: ~', OppAttack);
  WriteLn('Purse on the Table -> ', GoldPot, ' gold & ', XPPot, ' XP');
  WriteLn;
  TextColor(Yellow);
  Write('Step into the ring? [Y/N]: ');
  TextColor(LightGray);

  Action := UpCase(ReadKey);
  WriteLn(Action);

  if Action <> 'Y' then
  begin
    WriteLn('You wisely keep your seat and nurse your mug.');
    Pause;
    Exit;
  end;

  { Lock out further brawls until the player sleeps at the Inn }
  P.TavernDone := True;
  SavePlayer(P);

  WriteLn;
  WriteLn('The crowd roars as the iron gate clangs shut behind you!');

  repeat
    WriteLn;
    WriteLn(P.Name, ' HP: ', P.HP, '  |  ', OpponentName, ' HP: ', OppHP);
    Write('[A]ttack or [F]orfeit? ');
    Action := UpCase(ReadKey);
    WriteLn(Action);

    if Action = 'A' then
    begin
      PlayerDmg := Random(P.Strength) + WEAPONS[P.WeaponIndex].StatBonus + 1;
      OppHP := OppHP - PlayerDmg;
      TextColor(LightGreen);
      WriteLn('You strike ', OpponentName, ' for ', PlayerDmg, ' damage!');

      if OppHP > 0 then
      begin
        OppDmg := (Random(OppAttack) + 1) - ARMORS[P.ArmorIndex].StatBonus;
        if OppDmg < 2 then
          OppDmg := 2; { Pit fighters always hit for at least 2 damage }

        P.HP := P.HP - OppDmg;
        TextColor(LightRed);
        WriteLn(OpponentName, ' slams you for ', OppDmg, ' damage!');
      end;
      TextColor(LightGray);
    end
    else if Action = 'F' then
    begin
      WriteLn('You throw in the towel! The crowd boos as you limp out.');
      SavePlayer(P);
      Pause;
      Exit;
    end;
  until (OppHP <= 0) or (P.HP <= 0);

  WriteLn;
  if P.HP <= 0 then
  begin
    TextColor(Red);
    WriteLn('LIGHTS OUT! ', OpponentName, ' knocks you cold.');
    WriteLn('You wake up in the mud behind the tavern, missing half your pocket gold.');
    P.HP := 1;
    P.Gold := P.Gold div 2;
  end
  else
  begin
    TextColor(Yellow);
    WriteLn('KNOCKOUT! The tavern erupts as ', OpponentName, ' hits the sawdust!');
    WriteLn('You collect the ', GoldPot, ' gold purse and gain ', XPPot, ' XP!');
    P.Gold := P.Gold + GoldPot;
    P.XP := P.XP + XPPot;
  end;

  SavePlayer(P);
  TextColor(LightGray);
  Pause;
end;

procedure VisitTavern(var P: TPlayer);
var
  Choice: Char;
begin
  repeat
    ClrScr;
    TextColor(Yellow);
    WriteLn('--- The Rusted Lantern Tavern ---');
    TextColor(LightGray);
    WriteLn('Smoke hangs thick from the rafters. Dice clatter in the corner.');
    WriteLn;
    if P.TavernDone then
      WriteLn('[B] The Fighting Pit (Closed until tomorrow)')
    else
      WriteLn('[B] The Fighting Pit (Daily High-Stakes Brawl Available!)');
    WriteLn('[R] Listen to Bar Rumors');
    WriteLn('[D] Buy a Mug of Ale (5 gold)');
    WriteLn('[L] Leave Tavern');
    WriteLn;
    Write('Your choice: ');

    Choice := UpCase(ReadKey);
    WriteLn(Choice);

    case Choice of
      'B': RunTavernBrawl(P);
      'R': begin
             WriteLn;
             TextColor(LightCyan);
             WriteLn('The barkeep leans in: "', RUMORS[Random(4) + 1], '"');
             TextColor(LightGray);
             Pause;
           end;
      'D': begin
             WriteLn;
             if P.Gold < 5 then
               WriteLn('The barkeep taps the empty bar. "Five gold for a pour, friend."')
             else
             begin
               P.Gold := P.Gold - 5;
               if P.HP < P.MaxHP then
                 Inc(P.HP);
               SavePlayer(P);
               WriteLn('You down a frothy mug of dark ale. Warmth spreads through your chest (+1 HP).');
             end;
             Pause;
           end;
    end;
  until Choice = 'L';
end;

end.