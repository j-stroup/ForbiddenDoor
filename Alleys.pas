{$MODE TP}
unit Alleys;

interface

uses
  Crt, SysUtils, GameTypes;

procedure VisitAlleys(var P: TPlayer);

implementation

procedure SecretIronDoor(var P: TPlayer);
var
  Code: string;
  Reward: LongInt;
begin
  ClrScr;
  TextColor(DarkGray);
  WriteLn('--- Unmarked Iron Cellar Door ---');
  TextColor(LightGray);
  WriteLn('A heavy rust-streaked slot slides open an inch. Two bloodshot eyes peer out.');
  WriteLn('"Password?"');
  WriteLn;
  Write('Speak password: ');
  TextColor(White);
  Code := UpperCase(Trim(ReadInput(30, False)));
  TextColor(LightGray);
  WriteLn;

  if P.IronDoorDone then
  begin
    WriteLn('The slot slams shut. "You already got yours tonight. Beat it."');
    Pause;
    Exit;
  end;

  if Code = 'U9LY' then
  begin
    P.IronDoorDone := True;
    Reward := 150 * LongInt(P.Level);
    AddGold(P.Gold, Reward);
    TextColor(Yellow);
    WriteLn('The deadbolt clanks back. A gloved hand slips you a heavy pouch (+', Reward, ' gold).');
  end
  else if Code = 'BRYCE' then
  begin
    P.IronDoorDone := True;
    P.Strength := P.Strength + 1;
    TextColor(LightGreen);
    WriteLn('A guy in a stained hoodie nods in respect and hands you a protein bar.');
    WriteLn('PERMANENT +1 STRENGTH!');
  end
  else if Code = '1993' then
  begin
    P.IronDoorDone := True;
    Reward := 60 * LongInt(P.Level);
    P.XP := P.XP + Reward;
    P.MP := P.MaxMP;
    TextColor(LightCyan);
    WriteLn('Modem carrier tones echo from down the stairs... (+', Reward, ' XP & Full MP!)');
  end
  else
  begin
    WriteLn('"Never heard of it." The iron slot snaps shut.');
  end;

  TextColor(LightGray);
  SavePlayer(P);
  Pause;
end;

{ Heat is saved on the player and only resets at midnight, so leaving and
  re-entering the alleys no longer wipes it. High heat means every search
  ends in thugs, which naturally caps how much a player can farm per day. }
procedure ScavengeAlley(var P: TPlayer);
var
  Roll, Heat: Integer;
  Amt: LongInt;
begin
  if P.AlleyHeat < 50 then
    Inc(P.AlleyHeat);
  Heat := P.AlleyHeat;
  Roll := (Random(100) + 1) + (Heat * 7);

  WriteLn;
  case Roll of
    1..18:
      begin
        Amt := (Random(28) + 14) * LongInt(P.Level);
        AddGold(P.Gold, Amt);
        TextColor(Yellow);
        WriteLn('Behind a collapsed brick stoop, you pry up a loose flagstone');
        WriteLn('and find a cutpurse''s stash (+', Amt, ' gold)!');
      end;

    19..34:
      begin
        Amt := (16 + Random(12)) * LongInt(P.Level);
        P.XP := P.XP + Amt;
        TextColor(LightCyan);
        WriteLn('You overhear two smugglers arguing through a cellar grate and');
        WriteLn('pick up a few dirty fighting tricks (+', Amt, ' XP).');
      end;

    35..48:
      begin
        Amt := 10 + (P.Level * 3);
        P.HP := P.HP + Amt;
        if P.HP > P.MaxHP then P.HP := P.MaxHP;
        TextColor(LightGreen);
        WriteLn('You find an unopened apothecary salve tossed in a rain barrel (+', Amt, ' HP).');
      end;

    49..60:
      begin
        Amt := 8 + (P.Level * 2);
        P.MP := P.MP + Amt;
        if P.MP > P.MaxMP then P.MP := P.MaxMP;
        TextColor(LightMagenta);
        WriteLn('Chalked arcane sigils glow faintly on a brick wall. Tracing them');
        WriteLn('restores +', Amt, ' MP!');
      end;

    61..74:
      begin
        Amt := 6 + (P.Level * 3) + Heat;
        P.HP := P.HP - Amt;
        if P.HP < 1 then P.HP := 1;
        TextColor(LightRed);
        WriteLn('A feral alley hound lunges from behind a barrel, tearing your leg');
        WriteLn('for ', Amt, ' damage before you kick it away!');
      end;

    75..88:
      begin
        TextColor(LightRed);
        WriteLn('A nimble street urchin bumps into you and vanishes into the fog!');
        if P.Gold > 0 then
        begin
          Amt := (P.Gold * (15 + Random(16))) div 100;
          if Amt < 1 then Amt := 1;
          P.Gold := P.Gold - Amt;
          WriteLn('You check your belt - your purse is ', Amt, ' gold lighter!');
        end
        else
          WriteLn('Jokes on him - your pockets are completely empty.');
      end;

  else
    begin
      TextColor(LightRed);
      WriteLn('Two hooded thugs step out from both ends of the narrow passage!');
      if P.Gold > 0 then
      begin
        Amt := (P.Gold * 35) div 100;
        if Amt < 1 then Amt := 1;
        P.Gold := P.Gold - Amt;
        WriteLn('Outnumbered in the dark, they relieve you of ', Amt, ' gold!');
      end
      else
      begin
        Amt := 6 + (P.Level * 2);
        P.HP := P.HP - Amt;
        if P.HP < 1 then P.HP := 1;
        WriteLn('Finding your pockets empty, they beat you with a club for ', Amt, ' damage!');
      end;
    end;
  end;

  TextColor(LightGray);
  SavePlayer(P);
  Pause;
end;

procedure PlayAlleyDice(var P: TPlayer);
var
  Bet, MaxBet: LongInt;
  Die1, Die2, Total: Integer;
begin
  WriteLn;
  MaxBet := 100 * P.Level;
  TextColor(Yellow);
  WriteLn('--- Crooked Finger''s Bone Dice ---');
  TextColor(LightGray);
  WriteLn('A one-eyed gambler rattles yellowed bone dice in a leather cup.');
  WriteLn('"Roll 8 or higher to win. Boxcars (12) pays TRIPLE! Max bet: ', MaxBet, '."');
  Write('Enter wager (0 to walk away, Your gold: ', P.Gold, '): ');

  if (not ReadNumber(9, Bet)) or (Bet <= 0) then
    Exit;

  if Bet > MaxBet then
  begin
    Bet := MaxBet;
    WriteLn('He slides some coins back. "House limit is ', MaxBet, '."');
  end;

  if Bet > P.Gold then
  begin
    WriteLn('He scoffs. "Put real coin on the crate or get lost."');
    Pause;
    Exit;
  end;

  Die1 := Random(6) + 1;
  Die2 := Random(6) + 1;
  Total := Die1 + Die2;
  WriteLn;
  WriteLn('You shake the cup and roll: [', Die1, '] and [', Die2, '] (Total: ', Total, ')');

  if Total = 12 then
  begin
    AddGold(P.Gold, Bet * 2);
    TextColor(Yellow);
    WriteLn('BOXCARS! Crooked Finger curses under his breath and pays triple (+', Bet * 2, ' net gold)!');
  end
  else if Total >= 8 then
  begin
    AddGold(P.Gold, Bet);
    TextColor(LightGreen);
    WriteLn('High roll! You scoop up your winnings (+', Bet, ' net gold)!');
  end
  else if Total = 2 then
  begin
    P.Gold := P.Gold - Bet;
    P.HP := P.HP - (3 + P.Level);
    if P.HP < 1 then P.HP := 1;
    TextColor(LightRed);
    WriteLn('SNAKE EYES! He takes your ', Bet, ' gold and his bodyguard shoves you into a wall (-', 3 + P.Level, ' HP)!');
  end
  else
  begin
    P.Gold := P.Gold - Bet;
    TextColor(LightRed);
    WriteLn('Low roll. He sweeps your ', Bet, ' gold into his coat.');
  end;

  TextColor(LightGray);
  SavePlayer(P);
  Pause;
end;

procedure DrinkAlleyVial(var P: TPlayer; TonicCost: LongInt);
var
  Roll: Integer;
  Amt: LongInt;
begin
  WriteLn;
  if P.Gold < TonicCost then
  begin
    WriteLn('A raspy voice from a doorway hisses: "Come back with ', TonicCost, ' gold."');
    Pause;
    Exit;
  end;

  P.Gold := P.Gold - TonicCost;
  Roll := Random(100) + 1;

  case Roll of
    1..35:
      begin
        P.HP := P.MaxHP;
        P.MP := P.MaxMP;
        TextColor(LightGreen);
        WriteLn('Bitter smoke burns your throat - then pure vigor surges! HP & MP FULL!');
      end;
    36..60:
      begin
        Amt := 30 * LongInt(P.Level);
        P.XP := P.XP + Amt;
        TextColor(LightCyan);
        WriteLn('The world fractures into neon geometry - visions of combat tactics (+', Amt, ' XP)!');
      end;
    61..78:
      begin
        P.MP := P.MaxMP;
        TextColor(LightMagenta);
        WriteLn('Blue sparks crackle across your fingertips - MP completely restored!');
      end;
    79..92:
      begin
        Amt := 10 + (P.Level * 3);
        P.HP := P.HP - Amt;
        if P.HP < 1 then P.HP := 1;
        TextColor(LightRed);
        WriteLn('Bad batch! Your stomach cramps violently (-', Amt, ' HP)!');
      end;
  else
    begin
      Amt := 50 * LongInt(P.Level);
      AddGold(P.Gold, Amt);
      TextColor(Yellow);
      WriteLn('It tastes like turnip water, but you find ', Amt, ' gold coins glued to the bottom of the flask!');
    end;
  end;

  TextColor(LightGray);
  SavePlayer(P);
  Pause;
end;

procedure VisitAlleys(var P: TPlayer);
var
  Choice: Char;
  TonicCost: LongInt;
begin

  repeat
    ClrScr;
    TextColor(DarkGray);
    WriteLn('--- The Dark Back Alleys ---');
    TextColor(LightGray);
    WriteLn('Narrow cobblestone passages wind behind the taverns and warehouses.');
    WriteLn('Shadows shift in doorways. Pocket gold: ', P.Gold, ' | HP: ', P.HP, '/', P.MaxHP);
    WriteLn;

    TonicCost := 25 * P.Level;

    WriteLn('[S] Scavenge the Alleys (Search crates & shadows - Heat: ', P.AlleyHeat, ')');
    WriteLn('[G] Gamble at Bone Dice (High-risk street wager)');
    WriteLn('[V] Buy a Murky Alley Vial (', TonicCost, ' gold - Wild mystery brew)');
    WriteLn('[L] Return to Main Street');
    WriteLn;
    Write('Your choice: ');

    Choice := UpCase(GetKey);
    WriteLn(Choice);

    case Choice of
      'I': SecretIronDoor(P); { Hidden Exitilus-style Easter egg }
      'S': ScavengeAlley(P);
      'G': PlayAlleyDice(P);
      'V': DrinkAlleyVial(P, TonicCost);
    end;
  until Choice = 'L';
end;

end.