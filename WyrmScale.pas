{$MODE TP}
unit WyrmScale;

{ Sizes the Ashen Wyrm to whoever wakes it.

  Rather than fixed stats (which only the top few warriors could ever
  beat), the Wyrm is tuned against the challenger's own stats, gear and
  skills. When a warrior wakes it, the game plays out a batch of quick
  simulated fights using the real combat rules and adjusts the Wyrm
  until a sensible fighter would win about WYRM_TARGET_WIN percent of
  the time. A level 13 warrior and a level 40 warrior face the same odds,
  and new weapons, armor or skills are accounted for automatically. }

interface

uses
  GameTypes;

const
  { Chance (percent) a sensibly played warrior has of besting the Wyrm }
  WYRM_TARGET_WIN = 35;

  { The Wyrm breathes fire, ignoring armor, every this many turns }
  WYRM_BREATH_EVERY = 4;

  { Average number of weapon blows it should take to bring the Wyrm down }
  WYRM_BLOWS = 16;

  MIN_WYRM_HP = 500;

procedure ScaleWyrm(const P: TPlayer; var WyrmHP, WyrmAtk, WyrmBreath: LongInt);
function SimulateWyrmWins(const P: TPlayer; WyrmHP, WyrmAtk, WyrmBreath: LongInt;
                          Trials: Integer): Integer;

implementation

const
  CALIBRATION_TRIALS = 600;
  CALIBRATION_STEPS  = 13;
  CALIBRATION_SEED   = 1993;

{ The same damage roll as an [A]ttack in FightFoe }
function WeaponHit(const P: TPlayer): LongInt;
begin
  WeaponHit := (P.Strength div 2) + Random(P.Strength) + WEAPONS[P.WeaponIndex].StatBonus;
end;

{ Best unlocked healing skill the warrior can pay for, or 0 }
function BestHeal(const P: TPlayer; MP: LongInt): Integer;
var
  i, Best: Integer;
begin
  Best := 0;
  for i := 1 to High(SKILLS) do
    if SKILLS[i].IsHeal and (P.Level >= SKILLS[i].MinLevel) and (MP >= SKILLS[i].MPCost) then
      if (Best = 0) or (SKILLS[i].Power > SKILLS[Best].Power) then
        Best := i;
  BestHeal := Best;
end;

{ Plays out Trials fights with the real combat rules and a simple sensible
  strategy: heal below 40% HP while MP lasts, otherwise swing. Returns the
  percentage won. }
function SimulateWyrmWins(const P: TPlayer; WyrmHP, WyrmAtk, WyrmBreath: LongInt;
                          Trials: Integer): Integer;
var
  t, Wins, Turn, Heal, Rounds: Integer;
  HP, MP, Foe, Dmg: LongInt;
begin
  Wins := 0;
  for t := 1 to Trials do
  begin
    HP := P.MaxHP;
    MP := P.MaxMP;
    Foe := WyrmHP;
    Turn := 0;
    Rounds := 0;
    repeat
      Inc(Rounds);
      Heal := 0;
      if HP * 10 < LongInt(P.MaxHP) * 4 then
        Heal := BestHeal(P, MP);

      if Heal > 0 then
      begin
        MP := MP - SKILLS[Heal].MPCost;
        HP := HP + SKILLS[Heal].Power + Random(P.Level * 4 + 1);
        if HP > P.MaxHP then
          HP := P.MaxHP;
      end
      else
        Foe := Foe - WeaponHit(P);

      if Foe > 0 then
      begin
        Inc(Turn);
        if Turn mod WYRM_BREATH_EVERY = 0 then
          Dmg := (WyrmBreath * (85 + Random(31))) div 100
        else
        begin
          Dmg := (Random(WyrmAtk) + 1) - ARMORS[P.ArmorIndex].StatBonus;
          if Dmg < 1 then
            Dmg := 1;
        end;
        HP := HP - Dmg;
      end;
    until (Foe <= 0) or (HP <= 0) or (Rounds > 500);
    if Foe <= 0 then
      Inc(Wins);
  end;
  SimulateWyrmWins := (Wins * 100) div Trials;
end;

{ Wyrm attack and breath for a given ferocity (thousandths of MaxHP) }
procedure StatsForFerocity(const P: TPlayer; Ferocity: LongInt; var Atk, Breath: LongInt);
var
  DmgUnit: LongInt;
begin
  DmgUnit := (LongInt(P.MaxHP) * Ferocity) div 1000;
  if DmgUnit < 1 then
    DmgUnit := 1;
  Atk := ARMORS[P.ArmorIndex].StatBonus + DmgUnit;
  Breath := (DmgUnit * 3) div 5;
  if Breath < 1 then
    Breath := 1;
end;

procedure ScaleWyrm(const P: TPlayer; var WyrmHP, WyrmAtk, WyrmBreath: LongInt);
var
  AvgHit, Lo, Hi, Mid, SavedSeed: LongInt;
  Step: Integer;
begin
  { Long enough to be an ordeal, sized to the challenger's own blows }
  AvgHit := (P.Strength div 2) + ((P.Strength - 1) div 2) + WEAPONS[P.WeaponIndex].StatBonus;
  WyrmHP := AvgHit * WYRM_BLOWS;
  if WyrmHP < MIN_WYRM_HP then
    WyrmHP := MIN_WYRM_HP;

  { Higher ferocity means a lower win rate, so binary search for the
    fiercest Wyrm that still leaves the challenger the target chance }
  { Every candidate is judged against the same dice rolls, so the search
    compares like with like instead of chasing noise }
  SavedSeed := RandSeed;
  Lo := 1;
  Hi := 4000;
  for Step := 1 to CALIBRATION_STEPS do
  begin
    if Lo >= Hi then
      Break;
    Mid := (Lo + Hi + 1) div 2;
    StatsForFerocity(P, Mid, WyrmAtk, WyrmBreath);
    RandSeed := CALIBRATION_SEED;
    if SimulateWyrmWins(P, WyrmHP, WyrmAtk, WyrmBreath, CALIBRATION_TRIALS) >= WYRM_TARGET_WIN then
      Lo := Mid
    else
      Hi := Mid - 1;
  end;
  RandSeed := SavedSeed;
  StatsForFerocity(P, Lo, WyrmAtk, WyrmBreath);
end;

end.
