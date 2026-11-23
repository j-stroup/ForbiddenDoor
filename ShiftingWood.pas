{$MODE TP}
unit ShiftingWood;

{ Beyond the footbridge, for warriors of WOOD_MIN_LEVEL and up.
  Every day the Wood hides one true path (the same for every player) and
  one sign that marks it. The Crier whispers the sign each morning. Take
  every fork correctly and the trees open onto North Ridge; take one wrong
  turn and the Wood quietly turns you around. Dying in here leaves you
  lost until tomorrow. }

interface

uses
  Crt, SysUtils, GameTypes, Town;

type
  TFightResult = (frWon, frFled, frDied);

function WoodPathLength(Day: LongInt): Integer;
function WoodTurn(Day: LongInt; Step: Integer): Char;
function WoodSignIndex(Day: LongInt): Integer;
procedure PrintWoodWhisper;
function FightFoe(var P: TPlayer; const FoeName: string;
                  FoeHP, FoeAtk: LongInt; IsWyrm: Boolean): TFightResult;
procedure BecomeLost(var P: TPlayer; const Headline: string);
function RunShiftingWood(var P: TPlayer): Boolean;

implementation

const
  NUM_SIGNS = 8;

  { How the sign looks at a fork }
  SIGN_AT_FORK: array[1..NUM_SIGNS] of string[50] = (
    'a cairn of white stones',
    'a strip of red cloth knotted to a branch',
    'a crow watching from a dead limb, silent',
    'a doll of woven twigs hanging by its neck',
    'a lantern burning with no one to tend it',
    'cloven hoofprints pressed deep in the mud',
    'a bell hanging still from a frayed rope',
    'a ring of pale mushrooms'
  );

  { What the woodcutters tell the Crier }
  SIGN_WHISPER: array[1..NUM_SIGNS] of string[60] = (
    'Where the white stones are stacked, the Wood holds still.',
    'The red cloth was tied by someone who made it out.',
    'Trust the crow that does not call.',
    'Go where the twig-dolls hang.',
    'Walk toward the lantern no hand has lit.',
    'Follow what walks on cloven feet.',
    'Go where the bell hangs silent.',
    'Step past the pale ring, never around it.'
  );

  TRAILS: array[1..10] of string[66] = (
    'a path of black needles that crunch like small bones',
    'a trail that curves back on itself, though you walk it straight',
    'a tunnel of thorn where something has recently slept',
    'a deer trail that ends, then begins again a few yards on',
    'a gully where your footsteps echo a moment too late',
    'a narrow way between birches with eyes carved in the bark',
    'a sunken road paved with stones that were not here before',
    'a slope where the fog runs uphill',
    'a clearing you are certain you have crossed already',
    'a creek bed with no water, only the sound of it'
  );

  QUIET: array[1..8] of string[72] = (
    'Something walks beside you, just out of sight, matching your steps.',
    'Every bird in the Wood stops singing at once.',
    'You pass a tree carved with your name. The carving is very old.',
    'When you look back, the trail behind you is gone.',
    'A child laughs somewhere ahead. Nobody brings children here.',
    'You find your own footprints in the mud, heading the other way.',
    'The trees lean in while you are not looking at them.',
    'For a long while there is no sound at all, not even your breath.'
  );

  FOES: array[1..10] of string[30] = (
    'Giggling Cutthroat',
    'Bandit Who Wears Faces',
    'Antler-Crowned Brigand',
    'Toothless Knife-Saint',
    'Moth-Eaten Highwayman',
    'Thornwife Crone',
    'Weeping Hex-Witch',
    'Mother Mildew',
    'Crone of Seven Fingers',
    'The Witch Under the Roots'
  );

  FOE_INTRO: array[1..10] of string[72] = (
    'A man in rags drops from the branches, giggling, a knife in each hand.',
    'A bandit steps out wearing a face that is not his. He wants yours.',
    'A brigand with antlers lashed to his skull charges out of the brush.',
    'A grinning old man with no teeth blesses his knife and comes for you.',
    'A highwayman with moths crawling from his collar levels a rusted blade.',
    'A crone woven half from bramble rises from the thicket, hissing.',
    'A witch weeps black tears as she raises her hands to curse you.',
    'Something soft and grey and smiling oozes off a stump: Mother Mildew.',
    'A crone counts on seven fingers, then points all of them at you.',
    'The roots beneath your feet part, and a witch climbs out of the earth.'
  );

{ ---------- The shared daily path ---------- }

function WoodPathLength(Day: LongInt): Integer;
var
  N: Integer;
  C: TCondition;
begin
  N := 6;
  C := ConditionOnDay(Day);
  if C = cdStorm then
    N := N + 2;   { The storm washes out paths and adds forks }
  if C = cdAllSouls then
    N := N - 2;   { On All Souls' Night the dead town is close }
  WoodPathLength := N;
end;

function WoodTurn(Day: LongInt; Step: Integer): Char;
begin
  if Odd(DayHash(Day, 100 + Step)) then
    WoodTurn := 'R'
  else
    WoodTurn := 'L';
end;

function WoodSignIndex(Day: LongInt): Integer;
begin
  WoodSignIndex := (DayHash(Day, 7) mod NUM_SIGNS) + 1;
end;

{ The Crier's line about the Wood; fog swallows it }
procedure PrintWoodWhisper;
begin
  TextColor(DarkGray);
  if TodayCondition = cdFog then
    WriteLn('  From the Shifting Wood: no word. The woodcutters never came out of the fog.')
  else
    WriteLn('  From the Shifting Wood, the woodcutters whisper: "',
            SIGN_WHISPER[WoodSignIndex(Trunc(Date))], '"');
  TextColor(LightGray);
end;

{ ---------- Fighting ---------- }

procedure ShowFightStatus(const P: TPlayer; const FoeName: string; FoeHP: LongInt);
begin
  WriteLn;
  WriteLn(P.Name, ' HP: ', P.HP, '/', P.MaxHP, ' | MP: ', P.MP, '  ||  ', FoeName, ' HP: ', FoeHP);
end;

{ A fight with no 1 HP safety net. The Wyrm breathes fire every fourth
  turn, which no armor stops. HP is saved after every blow, so hanging up
  cannot undo the damage. }
function FightFoe(var P: TPlayer; const FoeName: string;
                  FoeHP, FoeAtk: LongInt; IsWyrm: Boolean): TFightResult;
var
  Action: Char;
  PlayerDmg, FoeDmg: LongInt;
  Turn: Integer;
  TurnTaken: Boolean;
begin
  Turn := 0;
  repeat
    TurnTaken := False;
    ShowFightStatus(P, FoeName, FoeHP);
    Write('[A]ttack, [S]kill, or [R]un? ');
    Action := UpCase(GetKey);
    WriteLn(Action);

    if Action = 'A' then
    begin
      PlayerDmg := (P.Strength div 2) + Random(P.Strength) + WEAPONS[P.WeaponIndex].StatBonus;
      FoeHP := FoeHP - PlayerDmg;
      TextColor(LightGreen);
      WriteLn('You strike with your ', WEAPONS[P.WeaponIndex].Name, ' for ', PlayerDmg, ' damage!');
      TextColor(LightGray);
      TurnTaken := True;
    end
    else if Action = 'S' then
      TurnTaken := CastCombatSkill(P, FoeName, FoeHP)
    else if Action = 'R' then
    begin
      SavePlayer(P);
      FightFoe := frFled;
      Exit;
    end;

    if TurnTaken and (FoeHP > 0) then
    begin
      Inc(Turn);
      if IsWyrm and (Turn mod 4 = 0) then
      begin
        FoeDmg := 60 + Random(41);
        TextColor(Yellow);
        WriteLn('The Wyrm draws a breath that pulls the ash off the floor...');
        TextColor(LightRed);
        WriteLn('A torrent of grey fire washes over you for ', FoeDmg, ' damage! Armor is useless.');
      end
      else
      begin
        FoeDmg := (Random(FoeAtk) + 1) - ARMORS[P.ArmorIndex].StatBonus;
        if FoeDmg < 1 then
          FoeDmg := 1;
        TextColor(LightRed);
        WriteLn(FoeName, ' hits you for ', FoeDmg, ' damage!');
      end;
      TextColor(LightGray);

      if FoeDmg > P.HP then
        P.HP := 0
      else
        P.HP := P.HP - FoeDmg;
      SavePlayer(P);
    end;
  until (FoeHP <= 0) or (P.HP <= 0);

  if P.HP <= 0 then
    FightFoe := frDied
  else
    FightFoe := frWon;
end;

{ Death beyond the footbridge: the gold is gone and the warrior is out
  of the game until the next dawn. }
procedure BecomeLost(var P: TPlayer; const Headline: string);
begin
  WriteLn;
  TextColor(Red);
  WriteLn('Your legs give out. The trees lean close, and the Wood takes you in.');
  if P.Gold > 0 then
    WriteLn('Whatever finds you first takes all ', P.Gold, ' gold you were carrying.');
  WriteLn;
  TextColor(LightRed);
  WriteLn('You are LOST IN THE WOOD. Your adventure is over until tomorrow,');
  WriteLn('when the woodcutters will find you at dawn and carry you to South Ridge.');
  TextColor(LightGray);
  P.Gold := 0;
  P.HP := 1;
  P.LostInWood := True;
  SavePlayer(P);
  PostNews(Headline);
  Pause;
end;

{ A deranged local. Tougher than it looks and paid accordingly.
  Returns False if the warrior did not walk away from it. }
function WoodFight(var P: TPlayer; var OnPath: Boolean): Boolean;
var
  MinIdx, MaxIdx, Pick: Integer;
  Base: TMonster;
  FoeHP, FoeAtk, GoldReward, XPReward: LongInt;
begin
  WoodFight := True;
  MonsterBracket(P.Level, MinIdx, MaxIdx);
  Base := MONSTERS[MinIdx + Random(MaxIdx - MinIdx + 1)];
  FoeHP := (LongInt(Base.HP) * 3) div 5;
  FoeAtk := (LongInt(Base.Attack) * 9) div 10;
  GoldReward := (LongInt(Base.GoldReward) * 3) div 4;
  XPReward := (LongInt(Base.XPReward) * 3) div 4;
  if TodayCondition = cdBloodMoon then
  begin
    FoeHP := (FoeHP * 5) div 4;
    FoeAtk := (FoeAtk * 5) div 4;
    GoldReward := (GoldReward * 3) div 2;
    XPReward := (XPReward * 3) div 2;
  end;

  Pick := Random(High(FOES)) + 1;
  TextColor(LightRed);
  WriteLn(FOE_INTRO[Pick]);
  TextColor(LightGray);

  case FightFoe(P, FOES[Pick], FoeHP, FoeAtk, False) of
    frWon:
      begin
        TextColor(Yellow);
        WriteLn;
        WriteLn('The ', FOES[Pick], ' falls, still laughing. You take ', GoldReward,
                ' gold and ', XPReward, ' XP.');
        TextColor(LightGray);
        AddGold(P.Gold, GoldReward);
        P.XP := P.XP + XPReward;
        SavePlayer(P);
      end;
    frFled:
      begin
        TextColor(LightMagenta);
        WriteLn;
        WriteLn('You run blind through the trees until the laughter fades.');
        WriteLn('Nothing around you looks like anything you have seen before.');
        TextColor(LightGray);
        OnPath := False; { Running blind always loses the path }
      end;
    frDied:
      begin
        BecomeLost(P, P.Name + ' crossed the footbridge and has not been seen since.');
        WoodFight := False;
      end;
  end;
end;

{ What happens after each fork. Returns False if the warrior died.
  HideNextSign / Hint are set for the fork that follows. }
function WoodEvent(var P: TPlayer; Step: Integer; var OnPath, HideNextSign: Boolean;
                   var Hint: Char): Boolean;
var
  Roll: Integer;
  Amount: LongInt;
  NextTurn: Char;
begin
  WoodEvent := True;
  Roll := Random(100) + 1;

  case Roll of
    1..40:
      WoodEvent := WoodFight(P, OnPath);

    41..52: { A witch's hex. Here it can kill. }
      begin
        Amount := (LongInt(P.MaxHP) * (8 + Random(8))) div 100;
        if Amount < 1 then
          Amount := 1;
        TextColor(LightMagenta);
        WriteLn('A voice sings your name from the canopy. Your blood runs cold, then hot.');
        WriteLn('The hex tears ', Amount, ' HP out of you.');
        TextColor(LightGray);
        if Amount >= P.HP then
        begin
          P.HP := 0;
          BecomeLost(P, P.Name + ' was sung to death by something in the Shifting Wood.');
          WoodEvent := False;
          Exit;
        end;
        P.HP := P.HP - Amount;
        WriteLn('(HP: ', P.HP, '/', P.MaxHP, ')');
      end;

    53..62: { Witch-silk: drains MP and blinds the next fork }
      begin
        TextColor(LightMagenta);
        WriteLn('You walk face-first into a sheet of witch-silk. It clings to your eyes.');
        Amount := 8 + LongInt(P.Level) * 2;
        if Amount > P.MP then
          Amount := P.MP;
        P.MP := P.MP - Amount;
        if Amount > 0 then
          WriteLn('It drinks ', Amount, ' MP from you before you tear it free.');
        WriteLn('Everything ahead looks blurred and wrong.');
        TextColor(LightGray);
        HideNextSign := True;
      end;

    63..70: { The mad hermit. Two times in three he tells the truth. }
      begin
        TextColor(LightCyan);
        WriteLn('An old man sits in the crook of a tree, rocking and humming.');
        if Step >= WoodPathLength(Trunc(Date)) then
          WriteLn('"Almost there," he says. "Almost there. Almost there. Almost."')
        else
        begin
          NextTurn := WoodTurn(Trunc(Date), Step + 1);
          if Random(3) = 0 then
          begin
            if NextTurn = 'L' then NextTurn := 'R' else NextTurn := 'L';
          end;
          Hint := NextTurn;
          if NextTurn = 'L' then
            WriteLn('"Left hand, left hand, the left hand knows," he sings.')
          else
            WriteLn('"Right, right, always right, never wrong," he sings.');
          WriteLn('He giggles, and when you blink, the tree is empty.');
        end;
        TextColor(LightGray);
      end;

    71..78: { A dead traveler's stash }
      begin
        Amount := (Random(50) + 40) * LongInt(P.Level);
        AddGold(P.Gold, Amount);
        TextColor(Yellow);
        WriteLn('A skeleton sits against an oak, still clutching its purse.');
        WriteLn('It does not object when you take the ', Amount, ' gold inside.');
        TextColor(LightGray);
      end;
  else
    begin
      TextColor(DarkGray);
      WriteLn(QUIET[Random(High(QUIET)) + 1]);
      TextColor(LightGray);
    end;
  end;

  SavePlayer(P);
end;

{ Walks the Wood. Returns True if the warrior reached North Ridge. }
function RunShiftingWood(var P: TPlayer): Boolean;
var
  Today: LongInt;
  Forks, Step, Sign, Decoy, SignChance: Integer;
  Correct, Dir, Hint, DecoySide: Char;
  OnPath, HideNextSign, HideThis, ShowSign, ShowDecoy: Boolean;
  LeftDesc, RightDesc: Integer;
begin
  RunShiftingWood := False;
  P.BridgeDone := True;
  SavePlayer(P);

  Today := Trunc(Date);
  Forks := WoodPathLength(Today);
  Sign := WoodSignIndex(Today);
  OnPath := True;
  HideNextSign := False;
  Hint := ' ';

  case TodayCondition of
    cdFog:     SignChance := 40;
    cdAllSouls: SignChance := 100;
  else
    SignChance := 70;
  end;

  for Step := 1 to Forks do
  begin
    ClrScr;
    TextColor(Magenta);
    WriteLn('===========================================================');
    WriteLn(' THE SHIFTING WOOD');
    WriteLn(' HP: ', P.HP, '/', P.MaxHP, ' | MP: ', P.MP, '/', P.MaxMP, ' | Pocket Gold: ', P.Gold);
    WriteLn('===========================================================');
    TextColor(LightGray);
    WriteLn;

    Correct := WoodTurn(Today, Step);
    HideThis := HideNextSign;
    HideNextSign := False;

    { Once off the path, the true sign never shows again. Only decoys. }
    ShowSign := OnPath and (not HideThis) and (Random(100) < SignChance);
    ShowDecoy := (not HideThis) and (TodayCondition <> cdAllSouls) and (Random(100) < 35);
    repeat
      Decoy := Random(NUM_SIGNS) + 1;
    until Decoy <> Sign;

    LeftDesc := Random(High(TRAILS)) + 1;
    repeat
      RightDesc := Random(High(TRAILS)) + 1;
    until RightDesc <> LeftDesc;

    if HideThis then
      WriteLn('Through the witch-silk smear you can barely make out two ways on:')
    else
      WriteLn('The way splits. Neither path was here a moment ago:');

    { A decoy sits opposite the true path, or anywhere once you are lost }
    if not OnPath then
    begin
      if Random(2) = 0 then DecoySide := 'L' else DecoySide := 'R';
    end
    else if Correct = 'L' then
      DecoySide := 'R'
    else
      DecoySide := 'L';

    WriteLn('  [L] ', TRAILS[LeftDesc]);
    if ShowSign and (Correct = 'L') then
      WriteLn('        beside it, ', SIGN_AT_FORK[Sign])
    else if ShowDecoy and (DecoySide = 'L') then
      WriteLn('        beside it, ', SIGN_AT_FORK[Decoy]);

    WriteLn('  [R] ', TRAILS[RightDesc]);
    if ShowSign and (Correct = 'R') then
      WriteLn('        beside it, ', SIGN_AT_FORK[Sign])
    else if ShowDecoy and (DecoySide = 'R') then
      WriteLn('        beside it, ', SIGN_AT_FORK[Decoy]);

    if Hint <> ' ' then
    begin
      TextColor(DarkGray);
      WriteLn;
      WriteLn('  (The hermit''s song is still in your head: "', Hint, '...")');
      TextColor(LightGray);
      Hint := ' ';
    end;

    WriteLn;
    Write('Which way? [L/R]: ');
    repeat
      Dir := UpCase(GetKey);
    until Dir in ['L', 'R'];
    WriteLn(Dir);
    WriteLn;

    if Dir <> Correct then
      OnPath := False;

    if not WoodEvent(P, Step, OnPath, HideNextSign, Hint) then
      Exit; { Lost in the Wood }
    Pause;
  end;

  ClrScr;
  if OnPath then
  begin
    TextColor(DarkGray);
    WriteLn('The trees thin, and then they simply stop.');
    WriteLn;
    WriteLn('Below you, under a sky the color of old ash, lies a town.');
    WriteLn('The same crooked streets. The same chapel steeple. The same bridge.');
    WriteLn('It is South Ridge. It is not South Ridge.');
    WriteLn;
    TextColor(LightGray);
    WriteLn('No smoke rises from any chimney. Nothing moves.');
    if P.NRVisits = 0 then
      PostNews(P.Name + ' stepped out of the Shifting Wood and spoke of a town that should not exist.');
    Inc(P.NRVisits);
    SavePlayer(P);
    Pause;
    RunShiftingWood := True;
  end
  else
  begin
    TextColor(LightCyan);
    WriteLn('The trees part, and there is the creek, and the mossy footbridge,');
    WriteLn('and the smoke of South Ridge''s chimneys beyond it.');
    WriteLn;
    TextColor(LightGray);
    WriteLn('You walked straight the whole way. You are sure of it.');
    WriteLn('The Wood turned you around anyway. It will be different tomorrow.');
    Pause;
  end;
end;

end.
