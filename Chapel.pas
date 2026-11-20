{$MODE TP}
unit Chapel;

interface

uses
  Crt, SysUtils, GameTypes;

procedure VisitChapel(var P: TPlayer);

implementation

var
  { Session-only on purpose: reconnecting refreshes the free heal words.
    The gold and XP words use the saved daily flag P.ConfessDone instead. }
  UsedHealWord: Boolean;

procedure SecretConfessional(var P: TPlayer);
var
  Whisper: string;
  Bonus: LongInt;
begin
  ClrScr;
  TextColor(DarkGray);
  WriteLn('--- The Dusty Confessional ---');
  TextColor(LightGray);
  WriteLn('You slide open the lattice screen. Shadows shift on the other side.');
  WriteLn('"Speak a word of power, wanderer, or confess your sins..."');
  WriteLn;
  Write('Whisper into the dark: ');
  TextColor(White);
  Whisper := UpperCase(Trim(ReadInput(30, False)));
  TextColor(LightGray);
  WriteLn;

  if ((Whisper = 'XYZZY') or (Whisper = 'WORM')) and P.ConfessDone then
  begin
    WriteLn('Only wind whistles through the wooden lattice. Come back tomorrow.');
    Pause;
    Exit;
  end;

  if ((Whisper = 'IDDQD') or (Whisper = 'GREG')) and UsedHealWord then
  begin
    WriteLn('Only wind whistles through the wooden lattice. Come back another session.');
    Pause;
    Exit;
  end;

  if Whisper = 'XYZZY' then
  begin
    P.ConfessDone := True;
    Bonus := 120 * LongInt(P.Level);
    AddGold(P.Gold, Bonus);
    TextColor(Yellow);
    WriteLn('A hollow voice beyond the screen whispers: "Fool."');
    WriteLn(Bonus, ' ancient brass coins clatter onto your boots!');
  end
  else if Whisper = 'IDDQD' then
  begin
    UsedHealWord := True;
    P.HP := P.MaxHP;
    P.MP := P.MaxMP;
    TextColor(LightGreen);
    WriteLn('Your eyes flare with pale golden fire! Body and spirit surge to 100%!');
  end
  else if Whisper = 'WORM' then
  begin
    P.ConfessDone := True;
    Bonus := 45 * LongInt(P.Level);
    P.XP := P.XP + Bonus;
    TextColor(LightMagenta);
    WriteLn('Too many fingers tap against the cedar screen from the inside...');
    WriteLn('Forbidden memories flood your mind (+', Bonus, ' XP)!');
  end
  else if Whisper = 'GREG' then
  begin
    UsedHealWord := True;
    P.MP := P.MaxMP;
    TextColor(LightCyan);
    WriteLn('Six hands applaud slowly behind the curtain. Your MP is fully restored!');
  end
  else
  begin
    WriteLn('A quiet voice murmurs: "Go in peace, ', P.Name, '." Nothing else happens.');
  end;

  TextColor(LightGray);
  SavePlayer(P);
  Pause;
end;

procedure VisitChapel(var P: TPlayer);
var
  Choice: Char;
  TitheCost: LongInt;
  Roll: Integer;
  Amt, XPGain: LongInt;
begin
  repeat
    ClrScr;
    TextColor(LightCyan);
    WriteLn('--- Old Parish Chapel of South Ridge ---');
    TextColor(LightGray);
    WriteLn('Tallow candles flicker before a weathered stone altar. Rain taps');
    WriteLn('against cracked stained glass. Here, fate answers in mysterious ways.');
    WriteLn;
    WriteLn('HP: ', P.HP, '/', P.MaxHP, ' | MP: ', P.MP, '/', P.MaxMP, ' | Gold: ', P.Gold);
    WriteLn;

    TitheCost := 20 * P.Level;

    WriteLn('[T] Light a Candle & Tithe (', TitheCost, ' gold - Seek a blessing)');
    WriteLn('[M] Quiet Meditation (Spend 6 MP - Unpredictable trance)');
    WriteLn('[B] Inspect the Wooden Poor Box');
    WriteLn('[L] Leave Chapel');
    WriteLn;
    Write('Your choice: ');

    Choice := UpCase(GetKey);
    WriteLn(Choice);
    WriteLn;

    case Choice of
      'K': SecretConfessional(P); { Hidden Exitilus-style Easter egg }

      'T': begin
             if P.Gold < TitheCost then
             begin
               WriteLn('You check your pouch - you do not have ', TitheCost, ' gold to tithe.');
               Pause;
             end
             else
             begin
               P.Gold := P.Gold - TitheCost;
               Roll := Random(100) + 1;

               case Roll of
                 1..45: { Standard Blessing }
                   begin
                     P.MP := P.MaxMP;
                     Amt := P.MaxHP div 4;
                     if Amt < 1 then Amt := 1;
                     P.HP := P.HP + Amt;
                     if P.HP > P.MaxHP then P.HP := P.MaxHP;
                     TextColor(LightGreen);
                     WriteLn('Warmth settles over your shoulders as the wick catches.');
                     WriteLn('MP fully restored and HP healed by +', Amt, '!');
                   end;
                 46..70: { Greater Miracle }
                   begin
                     P.HP := P.MaxHP;
                     P.MP := P.MaxMP;
                     XPGain := 20 * P.Level;
                     P.XP := P.XP + XPGain;
                     TextColor(Yellow);
                     WriteLn('MIRACLE! A shaft of silver light pierces the rafters!');
                     WriteLn('HP and MP are 100% restored, and insight fills you (+', XPGain, ' XP)!');
                   end;
                 71..88: { Prophetic Vision }
                   begin
                     XPGain := 35 * P.Level;
                     P.XP := P.XP + XPGain;
                     Amt := P.MaxMP div 2;
                     P.MP := P.MP + Amt;
                     if P.MP > P.MaxMP then P.MP := P.MaxMP;
                     TextColor(LightCyan);
                     WriteLn('Smoke curls into shapes of the Ashen Wyrm''s lair...');
                     WriteLn('You gain +', XPGain, ' XP and recover +', Amt, ' MP.');
                   end;
               else { 89..100: Sputtering Wick }
                 begin
                   Amt := (P.MaxMP div 3) + 2;
                   P.MP := P.MP + Amt;
                   if P.MP > P.MaxMP then P.MP := P.MaxMP;
                   TextColor(DarkGray);
                   WriteLn('A draft sweeps under the door and snuffs your candle early.');
                   WriteLn('You salvage a quiet moment (+', Amt, ' MP).');
                 end;
               end;

               TextColor(LightGray);
               SavePlayer(P);
               Pause;
             end;
           end;

      'M': begin
             if P.MP < 6 then
             begin
               TextColor(Red);
               WriteLn('You need at least 6 MP to focus your thoughts.');
               TextColor(LightGray);
               Pause;
             end
             else
             begin
               P.MP := P.MP - 6;
               Roll := Random(100) + 1;

               case Roll of
                 1..50: { Deep Mending }
                   begin
                     Amt := 12 + (P.Level * 4) + Random(8);
                     P.HP := P.HP + Amt;
                     if P.HP > P.MaxHP then P.HP := P.MaxHP;
                     TextColor(LightGreen);
                     WriteLn('Steady breathing knits your torn flesh (+', Amt, ' HP).');
                   end;
                 51..75: { Astral Clarity }
                   begin
                     XPGain := 25 * P.Level;
                     P.XP := P.XP + XPGain;
                     TextColor(LightCyan);
                     WriteLn('Your mind drifts above South Ridge, mapping hidden paths (+', XPGain, ' XP).');
                   end;
                 76..90: { Harmonic Feedback }
                   begin
                     Amt := 18 + (P.Level * 5);
                     P.HP := P.HP + Amt;
                     if P.HP > P.MaxHP then P.HP := P.MaxHP;
                     P.MP := P.MP + 4;
                     if P.MP > P.MaxMP then P.MP := P.MaxMP;
                     TextColor(Yellow);
                     WriteLn('Effortless resonance! You recover +', Amt, ' HP and refund 4 MP!');
                   end;
               else { 91..100: Psychic Backlash }
                 begin
                   Amt := 5 + P.Level;
                   P.HP := P.HP - Amt;
                   if P.HP < 1 then P.HP := 1;
                   TextColor(LightRed);
                   WriteLn('A stray nightmare tears through your trance (-', Amt, ' HP)!');
                 end;
               end;

               TextColor(LightGray);
               SavePlayer(P);
               Pause;
             end;
           end;

      'B': begin
             WriteLn('A brass-bound poor box sits bolted to the back pew.');
             if P.PoorBoxDone then
             begin
               WriteLn('The deacon is watching it closely now. Best leave it until tomorrow.');
               Pause;
             end
             else
             begin
               Write('[D]rop 15 gold inside, [S]teal from the box, or [I]gnore? ');
               Choice := UpCase(GetKey);
               WriteLn(Choice);
               WriteLn;

               if Choice = 'D' then
               begin
                 if P.Gold < 15 then
                   WriteLn('You don''t even have 15 gold to spare.')
                 else
                 begin
                   P.Gold := P.Gold - 15;
                   P.PoorBoxDone := True;
                   Roll := Random(100) + 1;
                   case Roll of
                     1..55:
                       begin
                         XPGain := (12 + Random(10)) * LongInt(P.Level);
                         P.XP := P.XP + XPGain;
                         TextColor(Yellow);
                         WriteLn('You slip 15 coins through the slot. Quiet clarity finds you (+', XPGain, ' XP).');
                       end;
                     56..85:
                       begin
                         Amt := 10 + (P.Level * 3);
                         P.HP := P.HP + Amt;
                         if P.HP > P.MaxHP then P.HP := P.MaxHP;
                         P.MP := P.MP + 5;
                         if P.MP > P.MaxMP then P.MP := P.MaxMP;
                         TextColor(LightGreen);
                         WriteLn('A warm breeze brushes your face (+', Amt, ' HP, +5 MP).');
                       end;
                   else
                     begin
                       Amt := 40 * LongInt(P.Level);
                       AddGold(P.Gold, Amt);
                       TextColor(LightCyan);
                       WriteLn('As your coin drops, a heavy gold sovereign rolls out the bottom (+', Amt, ' gold)!');
                     end;
                   end;
                   TextColor(LightGray);
                   SavePlayer(P);
                 end;
                 Pause;
               end
               else if Choice = 'S' then
               begin
                 P.PoorBoxDone := True;
                 Roll := Random(100) + 1;
                 case Roll of
                   1..30:
                     begin
                       Amt := (25 + Random(25)) * LongInt(P.Level);
                       AddGold(P.Gold, Amt);
                       TextColor(Yellow);
                       WriteLn('Your fingers hook ', Amt, ' tarnished coins - and a cold chill runs down your spine.');
                     end;
                   31..65:
                     begin
                       Amt := 8 + (P.Level * 3) + Random(6);
                       P.HP := P.HP - Amt;
                       if P.HP < 1 then P.HP := 1;
                       TextColor(LightRed);
                       WriteLn('A rusted spring-trap snaps across your knuckles (-', Amt, ' HP)!');
                     end;
                   66..90:
                     begin
                       Amt := 8 + (P.Level * 2);
                       P.MP := P.MP - Amt;
                       if P.MP < 0 then P.MP := 0;
                       TextColor(LightMagenta);
                       WriteLn('Spectral frost leaps from the brass lock, draining ', Amt, ' MP!');
                     end;
                 else
                   begin
                     WriteLn('The box is completely empty save for a dead moth and dust.');
                   end;
                 end;
                 TextColor(LightGray);
                 SavePlayer(P);
                 Pause;
               end;
             end;
             Choice := ' ';
           end;
    end;
  until Choice = 'L';
end;

end.