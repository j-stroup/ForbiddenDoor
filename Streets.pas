{$MODE TP}
unit Streets;

{ Street ambushes. Warriors who log off without a room at the Inn sleep
  where they dropped, and other warriors may prowl the streets and jump
  them. To keep it fair, the sleeper always fights back at full strength
  and full HP with their own gear, however hurt they went to bed, and the
  fight never changes their real HP. The winner takes the loser's
  pocket gold.
  Each warrior can be ambushed once a day at most. }

interface

uses
  Crt, SysUtils, GameTypes, Town;

procedure ProwlStreets(var P: TPlayer);

implementation

const
  MAX_TARGETS = 15;

type
  TTarget = record
    Index: LongInt;
    Rec: TPlayer;
  end;

var
  Targets: array[1..MAX_TARGETS] of TTarget;

{ A rough idea of how much a sleeper is carrying, never the exact sum }
function PurseLooks(Gold, Level: LongInt): string;
begin
  if Gold <= 0 then
    PurseLooks := 'no purse at all'
  else if Gold < 50 * Level then
    PurseLooks := 'a thin purse'
  else if Gold < 400 * Level then
    PurseLooks := 'a decent purse'
  else
    PurseLooks := 'a FAT purse';
end;

{ Can this attacker jump this sleeper right now? }
function CanAmbush(const P, R: TPlayer): Boolean;
begin
  CanAmbush := (not SameName(P.Name, R.Name)) and
               (R.Name <> '') and
               (R.Level >= PVP_MIN_LEVEL) and
               (R.Level >= P.Level - PVP_LEVEL_RANGE) and
               (not R.AsleepAtInn) and
               (not R.LostInWood) and
               (R.AmbushedDay <> Trunc(Date)) and
               (not IsAwake(R));
end;

function GatherTargets(const P: TPlayer): Integer;
var
  i, Total: LongInt;
  Count: Integer;
  R: TPlayer;
begin
  Count := 0;
  Total := PlayerCount;
  i := 0;
  while (i < Total) and (Count < MAX_TARGETS) do
  begin
    if ReadPlayerAt(i, R) and CanAmbush(P, R) then
    begin
      Inc(Count);
      Targets[Count].Index := i;
      Targets[Count].Rec := R;
    end;
    Inc(i);
  end;
  GatherTargets := Count;
end;

{ The fight itself. The sleeper fights at full HP and full strength.
  Returns True if the attacker won. Fled is set if the attacker ran. }
function StreetFight(var P: TPlayer; var V: TPlayer; var Fled: Boolean): Boolean;
var
  Action: Char;
  Dmg, VictimHP: LongInt;
  TurnTaken, Crit: Boolean;
begin
  Fled := False;
  VictimHP := V.MaxHP; { Always a fair fight, whatever HP they slept with }
  repeat
    TurnTaken := False;
    WriteLn;
    WriteLn(P.Name, ' HP: ', P.HP, ' | MP: ', P.MP, '  ||  ', V.Name, ' HP: ', VictimHP);
    Write('[A]ttack, [S]kill, or [R]un? ');
    Action := UpCase(GetKey);
    WriteLn(Action);

    if Action = 'A' then
    begin
      Dmg := WeaponDamage(P, Crit) - ArmorValue(V);
      if Dmg < 1 then
        Dmg := 1;
      VictimHP := VictimHP - Dmg;
      TextColor(Yellow);
      if Crit then
        Write('CRITICAL! ');
      TextColor(LightGreen);
      WriteLn('You hit ', V.Name, ' for ', Dmg, ' damage!');
      TextColor(LightGray);
      TurnTaken := True;
    end
    else if Action = 'S' then
      TurnTaken := CastCombatSkill(P, V.Name, VictimHP)
    else if Action = 'R' then
    begin
      Fled := True;
      StreetFight := False;
      SavePlayer(P);
      Exit;
    end;

    if TurnTaken and (VictimHP > 0) then
    begin
      Dmg := WeaponDamage(V, Crit) - ArmorValue(P);
      if Dmg < 1 then
        Dmg := 1;
      if Crit then
      begin
        TextColor(Yellow);
        Write('CRITICAL! ');
      end;
      if Dmg > P.HP then
        P.HP := 0
      else
        P.HP := P.HP - Dmg;
      TextColor(LightRed);
      WriteLn(V.Name, ' strikes back with ', WEAPONS[V.WeaponIndex].Name,
              ' for ', Dmg, ' damage!');
      TextColor(LightGray);
      SavePlayer(P);
    end;
  until (VictimHP <= 0) or (P.HP <= 0);

  StreetFight := P.HP > 0;
end;

procedure Ambush(var P: TPlayer; const T: TTarget);
var
  V, Fresh: TPlayer;
  Won, Fled: Boolean;
  Take, XPGain: LongInt;
begin
  { Re-read: the sleeper may have woken or been jumped by someone else }
  if (not ReadPlayerAt(T.Index, Fresh)) or (not CanAmbush(P, Fresh)) then
  begin
    WriteLn('When you get there, the doorway is empty. Someone got there first, or they woke.');
    Pause;
    Exit;
  end;
  V := Fresh;

  Dec(P.FightsLeft);
  Dec(P.AmbushesLeft);
  SavePlayer(P);

  ClrScr;
  TextColor(LightRed);
  WriteLn('You find ', V.Name, ' (Level ', V.Level, ') curled in a doorway, snoring.');
  WriteLn('You draw your ', WEAPONS[P.WeaponIndex].Name, '. Their eyes snap open and they');
  WriteLn('are on their feet in an instant, wide awake and ready.');
  TextColor(LightGray);

  Won := StreetFight(P, V, Fled);
  WriteLn;

  V.AmbushedDay := Trunc(Date);
  if Fled then
  begin
    TextColor(LightMagenta);
    WriteLn('You bolt down an alley. ', V.Name, ' curses after you and goes back to sleep.');
    TextColor(LightGray);
    V.NightNews := P.Name + ' jumped you in the street, then ran off.';
    WriteSleeperAt(T.Index, Fresh, V);
    PostNews(P.Name + ' jumped ' + V.Name + ' in the street and ran away.');
  end
  else if Won then
  begin
    Take := V.Gold;
    XPGain := 40 * LongInt(V.Level);
    V.Gold := 0;
    V.NightNews := P.Name + ' beat you senseless in the street and took ' +
                   IntToStr(Take) + ' gold.';
    if WriteSleeperAt(T.Index, Fresh, V) then
    begin
      AddGold(P.Gold, Take);
      P.XP := P.XP + XPGain;
      TextColor(Yellow);
      WriteLn(V.Name, ' slumps against the door. You empty their purse: ', Take,
              ' gold, and ', XPGain, ' XP.');
      TextColor(LightGray);
      PostNews(P.Name + ' ambushed ' + V.Name + ' sleeping in the street and robbed them blind.');
    end
    else
      WriteLn(V.Name, ' wakes fully, scrambles over a wall, and is gone with their purse.');
  end
  else
  begin
    { The attacker went down: the sleeper keeps the attacker's purse }
    Take := P.Gold;
    TextColor(Red);
    WriteLn('You go down hard on the cobbles. ', V.Name, ' helps themself to your purse');
    if Take > 0 then
      WriteLn('(', Take, ' gold) and goes back to sleep.')
    else
      WriteLn('and finds it empty. They go back to sleep, disgusted.');
    TextColor(LightGray);
    AddGold(V.Gold, Take);
    V.NightNews := P.Name + ' tried to rob you in the street. You won and took ' +
                   IntToStr(Take) + ' gold off them.';
    WriteSleeperAt(T.Index, Fresh, V); { If they woke meanwhile, the gold just scatters }
    P.Gold := 0;
    P.HP := 1;
    PostNews(P.Name + ' tried to ambush ' + V.Name + ' in the street and got beaten by a sleeping warrior.');
  end;

  SavePlayer(P);
  Pause;
end;

procedure ProwlStreets(var P: TPlayer);
var
  Count, i, Pick: Integer;
  Num: LongInt;
begin
  ClrScr;
  TextColor(LightRed);
  WriteLn('--- The Streets After Dark ---');
  TextColor(LightGray);
  WriteLn('Not everyone can afford a room. Some sleep in doorways, under carts,');
  WriteLn('behind the chapel wall - and some of them are carrying gold.');
  WriteLn;

  if P.Level < PVP_MIN_LEVEL then
  begin
    WriteLn('You are too green for this kind of work. Come back at level ', PVP_MIN_LEVEL, '.');
    Pause;
    Exit;
  end;
  if P.AmbushesLeft <= 0 then
  begin
    WriteLn('You have pushed your luck enough for one day.');
    Pause;
    Exit;
  end;
  if P.FightsLeft <= 0 then
  begin
    WriteLn('You are too tired to jump anyone. (An ambush uses a forest fight.)');
    Pause;
    Exit;
  end;

  Count := GatherTargets(P);
  if Count = 0 then
  begin
    WriteLn('Every doorway is empty tonight. Everyone worth robbing is awake, at the');
    WriteLn('Inn, or already been robbed today.');
    Pause;
    Exit;
  end;

  TextColor(LightCyan);
  WriteLn('Sleeping in the street (ambushes left today: ', P.AmbushesLeft, '):');
  TextColor(LightGray);
  for i := 1 to Count do
    WriteLn('  [', i:2, '] ', PadRight(Targets[i].Rec.Name, 30), ' Lvl ', Targets[i].Rec.Level:3,
            ' ', PadRight(CallingName(Targets[i].Rec.Calling), 9),
            PurseLooks(Targets[i].Rec.Gold, Targets[i].Rec.Level));
  WriteLn;
  TextColor(DarkGray);
  WriteLn('An ambush uses a forest fight. Lose, and they keep YOUR purse.');
  TextColor(LightGray);
  Write('Who do you jump? (number, or blank to leave): ');
  if not ReadNumber(2, Num) then
    Exit;
  Pick := Num;
  if (Pick < 1) or (Pick > Count) then
    Exit;
  Ambush(P, Targets[Pick]);
end;

end.
