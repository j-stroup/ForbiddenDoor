{$MODE TP}
program AshenWyrm;

uses
  Crt, SysUtils, GameTypes, Town, Shops, Combat, Tavern, Cemetery, Footbridge, Chapel, Alleys;

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
  WriteLn;
  PrintNews(12);
  Pause;
end;

procedure TownMenu;
var
  Choice: Char;
  StatusLine: string;
begin
  CheckDailyReset(Hero);
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

  { 8 Rows (15 Menu Options) }
  PrintDualRow('W', 'Weapon Shop',             'F', 'Enter the Forest (Hunt)');
  PrintDualRow('A', 'Armor Shop',              'G', 'Old Cemetery (Crypt)');
  PrintDualRow('T', 'Training Grounds',        'C', 'Creek Footbridge (Explore)');
  PrintDualRow('B', 'South Ridge Bank',        'D', 'Dark Back Alleys');
  PrintDualRow('I', 'Inn (Rest & Recover)',    'V', 'View Warrior Stats');
  PrintDualRow('H', 'Olde Hallowed Tavern',    'R', 'Hall of Fame (Rankings)');
  PrintDualRow('P', 'Parish Chapel',           'Q', 'Save & Quit');
  PrintDualRow('N', 'Town Crier (Daily News)', ' ', '');

  TextColor(DarkGray);
  WriteLn('+====================================+====================================+');
  WriteLn;
  TextColor(LightGray);
  Write('Command [W,A,T,B,I,H,P,N / F,G,C,D,V,R,Q]: ');

  Choice := UpCase(GetKey);
  WriteLn(Choice);

  case Choice of
    'F': EnterForest(Hero);
    'W': VisitWeaponShop(Hero);
    'A': VisitArmorShop(Hero);
    'T': VisitTrainer(Hero);
    'B': VisitBank(Hero);
    'I': RestAtInn(Hero);
    'H': VisitTavern(Hero);
    'G': VisitCemetery(Hero);
    'C': VisitFootbridge(Hero);
    'P': VisitChapel(Hero);
    'D': VisitAlleys(Hero);
    'V': ShowStats(Hero);
    'R': ShowLeaderboard(Hero.Name);
    'N': ShowCrier;
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
    'Q': begin
           SavePlayer(Hero);
           QuitGame := True;
         end;
  end;
end;

begin
  Randomize;
  QuitGame := False;

  if not LoginPlayer(Hero) then
    Halt;

  ShowCrier;

  repeat
    TownMenu;
  until QuitGame;

  ClrScr;
  WriteLn('Progress saved. Safe travels, ', Hero.Name, '.');
end.