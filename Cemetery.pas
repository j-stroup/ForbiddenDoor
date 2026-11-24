{$MODE TP}
unit Cemetery;

interface

uses
  Crt, GameTypes, Town;

procedure VisitCemetery(var P: TPlayer);

implementation


{ Returns True if the player defeated the guardian, False if they fled or fell }
function CryptBattle(var P: TPlayer; const EnemyName: string; EnemyHP, EnemyAtk, GoldReward, XPReward: LongInt): Boolean;
var
  Action: Char;
  PlayerDmg, EnemyDmg: LongInt;
  TurnTaken, Crit: Boolean;
begin
  CryptBattle := False;
  if TodayCondition = cdAllSouls then
    GoldReward := (GoldReward * 5) div 4;
  TextColor(LightRed);
  WriteLn(EnemyName, ' blocks the stone archway!');
  TextColor(LightGray);

  repeat
    TurnTaken := False;
    WriteLn;
    WriteLn(P.Name, ' HP: ', P.HP, ' | MP: ', P.MP, '  ||  ', EnemyName, ' HP: ', EnemyHP);
    Write('[A]ttack, [S]kill, or [F]lee Crypt? ');
    Action := UpCase(GetKey);
    WriteLn(Action);

    if Action = 'A' then
    begin
      PlayerDmg := WeaponDamage(P, Crit);
      EnemyHP := EnemyHP - PlayerDmg;
      TextColor(Yellow);
      if Crit then
        Write('CRITICAL! ');
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
      EnemyDmg := (Random(EnemyAtk) + 1) - ArmorValue(P);
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
    PostNews(P.Name + ' was swallowed by darkness in the Sunken Crypt.');
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
  AddGold(P.Gold, GoldReward);
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
              35 + (LongInt(P.Level) * 22),
              7 + (LongInt(P.Level) * 4),
              70 * LongInt(P.Level),
              60 * LongInt(P.Level)) then
             Exit;
         end;

      2: begin
           WriteLn('Rows of sealed clay urns line this narrow vault.');
           Write('Smash a dusty urn before moving on? [Y/N]: ');
           Choice := UpCase(GetKey);
           WriteLn(Choice);

           if Choice = 'Y' then
           begin
             if Random(2) = 0 then
             begin
               BonusGold := 80 * LongInt(P.Level);
               AddGold(P.Gold, BonusGold);
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
              52 + (LongInt(P.Level) * 30),
              10 + (LongInt(P.Level) * 5),
              110 * LongInt(P.Level),
              90 * LongInt(P.Level)) then
             Exit;
         end;

      3: begin
           WriteLn('Black ankle-deep water covers the flagstones. Cold mist clings to your armor.');
           if not CryptBattle(P, 'Wraith of South Ridge',
              75 + (LongInt(P.Level) * 40),
              13 + (LongInt(P.Level) * 6),
              160 * LongInt(P.Level),
              130 * LongInt(P.Level)) then
             Exit;
         end;

      4: begin
           TextColor(Yellow);
           WriteLn('You enter the Inner Sanctum. An obsidian sarcophagus cracks open!');
           TextColor(LightGray);
           if not CryptBattle(P, 'Malakor, Lord of the Crypt',
              110 + (LongInt(P.Level) * 52) + (LongInt(P.Level) * P.Level * 3),
              16 + (LongInt(P.Level) * 8),
              320 * LongInt(P.Level),
              260 * LongInt(P.Level)) then
             Exit;

           WriteLn;
           TextColor(LightGreen);
           WriteLn('*** CRYPT CLEARED! ***');
           PostNews(P.Name + ' has slain Malakor, Lord of the Crypt!');
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
    Choice := UpCase(GetKey);
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
  Choice: Char;
begin
  ClrScr;
  TextColor(DarkGray);
  WriteLn('--- South Ridge Old Cemetery ---');
  TextColor(LightGray);
  WriteLn('Crooked iron fences lean into the mist among weathered 19th-century headstones.');
  WriteLn('You approach the heavy stone crypt at the far end of the grounds...');
  if TodayCondition = cdAllSouls then
  begin
    TextColor(LightMagenta);
    WriteLn('It is All Souls'' Night. The dead are restless, and the crypt hums with power.');
    TextColor(LightGray);
  end;
  WriteLn;

  { The portal is rolled once per day (20% chance), so re-entering cannot reroll it }
  if P.CryptState = CRYPT_UNROLLED then
  begin
    if (Random(5) = 0) or (TodayCondition = cdAllSouls) then
      P.CryptState := CRYPT_OPEN
    else
      P.CryptState := CRYPT_SEALED;
    SavePlayer(P);
  end;

  case P.CryptState of
    CRYPT_OPEN:
      begin
        TextColor(LightMagenta);
        WriteLn('A swirling violet portal hums inside the open crypt archway!');
        TextColor(Yellow);
        Write('Step through the portal into the Sunken Crypt? [Y/N]: ');
        TextColor(LightGray);

        Choice := UpCase(GetKey);
        WriteLn(Choice);

        if Choice = 'Y' then
        begin
          P.CryptState := CRYPT_USED;
          SavePlayer(P);
          ExploreCrypt(P);
        end
        else
        begin
          WriteLn('You step back from the hum of arcane energy. It still swirls behind you.');
          Pause;
        end;
      end;

    CRYPT_USED:
      begin
        WriteLn('Scorch marks ring the archway where the portal collapsed behind you.');
        WriteLn('Nothing more will stir here until tomorrow.');
        Pause;
      end;
  else
    begin
      WriteLn('The heavy iron doors are sealed cold and silent. No portal stirs today.');
      Pause;
    end;
  end;
end;

end.