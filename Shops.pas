{$MODE TP}
unit Shops;

interface

uses
  Crt, SysUtils, GameTypes;

procedure VisitBank(var P: TPlayer);
procedure VisitTrainer(var P: TPlayer);
procedure VisitWeaponShop(var P: TPlayer);
procedure VisitArmorShop(var P: TPlayer);
procedure VisitHealer(var P: TPlayer);
procedure RestAtInn(var P: TPlayer);

implementation

procedure VisitBank(var P: TPlayer);
var
  Choice: Char;
  Amount: LongInt;
begin
  repeat
    ClrScr;
    TextColor(Yellow);
    WriteLn('--- First National Bank of South Ridge ---');
    TextColor(LightGray);
    WriteLn('Gold in Hand : ', P.Gold);
    WriteLn('Gold in Vault: ', P.BankGold, ' (Earns 5% interest each night at the Inn)');
    WriteLn;
    WriteLn('[D] Deposit Gold');
    WriteLn('[W] Withdraw Gold');
    WriteLn('[A] Deposit All');
    WriteLn('[L] Leave Bank');
    WriteLn;
    Write('Your choice: ');

    Choice := UpCase(ReadKey);
    WriteLn(Choice);

    case Choice of
      'D': begin
             Write('Amount to deposit: ');
             {$I-} ReadLn(Amount); {$I+}
             if (IOResult <> 0) or (Amount <= 0) then
               WriteLn('Invalid amount.')
             else if Amount > P.Gold then
               WriteLn('You don''t have that much gold on hand.')
             else
             begin
               P.Gold := P.Gold - Amount;
               P.BankGold := P.BankGold + Amount;
               SavePlayer(P);
               WriteLn('Deposited ', Amount, ' gold.');
             end;
             Pause;
           end;
      'W': begin
             Write('Amount to withdraw: ');
             {$I-} ReadLn(Amount); {$I+}
             if (IOResult <> 0) or (Amount <= 0) then
               WriteLn('Invalid amount.')
             else if Amount > P.BankGold then
               WriteLn('You don''t have that much in your vault.')
             else
             begin
               P.BankGold := P.BankGold - Amount;
               P.Gold := P.Gold + Amount;
               SavePlayer(P);
               WriteLn('Withdrew ', Amount, ' gold.');
             end;
             Pause;
           end;
      'A': begin
             if P.Gold > 0 then
             begin
               WriteLn('Deposited ', P.Gold, ' gold into your vault.');
               P.BankGold := P.BankGold + P.Gold;
               P.Gold := 0;
               SavePlayer(P);
             end
             else
               WriteLn('Your pockets are empty.');
             Pause;
           end;
    end;
  until Choice = 'L';
end;

procedure VisitTrainer(var P: TPlayer);
var
  Needed: LongInt;
begin
  ClrScr;
  Needed := XPForNextLevel(P.Level);

  TextColor(LightMagenta);
  WriteLn('--- Master Vane''s Training Grounds ---');
  TextColor(LightGray);
  WriteLn('Current Level : ', P.Level);
  WriteLn('Current XP    : ', P.XP, ' / ', Needed);
  WriteLn;

  if P.XP < Needed then
  begin
    WriteLn('Master Vane sizes you up and shakes his head.');
    WriteLn('"You need ', Needed - P.XP, ' more experience before I can train you."');
  end
  else
  begin
    Inc(P.Level);
    P.MaxHP := P.MaxHP + 12;
    P.HP := P.MaxHP;
    P.MaxMP := P.MaxMP + 6;
    P.MP := P.MaxMP;
    P.Strength := P.Strength + 3;
    SavePlayer(P);

    TextColor(Yellow);
    WriteLn('*** LEVEL UP! You are now Level ', P.Level, '! ***');
    TextColor(LightGreen);
    WriteLn('Max HP +12 (now ', P.MaxHP, ') | Max MP +6 (now ', P.MaxMP, ') | Strength +3 (now ', P.Strength, ')!');
    TextColor(LightGray);
  end;
  Pause;
end;

procedure VisitWeaponShop(var P: TPlayer);
var
  i, Pick: Integer;
begin
  ClrScr;
  TextColor(LightCyan);
  WriteLn('--- The Blacksmith (Your Gold: ', P.Gold, ') ---');
  TextColor(LightGray);
  WriteLn('Equipped: ', WEAPONS[P.WeaponIndex].Name, ' (+', WEAPONS[P.WeaponIndex].StatBonus, ' Atk)');
  WriteLn;

  for i := 2 to High(WEAPONS) do
    WriteLn('[', i:2, '] ', WEAPONS[i].Name:22, ' (+', WEAPONS[i].StatBonus:3, ' Atk) - ', WEAPONS[i].Cost, ' gold');

  WriteLn('[ 0] Leave Shop');
  WriteLn;
  Write('Enter weapon number to buy: ');
  {$I-} ReadLn(Pick); {$I+}

  if (IOResult <> 0) or (Pick = 0) then
    Exit;

  if (Pick >= 2) and (Pick <= High(WEAPONS)) then
  begin
    if Pick <= P.WeaponIndex then
      WriteLn('You already own that weapon or better!')
    else if P.Gold < WEAPONS[Pick].Cost then
      WriteLn('You do not have enough gold.')
    else
    begin
      P.Gold := P.Gold - WEAPONS[Pick].Cost;
      P.WeaponIndex := Pick;
      SavePlayer(P);
      TextColor(LightGreen);
      WriteLn('You equip the ', WEAPONS[Pick].Name, '!');
      TextColor(LightGray);
    end;
    Pause;
  end;
end;

procedure VisitArmorShop(var P: TPlayer);
var
  i, Pick: Integer;
begin
  ClrScr;
  TextColor(LightCyan);
  WriteLn('--- The Armorer (Your Gold: ', P.Gold, ') ---');
  TextColor(LightGray);
  WriteLn('Equipped: ', ARMORS[P.ArmorIndex].Name, ' (+', ARMORS[P.ArmorIndex].StatBonus, ' Def)');
  WriteLn;

  for i := 2 to High(ARMORS) do
    WriteLn('[', i:2, '] ', ARMORS[i].Name:22, ' (+', ARMORS[i].StatBonus:2, ' Def) - ', ARMORS[i].Cost, ' gold');

  WriteLn('[ 0] Leave Shop');
  WriteLn;
  Write('Enter armor number to buy: ');
  {$I-} ReadLn(Pick); {$I+}

  if (IOResult <> 0) or (Pick = 0) then
    Exit;

  if (Pick >= 2) and (Pick <= High(ARMORS)) then
  begin
    if Pick <= P.ArmorIndex then
      WriteLn('You already own that armor or better!')
    else if P.Gold < ARMORS[Pick].Cost then
      WriteLn('You do not have enough gold.')
    else
    begin
      P.Gold := P.Gold - ARMORS[Pick].Cost;
      P.ArmorIndex := Pick;
      SavePlayer(P);
      TextColor(LightGreen);
      WriteLn('You strap on the ', ARMORS[Pick].Name, '!');
      TextColor(LightGray);
    end;
    Pause;
  end;
end;

procedure VisitHealer(var P: TPlayer);
var
  HealCost: LongInt;
begin
  ClrScr;
  { Scale healing cost gently with level so full heals stay meaningful }
  HealCost := 15 + ((P.Level - 1) * 10);

  TextColor(LightGreen);
  WriteLn('--- The Apothecary (Fee: ', HealCost, ' gold) ---');
  TextColor(LightGray);

  if P.HP = P.MaxHP then
    WriteLn('You are already at full health.')
  else if P.Gold < HealCost then
    WriteLn('You need ', HealCost, ' gold, but only have ', P.Gold, '.')
  else
  begin
    P.Gold := P.Gold - HealCost;
    P.HP := P.MaxHP;
    SavePlayer(P);
    WriteLn('Your wounds close. HP restored to ', P.MaxHP, '!');
  end;
  Pause;
end;

procedure RestAtInn(var P: TPlayer);
var
  RoomCost: LongInt;
  HPRecover, MPRecover: Integer;
  Choice: Char;
begin
  ClrScr;
  RoomCost := 15 * P.Level;

  TextColor(Yellow);
  WriteLn('--- The South Ridge Inn ---');
  TextColor(LightGray);
  WriteLn('Server Time: ', FormatDateTime('hh:nn am/pm', Now), ' (Daily limits reset at midnight)');
  WriteLn;
  WriteLn('A quiet room for a few hours costs ', RoomCost, ' gold (Your gold: ', P.Gold, ').');
  WriteLn('Resting recovers up to 50% of your Max HP and Max MP.');
  WriteLn;
  WriteLn('[R] Rent a Room to Recover (', RoomCost, ' gold)');
  WriteLn('[L] Leave');
  WriteLn;
  Write('Your choice: ');

  Choice := UpCase(ReadKey);
  WriteLn(Choice);

  if Choice = 'R' then
  begin
    if (P.HP = P.MaxHP) and (P.MP = P.MaxMP) then
    begin
      WriteLn('You are already fully rested!');
      Pause;
      Exit;
    end;

    if P.Gold < RoomCost then
    begin
      WriteLn('The innkeeper shakes his head. "You don''t have enough gold for a room."');
      Pause;
      Exit;
    end;

    P.Gold := P.Gold - RoomCost;

    HPRecover := P.MaxHP div 2;
    if HPRecover < 1 then HPRecover := 1;
    P.HP := P.HP + HPRecover;
    if P.HP > P.MaxHP then P.HP := P.MaxHP;

    MPRecover := P.MaxMP div 2;
    if MPRecover < 1 then MPRecover := 1;
    P.MP := P.MP + MPRecover;
    if P.MP > P.MaxMP then P.MP := P.MaxMP;

    SavePlayer(P);
    TextColor(LightGreen);
    WriteLn('You nap beside the hearth and wake refreshed!');
    WriteLn('HP is now ', P.HP, '/', P.MaxHP, ' | MP is now ', P.MP, '/', P.MaxMP, '.');
    TextColor(LightGray);
    Pause;
  end;
end;

end.