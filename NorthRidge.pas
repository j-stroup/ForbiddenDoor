{$MODE TP}
unit NorthRidge;

{ North Ridge: a darkened copy of South Ridge with no one in it.
  This is the Ashen Wyrm's domain. Each trip allows a few hours of
  searching before dusk drives the warrior back over the footbridge.
  Searching NR_KEEP_REVEAL places (across any number of trips) reveals
  the Ashen Keep, where the Wyrm waits. Besting it makes the warrior
  Champion of the Ridge until someone else bests it. }

interface

uses
  Crt, SysUtils, GameTypes, Town, ShiftingWood, WyrmScale;

procedure VisitNorthRidge(var P: TPlayer);

implementation

const
  HOURS_PER_TRIP = 5;

  WYRM_NAME = 'The Ashen Wyrm';

  { Hotkeys of the searchable places, in bit order }
  PLACE_KEYS: string[NR_PLACES] = 'WATBIHPNFGDRLS';

  PLACE_NAMES: array[1..NR_PLACES] of string[30] = (
    'Weapon Shop', 'Armor Shop', 'Training Grounds', 'South Ridge Bank',
    'Inn (Sleep Safely)', 'Olde Hallowed Tavern', 'Parish Chapel',
    'Town Crier (Daily News)', 'Enter the Forest (Hunt)', 'Old Cemetery (Crypt)',
    'Dark Back Alleys', 'Hall of Fame (Rankings)', 'Healer''s Hut',
    'Prowl the Streets (PvP)'
  );

  { First search of each place: three lines, no people anywhere }
  PLACE_TEXT: array[1..NR_PLACES, 1..3] of string[74] = (
    ('The forge is cold. The anvil is split clean down the middle.',
     'Every blade on the rack has been bent double, all in the same direction,',
     'as though something very large leaned against the wall to rest.'),
    ('The armor stands are empty but for one breastplate.',
     'It is fitted for a man, and it has been bitten through.',
     'The teeth marks are as wide as your hand.'),
    ('The straw dummies have been burned down to their posts.',
     'The ash around them is still warm. The ground is scored with long',
     'parallel furrows, the way a cat marks a tree.'),
    ('The vault door hangs open. Every strongbox is empty.',
     'Not robbed. Melted. The gold ran out across the floor and set',
     'into a smooth yellow pool, and something has been lying on it.'),
    ('The beds are made. The fire is laid but never lit.',
     'In the ledger behind the desk, the last guest signed in today''s date.',
     'The name is smudged with grey ash, and you cannot read it.'),
    ('The chairs are up on the tables. One mug sits at the bar.',
     'It is still half full, and the ale in it is warm.',
     'You do not drink it. You do not stay.'),
    ('Every pew has been turned to face the door instead of the altar.',
     'The altar cloth is gone. The great window above it has melted',
     'and run down the wall like candle wax.'),
    ('One sheet is nailed to the board. It is dated today.',
     'It is blank, except for a sooty print in one corner,',
     'too large and too many-jointed to be a hand.'),
    ('The trees past the town line are black and leafless.',
     'Nothing moves in them. No birds, no wind, no insects.',
     'The only path leads back toward the town, and up the hill.'),
    ('Every grave in the cemetery is open, and every grave is empty.',
     'The earth was not dug. It was pushed up from below.',
     'Long grey scales lie in the bottom of the deepest one.'),
    ('The alleys are quiet. No dice, no voices, no rats.',
     'Crooked Finger''s barrel table is overturned and scorched black.',
     'His bone dice sit on top of it. Both show a single pip.'),
    ('Every plaque on the wall has been scratched blank,',
     'raked over and over by something with claws',
     'until the names were gone.'),
    ('The herbs hanging from the rafters have crumbled to grey powder.',
     'The cot is made up with clean linen, turned down, waiting.',
     'On the pillow lies a single grey scale, curled like a fingernail.'),
    ('The doorways where the poor sleep are empty, blankets still laid out.',
     'Every blanket is scorched in the same place, a long dark smear',
     'that leads up the street toward the hill.')
  );

  REVISIT: array[1..4] of string[60] = (
    'Nothing has moved. Nothing ever will.',
    'It is exactly as you left it. Too exactly.',
    'The dust holds only your own footprints.',
    'You do not remember the door being open. It is open.'
  );

  UNEASE: array[1..6] of string[66] = (
    'Somewhere behind you, a door closes softly.',
    'For a heartbeat you hear the tavern crowd. Then nothing.',
    'Your shadow is a moment late following you.',
    'The ground shivers, like something huge turning over in its sleep.',
    'A warm wind breathes out of the hill, then draws back in.',
    'Ash falls, though there is no fire anywhere you can see.'
  );

function PlaceIndex(Key: Char): Integer;
begin
  PlaceIndex := Pos(Key, PLACE_KEYS);
end;

function IsSearched(const P: TPlayer; Idx: Integer): Boolean;
begin
  IsSearched := (P.NRSearched and (Word(1) shl (Idx - 1))) <> 0;
end;

function SearchedCount(const P: TPlayer): Integer;
var
  i, N: Integer;
begin
  N := 0;
  for i := 1 to NR_PLACES do
    if IsSearched(P, i) then
      Inc(N);
  SearchedCount := N;
end;

function KeepRevealed(const P: TPlayer): Boolean;
begin
  KeepRevealed := SearchedCount(P) >= NR_KEEP_REVEAL;
end;

{ One row of the darkened two-column menu }
procedure PrintDimRow(LeftKey: Char; const LeftLabel: string;
                      RightKey: Char; const RightLabel: string);
begin
  TextColor(DarkGray);
  Write('| ');
  if LeftKey = ' ' then
    Write('    ')
  else
  begin
    TextColor(Brown);
    Write('[', LeftKey, '] ');
  end;
  TextColor(DarkGray);
  Write(PadRight(LeftLabel, 30));
  Write(' | ');
  if RightKey = ' ' then
    Write('    ')
  else
  begin
    TextColor(Brown);
    Write('[', RightKey, '] ');
  end;
  TextColor(DarkGray);
  Write(PadRight(RightLabel, 30));
  WriteLn(' |');
end;

procedure DrawTown(const P: TPlayer; Hours: Integer);
var
  Bar: string;
  i: Integer;
begin
  ClrScr;
  TextColor(DarkGray);
  WriteLn('+=========================================================================+');
  Write('| ');
  TextColor(Red);
  Write(PadRight('THE NORTH RIDGE', 47));
  TextColor(DarkGray);
  Write(PadRight('Warrior: ' + P.Name, 24));
  WriteLn(' |');
  WriteLn('+-------------------------------------------------------------------------+');
  Write('| ');
  TextColor(LightGray);
  Write(PadRight('Lvl: ' + IntToStr(P.Level) + '   HP: ' + IntToStr(P.HP) + '/' + IntToStr(P.MaxHP) +
                 '   MP: ' + IntToStr(P.MP) + '/' + IntToStr(P.MaxMP) +
                 '   Gold: ' + IntToStr(P.Gold), 71));
  TextColor(DarkGray);
  WriteLn(' |');
  WriteLn('+-------------------------------------------------------------------------+');

  Bar := '';
  for i := 1 to HOURS_PER_TRIP do
    if i <= Hours then
      Bar := Bar + '#'
    else
      Bar := Bar + '.';
  Write('| ');
  TextColor(Brown);
  Write(PadRight('Daylight: [' + Bar + ']   Places searched: ' + IntToStr(SearchedCount(P)) +
                 ' of ' + IntToStr(NR_PLACES), 71));
  TextColor(DarkGray);
  WriteLn(' |');
  WriteLn('+====================================+====================================+');
  Write('| ');
  Write(PadRight('TOWN & SANCTUARIES', 34));
  Write(' | ');
  Write(PadRight('WILDS, QUESTS & RECORDS', 34));
  WriteLn(' |');
  WriteLn('+------------------------------------+------------------------------------+');

  PrintDimRow('W', 'Weapon Shop',             'F', 'Enter the Forest (Hunt)');
  PrintDimRow('A', 'Armor Shop',              'G', 'Old Cemetery (Crypt)');
  PrintDimRow('T', 'Training Grounds',        'C', 'Creek Footbridge (Leave)');
  PrintDimRow('B', 'South Ridge Bank',        'D', 'Dark Back Alleys');
  PrintDimRow('L', 'Healer''s Hut',            'S', 'Prowl the Streets (PvP)');
  PrintDimRow('I', 'Inn (Sleep Safely)',      'V', 'View Warrior Stats');
  PrintDimRow('H', 'Olde Hallowed Tavern',    'R', 'Hall of Fame (Rankings)');
  PrintDimRow('P', 'Parish Chapel',           'Q', 'Save & Quit');
  PrintDimRow('N', 'Town Crier (Daily News)', ' ', '');

  if KeepRevealed(P) then
  begin
    TextColor(DarkGray);
    Write('| ');
    TextColor(LightRed);
    Write('[K] ');
    TextColor(Red);
    Write(PadRight('The Ashen Keep (on the hill that should not be there)', 67));
    TextColor(DarkGray);
    WriteLn(' |');
  end;

  TextColor(DarkGray);
  WriteLn('+====================================+====================================+');
  WriteLn;
  TextColor(DarkGray);
  if KeepRevealed(P) then
    Write('Command [W,A,T,B,L,I,H,P,N / F,G,C,D,S,V,R,Q / K]: ')
  else
    Write('Command [W,A,T,B,L,I,H,P,N / F,G,C,D,S,V,R,Q]: ');
end;

{ Visits one of the twelve places. Returns True if it used up an hour. }
function SearchPlace(var P: TPlayer; Idx: Integer): Boolean;
var
  Champ: string;
  Before: Boolean;
begin
  ClrScr;
  TextColor(DarkGray);
  WriteLn('--- ', PLACE_NAMES[Idx], ' ---');
  WriteLn;
  TextColor(LightGray);

  Before := IsSearched(P, Idx);
  if Before then
  begin
    WriteLn(REVISIT[Random(High(REVISIT)) + 1]);
    SearchPlace := False;
  end
  else
  begin
    WriteLn(PLACE_TEXT[Idx, 1]);
    WriteLn(PLACE_TEXT[Idx, 2]);
    WriteLn(PLACE_TEXT[Idx, 3]);
    P.NRSearched := P.NRSearched or (Word(1) shl (Idx - 1));
    SearchPlace := True;
  end;

  { The Hall of Fame keeps exactly one name: the Wyrm's last conqueror }
  if PLACE_KEYS[Idx] = 'R' then
  begin
    WriteLn;
    Champ := GetChampion;
    TextColor(Yellow);
    if Champ <> '' then
      WriteLn('All but one. Cut deep into the last plaque: ', Champ, '.')
    else
      WriteLn('All but one plaque, which has been left smooth and empty. Waiting.');
    TextColor(LightGray);
  end;

  if (not Before) and (SearchedCount(P) = NR_KEEP_REVEAL) then
  begin
    WriteLn;
    TextColor(LightRed);
    WriteLn('Stepping back outside, you notice a hill rising above the rooftops.');
    WriteLn('There is no hill there in South Ridge. On top of it stands a keep');
    WriteLn('of black stone, and a thin grey smoke leaks from its doors.');
    TextColor(LightGray);
    PostNews('Someone has seen the Ashen Keep. Nobody in South Ridge will say who.');
  end;

  if Random(4) = 0 then
  begin
    WriteLn;
    TextColor(DarkGray);
    WriteLn(UNEASE[Random(High(UNEASE)) + 1]);
    TextColor(LightGray);
  end;

  SavePlayer(P);
  Pause;
end;

{ The final fight. Returns True when the trip should end. }
function EnterKeep(var P: TPlayer): Boolean;
var
  Choice: Char;
  OldChamp: string;
  GoldReward, XPReward, WyrmHP, WyrmAtk, WyrmBreath: LongInt;
begin
  EnterKeep := False;
  ClrScr;
  TextColor(Red);
  WriteLn('--- The Ashen Keep ---');
  WriteLn;
  TextColor(LightGray);
  WriteLn('The doors are taller than the chapel steeple. Inside it is warm, then hot.');
  WriteLn('The floor is ash, knee-deep and soft, and it rises and falls, slowly,');
  WriteLn('because it is not the floor. It is breathing.');
  WriteLn;

  if IsChampion(P) then
  begin
    TextColor(DarkGray);
    WriteLn('One eye opens in the ash, as big as a cartwheel. It knows you.');
    WriteLn('It closes again. The Wyrm will not rise for you while you hold its title.');
    WriteLn('Another must take it first.');
    TextColor(LightGray);
    Pause;
    Exit;
  end;

  TextColor(Yellow);
  Write('Wake the Ashen Wyrm? [Y/N]: ');
  TextColor(LightGray);
  Choice := UpCase(GetKey);
  WriteLn(Choice);
  if Choice <> 'Y' then
  begin
    WriteLn('You back out of the keep one silent step at a time.');
    Pause;
    Exit;
  end;

  EnterKeep := True; { Win, lose or flee, the trip is over }
  WriteLn;
  TextColor(LightRed);
  WriteLn('The ash heaves up and pours off a body that fills the hall.');
  WriteLn('The Ashen Wyrm uncoils, and looks at you, and opens its mouth.');
  WriteLn;
  TextColor(DarkGray);
  WriteLn('Its breath rolls over you, hot and slow, and your wounds close.');
  WriteLn('It wants you whole. It has always been the same size as whoever wakes it.');
  TextColor(LightGray);

  { A fair fight: the Wyrm restores the challenger, then sizes itself to them }
  P.HP := P.MaxHP;
  P.MP := P.MaxMP;
  SavePlayer(P);
  ScaleWyrm(P, WyrmHP, WyrmAtk, WyrmBreath);

  case FightFoe(P, WYRM_NAME, WyrmHP, WyrmAtk, WyrmBreath) of
    frWon:
      begin
        OldChamp := GetChampion;
        GoldReward := 20000 + LongInt(P.Level) * 1000;
        XPReward := 15000 + LongInt(P.Level) * 500;
        AddGold(P.Gold, GoldReward);
        P.XP := P.XP + XPReward;
        Inc(P.WyrmWins);
        SetChampion(P.Name);
        SavePlayer(P);

        WriteLn;
        TextColor(Yellow);
        WriteLn('The Wyrm sinks into the ash with a sound like a forge going out.');
        WriteLn('It is not dead. It cannot die. But it is beaten, and it knows your name.');
        WriteLn;
        WriteLn('You are CHAMPION OF THE RIDGE!');
        WriteLn('From its hoard you take ', GoldReward, ' gold, and you gain ', XPReward, ' XP.');
        TextColor(LightGray);
        if OldChamp <> '' then
          PostNews(P.Name + ' has bested the Ashen Wyrm and taken the title of Champion of the Ridge from ' +
                   OldChamp + '!')
        else
          PostNews(P.Name + ' has bested the Ashen Wyrm and is the first Champion of the Ridge!');
        WriteLn;
        TextColor(DarkGray);
        WriteLn('When you look back from the footbridge, there is no hill above North Ridge.');
        TextColor(LightGray);
        Pause;
      end;
    frFled:
      begin
        WriteLn;
        TextColor(LightMagenta);
        WriteLn('You run. Behind you the Wyrm does not chase. It does not need to.');
        WriteLn('You do not stop running until your boots hit the footbridge planks.');
        TextColor(LightGray);
        Pause;
      end;
    frDied:
      BecomeLost(P, P.Name + ' entered the Ashen Keep and did not come out.');
  end;
end;

procedure VisitNorthRidge(var P: TPlayer);
var
  Hours, Idx: Integer;
  Choice: Char;
begin
  Hours := HOURS_PER_TRIP;

  repeat
    DrawTown(P, Hours);
    Choice := UpCase(GetKey);
    WriteLn(Choice);

    Idx := PlaceIndex(Choice);
    if (Choice <> ' ') and (Idx > 0) then
    begin
      if SearchPlace(P, Idx) then
        Dec(Hours);
    end
    else
      case Choice of
        'V': ShowStats(P);
        'K': if KeepRevealed(P) then
               if EnterKeep(P) then
                 Exit;
        'C': begin
               ClrScr;
               TextColor(DarkGray);
               WriteLn('You cross the footbridge out of North Ridge. You do not look back.');
               WriteLn('When you do look back, there is only the Wood.');
               TextColor(LightGray);
               Pause;
               Exit;
             end;
        'Q': begin
               SavePlayerAsleep(P, False); { No room out here: they wake in the street }
               ClrScr;
               WriteLn('Progress saved. You close your eyes in North Ridge,');
               WriteLn('and wake in South Ridge, not sure how you got there.');
               Halt;
             end;
      end;

    if P.LostInWood then
      Exit;

    if Hours <= 0 then
    begin
      ClrScr;
      TextColor(Brown);
      WriteLn('The ash-colored sun touches the ridge.');
      WriteLn('Beneath the town, something vast begins to stir.');
      WriteLn;
      TextColor(LightGray);
      WriteLn('You run for the footbridge and do not look back.');
      Pause;
      Exit;
    end;
  until False;
end;

end.
