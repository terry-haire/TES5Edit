unit __FNVConvertActors;

// Converts FNV actor base records (NPC_ and CREA) to FO4 NPC_ records.
//
// FNV faces (FaceGen), hair meshes, creature skeletons and animations can't be used by Fallout 4, so actors
// get a FO4 race (and FO4 template actor for creatures) from ElementConversions\__ActorMap.csv, FO4 head
// parts from __AppearanceMap.csv and the nearest FO4 hair colour from __HairColors.csv. Everything that
// carries over (names, flags, level, factions, inventory, class, voice, templates, AI data) is copied.

interface

uses
  wbInterface,
  converterFileManager;

const
  // EditorID prefix of converted actors that have no FO4 equivalent and are removed during cleanup.
  SkipActorPrefix = 'NVSkipActor_';

procedure ConvertActorBase(const fromRec: IwbMainRecord; const rec: IwbMainRecord; ToFileManaged: TConverterManagedFile);

// FO4 FormID (hex) of an FNV engine record (object ID < 0x800) from __HardcodedMap.csv, or '' if it has none.
function HardcodedFormID(aObjectID: Cardinal): string;

implementation

uses
  Classes,
  SysUtils,
  Math,
  System.Generics.Collections,
  System.RegularExpressions,
  __ScriptAdapterFunctions;

type
  TActorMapping = record
    Race: string;
    Template: string;
    CreatureClass: string;
  end;

  THairColor = record
    FormID: string;
    R, G, B: Integer;
  end;

  TOutfitRule = record
    Pattern: TRegEx;
    FO4Armor: string;
  end;

var
  ActorMap: TDictionary<string, TActorMapping>;
  AppearanceMap: TDictionary<string, string>;
  HairColors: TList<THairColor>;
  HardcodedMap: TDictionary<Cardinal, string>;
  OutfitRules: TList<TOutfitRule>;
  SkinTones: TDictionary<string, string>;

const
  // FO4 DefaultSandboxEditorLocation, until FNV packages are converted.
  DefaultSandboxPackage = '00107AEA';
  // FO4 Citizen class, for actors whose FNV class didn't convert.
  DefaultClass = '0001326B';
  // Template flags taken from the FO4 template actor of a substituted creature: Traits, Stats, Spell List,
  // AI Data, AI Packages, Model/Animation, Def Pack List, Attack Data, Keywords.
  CreatureTemplateFlags = $1C7B;

procedure ReadCsv(const aFileName: string; aProc: TProc<TStringList>);
begin
  var lines := TStringList.Create;
  var cols := TStringList.Create;
  try
    cols.Delimiter := ';';
    cols.StrictDelimiter := True;
    if FileExists(aFileName) then
      lines.LoadFromFile(aFileName)
    else
      AddMessage('WARNING: missing ' + aFileName);
    for var line in lines do begin
      if (Trim(line) = '') or line.StartsWith('#') then
        Continue;
      cols.DelimitedText := line;
      aProc(cols);
    end;
  finally
    cols.Free;
    lines.Free;
  end;
end;

procedure LoadMaps;
begin
  if Assigned(ActorMap) then
    Exit;

  var dir := wbProgramPath + 'ElementConversions\';

  ActorMap := TDictionary<string, TActorMapping>.Create;
  ReadCsv(dir + '__ActorMap.csv', procedure(cols: TStringList)
  begin
    var m: TActorMapping;
    m.Race := cols[1];
    if cols.Count > 2 then m.Template := cols[2] else m.Template := '';
    if cols.Count > 3 then m.CreatureClass := cols[3] else m.CreatureClass := '';
    ActorMap.AddOrSetValue(LowerCase(cols[0]), m);
  end);

  HardcodedMap := TDictionary<Cardinal, string>.Create;
  ReadCsv(dir + '__HardcodedMap.csv', procedure(cols: TStringList)
  begin
    HardcodedMap.AddOrSetValue(StrToInt('$' + cols[0]), cols[1]);
  end);

  AppearanceMap := TDictionary<string, string>.Create;
  ReadCsv(dir + '__AppearanceMap.csv', procedure(cols: TStringList)
  begin
    AppearanceMap.AddOrSetValue(LowerCase(cols[0] + ';' + cols[1]), cols[2]);
  end);

  HairColors := TList<THairColor>.Create;
  ReadCsv(dir + '__HairColors.csv', procedure(cols: TStringList)
  begin
    var c: THairColor;
    c.FormID := cols[0];
    c.R := StrToInt(cols[1]);
    c.G := StrToInt(cols[2]);
    c.B := StrToInt(cols[3]);
    HairColors.Add(c);
  end);

  OutfitRules := TList<TOutfitRule>.Create;
  ReadCsv(dir + '__OutfitMap.csv', procedure(cols: TStringList)
  begin
    var rule: TOutfitRule;
    rule.Pattern := TRegEx.Create(cols[0], [roIgnoreCase]);
    if cols.Count > 1 then rule.FO4Armor := cols[1] else rule.FO4Armor := '';
    OutfitRules.Add(rule);
  end);

  SkinTones := TDictionary<string, string>.Create;
  ReadCsv(dir + '__SkinTones.csv', procedure(cols: TStringList)
  begin
    SkinTones.AddOrSetValue(LowerCase(cols[0]), cols[1] + ';' + cols[2] + ';' + cols[3]);
  end);
end;

// FO4 armor replacing an FNV armor in an NPC outfit; '' drops the item. See __OutfitMap.csv.
function SubstituteArmor(const aEditorID: string): string;
begin
  for var rule in OutfitRules do
    if rule.Pattern.IsMatch(aEditorID) then
      Exit(rule.FO4Armor);
  Result := '';
end;

function HardcodedFormID(aObjectID: Cardinal): string;
begin
  LoadMaps;
  if not HardcodedMap.TryGetValue(aObjectID, Result) then
    Result := '';
end;

function AppearancePart(const aEditorID: string; aFemale: Boolean): string;
const
  Genders: array[Boolean] of string = ('m', 'f');
begin
  if not AppearanceMap.TryGetValue(LowerCase(aEditorID + ';' + Genders[aFemale]), Result) then
    if not AppearanceMap.TryGetValue(LowerCase(aEditorID + ';*'), Result) then
      Result := '';
end;

function NearestHairColor(R, G, B: Integer): string;
begin
  Result := '';
  var best := MaxInt;
  for var c in HairColors do begin
    var d := Sqr(c.R - R) + Sqr(c.G - G) + Sqr(c.B - B);
    if d < best then begin
      best := d;
      Result := c.FormID;
    end;
  end;
end;

// FO4 load order FormID (hex) of the converted record an FNV reference element points to, or ''.
function NewRef(const aElement: IwbElement; ToFileManaged: TConverterManagedFile): string;
var
  target: IwbMainRecord;
begin
  Result := '';
  if not Assigned(aElement) then
    Exit;
  if not Supports(aElement.LinksTo, IwbMainRecord, target) then
    Exit;
  // Engine records (object ID < 0x800) differ between the games; see __HardcodedMap.csv.
  if target.LoadOrderFormID.ObjectID < $800 then begin
    if not HardcodedMap.TryGetValue(target.LoadOrderFormID.ObjectID, Result) then
      Result := '';
    Exit;
  end;
  try
    Result := ToFileManaged.GetNewFormID(IntToHex(target.LoadOrderFormID.ToCardinal, 8)).ToString;
  except
    Result := '';
  end;
end;

function AppendEntry(const aRec: IwbMainRecord; const aArrayName, aSignature: string): IwbElement;
var
  arr: IwbContainer;
begin
  Result := nil;
  if not Supports(aRec.ElementByPath[aArrayName], IwbContainer, arr) then begin
    aRec.Add(aSignature, True);
    if not Supports(aRec.ElementByPath[aArrayName], IwbContainer, arr) then
      Exit;
    if arr.ElementCount > 0 then
      Exit(arr.Elements[0]);
  end;
  Result := arr.Assign(High(Integer), nil, False);
end;

procedure SetValue(const aContainer: IwbContainer; const aPath, aEditValue, aContext: string);
begin
  if aEditValue = '' then
    Exit;
  try
    var e := aContainer.ElementByPath[aPath];
    if not Assigned(e) then
      e := aContainer.Add(aPath, True);
    if not Assigned(e) then
      raise Exception.Create('element not found');
    e.EditValue := aEditValue;
  except
    on E: Exception do
      AddMessage(aContext + ': could not set ' + aPath + ' to ' + aEditValue + ': ' + E.Message);
  end;
end;

// Skeleton folder of an FNV creature, following its templates, e.g. 'dog' for coyotes.
function CreatureSkeletonKey(const aCrea: IwbMainRecord): string;
var
  current, next: IwbMainRecord;
begin
  Result := '';
  current := aCrea;
  for var depth := 0 to 10 do begin
    if not Assigned(current) then
      Exit;
    if current.Signature = 'CREA' then begin
      var model := LowerCase(StringReplace(current.ElementEditValues['Model\MODL'], '/', '\', [rfReplaceAll]));
      if model <> '' then begin
        if model.StartsWith('creatures\') then begin
          model := Copy(model, Length('creatures\') + 1, MaxInt);
          if Pos('\', model) > 0 then
            model := Copy(model, 1, Pos('\', model) - 1);
        end;
        Exit(model);
      end;
    end;
    // Leveled creature lists: use the first entry.
    if current.Signature = 'LVLC' then begin
      var entry := current.ElementByPath['Leveled List Entries\[0]\LVLO\Reference'];
      if not Assigned(entry) or not Supports(entry.LinksTo, IwbMainRecord, next) then
        Exit;
    end else if not Supports(current.ElementLinksTo['TPLT'], IwbMainRecord, next) then
      Exit;
    current := next;
  end;
end;

procedure ConvertActorBase(const fromRec: IwbMainRecord; const rec: IwbMainRecord; ToFileManaged: TConverterManagedFile);
var
  isCreature, female, hasTemplate: Boolean;
  context, edid, full, raceKey, voice, template, deathItem, cls, combatStyle, hairColor, skinTone: string;
  weight: Double;
  acbsFlags, templateFlags: Cardinal;
  level, calcMin, calcMax: Integer;
  mapping: TActorMapping;
  factions, items: TList<TPair<string, Integer>>;
  armor, packages, headParts: TStringList;
  aggression, confidence, assistance, mood: Integer;
  container: IwbContainer;
  target: IwbMainRecord;
begin
  LoadMaps;

  factions := TList<TPair<string, Integer>>.Create;
  items := TList<TPair<string, Integer>>.Create;
  armor := TStringList.Create;
  packages := TStringList.Create;
  headParts := TStringList.Create;
  try
    ////////////////////////////////////////////////////////////////////////////
    ///  Read the FNV record
    ////////////////////////////////////////////////////////////////////////////
    wbGameMode := gmFNV;
    isCreature := fromRec.Signature = 'CREA';
    edid := fromRec.EditorID;
    context := 'NPC ' + edid;
    full := fromRec.ElementEditValues['FULL'];
    acbsFlags := fromRec.ElementNativeValues['ACBS\Flags'];
    female := (acbsFlags and $1) <> 0;
    level := fromRec.ElementNativeValues['ACBS\Level'];
    calcMin := fromRec.ElementNativeValues['ACBS\Calc min'];
    calcMax := fromRec.ElementNativeValues['ACBS\Calc max'];
    templateFlags := fromRec.ElementNativeValues['ACBS\Template Flags'];
    template := NewRef(fromRec.ElementByPath['TPLT'], ToFileManaged);
    hasTemplate := template <> '';
    voice := NewRef(fromRec.ElementByPath['VTCK'], ToFileManaged);
    deathItem := NewRef(fromRec.ElementByPath['INAM'], ToFileManaged);
    // CREA has no class (its CNAM is the impact data set).
    if not isCreature then
      cls := NewRef(fromRec.ElementByPath['CNAM'], ToFileManaged);
    combatStyle := NewRef(fromRec.ElementByPath['ZNAM'], ToFileManaged);

    if isCreature then
      raceKey := 'CREA:' + CreatureSkeletonKey(fromRec)
    else if Supports(fromRec.ElementLinksTo['RNAM'], IwbMainRecord, target) then
      raceKey := 'RACE:' + target.EditorID
    else
      raceKey := 'RACE:Caucasian';
    if not isCreature then
      if not SkinTones.TryGetValue(LowerCase(Copy(raceKey, 6, MaxInt)), skinTone) then
        skinTone := '';
    weight := 0.5;
    if not isCreature and Assigned(fromRec.ElementByPath['LNAM']) then
      weight := fromRec.ElementNativeValues['LNAM'];
    if not ActorMap.TryGetValue(LowerCase(raceKey), mapping) then begin
      AddMessage(context + ': no FO4 race for ' + raceKey + ', using HumanRace');
      mapping.Race := '00013746';
      mapping.Template := '';
      mapping.CreatureClass := '';
    end;
    if cls = '' then
      cls := mapping.CreatureClass;
    if cls = '' then
      cls := DefaultClass;

    if SameText(mapping.Race, 'SKIP') then begin
      // No FO4 equivalent: FNVImportCleanRecord removes the actor and its placed references.
      wbGameMode := gmFO4;
      SetEditorID(rec, SkipActorPrefix + edid);
      SetValue(rec, 'RNAM', '00013746', context);
      SetValue(rec, 'CNAM', DefaultClass, context);
      Exit;
    end;

    if Supports(fromRec.ElementByPath['Factions'], IwbContainer, container) then
      for var i := 0 to container.ElementCount - 1 do begin
        var f := container.Elements[i] as IwbContainer;
        var ref := NewRef(f.ElementByName['Faction'], ToFileManaged);
        if ref <> '' then
          factions.Add(TPair<string, Integer>.Create(ref, f.ElementNativeValues['Rank']));
      end;

    if Supports(fromRec.ElementByPath['Items'], IwbContainer, container) then
      for var i := 0 to container.ElementCount - 1 do begin
        var item := container.Elements[i] as IwbContainer;
        var itemRef := item.ElementByPath['CNTO\Item'];
        var ref := NewRef(itemRef, ToFileManaged);
        if ref = '' then
          Continue;
        if Supports(itemRef.LinksTo, IwbMainRecord, target) and (target.Signature = 'ARMO') then begin
          // NPCs wear FO4 substitutes until FNV armor meshes are converted for FO4 bodies.
          var substitute := SubstituteArmor(target.EditorID);
          if (substitute <> '') and (armor.IndexOf(substitute) < 0) then
            armor.Add(substitute);
        end else
          items.Add(TPair<string, Integer>.Create(ref, item.ElementNativeValues['CNTO\Count']));
      end;

    if Supports(fromRec.ElementByPath['Packages'], IwbContainer, container) then
      for var i := 0 to container.ElementCount - 1 do begin
        var ref := NewRef(container.Elements[i], ToFileManaged);
        if ref <> '' then
          packages.Add(ref);
      end;

    aggression := fromRec.ElementNativeValues['AIDT\Aggression'];
    confidence := fromRec.ElementNativeValues['AIDT\Confidence'];
    assistance := fromRec.ElementNativeValues['AIDT\Assistance'];
    // FNV responsibility is 0-100; FO4 uses Any crime .. No crime.
    mood := fromRec.ElementNativeValues['AIDT\Responsibility'];
    if mood >= 50 then mood := 3 else if mood >= 25 then mood := 2 else if mood > 0 then mood := 1;

    if not isCreature then begin
      var hair := fromRec.ElementLinksTo['HNAM'];
      if Supports(hair, IwbMainRecord, target) then
        headParts.Add(AppearancePart(target.EditorID, female));
      var eyes := fromRec.ElementLinksTo['ENAM'];
      if Supports(eyes, IwbMainRecord, target) then
        headParts.Add(AppearancePart(target.EditorID, female));
      if Supports(fromRec.ElementByPath['Head Parts'], IwbContainer, container) then
        for var i := 0 to container.ElementCount - 1 do
          if Supports(container.Elements[i].LinksTo, IwbMainRecord, target) then
            headParts.Add(AppearancePart(target.EditorID, female));
      var hclr := fromRec.ElementByPath['HCLR'];
      if Assigned(hclr) then
        hairColor := NearestHairColor(fromRec.ElementNativeValues['HCLR\Red'],
          fromRec.ElementNativeValues['HCLR\Green'], fromRec.ElementNativeValues['HCLR\Blue']);
    end;

    ////////////////////////////////////////////////////////////////////////////
    ///  Write the FO4 record
    ////////////////////////////////////////////////////////////////////////////
    wbGameMode := gmFO4;

    SetEditorID(rec, edid);
    SetValue(rec, 'FULL', full, context);
    SetValue(rec, 'RNAM', mapping.Race, context);
    SetValue(rec, 'VTCK', voice, context);
    if (voice = '') and Assigned(rec.ElementByPath['VTCK']) then
      rec.RemoveElement('VTCK');
    SetValue(rec, 'INAM', deathItem, context);
    SetValue(rec, 'CNAM', cls, context);
    SetValue(rec, 'ZNAM', combatStyle, context);
    SetValue(rec, 'HCLF', hairColor, context);

    // Height and body weight. FNV's single weight (LNAM, 0..1) becomes FO4's thin/muscular/fat triangle.
    try
      rec.ElementNativeValues['NAM6'] := 1.0;
      if not Assigned(rec.ElementByPath['NAM4']) then
        rec.Add('NAM4', True);
      rec.ElementNativeValues['NAM4'] := 1.0;
      if not isCreature then begin
        if not Assigned(rec.ElementByPath['MWGT']) then
          rec.Add('MWGT', True);
        var w := EnsureRange(weight, 0.0, 1.0);
        rec.ElementNativeValues['MWGT\Thin'] := (1.0 - w) * 0.5;
        rec.ElementNativeValues['MWGT\Muscular'] := 0.33;
        rec.ElementNativeValues['MWGT\Fat'] := w * 0.5;
      end;
      // Skin tone; without it FO4 renders the body and head black.
      if skinTone <> '' then begin
        var tone := skinTone.Split([';']);
        var fs := TFormatSettings.Invariant;
        if not Assigned(rec.ElementByPath['QNAM']) then
          rec.Add('QNAM', True);
        rec.ElementNativeValues['QNAM\Red'] := StrToFloat(tone[0], fs) * 255;
        rec.ElementNativeValues['QNAM\Green'] := StrToFloat(tone[1], fs) * 255;
        rec.ElementNativeValues['QNAM\Blue'] := StrToFloat(tone[2], fs) * 255;
        rec.ElementNativeValues['QNAM\Alpha'] := 1.0;
      end;
    except
      on E: Exception do
        AddMessage(context + ': could not set body data: ' + E.Message);
    end;

    // Female, Essential, Respawn, Auto-calc stats and PC Level Mult use the same bits in both games.
    var fo4Flags := acbsFlags and ($1 or $2 or $8 or $10 or $80);
    var fo4TemplateFlags := 0;
    if hasTemplate then
      fo4TemplateFlags := templateFlags and $3FF
    else if isCreature and (mapping.Template <> '') then begin
      template := mapping.Template;
      fo4TemplateFlags := CreatureTemplateFlags;
    end;
    try
      rec.ElementNativeValues['ACBS\Flags'] := fo4Flags;
      rec.ElementNativeValues['ACBS\Level'] := level;
      rec.ElementNativeValues['ACBS\Calc min level'] := calcMin;
      rec.ElementNativeValues['ACBS\Calc max level'] := calcMax;
      rec.ElementNativeValues['ACBS\Use Template Actors'] := fo4TemplateFlags;
    except
      on E: Exception do
        AddMessage(context + ': could not set ACBS: ' + E.Message);
    end;
    SetValue(rec, 'TPLT', template, context);

    for var f in factions do begin
      var entry := AppendEntry(rec, 'Factions', 'SNAM') as IwbContainer;
      if Assigned(entry) then begin
        SetValue(entry, 'Faction', f.Key, context);
        SetValue(entry, 'Rank', IntToStr(f.Value), context);
      end;
    end;

    for var it in items do begin
      var entry := AppendEntry(rec, 'Items', 'CNTO') as IwbContainer;
      if Assigned(entry) then begin
        SetValue(entry, 'CNTO\Item', it.Key, context);
        SetValue(entry, 'CNTO\Count', IntToStr(it.Value), context);
      end;
    end;
    if items.Count > 0 then
      SetValue(rec, 'COCT', IntToStr(items.Count), context);

    // FNV actors wear the armor in their inventory; FO4 actors wear their default outfit.
    if armor.Count > 0 then begin
      var group := rec._File.Add('OTFT', True) as IwbContainer;
      var outfit := group.Add('OTFT', True) as IwbMainRecord;
      SetEditorID(outfit, 'NV' + edid + 'Outfit');
      for var a in armor do begin
        var entry := AppendEntry(outfit, 'INAM', 'INAM');
        if Assigned(entry) then
          entry.EditValue := a;
      end;
      SetValue(rec, 'DOFT', IntToHex(outfit.LoadOrderFormID.ToCardinal, 8), context);
    end;

    // FNV packages need converting before they can drive FO4 actors; let humans sandbox meanwhile.
    if not isCreature and ((fo4TemplateFlags and $20) = 0) then begin
      var entry := AppendEntry(rec, 'Packages', 'PKID');
      if Assigned(entry) then
        entry.EditValue := DefaultSandboxPackage;
    end;

    // NPC S.P.E.C.I.A.L. is not converted: FO4 derives NPC stats from level and class.

    try
      rec.ElementNativeValues['AIDT\Aggression'] := aggression;
      rec.ElementNativeValues['AIDT\Confidence'] := confidence;
      rec.ElementNativeValues['AIDT\Assistance'] := assistance;
      rec.ElementNativeValues['AIDT\Responsibility'] := mood;
    except
      on E: Exception do
        AddMessage(context + ': could not set AIDT: ' + E.Message);
    end;

    for var hp in headParts do
      if hp <> '' then begin
        var entry := AppendEntry(rec, 'Head Parts', 'PNAM');
        if Assigned(entry) then
          entry.EditValue := hp;
      end;
  finally
    wbGameMode := gmFO4;
    factions.Free;
    items.Free;
    armor.Free;
    packages.Free;
    headParts.Free;
  end;
end;

end.
