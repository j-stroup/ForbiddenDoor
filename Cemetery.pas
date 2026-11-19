{$MODE TP}
unit Cemetery;

interface

uses
  Crt, GameTypes;

procedure VisitCemetery(var P: TPlayer);

implementation


{ Returns True if the player defeated the guardian, False if they fled or fell }
function CryptBattle(var P: TPlayer; const EnemyName: string; EnemyHP, EnemyAtk, GoldReward, XPReward: Integer): Boolean;
var
  Action: Char;
  PlayerDmg, EnemyDmg: Integer;
  TurnTaken: Boolean;
begin
  CryptBattle := False;
  TextColor(LightRed);
  WriteLn(EnemyName, ' blocks the stone archway!');
  TextColor(LightGray);

  repeat
    TurnTaken := False;
    WriteLn;
    WriteLn(P.Name, ' HP: ', P.HP, ' | MP: ', P.MP, '  ||  ', EnemyName, ' HP: ', EnemyHP);
    Write('[A]ttack, [S]kill, or [F]lee Crypt? ');
    Action := UpCase(ReadKey);
    WriteLn(Action);

    if Action = 'A' then
    begin
      PlayerDmg := (P.Strength div 2) + Random(P.Strength) + WEAPONS[P.WeaponIndex].StatBonus;
      EnemyHP := EnemyHP - PlayerDmg;
      TextColor(LightGreen);
      WriteLn('You strike ', EnemyName, ' for ', PlayerDmg, ' damage!');
      TextColor(LightGray);
      TurnTaken := True;
    end
    else if Action = 'S' then
    begin
      TurnTaken := CastCombatSkill(P, EnemyName, EnemyHP);
    end
    else if Action = 'F' then
    begin
      WriteLn('You bolt up the slick stone stairs and out of the portal!');
      SavePlayer(P);
      Pause;
      Exit;
    end;

    if TurnTaken and (EnemyHP > 0) then
    begin
      EnemyDmg := (Random(EnemyAtk) + 1) - ARMORS[P.ArmorIndex].StatBonus;
      if EnemyDmg < 2 then
        EnemyDmg := 2;

      P.HP := P.HP - EnemyDmg;
      TextColor(LightRed);
      WriteLn(EnemyName, ' slashes you for ', EnemyDmg, ' damage!');
      TextColor(LightGray);
    end;
  until (EnemyHP <= 0) or (P.HP <= 0);

  WriteLn;
  if P.HP <= 0 then
  begin
    TextColor(Red);
    WriteLn('Darkness swallows you! The portal spits you back onto the cemetery grass.');
    if P.Gold > 0 then
      WriteLn('All ', P.Gold, ' gold you carried was lost in the abyss!');
    P.HP := 1;
    P.Gold := 0;
    SavePlayer(P);
    TextColor(LightGray);
    Pause;
    Exit;
  end;

  TextColor(Yellow);
  WriteLn(EnemyName, ' crumbles to dust! You loot ', GoldReward, ' gold and ', XPReward, ' XP.');
  P.Gold := P.Gold + GoldReward;
  P.XP := P.XP + XPReward;
  SavePlayer(P);
  TextColor(LightGray);
  CryptBattle := True;
end;

{ Multi-room state-machine dungeon }
procedure ExploreCrypt(var P: TPlayer);
var
  Room: Integer;
  Retreat: Boolean;
  Choice: Char;
  BonusGold: LongInt;
begin
  Room := 1;
  Retreat := False;

  repeat
    ClrScr;
    TextColor(LightMagenta);
    WriteLn('==================================================');
    WriteLn(' THE SUNKEN CRYPT - CHAMBER ', Room, ' OF 4');
    WriteLn('==================================================');
    TextColor(LightGray);
    WriteLn;

    case Room of
      1: begin
           WriteLn('Torchlight flickers across damp limestone walls lined with carved skulls.');
           if not CryptBattle(P, 'Risen Gravewarden',
              35 + (P.Level * 22),
              7 + (P.Level * 4),
              70 * P.Level,
              60 * P.Level) then
             Exit;
         end;

      2: begin
           WriteLn('Rows of sealed clay urns line this narrow vault.');
           Write('Smash a dusty urn before moving on? [Y/N]: ');
           Choice := UpCase(ReadKey);
           WriteLn(Choice);

           if Choice = 'Y' then
           begin
             if Random(2) = 0 then
             begin
               BonusGold := 80 * P.Level;
               P.Gold := P.Gold + BonusGold;
               TextColor(Yellow);
               WriteLn('Jackpot! Ancient silver coins spill out (+', BonusGold, ' gold)!');
             end
             else
             begin
               TextColor(LightRed);
               WriteLn('Green tomb gas hisses from the shards! You choke for 8 damage.');
               P.HP := P.HP - 8;
               if P.HP < 1 then
                 P.HP := 1;
             end;
             TextColor(LightGray);
             SavePlayer(P);
           end;

           WriteLn;
           if not CryptBattle(P, 'Bone Sentinel',
              52 + (P.Level * 30),
              10 + (P.Level * 5),
              110 * P.Level,
              90 * P.Level) then
             Exit;
         end;

      3: begin
           WriteLn('Black ankle-deep water covers the flagstones. Cold mist clings to your armor.');
           if not CryptBattle(P, 'Wraith of South Ridge',
              75 + (P.Level * 40),
              13 + (P.Level * 6),
              160 * P.Level,
              130 * P.Level) then
             Exit;
         end;

      4: begin
           TextColor(Yellow);
           WriteLn('You enter the Inner Sanctum. An obsidian sarcophagus cracks open!');
           TextColor(LightGray);
           if not CryptBattle(P, 'Malakor, Lord of the Crypt',
              110 + (P.Level * 52) + (P.Level * P.Level * 3),
              16 + (P.Level * 8),
              320 * P.Level,
              260 * P.Level) then
             Exit;

           WriteLn;
           TextColor(LightGreen);
           WriteLn('*** CRYPT CLEARED! ***');
           WriteLn('The portal stabilizes long enough for you to step back into the night air.');
           TextColor(LightGray);
           Pause;
           Exit;
         end;
    end;

    WriteLn;
    TextColor(LightCyan);
    Write('Descend into Chamber ', Room + 1, ', or [R]etreat to the surface? [D/R]: ');
    TextColor(LightGray);
    Choice := UpCase(ReadKey);
    WriteLn(Choice);

    if Choice = 'R' then
    begin
      WriteLn('You climb back through the shimmering rift with your hard-won loot.');
      Pause;
      Retreat := True;
    end
    else
      Inc(Room);

  until (Room > 4) or Retreat or (P.HP <= 0);
end;

procedure VisitCemetery(var P: TPlayer);
var
  PortalRoll: Integer;
  Choice: Char;
begin
  ClrScr;
  TextColor(DarkGray);
  WriteLn('--- South Ridge Old Cemetery ---');
  TextColor(LightGray);
  WriteLn('Crooked iron fences lean into the mist among weathered 19th-century headstones.');
  WriteLn('You approach the heavy stone crypt at the far end of the grounds...');
  WriteLn;

  { 1 out of 5 chance (20%) that the portal is open }
  PortalRoll := Random(5) + 1;

  if PortalRoll = 1 then
  begin
    TextColor(LightMagenta);
    WriteLn('A swirling violet portal hums inside the open crypt archway!');
    TextColor(Yellow);
    Write('Step through the portal into the Sunken Crypt? [Y/N]: ');
    TextColor(LightGray);

    Choice := UpCase(ReadKey);
    WriteLn(Choice);

    if Choice = 'Y' then
      ExploreCrypt(P)
    else
    begin
      WriteLn('You step back from the hum of arcane energy.');
      Pause;
    end;
  end
  else
  begin
    WriteLn('The heavy iron doors are sealed cold and silent. No portal stirs right now.');
    Pause;
  end;
end;

end.