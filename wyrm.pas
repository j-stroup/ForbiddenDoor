{$MODE TP}
program AshenWyrm;

uses
  Crt, GameTypes, Shops, Combat, Tavern, Cemetery, Footbridge;

var
  Hero: TPlayer;
  QuitGame: Boolean;

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
  WriteLn('[R] Hall of Fame (Leaderboard)');
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
    'C': VisitFootbridge(Hero);
    'V': ShowStats(Hero);
    'R': ShowLeaderboard(Hero.Name);
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
    Halt; { Cleanly exits and drops the SSH/Telnet session on cancel or failed PIN }

  repeat
    TownMenu;
  until QuitGame;

  ClrScr;
  WriteLn('Progress saved. Safe travels, ', Hero.Name, '.');
end.