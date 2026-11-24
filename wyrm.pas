{$MODE TP}
program AshenWyrm;

uses
  Crt, SysUtils, GameTypes, Town, Shops, Combat, Tavern, Cemetery, Footbridge, Chapel, Alleys, ShiftingWood, Streets, Holdings;

var
  Hero: TPlayer;
  QuitGame: Boolean;

{ Prints one paired row of the two-column town menu with highlighted hotkeys }
procedure PrintDualRow(LeftKey: Char; const LeftLabel: string;
                       RightKey: Char; const RightLabel: string);
begin
  TextColor(DarkGray);
  Write('| ');
  TextColor(Yellow);
  Write('[', LeftKey, '] ');
  TextColor(LightGray);
  Write(PadRight(LeftLabel, 30));

  TextColor(DarkGray);
  Write(' | ');
  if RightKey = ' ' then
    Write('    ') { Empty right-hand cell }
  else
  begin
    TextColor(Yellow);
    Write('[', RightKey, '] ');
  end;
  TextColor(LightGray);
  Write(PadRight(RightLabel, 30));

  TextColor(DarkGray);
  WriteLn(' |');
end;

{ The town newspaper: today's condition plus the latest headlines }
procedure ShowCrier;
var
  C: TCondition;
  Champ: string;
begin
  ClrScr;
  C := TodayCondition;
  TextColor(DarkGray);
  WriteLn('+=========================================================================+');
  TextColor(Yellow);
  WriteLn('                         THE SOUTH RIDGE CRIER');
  TextColor(DarkGray);
  WriteLn('                     ', FormatDateTime('dddd, mmmm d, yyyy', Date));
  WriteLn('+=========================================================================+');
  WriteLn;
  TextColor(LightCyan);
  WriteLn('TODAY: ', ConditionName(C));
  PrintConditionDetails(C);
  PrintWoodWhisper;
  WriteLn;
  Champ := GetChampion;
  TextColor(Yellow);
  if Champ <> '' then
    WriteLn('Champion of the Ridge: ', Champ)
  else
    WriteLn('Champion of the Ridge: none. The Ashen Wyrm has never been bested.');
  WriteLn;
  PrintNews(12);
  Pause;
end;

{ Where the warrior sleeps tonight decides whether they can be ambushed.
  Returns True once they have gone to bed. }
function ChooseBed: Boolean;
var
  Choice: Char;
begin
  ChooseBed := False;
  ClrScr;
  if Hero.InnPaidDay = Trunc(Date) then
  begin
    TextColor(LightGreen);
    WriteLn('You head up to the room you paid for at the Inn and bolt the door.');
    TextColor(LightGray);
    SavePlayerAsleep(Hero, True);
    ChooseBed := True;
    Exit;
  end;

  TextColor(Yellow);
  WriteLn('--- Turning In ---');
  TextColor(LightGray);
  WriteLn('You have no room at the Inn tonight. Sleep in the street and anyone may');
  WriteLn('jump you while you are away for the gold in your pocket.');
  if Hero.Gold > 0 then
  begin
    TextColor(LightRed);
    WriteLn('You are carrying ', Hero.Gold, ' gold. The bank is safer than your boot.');
  end;
  TextColor(LightGray);
  WriteLn;
  WriteLn('[I] Rent a room at the Inn (', RoomCost(Hero), ' gold)');
  WriteLn('[S] Sleep in the street');
  WriteLn('[N] Never mind, back to town');
  WriteLn;
  Write('Your choice: ');
  Choice := UpCase(GetKey);
  WriteLn(Choice);
  WriteLn;

  case Choice of
    'I': if RentRoom(Hero) then
         begin
           TextColor(LightGreen);
           WriteLn('You climb the stairs, bolt the door behind you, and sleep.');
           TextColor(LightGray);
           SavePlayerAsleep(Hero, True);
           ChooseBed := True;
         end
         else
           Pause;
    'S': begin
           WriteLn('You find a doorway out of the wind and pull your cloak tight.');
           SavePlayerAsleep(Hero, False);
           ChooseBed := True;
         end;
  end;
end;

procedure TownMenu;
var
  Choice: Char;
  StatusLine, Champ, BridgeLabel: string;
begin
  CheckDailyReset(Hero);
  SavePlayer(Hero); { Heartbeat: marks this warrior awake for other nodes }
  ClrScr;

  { Top Title & Live Warrior HUD Box }
  TextColor(DarkGray);
  WriteLn('+=========================================================================+');
  Write('| ');
  TextColor(LightRed);
  Write(PadRight('THE SOUTH RIDGE', 47));
  TextColor(LightCyan);
  Write(PadRight('Warrior: ' + Hero.Name, 24));
  TextColor(DarkGray);
  WriteLn(' |');
  WriteLn('+-------------------------------------------------------------------------+');

  { Color-coded vitals strip }
  Write('| ');
  TextColor(White);
  Write('Lvl: ', Hero.Level:2, '   ');

  if Hero.HP <= (Hero.MaxHP div 4) then
    TextColor(LightRed)
  else if Hero.HP < Hero.MaxHP then
    TextColor(Yellow)
  else
    TextColor(LightGreen);
  Write('HP: ', Hero.HP, '/', Hero.MaxHP, '   ');

  TextColor(LightCyan);
  Write('MP: ', Hero.MP, '/', Hero.MaxMP, '   ');

  TextColor(Yellow);
  Write('Gold: ', Hero.Gold, '   ');

  if Hero.FightsLeft > 0 then
    TextColor(LightGreen)
  else
    TextColor(Red);
  StatusLine := 'Fights: ' + IntToStr(Hero.FightsLeft);
  Write(PadRight(StatusLine, 12));

  TextColor(DarkGray);
  WriteLn(' |');
  WriteLn('+-------------------------------------------------------------------------+');

  { Today's town-wide condition }
  Write('| ');
  TextColor(LightMagenta);
  Write(PadRight('Today: ' + ConditionName(TodayCondition) + ' - ' + ConditionShort(TodayCondition), 71));
  TextColor(DarkGray);
  WriteLn(' |');

  { The reigning Champion of the Ridge, for everyone to see }
  Champ := GetChampion;
  Write('| ');
  TextColor(Yellow);
  if Champ = '' then
    Write(PadRight('Champion of the Ridge: none - the Ashen Wyrm is unbested', 71))
  else if UpperCase(Champ) = UpperCase(Trim(Hero.Name)) then
    Write(PadRight('Champion of the Ridge: YOU, ' + Champ, 71))
  else
    Write(PadRight('Champion of the Ridge: ' + Champ, 71));
  TextColor(DarkGray);
  WriteLn(' |');
  WriteLn('+====================================+====================================+');

  { Column Headers }
  Write('| ');
  TextColor(LightCyan);
  Write(PadRight('TOWN & SANCTUARIES', 34));
  TextColor(DarkGray);
  Write(' | ');
  TextColor(LightCyan);
  Write(PadRight('WILDS, QUESTS & RECORDS', 34));
  TextColor(DarkGray);
  WriteLn(' |');
  WriteLn('+------------------------------------+------------------------------------+');

  { 9 Rows (18 Menu Options) }
  PrintDualRow('W', 'Weapon Shop',             'F', 'Enter the Forest (Hunt)');
  PrintDualRow('A', 'Armor Shop',              'G', 'Old Cemetery (Crypt)');
  if (Hero.Level >= WOOD_MIN_LEVEL) and Hero.WoodSeen then
    BridgeLabel := 'Footbridge (Shifting Wood)'
  else
    BridgeLabel := 'Creek Footbridge (Explore)';
  PrintDualRow('T', 'Training Grounds',        'C', BridgeLabel);
  PrintDualRow('B', 'South Ridge Bank',        'D', 'Dark Back Alleys');
  PrintDualRow('L', 'Healer''s Hut',            'S', 'Prowl the Streets (PvP)');
  PrintDualRow('I', 'Inn (Sleep Safely)',      'V', 'View Warrior Stats');
  PrintDualRow('H', 'Olde Hallowed Tavern',    'R', 'Hall of Fame (Rankings)');
  PrintDualRow('P', 'Parish Chapel',           'Q', 'Save & Quit');
  PrintDualRow('N', 'Town Crier (Daily News)', 'O', 'Town Hall (Buy a Business)');

  TextColor(DarkGray);
  WriteLn('+====================================+====================================+');
  WriteLn;
  TextColor(LightGray);
  Write('Command [W,A,T,B,L,I,H,P,N / F,G,C,D,S,O,V,R,Q]: ');

  Choice := UpCase(GetKey);
  WriteLn(Choice);

  case Choice of
    'F': EnterForest(Hero);
    'W': VisitWeaponShop(Hero);
    'A': VisitArmorShop(Hero);
    'T': VisitTrainer(Hero);
    'B': VisitBank(Hero);
    'I': if RestAtInn(Hero) then
         begin
           SavePlayerAsleep(Hero, True);
           QuitGame := True;
         end;
    'L': VisitHealer(Hero);
    'S': ProwlStreets(Hero);
    'H': VisitTavern(Hero);
    'G': VisitCemetery(Hero);
    'C': VisitFootbridge(Hero);
    'P': VisitChapel(Hero);
    'D': VisitAlleys(Hero);
    'V': ShowStats(Hero);
    'R': ShowLeaderboard(Hero.Name);
    'N': ShowCrier;
    'O': VisitTownHall(Hero);
    '~': begin
           if not Hero.SysOpDone then
           begin
             Hero.SysOpDone := True;
             Inc(Hero.FightsLeft);
             SavePlayer(Hero);
             ClrScr;
             TextColor(LightGreen);
             WriteLn('[SYSOP OVERRIDE] You found the hidden console key!');
             WriteLn('The SysOp slides a lukewarm mug of coffee across the terminal.');
             WriteLn('(+1 Bonus Forest Fight granted!)');
             TextColor(LightGray);
             Pause;
           end;
         end;
    'Q': QuitGame := ChooseBed;
  end;
end;

begin
  Randomize;
  QuitGame := False;

  if not LoginPlayer(Hero) then
    Halt;
  CollectHoldings(Hero);

  if not Hero.LostInWood then
  begin
    ShowCrier;
    repeat
      TownMenu;
    until QuitGame or Hero.LostInWood;
  end;

  ClrScr;
  if Hero.LostInWood then
  begin
    TextColor(LightRed);
    WriteLn(Hero.Name, ' is lost in the Shifting Wood.');
    TextColor(LightGray);
    WriteLn('The woodcutters will find you at dawn. Come back tomorrow.');
  end
  else
    WriteLn('Progress saved. Safe travels, ', Hero.Name, '.');
end.