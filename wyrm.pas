{$MODE TP}
program AshenWyrm;

uses
  Crt, GameTypes, Shops, Combat, Tavern, Cemetery;

var
  Hero: TPlayer;
  QuitGame: Boolean;

{ Atmospheric exploration stubs ready for future features }
procedure VisitFootbridge;
begin
  ClrScr;
  TextColor(LightCyan);
  WriteLn('--- The Creek Footbridge ---');
  TextColor(LightGray);
  WriteLn('Dark water rushes beneath mossy timber planks into the thick woods.');
  WriteLn('Something metallic glints briefly in the gravel bed below, out of reach.');
  Pause;
end;

procedure TownMenu;
var
  Choice: Char;
begin
  ClrScr;
  TextColor(LightRed);
  WriteLn('===========================================================');
  WriteLn(' TOWN OF SOUTH RIDGE | Lvl ', Hero.Level, ' | HP: ', Hero.HP, '/', Hero.MaxHP, ' | MP: ', Hero.MP, '/', Hero.MaxMP);
  WriteLn('===========================================================');
  TextColor(LightGray);
  WriteLn('[F] Dark Forest (', Hero.FightsLeft, ' fights left)');
  WriteLn('[L] Rusted Lantern Tavern');
  WriteLn('[T] Training Grounds (XP: ', Hero.XP, '/', XPForNextLevel(Hero.Level), ')');
  WriteLn('[B] Bank (Vault: ', Hero.BankGold, ' gold)');
  WriteLn('[W] Weapon Shop (Blacksmith)');
  WriteLn('[A] Armor Shop (Armorer)');
  WriteLn('[H] Healer (15 gold)');
  WriteLn('[I] Inn (Rest & Reset Fights)');
  WriteLn('[G] Old Cemetery (Explore)');
  WriteLn('[C] Creek Footbridge (Explore)');
  WriteLn('[V] View Warrior Stats');
  WriteLn('[Q] Save & Quit');
  WriteLn;
  Write('Your choice: ');

  Choice := UpCase(ReadKey);
  case Choice of
    'F': EnterForest(Hero);
    'L': VisitTavern(Hero);
    'T': VisitTrainer(Hero);
    'B': VisitBank(Hero);
    'W': VisitWeaponShop(Hero);
    'A': VisitArmorShop(Hero);
    'H': VisitHealer(Hero);
    'I': RestAtInn(Hero);
    'G': VisitCemetery(Hero);
    'C': VisitFootbridge;
    'V': ShowStats(Hero);
    'Q': begin
           SavePlayer(Hero);
           QuitGame := True;
         end;
  end;
end;

begin
  Randomize;
  QuitGame := False;

  if LoadPlayer(Hero) then
  begin
    ClrScr;
    TextColor(LightGreen);
    WriteLn('Welcome back, ', Hero.Name, ' (Level ', Hero.Level, ')!');
    TextColor(LightGray);
    Pause;
  end
  else
    InitPlayer(Hero);

  repeat
    TownMenu;
  until QuitGame;

  ClrScr;
  WriteLn('Progress saved to ', SAVE_FILE, '. Safe travels, ', Hero.Name, '.');
end.