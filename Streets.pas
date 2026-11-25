{$MODE TP}
unit Streets;

{ Street ambushes. Warriors who log off without a room at the Inn sleep
  where they dropped, and other warriors may prowl the streets and jump
  them. To keep it fair, the sleeper always fights back at full strength
  and full HP with their own gear, however hurt they went to bed, and the
  fight never changes their real HP. The winner takes the loser's
  pocket gold.
  Each warrior can be ambushed once a day at most.

  Wanted outlaws (see Infamy in GameTypes) are the exception: bounty
  hunters may track them down wherever they sleep, even at the Inn, at
  any level, and collect the Sheriff's bounty. }

interface

uses
  Crt, SysUtils, GameTypes, Town;

procedure ProwlStreets(var P: TPlayer);
procedure PrintWantedPosters(MaxRows: Integer);
function CanAmbush(const P, R: TPlayer): Boolean;
function IsBullying(const P, R: TPlayer): Boolean;

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

{ Can this attacker jump this sleeper right now? A wanted outlaw can be
  hunted wherever they sleep, at any level, as often as hunters try.
  Anyone else must be sleeping in the street and not jumped yet today. }
function CanAmbush(const P, R: TPlayer): Boolean;
begin
  CanAmbush := (not SameName(P.Name, R.Name)) and
               (R.Name <> '') and
               (not R.LostInWood) and
               (not IsAwake(R)) and
               (IsWanted(R) or
                ((R.Level >= PVP_MIN_LEVEL) and
                 (not R.AsleepAtInn) and
                 (R.AmbushedDay <> Trunc(Date))));
end;

{ Jumping someone far below your own level is allowed, but it is an evil
  deed. Hunting a wanted outlaw never is. }
function IsBullying(const P, R: TPlayer): Boolean;
begin
  IsBullying := (not IsWanted(R)) and (R.Level < P.Level - PVP_LEVEL_RANGE);
end;

{ The wanted posters on the Town Hall door, for the Crier }
procedure PrintWantedPosters(MaxRows: Integer);
var
  i, Total: LongInt;
  Shown: Integer;
  R: TPlayer;
begin
  Shown := 0;
  Total := PlayerCount;
  i := 0;
  while (i < Total) and (Shown < MaxRows) do
  begin
    if ReadPlayerAt(i, R) and (R.Name <> '') and IsWanted(R) then
    begin
      if Shown = 0 then
      begin
        TextColor(LightRed);
        WriteLn('WANTED by the Sheriff of South Ridge:');
      end;
      Inc(Shown);
      TextColor(LightRed);
      Write('  ', PadRight(R.Name, 30));
      TextColor(LightGray);
      WriteLn(' Lvl ', R.Level:3, '  ', CallingName(R.Calling):8, '   bounty ', BountyFor(R), ' gold');
    end;
    Inc(i);
  end;
  TextColor(LightGray);
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
  Won, Fled, Hunt: Boolean;
  Take, XPGain, Bounty, Seized: LongInt;
begin
  { Re-read: the sleeper may have woken or been jumped by someone else }
  if (not ReadPlayerAt(T.Index, Fresh)) or (not CanAmbush(P, Fresh)) then
  begin
    WriteLn('When you get there, the doorway is empty. Someone got there first, or they woke.');
    Pause;
    Exit;
  end;
  V := Fresh;
  Hunt := IsWanted(V);

  ClrScr;
  Dec(P.FightsLeft);
  Dec(P.AmbushesLeft);
  if IsBullying(P, V) then
    AddInfamy(P, DEED_BULLY);
  SavePlayer(P);

  TextColor(LightRed);
  if Hunt and V.AsleepAtInn then
    WriteLn('You slip a coin to the night porter and climb the Inn stairs to ', V.Name, '''s room.')
  else if Hunt then
    WriteLn('You track the outlaw ', V.Name, ' (Level ', V.Level, ') to a doorway, snoring.')
  else
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
  else if Won and Hunt then
  begin
    { Bounty collected: the outlaw's purse, the Council's reward, and a
      share of their vault. Their slate is wiped clean. }
    Take := V.Gold;
    Bounty := BountyFor(V);
    Seized := SeizedFor(V);
    XPGain := 40 * LongInt(V.Level);
    V.Gold := 0;
    V.BankGold := V.BankGold - Seized;
    V.Infamy := 0;
    V.NightNews := P.Name + ' dragged you to the Sheriff. Bounty paid; your slate is clean.';
    if WriteSleeperAt(T.Index, Fresh, V) then
    begin
      AddGold(P.Gold, Take);
      AddGold(P.Gold, Bounty);
      P.XP := P.XP + XPGain;
      TextColor(Yellow);
      WriteLn('You haul ', V.Name, ' to the Sheriff in irons.');
      WriteLn('Their purse: ', Take, ' gold. The bounty: ', Bounty, ' gold (', Seized,
              ' of it seized from their vault). And ', XPGain, ' XP.');
      TextColor(LightGray);
      PostNews('BOUNTY COLLECTED: ' + P.Name + ' brought in the outlaw ' + V.Name +
               ' for ' + IntToStr(Bounty) + ' gold.');
    end
    else
      WriteLn(V.Name, ' slips the irons, goes over a wall, and is gone.');
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
  Choice: Char;
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
    WriteLn('Inn, or already been robbed today. No outlaws are asleep either.');
    Pause;
    Exit;
  end;

  TextColor(LightCyan);
  WriteLn('Asleep and within reach (ambushes left today: ', P.AmbushesLeft, '):');
  TextColor(LightGray);
  for i := 1 to Count do
  begin
    WriteLn('  [', i:2, '] ', PadRight(Targets[i].Rec.Name, 30), ' Lvl ', Targets[i].Rec.Level:3,
            ' ', PadRight(CallingName(Targets[i].Rec.Calling), 9),
            PurseLooks(Targets[i].Rec.Gold, Targets[i].Rec.Level));
    if IsWanted(Targets[i].Rec) then
    begin
      TextColor(LightRed);
      WriteLn('         WANTED - bounty ', BountyFor(Targets[i].Rec), ' gold');
      TextColor(LightGray);
    end
    else if IsBullying(P, Targets[i].Rec) then
    begin
      TextColor(DarkGray);
      WriteLn('         far beneath you - jumping them is an evil deed');
      TextColor(LightGray);
    end;
  end;
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
  if IsBullying(P, Targets[Pick].Rec) then
  begin
    Write('Picking on someone that far beneath you is an evil deed (+', DEED_BULLY,
          ' infamy). Do it anyway? [Y/N]: ');
    Choice := UpCase(GetKey);
    WriteLn(Choice);
    if Choice <> 'Y' then
      Exit;
  end;
  Ambush(P, Targets[Pick]);
end;

end.
