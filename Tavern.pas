{$MODE TP}
unit Tavern;

interface

uses
  Crt, GameTypes;

procedure VisitTavern(var P: TPlayer);

implementation

const
  RUMOR_FILE = 'RUMORS.TXT';

  BRAWLERS: array[1..5] of string[30] = (
    'One-Eyed Butcher',
    'Disgraced Pit Fighter',
    'Iron-Jawed Dockworker',
    'Scarred Mercenary Captain',
    'The Undefeated Swede'
  );

{ Creates RUMORS.TXT with starter lines if it does not exist yet }
procedure EnsureRumorFile;
var
  F: Text;
begin
  Assign(F, RUMOR_FILE);
  {$I-} Reset(F); {$I+}
  if IOResult = 0 then
  begin
    Close(F);
    Exit; { File already exists, nothing to do }
  end;

  { File is missing, so create it with initial tavern gossip }
  Rewrite(F);
  WriteLn(F, 'Barkeep: Word is a massive wyrm nests deep beyond the northern ridge...');
  WriteLn(F, 'Old Pritchard: I swear I saw 10,000 crows wearing a wool trenchcoat.');
  WriteLn(F, 'Traveller: Keep your gold in the South Ridge vault—bandits love unconscious heroes.');
  Close(F);
end;

{ Reads all lines from RUMORS.TXT and lets the player append a new one }
procedure RumorBoard(const P: TPlayer);
var
  F: Text;
  LineBuf: string;
  Msg: string[70];
  Choice: Char;
begin
  EnsureRumorFile;

  repeat
    ClrScr;
    TextColor(LightCyan);
    WriteLn('=== CARVED INTO THE TAVERN WALL ===');
    TextColor(LightGray);
    WriteLn;

    { Open the text file for reading from line 1 }
    Assign(F, RUMOR_FILE);
    Reset(F);
    while not Eof(F) do
    begin
      ReadLn(F, LineBuf);
      WriteLn(' - ', LineBuf);
    end;
    Close(F);

    WriteLn;
    TextColor(Yellow);
    Write('[W]rite a message on the wall, or [B]ack to tavern? ');
    TextColor(LightGray);
    Choice := UpCase(ReadKey);
    WriteLn(Choice);

    if Choice = 'W' then
    begin
      WriteLn;
      Write('Carve your message (max 70 chars, blank to cancel): ');
      ReadLn(Msg);

      if Msg <> '' then
      begin
        { Open the existing text file and move the cursor to the very end }
        Assign(F, RUMOR_FILE);
        Append(F);
        WriteLn(F, P.Name, ' (Lvl ', P.Level, '): ', Msg);
        Close(F);

        TextColor(LightGreen);
        WriteLn('Your words are carved into the oak wall.');
        TextColor(LightGray);
        Pause;
      end;
    end;
  until Choice = 'B';
end;

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

  { Tougher than a normal forest monster, but beatable with good tactics/skills }
  OppHP := 35 + (P.Level * 28) + (P.Level * P.Level * 2);
  OppAttack := 7 + (P.Level * 5);
  GoldPot := 120 * P.Level;
  XPPot := 95 * P.Level;

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
      PlayerDmg := (P.Strength div 2) + Random(P.Strength) + WEAPONS[P.WeaponIndex].StatBonus;
      OppHP := OppHP - PlayerDmg;
      TextColor(LightGreen);
      WriteLn('You strike ', OpponentName, ' for ', PlayerDmg, ' damage!');

      if OppHP > 0 then
      begin
        OppDmg := (Random(OppAttack) + 1) - ARMORS[P.ArmorIndex].StatBonus;
        if OppDmg < 2 then
          OppDmg := 2;

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
    WriteLn('You wake up in the alley behind the tavern—your pockets picked completely clean!');
    P.HP := 1;
    P.Gold := 0;
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
    WriteLn('[R] Read & Carve Wall Rumors');
    WriteLn('[D] Buy a Mug of Ale (5 gold)');
    WriteLn('[L] Leave Tavern');
    WriteLn;
    Write('Your choice: ');

    Choice := UpCase(ReadKey);
    WriteLn(Choice);

    case Choice of
      'B': RunTavernBrawl(P);
      'R': RumorBoard(P);
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