{$MODE TP}
unit Shops;

interface

uses
  Crt, SysUtils, GameTypes, Town, Holdings;

procedure VisitBank(var P: TPlayer);
procedure VisitTrainer(var P: TPlayer);
procedure VisitWeaponShop(var P: TPlayer);
procedure VisitArmorShop(var P: TPlayer);
function RoomCost(const P: TPlayer): LongInt;
function RentRoom(var P: TPlayer): Boolean;
function RestAtInn(var P: TPlayer): Boolean;
procedure VisitHealer(var P: TPlayer);

implementation

{ Harvest Festival knocks 15% off weapons and armor }
function ShopPrice(BaseCost: LongInt): LongInt;
begin
  if TodayCondition = cdFestival then
    ShopPrice := (BaseCost * 85) div 100
  else
    ShopPrice := BaseCost;
end;

procedure FestivalBanner;
begin
  if TodayCondition = cdFestival then
  begin
    TextColor(Yellow);
    WriteLn('Harvest Festival! Bunting hangs over the counter - 15% off everything today.');
    TextColor(LightGray);
  end;
end;

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
    WriteLn('Gold in Vault: ', P.BankGold, ' (Earns 5% interest each day, capped by level)');
    WriteLn;
    WriteLn('[D] Deposit Gold');
    WriteLn('[W] Withdraw Gold');
    WriteLn('[A] Deposit All');
    WriteLn('[L] Leave Bank');
    WriteLn;
    Write('Your choice: ');

    Choice := UpCase(GetKey);
    WriteLn(Choice);

    case Choice of
      'D': begin
             Write('Amount to deposit: ');
             if (not ReadNumber(9, Amount)) or (Amount <= 0) then
               WriteLn('Invalid amount.')
             else if Amount > P.Gold then
               WriteLn('You don''t have that much gold on hand.')
             else
             begin
               P.Gold := P.Gold - Amount;
               AddGold(P.BankGold, Amount);
               SavePlayer(P);
               WriteLn('Deposited ', Amount, ' gold.');
             end;
             Pause;
           end;
      'W': begin
             Write('Amount to withdraw: ');
             if (not ReadNumber(9, Amount)) or (Amount <= 0) then
               WriteLn('Invalid amount.')
             else if Amount > P.BankGold then
               WriteLn('You don''t have that much in your vault.')
             else
             begin
               P.BankGold := P.BankGold - Amount;
               AddGold(P.Gold, Amount);
               SavePlayer(P);
               WriteLn('Withdrew ', Amount, ' gold.');
             end;
             Pause;
           end;
      'A': begin
             if P.Gold > 0 then
             begin
               WriteLn('Deposited ', P.Gold, ' gold into your vault.');
               AddGold(P.BankGold, P.Gold);
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
    PostNews(P.Name + ' trained with Master Vane and reached Level ' + IntToStr(P.Level) + '.');

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
  i: Integer;
  Pick: LongInt;
begin
  ClrScr;
  TextColor(LightCyan);
  WriteLn('--- The Blacksmith (Your Gold: ', P.Gold, ') ---');
  TextColor(LightGray);
  PrintProprietor(PROP_SMITH);
  FestivalBanner;
  WriteLn('Equipped: ', WEAPONS[P.WeaponIndex].Name, ' (+', WEAPONS[P.WeaponIndex].StatBonus, ' Atk)');
  WriteLn;

  for i := 2 to High(WEAPONS) do
    WriteLn('[', i:2, '] ', WEAPONS[i].Name:22, ' (+', WEAPONS[i].StatBonus:3, ' Atk) - ', ShopPrice(WEAPONS[i].Cost), ' gold');

  WriteLn('[ 0] Leave Shop');
  WriteLn;
  Write('Enter weapon number to buy: ');

  if (not ReadNumber(3, Pick)) or (Pick = 0) then
    Exit;

  if (Pick >= 2) and (Pick <= High(WEAPONS)) then
  begin
    if Pick <= P.WeaponIndex then
      WriteLn('You already own that weapon or better!')
    else if P.Gold < ShopPrice(WEAPONS[Pick].Cost) then
      WriteLn('You do not have enough gold.')
    else
    begin
      P.Gold := P.Gold - ShopPrice(WEAPONS[Pick].Cost);
      P.WeaponIndex := Pick;
      SavePlayer(P);
      ShopTakings(PROP_SMITH, P.Name, ShopPrice(WEAPONS[Pick].Cost));
      if Pick >= 10 then
        PostNews(P.Name + ' now wields the ' + WEAPONS[Pick].Name + '.');
      TextColor(LightGreen);
      WriteLn('You equip the ', WEAPONS[Pick].Name, '!');
      TextColor(LightGray);
    end;
    Pause;
  end;
end;

procedure VisitArmorShop(var P: TPlayer);
var
  i: Integer;
  Pick: LongInt;
begin
  ClrScr;
  TextColor(LightCyan);
  WriteLn('--- The Armorer (Your Gold: ', P.Gold, ') ---');
  TextColor(LightGray);
  PrintProprietor(PROP_ARMOR);
  FestivalBanner;
  WriteLn('Equipped: ', ARMORS[P.ArmorIndex].Name, ' (+', ARMORS[P.ArmorIndex].StatBonus, ' Def)');
  WriteLn;

  for i := 2 to High(ARMORS) do
    WriteLn('[', i:2, '] ', ARMORS[i].Name:22, ' (+', ARMORS[i].StatBonus:2, ' Def) - ', ShopPrice(ARMORS[i].Cost), ' gold');

  WriteLn('[ 0] Leave Shop');
  WriteLn;
  Write('Enter armor number to buy: ');

  if (not ReadNumber(3, Pick)) or (Pick = 0) then
    Exit;

  if (Pick >= 2) and (Pick <= High(ARMORS)) then
  begin
    if Pick <= P.ArmorIndex then
      WriteLn('You already own that armor or better!')
    else if P.Gold < ShopPrice(ARMORS[Pick].Cost) then
      WriteLn('You do not have enough gold.')
    else
    begin
      P.Gold := P.Gold - ShopPrice(ARMORS[Pick].Cost);
      P.ArmorIndex := Pick;
      SavePlayer(P);
      ShopTakings(PROP_ARMOR, P.Name, ShopPrice(ARMORS[Pick].Cost));
      if Pick >= 9 then
        PostNews(P.Name + ' now wears the ' + ARMORS[Pick].Name + '.');
      TextColor(LightGreen);
      WriteLn('You strap on the ', ARMORS[Pick].Name, '!');
      TextColor(LightGray);
    end;
    Pause;
  end;
end;

function RoomCost(const P: TPlayer): LongInt;
var
  Cost: LongInt;
begin
  Cost := 15 * LongInt(P.Level);
  if TodayCondition = cdFestival then
    Cost := Cost div 2;
  RoomCost := Cost;
end;

{ Pays for tonight's room if it is not paid for already. True when the
  warrior has a room tonight. }
function RentRoom(var P: TPlayer): Boolean;
var
  Cost: LongInt;
begin
  RentRoom := True;
  if P.InnPaidDay = Trunc(Date) then
    Exit;
  Cost := RoomCost(P);
  if P.Gold < Cost then
  begin
    WriteLn('The innkeeper shakes his head. "', Cost, ' gold for a room. You don''t have it."');
    RentRoom := False;
    Exit;
  end;
  P.Gold := P.Gold - Cost;
  P.InnPaidDay := Trunc(Date);
  SavePlayer(P);
  ShopTakings(PROP_INN, P.Name, Cost);
  WriteLn('You hand over ', Cost, ' gold and the innkeeper gives you a heavy iron key.');
end;

{ The Inn is where you sleep, not where you patch up. A paid room keeps
  you safe from street ambushes while you are logged off, and a full
  night's sleep (waking on a later day) restores you completely.
  Returns True when the warrior turns in for the night. }
function RestAtInn(var P: TPlayer): Boolean;
var
  Choice: Char;
  HasRoom: Boolean;
begin
  RestAtInn := False;
  ClrScr;
  HasRoom := P.InnPaidDay = Trunc(Date);

  TextColor(Yellow);
  WriteLn('--- The South Ridge Inn ---');
  TextColor(LightGray);
  PrintProprietor(PROP_INN);
  if TodayCondition = cdFestival then
    WriteLn('Festival rates tonight: rooms are half price!');
  WriteLn('Server Time: ', FormatDateTime('hh:nn am/pm', Now), ' (Daily limits reset at midnight)');
  WriteLn;
  WriteLn('The common room is warm and loud. Upstairs, behind barred doors, it is quiet.');
  WriteLn('Those who sleep in a locked room here are safe from the knives of the street,');
  WriteLn('and a full night''s sleep sends you out tomorrow at full HP and MP.');
  WriteLn;
  TextColor(DarkGray);
  WriteLn('(Wounded now? Granny Wicks at the Healer''s Hut patches people up by day.)');
  TextColor(LightGray);
  WriteLn;
  if HasRoom then
    WriteLn('[R] Go up to your room and turn in for the night (already paid)')
  else
    WriteLn('[R] Rent a room and turn in for the night (', RoomCost(P), ' gold, ends today''s play)');
  WriteLn('[L] Leave');
  WriteLn;
  Write('Your choice: ');

  Choice := UpCase(GetKey);
  WriteLn(Choice);

  if Choice = 'R' then
  begin
    WriteLn;
    if RentRoom(P) then
    begin
      TextColor(LightGreen);
      WriteLn('You climb the stairs, bolt the door behind you, and sleep.');
      TextColor(LightGray);
      RestAtInn := True;
    end;
    Pause;
  end;
end;

{ Granny Wicks heals by day, for a price that grows with your level }
procedure VisitHealer(var P: TPlayer);
var
  HPRate, MPRate, Cost, Amount: LongInt;
  Missing: LongInt;
  Choice: Char;
begin
  repeat
    ClrScr;
    HPRate := 1 + P.Level div 3;
    MPRate := 2 + P.Level div 3;

    TextColor(LightGreen);
    WriteLn('--- Granny Wicks'' Healer''s Hut ---');
    TextColor(LightGray);
    PrintProprietor(PROP_HEALER);
    WriteLn('Bundles of drying herbs hang from the rafters. A kettle mutters on the coals.');
    WriteLn('Granny Wicks squints at you. "Let''s see the damage, then."');
    WriteLn;
    WriteLn('HP: ', P.HP, '/', P.MaxHP, '   MP: ', P.MP, '/', P.MaxMP, '   Gold: ', P.Gold);
    WriteLn;
    Missing := P.MaxHP - P.HP;
    WriteLn('[H] Heal all wounds  (', Missing * HPRate, ' gold, ', HPRate, ' per HP)');
    WriteLn('[S] Heal some        (choose how many HP)');
    Missing := P.MaxMP - P.MP;
    WriteLn('[M] Mana tea         (', Missing * MPRate, ' gold, ', MPRate, ' per MP)');
    WriteLn('[L] Leave');
    WriteLn;
    Write('Your choice: ');
    Choice := UpCase(GetKey);
    WriteLn(Choice);
    WriteLn;

    case Choice of
      'H', 'S':
        begin
          Missing := P.MaxHP - P.HP;
          if Missing <= 0 then
            WriteLn('"Not a scratch on you. Out, out, I''ve real patients."')
          else
          begin
            Amount := Missing;
            if Choice = 'S' then
            begin
              Write('How many HP? (up to ', Missing, '): ');
              if not ReadNumber(9, Amount) then
                Amount := 0;
              if Amount > Missing then
                Amount := Missing;
            end;
            if Amount > P.Gold div HPRate then
              Amount := P.Gold div HPRate;
            if Amount <= 0 then
              WriteLn('"Healing isn''t free, dearie."')
            else
            begin
              Cost := Amount * HPRate;
              P.Gold := P.Gold - Cost;
              P.HP := P.HP + Amount;
              SavePlayer(P);
              ShopTakings(PROP_HEALER, P.Name, Cost);
              TextColor(LightGreen);
              WriteLn('She packs your wounds with something that smells of moss and vinegar.');
              WriteLn('+', Amount, ' HP for ', Cost, ' gold (HP: ', P.HP, '/', P.MaxHP, ').');
              TextColor(LightGray);
            end;
          end;
          Pause;
        end;
      'M':
        begin
          Missing := P.MaxMP - P.MP;
          if Missing <= 0 then
            WriteLn('"Your head''s as full as it gets."')
          else
          begin
            Amount := Missing;
            if Amount > P.Gold div MPRate then
              Amount := P.Gold div MPRate;
            if Amount <= 0 then
              WriteLn('"Tea costs coin, same as anything."')
            else
            begin
              Cost := Amount * MPRate;
              P.Gold := P.Gold - Cost;
              P.MP := P.MP + Amount;
              SavePlayer(P);
              ShopTakings(PROP_HEALER, P.Name, Cost);
              TextColor(LightCyan);
              WriteLn('The tea is bitter and blue. Your thoughts sharpen.');
              WriteLn('+', Amount, ' MP for ', Cost, ' gold (MP: ', P.MP, '/', P.MaxMP, ').');
              TextColor(LightGray);
            end;
          end;
          Pause;
        end;
    end;
  until Choice = 'L';
end;

end.
