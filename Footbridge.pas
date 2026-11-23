{$MODE TP}
unit Footbridge;

interface

uses
  Crt, GameTypes, Town, ShiftingWood, NorthRidge;

procedure VisitFootbridge(var P: TPlayer);

implementation

const
  LEFT_PATHS: array[1..5] of string[65] = (
    'a narrow deer trail winding through dense hemlock shadows',
    'a mossy ravine where cold mist rises from the ferns',
    'a sunken logging track lined with toppled stone walls',
    'a tangle of briars skirting the edge of a stagnant marsh',
    'a steep ridge path beneath ancient, twisted oaks'
  );

  RIGHT_PATHS: array[1..5] of string[65] = (
    'the rocky creek bank where black water rushes over slate',
    'a stand of pale birch trees whispering in the wind',
    'an overgrown orchard choked with wild blackberries',
    'a hollow gully strewn with driftwood and river stones',
    'a winding footpath following a dry stone boundary'
  );

{ Executes a single randomized exploration encounter along the trail }
procedure TriggerTrailEvent(var P: TPlayer);
var
  Roll: Integer;
  GoldChange, HPChange, MPChange, XPChange: LongInt;
begin
  Roll := Random(100) + 1;
  { Lightning storms turn the hex-mist results into rare relic caches }
  if (TodayCondition = cdStorm) and (Roll >= 83) and (Roll <= 91) then
    Roll := 100;

  case Roll of
    1..22: { 22% - Treasure / Creek Find }
      begin
        GoldChange := (Random(30) + 15) * LongInt(P.Level);
        AddGold(P.Gold, GoldChange);
        TextColor(Yellow);
        WriteLn('TREASURE! Half-buried in the creek mud, you pry open a rotted');
        WriteLn('leather satchel containing ', GoldChange, ' tarnished gold coins!');
      end;

    23..38: { 16% - Swamp Witch Ambush (Drains HP) }
      begin
        HPChange := 6 + (P.Level * 4) + Random(6);
        P.HP := P.HP - HPChange;
        if P.HP < 1 then
          P.HP := 1; { Witches weaken you, but never kill you outright }

        TextColor(LightMagenta);
        WriteLn('A hunched bog witch steps from behind a hollow cedar, chanting!');
        WriteLn('Cold hex-fire sears your veins, draining ', HPChange, ' HP (HP: ', P.HP, '/', P.MaxHP, ')!');
      end;

    39..54: { 16% - Footpad Bandits (Steals Pocket Gold) }
      if TodayCondition = cdFog then
      begin
        TextColor(LightGray);
        WriteLn('Voices and snapping branches pass within a few yards of you - bandits!');
        WriteLn('In the thick fog they never see you crouched behind a stump.');
      end
      else
      begin
        TextColor(LightRed);
        WriteLn('Crossbow bolts thud into a tree trunk beside your head - bandits!');
        if P.Gold > 0 then
        begin
          GoldChange := (P.Gold * (25 + Random(26))) div 100; { Steals 25% to 50% of pocket gold }
          if GoldChange < 1 then
            GoldChange := 1;
          P.Gold := P.Gold - GoldChange;
          WriteLn('Outnumbered in the brush, you toss them ', GoldChange, ' gold to slip away!');
        end
        else
        begin
          WriteLn('They pat down your empty pockets, curse your poverty, and vanish.');
        end;
      end;

    55..68: { 14% - Forgotten Shrine / Ancient Carving (Grants XP) }
      begin
        XPChange := (18 + Random(15)) * LongInt(P.Level);
        P.XP := P.XP + XPChange;
        TextColor(LightCyan);
        WriteLn('You discover a moss-covered milestone carved with old frontier runes.');
        WriteLn('Studying the markings sharpens your instincts (+', XPChange, ' XP).');
      end;

    69..82: { 14% - Clear Spring / Wild Herbs (Restores HP & MP) }
      begin
        HPChange := 10 + (P.Level * 3);
        MPChange := 6 + (P.Level * 2);
        P.HP := P.HP + HPChange;
        if P.HP > P.MaxHP then
          P.HP := P.MaxHP;
        P.MP := P.MP + MPChange;
        if P.MP > P.MaxMP then
          P.MP := P.MaxMP;

        TextColor(LightGreen);
        WriteLn('You rest beside a cold spring fed by the ridge and drink deeply.');
        WriteLn('Refreshed! Restored up to +', HPChange, ' HP and +', MPChange, ' MP.');
      end;

    83..91: { 9% - Witch's Hex-Mist (Drains MP) }
      begin
        TextColor(LightMagenta);
        WriteLn('You walk straight through a shimmering web of witch-silk!');
        if P.MP > 0 then
        begin
          MPChange := 5 + (P.Level * 2);
          if MPChange > P.MP then
            MPChange := P.MP;
          P.MP := P.MP - MPChange;
          WriteLn('Arcane static saps ', MPChange, ' MP from your mind (MP: ', P.MP, '/', P.MaxMP, ').');
        end
        else
          WriteLn('Your mind is already drained of magic, so the web dissolves harmlessly.');
      end;

  else
    { 92..100 (9%) - Quiet Wilderness / Rare Relic Cache }
    begin
      GoldChange := (Random(50) + 40) * LongInt(P.Level);
      XPChange := 25 * LongInt(P.Level);
      AddGold(P.Gold, GoldChange);
      P.XP := P.XP + XPChange;
      TextColor(Yellow);
      WriteLn('RARE FIND! Inside a hollowed-out lightning-struck oak, you uncover');
      WriteLn('an old surveyor''s strongbox (+', GoldChange, ' gold, +', XPChange, ' XP)!');
      PostNews(P.Name + ' found a surveyor''s strongbox in a lightning-struck oak beyond the creek.');
    end;
  end;

  TextColor(LightGray);
  SavePlayer(P);
end;

procedure RunExpedition(var P: TPlayer);
var
  TotalForks, Step: Integer;
  Dir: Char;
  LeftDesc, RightDesc: string[65];
begin
  { Mark today's expedition used as soon as the player crosses the bridge }
  P.BridgeDone := True;
  SavePlayer(P);

  { Pick a random journey length between 4 and 12 forks }
  TotalForks := Random(9) + 4;
  if TodayCondition = cdStorm then
    TotalForks := TotalForks + 3; { The storm washes out paths, so the trail runs long }

  for Step := 1 to TotalForks do
  begin
    ClrScr;
    TextColor(LightCyan);
    WriteLn('===========================================================');
    WriteLn(' BEYOND THE CREEK - TRAIL FORK ', Step, ' OF ', TotalForks);
    WriteLn(' HP: ', P.HP, '/', P.MaxHP, ' | MP: ', P.MP, '/', P.MaxMP, ' | Pocket Gold: ', P.Gold);
    WriteLn('===========================================================');
    TextColor(LightGray);
    WriteLn;

    LeftDesc := LEFT_PATHS[Random(High(LEFT_PATHS)) + 1];
    RightDesc := RIGHT_PATHS[Random(High(RIGHT_PATHS)) + 1];

    WriteLn('The trail splits ahead in the dim woods:');
    WriteLn('  [L] Take ', LeftDesc);
    WriteLn('  [R] Take ', RightDesc);
    WriteLn;
    Write('Which fork do you take? [L/R]: ');

    repeat
      Dir := UpCase(GetKey);
    until Dir in ['L', 'R'];
    WriteLn(Dir);
    WriteLn;

    if Dir = 'L' then
      WriteLn('You bear left along ', LeftDesc, '...')
    else
      WriteLn('You turn right onto ', RightDesc, '...');

    WriteLn;
    TriggerTrailEvent(P);
    Pause;
  end;

  ClrScr;
  TextColor(LightCyan);
  WriteLn('--- Back at the Creek Footbridge ---');
  TextColor(LightGray);
  WriteLn('The winding woods loop back toward the sound of rushing water.');
  WriteLn('You step back across the mossy planks to South Ridge, done for the day.');
  Pause;
end;

{ The first time a warrior of WOOD_MIN_LEVEL comes to the creek }
procedure AnnounceWood(var P: TPlayer);
begin
  ClrScr;
  TextColor(Magenta);
  WriteLn('--- The Creek Footbridge ---');
  TextColor(LightGray);
  WriteLn('The creek sounds wrong today. Lower. Slower.');
  WriteLn;
  WriteLn('On the far bank, the trails you have walked a hundred times are gone.');
  WriteLn('In their place the trees stand close and dark, and they are not the');
  WriteLn('same trees. When you look away and back, they have moved.');
  WriteLn;
  TextColor(DarkGray);
  WriteLn('The old folk of South Ridge have a name for what lies beyond the bridge');
  WriteLn('for those who have grown strong enough to notice it: the Shifting Wood.');
  TextColor(LightGray);
  P.WoodSeen := True;
  SavePlayer(P);
  Pause;
end;

procedure VisitShiftingWood(var P: TPlayer);
var
  Choice: Char;
begin
  ClrScr;
  TextColor(Magenta);
  WriteLn('--- The Creek Footbridge ---');
  TextColor(LightGray);
  WriteLn('Black water slides under the planks without a sound.');
  WriteLn('On the far side, the Shifting Wood waits.');
  WriteLn;

  if P.BridgeDone then
  begin
    WriteLn('You have already been into the Wood today. It will have changed by');
    WriteLn('tomorrow. It always has.');
    Pause;
    Exit;
  end;

  WriteLn('Somewhere past it, if the tales are true, is a town that should not exist.');
  WriteLn('Bandits and witches live in the Wood, and they are not right in the head.');
  TextColor(LightRed);
  WriteLn('Die in there and you will be lost until tomorrow, and your gold with you.');
  WriteLn;
  TextColor(Yellow);
  Write('Cross into the Shifting Wood? [Y/N]: ');
  TextColor(LightGray);

  Choice := UpCase(GetKey);
  WriteLn(Choice);

  if Choice = 'Y' then
  begin
    if RunShiftingWood(P) then
      VisitNorthRidge(P);
  end
  else
  begin
    WriteLn('You step back from the railing. The trees seem disappointed.');
    Pause;
  end;
end;

procedure VisitFootbridge(var P: TPlayer);
var
  Choice: Char;
begin
  if P.Level >= WOOD_MIN_LEVEL then
  begin
    if not P.WoodSeen then
      AnnounceWood(P);
    VisitShiftingWood(P);
    Exit;
  end;

  ClrScr;
  TextColor(LightCyan);
  WriteLn('--- The Creek Footbridge ---');
  TextColor(LightGray);
  WriteLn('Dark water rushes beneath mossy timber planks into the thick woods.');
  WriteLn;

  if P.BridgeDone then
  begin
    WriteLn('Dusk settles thick over the creek. You have already explored the');
    WriteLn('woods today - come back tomorrow to cross again.');
    Pause;
    Exit;
  end;

  WriteLn('Unmarked trails wind deep into the timber beyond the far bank.');
  WriteLn('Rumors speak of buried caches - as well as highwaymen and bog witches.');
  WriteLn;
  TextColor(Yellow);
  Write('Cross the footbridge and explore the woods? [Y/N]: ');
  TextColor(LightGray);

  Choice := UpCase(GetKey);
  WriteLn(Choice);

  if Choice = 'Y' then
    RunExpedition(P)
  else
  begin
    WriteLn('You linger by the railing for a moment, then head back to town.');
    Pause;
  end;
end;

end.