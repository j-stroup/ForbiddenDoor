{$MODE TP}
unit Holdings;

{ Shops as property. The Town Hall sells the deeds to the town's
  businesses. A deed is expensive, so nobody can buy one early, and the
  Council allows only one deed per warrior.

  Income does not depend on how many players there are. Each owned
  business pays its owner TAKINGS_PCT percent of its BASE price every
  day (more during the Harvest Festival), plus SPEND_CUT_PCT percent of
  whatever other warriors spend there. The manager keeps the place open
  for TILL_DAYS days without the owner; after that the shutters stay down
  until the owner comes back.

  Deeds change hands three ways:
    - Buyout: anyone may buy an owned deed for BUYOUT_PCT percent of what
      the owner paid, never more than MAX_PRICE_PCT percent of its base
      price. The owner gets the full price, so being bought out is never
      a loss. A new deed is protected for PROTECT_DAYS.
    - Neglect: an owner who stays away NEGLECT_DAYS days loses the deed
      to the Council, and it goes back on sale at its base price.
    - Selling back: the owner may sell to the Council for SELLBACK_PCT
      percent of the base price.

  Income and the sell-back price are tied to the fixed base price, not to
  what the owner paid, so two warriors buying a deed back and forth can
  only pass gold between themselves, never create it.

  Payments to warriors who are not playing go into LEDGER.DAT and are
  paid into their bank vault the next time they log in. }

interface

uses
  Crt, SysUtils, GameTypes, Town;

const
  PROPERTY_FILE = 'PROPERTY.DAT';
  LEDGER_FILE   = 'LEDGER.DAT';

  NR_PROPS = 5;
  PROP_SMITH  = 1;
  PROP_ARMOR  = 2;
  PROP_INN    = 3;
  PROP_TAVERN = 4;
  PROP_HEALER = 5;

  PROPERTY_MIN_LEVEL = 10;  { Too green below this to hold a deed }
  TAKINGS_PCT   = 3;        { Of the deed's value, paid every day }
  SPEND_CUT_PCT = 20;       { Of what other warriors spend there }
  TILL_DAYS     = 3;        { Days the business runs with the owner away }
  NEGLECT_DAYS  = 14;       { Days away before the Council seizes the deed }
  PROTECT_DAYS  = 3;        { Days after a purchase before a buyout is allowed }
  BUYOUT_PCT    = 125;
  MAX_PRICE_PCT = 200;       { Buyouts stop climbing at this much of base }
  SELLBACK_PCT  = 75;

  PROP_NAMES: array[1..NR_PROPS] of string[30] = (
    'The Blacksmith',
    'The Armorer',
    'The South Ridge Inn',
    'Olde Hallowed Tavern',
    'Granny Wicks'' Healer''s Hut'
  );

  PROP_BASE: array[1..NR_PROPS] of LongInt = (
    300000, 250000, 150000, 120000, 100000
  );

type
  TProperty = record
    Owner: string[30];        { '' = for sale by the Council }
    Value: LongInt;           { What the owner paid; base price when unowned }
    Till: LongInt;            { Takings waiting for the owner }
    BoughtDay: LongInt;
    TakingsDay: LongInt;      { Last day takings were added to the till }
    CollectDay: LongInt;      { Last day the owner showed up }
  end;

  TPayout = record
    Name: string[30];
    Amount: LongInt;
    Note: string[78];
  end;

procedure CollectHoldings(var P: TPlayer);
procedure ShopTakings(Prop: Integer; const Spender: string; Amount: LongInt);
procedure PrintProprietor(Prop: Integer);
procedure VisitTownHall(var P: TPlayer);

function DailyTakings(Prop: Integer; Day: LongInt): LongInt;
function BuyoutPrice(const R: TProperty; Prop: Integer): LongInt;
procedure AddPayout(const Name: string; Amount: LongInt; const Note: string);

implementation

type
  TPropFile = file of TProperty;
  TPropArray = array[1..NR_PROPS] of TProperty;

function DailyTakings(Prop: Integer; Day: LongInt): LongInt;
var
  T: LongInt;
begin
  T := (PROP_BASE[Prop] div 100) * TAKINGS_PCT;
  if ConditionOnDay(Day) = cdFestival then
    T := (T div 2) * 3;
  DailyTakings := T;
end;

function BuyoutPrice(const R: TProperty; Prop: Integer): LongInt;
var
  Price, Cap: LongInt;
begin
  Cap := (PROP_BASE[Prop] div 100) * MAX_PRICE_PCT;
  if R.Owner = '' then
    Price := PROP_BASE[Prop]
  else
    Price := (R.Value div 100) * BUYOUT_PCT;
  if Price > Cap then
    Price := Cap;
  BuyoutPrice := Price;
end;

function OpenRetry(var F: TPropFile): Boolean;
var
  Retries: Integer;
  Opened: Boolean;
begin
  Retries := 0;
  repeat
    {$I-} Reset(F); {$I+}
    Opened := IOResult = 0;
    if not Opened then
    begin
      Inc(Retries);
      Delay(25);
    end;
  until Opened or (Retries >= 20);
  OpenRetry := Opened;
end;

procedure FreshDeed(var R: TProperty; i: Integer; Today: LongInt);
begin
  FillChar(R, SizeOf(R), 0);
  R.Owner := '';
  R.Value := PROP_BASE[i];
  R.TakingsDay := Today;
  R.CollectDay := Today;
end;

{ Seizes neglected deeds and adds any takings due since last time }
procedure Maintain(var R: TProperty; i: Integer; Today: LongInt);
var
  d: LongInt;
begin
  if (R.Owner <> '') and (Today - R.CollectDay > NEGLECT_DAYS) then
  begin
    AddPayout(R.Owner, 0, 'The Town Council seized your deed to ' + PROP_NAMES[i] +
              ' for neglect.');
    PostNews('The Town Council seized ' + PROP_NAMES[i] + ' from ' + R.Owner +
             '. The deed is for sale again.');
    FreshDeed(R, i, Today);
    Exit;
  end;

  if R.Owner = '' then
  begin
    R.TakingsDay := Today;
    Exit;
  end;

  if Today - R.TakingsDay > 60 then
    R.TakingsDay := Today - 60;
  d := R.TakingsDay + 1;
  while d <= Today do
  begin
    if d <= R.CollectDay + TILL_DAYS then
      AddGold(R.Till, DailyTakings(i, d));
    Inc(d);
  end;
  if Today > R.TakingsDay then
    R.TakingsDay := Today;
end;

{ Opens PROPERTY.DAT (creating it if needed), reads every deed and brings
  it up to date. The file stays open: call CloseProps to write it back. }
function OpenProps(var F: TPropFile; var A: TPropArray): Boolean;
var
  i: Integer;
  Today, Have: LongInt;
begin
  OpenProps := False;
  Today := Trunc(Date);
  Assign(F, PROPERTY_FILE);
  if not FileExists(PROPERTY_FILE) then
  begin
    {$I-} Rewrite(F); {$I+}
    if IOResult <> 0 then
      Exit;
    Close(F);
  end;
  if not OpenRetry(F) then
    Exit;

  Have := FileSize(F);
  for i := 1 to NR_PROPS do
  begin
    if i <= Have then
    begin
      Seek(F, i - 1);
      {$I-} Read(F, A[i]); {$I+}
      if IOResult <> 0 then
        FreshDeed(A[i], i, Today);
    end
    else
      FreshDeed(A[i], i, Today);
    Maintain(A[i], i, Today);
  end;
  OpenProps := True;
end;

procedure CloseProps(var F: TPropFile; const A: TPropArray);
var
  i: Integer;
begin
  Seek(F, 0);
  for i := 1 to NR_PROPS do
    Write(F, A[i]);
  Close(F);
end;

{ A read-only snapshot, still brought up to date }
function ReadProps(var A: TPropArray): Boolean;
var
  F: TPropFile;
begin
  ReadProps := False;
  if OpenProps(F, A) then
  begin
    CloseProps(F, A);
    ReadProps := True;
  end;
end;

function OwnedBy(const A: TPropArray; const Name: string): Integer;
var
  i: Integer;
begin
  OwnedBy := 0;
  for i := 1 to NR_PROPS do
    if (A[i].Owner <> '') and SameName(A[i].Owner, Name) then
    begin
      OwnedBy := i;
      Exit;
    end;
end;

procedure AddPayout(const Name: string; Amount: LongInt; const Note: string);
var
  F: file of TPayout;
  R: TPayout;
  Retries: Integer;
  Opened: Boolean;
begin
  Assign(F, LEDGER_FILE);
  if not FileExists(LEDGER_FILE) then
  begin
    {$I-} Rewrite(F); {$I+}
    if IOResult <> 0 then
      Exit;
    Close(F);
  end;
  Retries := 0;
  repeat
    {$I-} Reset(F); {$I+}
    Opened := IOResult = 0;
    if not Opened then
    begin
      Inc(Retries);
      Delay(25);
    end;
  until Opened or (Retries >= 20);
  if not Opened then
    Exit;
  FillChar(R, SizeOf(R), 0);
  R.Name := Name;
  R.Amount := Amount;
  R.Note := Note;
  Seek(F, FileSize(F));
  Write(F, R);
  Close(F);
end;

{ Pays out (and removes) every ledger entry for this warrior, printing
  each note. Returns the total gold. }
function CollectPayouts(const Name: string; var Shown: Boolean): LongInt;
var
  F: file of TPayout;
  R: TPayout;
  ReadAt, WriteAt, Total: LongInt;
begin
  CollectPayouts := 0;
  if not FileExists(LEDGER_FILE) then
    Exit;
  Assign(F, LEDGER_FILE);
  {$I-} Reset(F); {$I+}
  if IOResult <> 0 then
    Exit;
  Total := 0;
  ReadAt := 0;
  WriteAt := 0;
  while ReadAt < FileSize(F) do
  begin
    Seek(F, ReadAt);
    Read(F, R);
    Inc(ReadAt);
    if SameName(R.Name, Name) then
    begin
      if not Shown then
      begin
        ClrScr;
        TextColor(Yellow);
        WriteLn('--- A Letter from the Town Hall ---');
        WriteLn;
        Shown := True;
      end;
      TextColor(LightGray);
      WriteLn(R.Note);
      if R.Amount > 0 then
      begin
        TextColor(LightGreen);
        WriteLn('  ', R.Amount, ' gold has been paid into your vault.');
      end;
      AddGold(Total, R.Amount);
    end
    else
    begin
      if WriteAt <> ReadAt - 1 then
      begin
        Seek(F, WriteAt);
        Write(F, R);
      end;
      Inc(WriteAt);
    end;
  end;
  Seek(F, WriteAt);
  Truncate(F);
  Close(F);
  CollectPayouts := Total;
end;

{ At login (and on request at the Town Hall): empties the warrior's till
  and any ledger payouts into their bank vault. }
procedure CollectHoldings(var P: TPlayer);
var
  F: TPropFile;
  A: TPropArray;
  Mine: Integer;
  Till, Paid: LongInt;
  Shown: Boolean;
begin
  Shown := False;
  Till := 0;
  Mine := 0;
  if OpenProps(F, A) then
  begin
    Mine := OwnedBy(A, P.Name);
    if Mine > 0 then
    begin
      Till := A[Mine].Till;
      A[Mine].Till := 0;
      A[Mine].CollectDay := Trunc(Date);
    end;
    CloseProps(F, A);
  end;

  Paid := CollectPayouts(P.Name, Shown);

  if Till > 0 then
  begin
    if not Shown then
    begin
      ClrScr;
      TextColor(Yellow);
      WriteLn('--- Your Holdings ---');
      WriteLn;
      Shown := True;
    end;
    TextColor(LightGray);
    WriteLn('The manager of ', PROP_NAMES[Mine], ' hands over the takings.');
    TextColor(LightGreen);
    WriteLn('  ', Till, ' gold has been paid into your vault.');
  end;

  if (Till > 0) or (Paid > 0) then
  begin
    AddGold(P.BankGold, Till);
    AddGold(P.BankGold, Paid);
    SavePlayer(P);
  end;
  if Shown then
  begin
    TextColor(LightGray);
    WriteLn;
    WriteLn('Vault balance: ', P.BankGold, ' gold.');
    Pause;
  end;
end;

{ Called whenever a warrior spends gold at a business }
procedure ShopTakings(Prop: Integer; const Spender: string; Amount: LongInt);
var
  F: TPropFile;
  A: TPropArray;
begin
  if (Amount <= 0) or (Prop < 1) or (Prop > NR_PROPS) then
    Exit;
  if not OpenProps(F, A) then
    Exit;
  if (A[Prop].Owner <> '') and (not SameName(A[Prop].Owner, Spender)) then
    AddGold(A[Prop].Till, (Amount div 100) * SPEND_CUT_PCT + ((Amount mod 100) * SPEND_CUT_PCT) div 100);
  CloseProps(F, A);
end;

procedure PrintProprietor(Prop: Integer);
var
  A: TPropArray;
begin
  if not ReadProps(A) then
    Exit;
  if A[Prop].Owner <> '' then
  begin
    TextColor(DarkGray);
    WriteLn('Proprietor: ', A[Prop].Owner);
    TextColor(LightGray);
  end;
end;

function AskYes(const Question: string): Boolean;
var
  C: Char;
begin
  Write(Question, ' [Y/N]: ');
  C := UpCase(GetKey);
  WriteLn(C);
  AskYes := C = 'Y';
end;

procedure BuyDeed(var P: TPlayer; i: Integer; const Seen: TProperty);
var
  F: TPropFile;
  A: TPropArray;
  Price, Today, OldTill: LongInt;
  OldOwner: string;
  Ok: Boolean;
begin
  Today := Trunc(Date);
  WriteLn;
  if P.Level < PROPERTY_MIN_LEVEL then
  begin
    WriteLn('The clerk peers over his spectacles. "Deeds are for established warriors.');
    WriteLn('Come back at level ', PROPERTY_MIN_LEVEL, '."');
    Pause;
    Exit;
  end;
  if (Seen.Owner <> '') and SameName(Seen.Owner, P.Name) then
  begin
    WriteLn('"That one is already yours, sir or madam."');
    Pause;
    Exit;
  end;
  if (Seen.Owner <> '') and (Today - Seen.BoughtDay < PROTECT_DAYS) then
  begin
    WriteLn('"That deed changed hands only recently. The Council allows the new owner');
    WriteLn(PROTECT_DAYS, ' days before anyone may buy them out."');
    Pause;
    Exit;
  end;

  Price := BuyoutPrice(Seen, i);
  if Seen.Owner = '' then
    WriteLn(PROP_NAMES[i], ' is for sale from the Council for ', Price, ' gold.')
  else
  begin
    WriteLn(Seen.Owner, ' owns ', PROP_NAMES[i], '. A buyout costs ', Price, ' gold,');
    WriteLn('all of which goes to ', Seen.Owner, '.');
  end;
  WriteLn('It would earn you about ', DailyTakings(i, Today), ' gold a day, plus ',
          SPEND_CUT_PCT, '% of what others spend there.');
  WriteLn('The price comes out of your bank vault (', P.BankGold, ' gold).');
  if P.BankGold < Price then
  begin
    TextColor(LightRed);
    WriteLn('You do not have that much in the vault.');
    TextColor(LightGray);
    Pause;
    Exit;
  end;
  if not AskYes('Sign the deed?') then
    Exit;

  { Take the gold first, so a lost save never hands out a free deed }
  P.BankGold := P.BankGold - Price;
  SavePlayer(P);

  Ok := False;
  OldOwner := '';
  OldTill := 0;
  if OpenProps(F, A) then
  begin
    if (A[i].Owner = Seen.Owner) and (BuyoutPrice(A[i], i) = Price) and
       (OwnedBy(A, P.Name) = 0) then
    begin
      OldOwner := A[i].Owner;
      OldTill := A[i].Till;
      A[i].Owner := P.Name;
      A[i].Value := Price;
      A[i].Till := 0;
      A[i].BoughtDay := Today;
      A[i].TakingsDay := Today;
      A[i].CollectDay := Today;
      Ok := True;
    end;
    CloseProps(F, A);
  end;

  if not Ok then
  begin
    AddGold(P.BankGold, Price);
    SavePlayer(P);
    WriteLn('The clerk frowns at his ledger. "Someone beat you to it. Your gold is returned."');
    Pause;
    Exit;
  end;

  if OldOwner <> '' then
  begin
    AddPayout(OldOwner, Price, P.Name + ' bought you out of ' + PROP_NAMES[i] + '.');
    if OldTill > 0 then
      AddPayout(OldOwner, OldTill, 'Your last takings from ' + PROP_NAMES[i] + '.');
    PostNews(P.Name + ' bought ' + PROP_NAMES[i] + ' out from under ' + OldOwner +
             ' for ' + IntToStr(Price) + ' gold.');
  end
  else
    PostNews(P.Name + ' bought the deed to ' + PROP_NAMES[i] + ' for ' +
             IntToStr(Price) + ' gold.');

  TextColor(LightGreen);
  WriteLn('The clerk stamps the deed with a heavy brass seal. ', PROP_NAMES[i], ' is yours.');
  TextColor(LightGray);
  Pause;
end;

procedure SellDeed(var P: TPlayer);
var
  F: TPropFile;
  A: TPropArray;
  Mine: Integer;
  Pay: LongInt;
begin
  WriteLn;
  if not OpenProps(F, A) then
    Exit;
  Mine := OwnedBy(A, P.Name);
  if Mine = 0 then
  begin
    CloseProps(F, A);
    WriteLn('You hold no deed.');
    Pause;
    Exit;
  end;
  Pay := (PROP_BASE[Mine] div 100) * SELLBACK_PCT;
  CloseProps(F, A);

  WriteLn('The Council will buy ', PROP_NAMES[Mine], ' back for ', Pay, ' gold');
  WriteLn('(', SELLBACK_PCT, '% of its base price), plus whatever is in the till.');
  if not AskYes('Sell it?') then
    Exit;

  if not OpenProps(F, A) then
    Exit;
  if OwnedBy(A, P.Name) <> Mine then
  begin
    CloseProps(F, A);
    WriteLn('"Hm. According to the ledger, it is not yours any more."');
    Pause;
    Exit;
  end;
  Pay := (PROP_BASE[Mine] div 100) * SELLBACK_PCT;
  AddGold(Pay, A[Mine].Till);
  FreshDeed(A[Mine], Mine, Trunc(Date));
  CloseProps(F, A);

  AddGold(P.BankGold, Pay);
  SavePlayer(P);
  PostNews(P.Name + ' sold ' + PROP_NAMES[Mine] + ' back to the Town Council.');
  TextColor(LightGreen);
  WriteLn(Pay, ' gold has been paid into your vault.');
  TextColor(LightGray);
  Pause;
end;

procedure VisitTownHall(var P: TPlayer);
var
  A: TPropArray;
  i, Mine: Integer;
  Today, Num: LongInt;
  Choice: Char;
  Status: string;
begin
  repeat
    ClrScr;
    Today := Trunc(Date);
    TextColor(Yellow);
    WriteLn('--- South Ridge Town Hall: Deeds & Titles ---');
    TextColor(LightGray);
    WriteLn('A clerk sits behind a wall of pigeonholes stuffed with deeds and ledgers.');
    WriteLn('"The Council sells the deeds to the town''s businesses. One per warrior,');
    WriteLn('and any deed may be bought out from its owner, for a premium."');
    WriteLn;

    if not ReadProps(A) then
    begin
      WriteLn('The Town Hall is closed. (PROPERTY.DAT could not be opened.)');
      Pause;
      Exit;
    end;
    Mine := OwnedBy(A, P.Name);

    TextColor(LightCyan);
    WriteLn('    ', PadRight('Business', 28), PadRight('Owner', 22), PadRight('Price', 11), 'Gold/day');
    TextColor(LightGray);
    for i := 1 to NR_PROPS do
    begin
      if A[i].Owner = '' then
        Status := 'for sale'
      else
        Status := A[i].Owner;
      Write('[', i, '] ', PadRight(PROP_NAMES[i], 28), PadRight(Copy(Status, 1, 21), 22),
            PadRight(IntToStr(BuyoutPrice(A[i], i)), 11), DailyTakings(i, Today));
      if (A[i].Owner <> '') and (Today - A[i].BoughtDay < PROTECT_DAYS) then
      begin
        TextColor(DarkGray);
        Write('  (protected)');
        TextColor(LightGray);
      end;
      WriteLn;
    end;
    WriteLn;
    TextColor(DarkGray);
    WriteLn('Owned deeds sell for ', BUYOUT_PCT, '% of what the owner paid (at most ', MAX_PRICE_PCT,
            '% of base), all to the owner.');
    WriteLn('Each business pays ', TAKINGS_PCT, '% of its base price a day, plus ', SPEND_CUT_PCT,
            '% of what others spend.');
    WriteLn('Owners who stay away ', NEGLECT_DAYS, ' days lose the deed to the Council.');
    TextColor(LightGray);
    WriteLn;
    WriteLn('Your vault: ', P.BankGold, ' gold.');
    if Mine > 0 then
    begin
      TextColor(LightGreen);
      WriteLn('You own ', PROP_NAMES[Mine], '. Till: ', A[Mine].Till, ' gold.');
      TextColor(LightGray);
      WriteLn('[C] Collect the till   [S] Sell the deed back to the Council');
    end;
    WriteLn('[1-', NR_PROPS, '] Buy a deed   [L] Leave');
    WriteLn;
    Write('Your choice: ');
    Choice := UpCase(GetKey);
    WriteLn(Choice);

    if (Choice >= '1') and (Choice <= Chr(Ord('0') + NR_PROPS)) then
    begin
      Num := Ord(Choice) - Ord('0');
      if Mine = 0 then
        BuyDeed(P, Num, A[Num])
      else if Mine = Num then
      begin
        WriteLn;
        WriteLn('"That one is already yours."');
        Pause;
      end
      else
      begin
        WriteLn;
        WriteLn('"One deed per warrior. Sell ', PROP_NAMES[Mine], ' first."');
        Pause;
      end;
    end
    else if (Choice = 'C') and (Mine > 0) then
    begin
      CollectHoldings(P);
      if A[Mine].Till = 0 then
      begin
        WriteLn;
        WriteLn('The till is empty. Takings come in at dawn.');
        Pause;
      end;
    end
    else if (Choice = 'S') and (Mine > 0) then
      SellDeed(P);
  until Choice = 'L';
end;

end.
