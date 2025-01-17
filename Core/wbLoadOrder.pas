{******************************************************************************

  This Source Code Form is subject to the terms of the Mozilla Public License, 
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain 
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

unit wbLoadOrder;

{$I wbDefines.inc}

interface

uses
  System.Types,
  System.Classes,
  System.SysUtils,
  wbInterface;

type
  TwbModuleExtension = (
    meUnknown,
    meESM,
    meESL,
    meESP,
    meESU
  );

  TwbModuleExtensionHelper = record helper for TwbModuleExtension
    function ToString: string;
  end;

  TwbModuleFlag = (
    mfInvalid,
    mfValid,
    mfGhost,
    mfMastersMissing,
    mfHasESMFlag,
    mfHasESLFlag,
    mfHasOverlayFlag,
    mfHasLocalizedFlag,
    mfHasESMExtension,
    mfIsESM,
    mfActiveInPluginsTxt,
    mfActive,
    mfForceLoad,
    mfHasIndex,
    mfLoaded,
    mfLoading,
    mfTagged,
    mfHasFile,
    mfIsHardcoded,
    mfIsGameMaster,
    mfNew,
    mfTemplate,
    mfIsModGroupTarget,
    mfIsModGroupSource,
    mfEphemeralModGroupTagged,
    mfTaggedForPluginMode,
    mfModGroupMissingCurrentCRC,
    mfModGroupMissingAnyCRC
  );

  TwbModuleFlags = set of TwbModuleFlag;

  PwbModuleInfo = ^TwbModuleInfo;
  TwbModuleInfos = array of PwbModuleInfo;
  TwbModuleInfo = record
  private
    miCRC32             : TwbCRC32;
  public
    miOriginalName      : string;
    miName              : string;
    miDateTime          : TDateTime;

    miExtension         : TwbModuleExtension;

    miMasterNames       : TDynStrings;
    miMasters           : TwbModuleInfos;

    miFlags             : TwbModuleFlags;

    miOfficialIndex     : Integer;
    miCCIndex           : Integer;
    miPluginsTxtIndex   : Integer;
    miLoadOrderTxtIndex : Integer;

    miCombinedIndex     : Integer;

    miFileID            : TwbFileID;
    miLoadOrder         : Integer;

    miFile              : TObject;

    miModGroupTargets   : TwbModuleInfos;
    miModGroupSources   : TwbModuleInfos;

    function IsValid: Boolean;
    function HasIndex: Boolean;
    function IsActive: Boolean;
    function IsTemplate: Boolean;
    procedure ActivateMasters(aRecursive: Boolean);
    procedure Activate(aActivateMasters: Boolean = False);
    function LoadOrderDescription: string;
    function FlagsDescription: string;
    function Description: string;
    function ToString(aInclDesc: Boolean): string;
    function _File: IwbFile;
    class function AddNewModule(const aFileName: string; aTemplate: Boolean; aGameModeConfig: PTwbGameModeConfig): PwbModuleInfo; static;

    function HasCRC32(aCRC32: TwbCRC32; aGameModeConfig: PTwbGameModeConfig): Boolean;
    function GetCRC32(out aCRC32: TwbCRC32; aGameModeConfig: PTwbGameModeConfig): Boolean;
  end;

  TwbModuleInfosHelper = record helper for TwbModuleInfos
    function ToStrings(aInclDesc: Boolean = False): TDynStrings;
    procedure DeactivateAll;
    procedure ExcludeAll(aFlag: TwbModuleFlag);
    procedure IncludeAll(aFlag: TwbModuleFlag);
    procedure ActivateMasters;
    function SimulateLoad(aGameMode: TwbGameMode): TwbModuleInfos;
    procedure DisableSimulatedLoad(aGameMode: TwbGameMode);
    function FilteredByFlag(aFlag: TwbModuleFlag; aHasFlag: Boolean = True): TwbModuleInfos;
    function FilteredBy(const aFunc: TFunc<PwbModuleInfo, Boolean>): TwbModuleInfos;
  end;

procedure wbLoadModules(aGameMode: TwbGameMode; aDataPath: string);
function wbModuleByName(const aName: string; aGameMode: TwbGameMode; aDataPath: string): PwbModuleInfo;
function wbModulesByLoadOrder(aGameMode: TwbGameMode; aDataPath: string; aIncludeTemplates: Boolean = False): TwbModuleInfos;

implementation

uses
  System.IOUtils,
  System.Generics.Defaults,
  System.Generics.Collections,
  wbHelpers,
  wbImplementation,
  wbSort;

var _UpdateIndex: Integer = -1;

function TwbModuleExtensionHelper.ToString: string;
begin
  case Self of
    meESM: Result := csDotEsm;
    meESL: Result := csDotEsl;
    meESP: Result := csDotEsp;
    meESU: Result := csDotEsu;
  else
    Result := '';
  end;
end;

type
    TwbDynModuleInfos = array of TwbModuleInfo;

  TwbModuleConfig = record
    _Modules           : TwbDynModuleInfos;
    _ModulesLoadOrder  : TwbModuleInfos;

    _AdditionalModules : TwbModuleInfos;
    _TemplateModules   : TwbModuleInfos;
  end;
  PTwbModuleConfig = ^TwbModuleConfig;
var
  _InvalidModule     : TwbModuleInfo = (miFlags: [mfInvalid]);
  _GameModeToModuleConfig: array[TwbGameMode] of TwbModuleConfig;

function wbModuleByName(const aName: string; aGameMode: TwbGameMode; aDataPath: string): PwbModuleInfo;
var
  i: Integer;
  s: string;
begin
  s := aName;
  if s.EndsWith(csDotGhost, True) then
    SetLength(s, Length(s) + Length(csDotGhost));
  if s = '' then
    Exit(@_InvalidModule);
  wbLoadModules(aGameMode, aDataPath);
  if wbGameModeToConfig[aGameMode]._ModulesByName.Find(s, i) then
    Result := Pointer(wbGameModeToConfig[aGameMode]._ModulesByName.Objects[i])
  else
    Result := @_InvalidModule;
end;

function _ModulesLoadOrderCompare(Item1, Item2: Pointer): Integer;
var
  a, b: PwbModuleInfo;
begin
  if Item1 = Item2 then
    Exit(0);

  a := Item1;
  b := Item2;
  Result := CmpI32(a.miOfficialIndex, b.miOfficialIndex);
  if Result = 0 then begin
    Result := CmpI32(a.miCCIndex, b.miCCIndex);
    if Result = 0 then begin
      if (mfIsESM in a.miFlags) = (mfIsESM in b.miFlags) then begin
        Result := CmpI32(a.miPluginsTxtIndex, b.miPluginsTxtIndex);
        if Result = 0 then begin
          Result := CmpDouble(a.miDateTime, b.miDateTime);
          if Result = 0 then begin
            Result := CompareText(a.miName, b.miName);
            if Result = 0 then
              Result := CmpPtr(Item1, Item2);
          end;
        end;
      end else
        if mfIsESM in a.miFlags then
          Result := -1
        else
          Result := 1;
    end;
  end;
end;

function _ModulesLoadOrderCompareCombined(Item1, Item2: Pointer): Integer;
var
  a, b: PwbModuleInfo;
begin
  if Item1 = Item2 then
    Exit(0);

  a := Item1;
  b := Item2;
  Result := CmpI32(a.miOfficialIndex, b.miOfficialIndex);
  if Result = 0 then begin
    Result := CmpI32(a.miCCIndex, b.miCCIndex);
    if Result = 0 then begin
      if (mfIsESM in a.miFlags) = (mfIsESM in b.miFlags) then begin
        Result := CmpI32(a.miCombinedIndex, b.miCombinedIndex);
        if Result = 0 then begin
          Result := CmpI32(a.miPluginsTxtIndex, b.miPluginsTxtIndex);
          if Result = 0 then begin
            Result := CmpDouble(a.miDateTime, b.miDateTime);
            if Result = 0 then begin
              Result := CompareText(a.miName, b.miName);
              if Result = 0 then
                Result := CmpPtr(Item1, Item2);
            end;
          end;
        end;
      end else
        if mfIsESM in a.miFlags then
          Result := -1
        else
          Result := 1;
    end;
  end;
end;

procedure wbLoadModules(aGameMode: TwbGameMode; aDataPath: string);
var
  Files      : TStringDynArray;
  i, j, k    : Integer;
  s          : string;
  IsESM      ,
  IsESL      ,
  IsOverlay  ,
  IsLocalized: Boolean;
  lIsActive  : Boolean;
  sl         : TStringList;
  ThisModule ,
  PrevModule : PwbModuleInfo;
  MadeAChange: Boolean;
begin
  if Assigned(wbGameModeToConfig[aGameMode]._ModulesByName) then {already loaded}
    Exit;

  var gameModeConfig := wbGameModeToConfig[aGameMode];
  var gameModeConfigP := @wbGameModeToConfig[aGameMode];

  if aGameMode = gmEnderalSE then
    _UpdateIndex := Pred(High(Integer));

  if gameModeConfig.wbDataPath <> '' then begin
    Files := TDirectory.GetFiles(gameModeConfig.wbDataPath);
    i := Length(Files);
    if i > 1 then
      wbMergeSortPtr(@Files[0], i, TListSortCompare(@CompareText));

    SetLength(_GameModeToModuleConfig[aGameMode]._Modules, Succ(Length(Files)));
    with _GameModeToModuleConfig[aGameMode]._Modules[0] do begin
      miFlags := [];
      miOriginalName := gameModeConfig.wbGameExeName;
      miName := miOriginalName;
      miExtension := meESM;

      Include(miFlags, mfHasESMFlag);
      Include(miFlags, mfIsESM);
      Include(miFlags, mfIsHardcoded);
    end;
    j := 1;
    for i := Low(Files) to High(Files) do
      with _GameModeToModuleConfig[aGameMode]._Modules[j] do try
        miFlags := [];
        miOriginalName := ExtractFileName(Files[i]);
        if miOriginalName.EndsWith(csDotGhost, True) then begin
          miName := Copy(miOriginalName, 1, Length(miOriginalName) - Length(csDotGhost));
          Include(miFlags, mfGhost);
          if (j > 0) and SameText(miName, _GameModeToModuleConfig[aGameMode]._Modules[Pred(j)].miName) then
            Continue; {ignore ghost if original exists}
        end else
          miName := miOriginalName;
        miExtension := meUnknown;
        if miName.EndsWith(csDotEsm, True) then
          miExtension := meESM
        else if miName.EndsWith(csDotEsp, True) then
          miExtension := meESP
        else if miName.EndsWith(csDotEsu, True) then
          miExtension := meESU
        else if miName.EndsWith(csDotEsl, True) and wbIsEslSupported then
          miExtension := meESL;
        if miExtension = meUnknown then
          Continue;

        if aGameMode >= gmFO4 then
          if miExtension in [meESM, meESL] then begin
            Include(miFlags, mfHasESMExtension);
            Include(miFlags, mfIsESM);
          end;

        miDateTime := wbGetLastWriteTime(aDataPath + miOriginalName);

        if not wbMastersForFile(aDataPath+miOriginalName, miMasterNames, aGameMode, aDataPath, @IsESM, @IsESL, @IsLocalized, @IsOverlay) then
          Continue;

        if IsESM then begin
          Include(miFlags, mfHasESMFlag);
          if (wbToolMode in [tmMasterUpdate, tmMasterRestore]) and wbIsFallout3 then
            {ignore header flag for load order, only extension counts}
          else
            Include(miFlags, mfIsESM);
        end;

        {
        if the 0x200 flag is set then begin
          if there is no master list, or the 0x100 flag is set then
            remove the 0x200 flag
        end else
          if the extension is .esl then
            force 0x100 flag
        }
        if IsOverlay then begin
          if {(Length(miMasterNames) < 1) or} IsESL then
            IsOverlay := False;
        end else
          if miExtension in [meESL] then
            Include(miFlags, mfHasESLFlag);

        if IsOverlay then
          Include(miFlags, mfHasOverlayFlag);

        if IsESL then
          Include(miFlags, mfHasESLFlag);

        if IsLocalized then
          Include(miFlags, mfHasLocalizedFlag);

        Include(miFlags, mfValid);

        Inc(j);
      except
        on E: Exception do
        wbProgress('Error loading module information for "%s": [%s] %s', [Files[i], E.ClassName, E.Message]);
      end;
    SetLength(_GameModeToModuleConfig[aGameMode]._Modules, j);
  end;
  {do NOT perform SetLength on _Modules after this, it could invalidate pointer into the array}
  wbGameModeToConfig[aGameMode]._ModulesByName := TStringList.Create;
  for i := Low(_GameModeToModuleConfig[aGameMode]._Modules) to High(_GameModeToModuleConfig[aGameMode]._Modules) do
    wbGameModeToConfig[aGameMode]._ModulesByName.AddObject(_GameModeToModuleConfig[aGameMode]._Modules[i].miName, @_GameModeToModuleConfig[aGameMode]._Modules[i]);
  wbGameModeToConfig[aGameMode]._ModulesByName.Sorted := True;

  SetLength(_GameModeToModuleConfig[aGameMode]._ModulesLoadOrder, Length(_GameModeToModuleConfig[aGameMode]._Modules));
  for i := Low(_GameModeToModuleConfig[aGameMode]._Modules) to High(_GameModeToModuleConfig[aGameMode]._Modules) do
    with _GameModeToModuleConfig[aGameMode]._Modules[i] do begin
      _GameModeToModuleConfig[aGameMode]._ModulesLoadOrder[i] := @_GameModeToModuleConfig[aGameMode]._Modules[i];
      SetLength(miMasters, Length(miMasterNames));
      for j := Low(miMasterNames) to High(miMasterNames) do
        if wbGameModeToConfig[aGameMode]._ModulesByName.Find(miMasterNames[j], k) then
          miMasters[j] := Pointer(wbGameModeToConfig[aGameMode]._ModulesByName.Objects[k])
        else
          Include(miFlags, mfMastersMissing);
      miOfficialIndex  := High(Integer);
      miCCIndex        := High(Integer);
      miPluginsTxtIndex   := High(Integer);
      miLoadOrderTxtIndex := High(Integer);
    end;

  if Length(_GameModeToModuleConfig[aGameMode]._Modules) < 1 then
    Exit;

  repeat
    MadeAChange := False;
    for i := Low(_GameModeToModuleConfig[aGameMode]._Modules) to High(_GameModeToModuleConfig[aGameMode]._Modules) do
      with _GameModeToModuleConfig[aGameMode]._Modules[i] do begin
        if not (mfMastersMissing in miFlags) then
          for j := Low(miMasters) to High(miMasters) do
            if not Assigned(miMasters[j]) or (mfMastersMissing in miMasters[j].miFlags) then begin
              Include(miFlags, mfMastersMissing);
              MadeAChange := True;
            end
      end;
  until not MadeAChange;

  sl := TStringList.Create;
  try
    if FileExists(wbPluginsFileName) then begin
      sl.LoadFromFile(wbPluginsFileName);
      for i := 0 to Pred(sl.Count) do begin
        s := sl[i];
        j := Pos('#', s);
        if j > 0 then
          Delete(s, j, High(Integer));
        s := Trim(s);
        lIsActive := aGameMode in wbSimplePluginsTxt;
        if not lIsActive then begin
          lIsActive := s.StartsWith('*');
          if lIsActive then
            Delete(s, 1, 1);
          s := Trim(s);
        end;
        with wbModuleByName(s, aGameMode, aDataPath)^ do
          if IsValid then begin
            if aGameMode in wbOrderFromPluginsTxt then begin
              miPluginsTxtIndex := i;
              Include(miFlags, mfHasIndex);
            end;
            if lIsActive then begin
              Include(miFlags, mfActiveInPluginsTxt);
              Include(miFlags, mfActive);
            end;
          end;
      end;
    end;

  finally
    sl.Free;
  end;

  for i := Low(_GameModeToModuleConfig[aGameMode]._Modules) to High(_GameModeToModuleConfig[aGameMode]._Modules) do
    with _GameModeToModuleConfig[aGameMode]._Modules[i] do
      if mfMastersMissing in miFlags then
        Exclude(miFlags, mfActive);

  with wbModuleByName(gameModeConfig.wbGameMasterEsm, aGameMode, aDataPath)^ do
    if IsValid then begin
      miOfficialIndex := Low(Integer);
      Include(miFlags, mfActive);
      Include(miFlags, mfHasIndex);
      Include(miFlags, mfIsGameMaster);
    end;
  with wbModuleByName(gameModeConfig.wbGameExeName, aGameMode, aDataPath)^ do begin
    miOfficialIndex := Succ(Low(Integer));
    Include(miFlags, mfHasIndex);
  end;

  if wbIsSkyrim then
    with wbModuleByName('Update.esm', aGameMode, aDataPath)^ do
      if IsValid then begin
        miOfficialIndex := _UpdateIndex;
        Include(miFlags, mfActive);
        Include(miFlags, mfHasIndex);
      end;

  for i := Low(gameModeConfig.wbOfficialDLC) to High(gameModeConfig.wbOfficialDLC) do
    with wbModuleByName(gameModeConfig.wbOfficialDLC[i], aGameMode, aDataPath)^ do
      if IsValid then begin
        miOfficialIndex := i;
        Include(miFlags, mfActive);
        Include(miFlags, mfHasIndex);
      end;

  for i := Low(wbCreationClubContent) to High(wbCreationClubContent) do
    with wbModuleByName(wbCreationClubContent[i], aGameMode, aDataPath)^ do
      if IsValid then begin
        miCCIndex := Succ(i);
        Include(miFlags, mfActive);
        Include(miFlags, mfHasIndex);
      end;

  i := Length(_GameModeToModuleConfig[aGameMode]._ModulesLoadOrder);
  if i > 1 then
    wbMergeSortPtr(@_GameModeToModuleConfig[aGameMode]._ModulesLoadOrder[0], i, _ModulesLoadOrderCompare);

  if (aGameMode in [gmTES5, gmEnderal]) then begin
    s := ExtractFilePath(wbPluginsFileName) + 'loadorder.txt';
    if FileExists(s) then begin
      sl := TStringList.Create;
      try
        sl.LoadFromFile(s);
        for i := Pred(sl.Count) downto 0  do begin
          s := sl[i];
          j := Pos('#', s);
          if j > 0 then
            Delete(s, j, High(Integer));
          s := Trim(s);
          ThisModule := wbModuleByName(s, aGameMode, aDataPath);
          if ThisModule.IsValid then begin
            sl[i] := s;
            sl.Objects[i] := Pointer(i);
          end else
            sl.Delete(i);
        end;
        if sl.Count > 1 then begin
          for i := Low(_GameModeToModuleConfig[aGameMode]._ModulesLoadOrder) to High(_GameModeToModuleConfig[aGameMode]._ModulesLoadOrder) do
            with _GameModeToModuleConfig[aGameMode]._ModulesLoadOrder[i]^ do
              miCombinedIndex := Succ(i) * 1000;

          for i := 1 to Pred(sl.Count) do begin
            ThisModule := wbModuleByName(sl[i], aGameMode, aDataPath);
            if ThisModule.IsValid then begin
              ThisModule.miLoadOrderTxtIndex := Integer(sl.Objects[i]);
              if not ThisModule.HasIndex then begin
                PrevModule := @_InvalidModule;
                for j := Pred(i) downto 0 do begin
                  PrevModule := wbModuleByName(sl[j], aGameMode, aDataPath);
                  if PrevModule.HasIndex then
                    Break;
                end;
                if PrevModule.HasIndex then begin
                  ThisModule.miCombinedIndex := PrevModule.miCombinedIndex + 1;
                  Include(ThisModule.miFlags, mfHasIndex);
                end;
              end;
            end;
          end;

          wbMergeSortPtr(@_GameModeToModuleConfig[aGameMode]._ModulesLoadOrder[0], Length(_GameModeToModuleConfig[aGameMode]._ModulesLoadOrder), _ModulesLoadOrderCompareCombined);
        end;
      finally
        sl.Free;
      end;
    end;
  end;

  for i := Low(_GameModeToModuleConfig[aGameMode]._ModulesLoadOrder) to High(_GameModeToModuleConfig[aGameMode]._ModulesLoadOrder) do
    _GameModeToModuleConfig[aGameMode]._ModulesLoadOrder[i].miCombinedIndex := i;

  if aGameMode <> gmSF1 then begin
    TwbModuleInfo.AddNewModule('<new file>.esp', True, gameModeConfigP);
    with TwbModuleInfo.AddNewModule('<new file>.esp', True, gameModeConfigP)^ do begin
      Include(miFlags, mfHasESMFlag);
      Include(miFlags, mfIsESM);
    end;
    if wbIsEslSupported then begin
      with TwbModuleInfo.AddNewModule('<new file>.esp', True, gameModeConfigP)^ do
        Include(miFlags, mfHasESLFlag);
      with TwbModuleInfo.AddNewModule('<new file>.esp', True, gameModeConfigP)^ do begin
        Include(miFlags, mfHasESMFlag);
        Include(miFlags, mfHasESLFlag);
        Include(miFlags, mfIsESM);
      end;
    end;
    if wbIsOverlaySupported then begin
      with TwbModuleInfo.AddNewModule('<new file>.esp', True, gameModeConfigP)^ do
        Include(miFlags, mfHasOverlayFlag);
      with TwbModuleInfo.AddNewModule('<new file>.esp', True, gameModeConfigP)^ do begin
        Include(miFlags, mfHasESMFlag);
        Include(miFlags, mfHasOverlayFlag);
        Include(miFlags, mfIsESM);
      end;
    end;
  end;

  with TwbModuleInfo.AddNewModule('<new file>.esm', True, gameModeConfigP)^ do begin
    Include(miFlags, mfHasESMFlag);
    Include(miFlags, mfIsESM);
    if not (wbStarfieldIsABugInfestedHellhole and wbIsStarfield) then begin
      if wbIsEslSupported then begin
        with TwbModuleInfo.AddNewModule('<new file>.esm', True, gameModeConfigP)^ do begin
          Include(miFlags, mfHasESLFlag);
          Include(miFlags, mfHasESMFlag);
          Include(miFlags, mfIsESM);
        end;
      end;
      if wbIsOverlaySupported then begin
        with TwbModuleInfo.AddNewModule('<new file>.esm', True, gameModeConfigP)^ do begin
          Include(miFlags, mfHasOverlayFlag);
          Include(miFlags, mfHasESMFlag);
          Include(miFlags, mfIsESM);
        end;
      end;
    end;
  end;

  if aGameMode <> gmSF1 then begin
    if wbIsEslSupported then begin
      with TwbModuleInfo.AddNewModule('<new file>.esl', True, gameModeConfigP)^ do begin
        Include(miFlags, mfHasESMFlag);
        Include(miFlags, mfHasESLFlag);
        Include(miFlags, mfIsESM);
      end;
      if wbIsOverlaySupported then begin
        with TwbModuleInfo.AddNewModule('<new file>.esl', True, gameModeConfigP)^ do begin
          Include(miFlags, mfHasOverlayFlag);
          Include(miFlags, mfHasESMFlag);
          Include(miFlags, mfIsESM);
        end;
      end;
    end;
  end;
end;

function wbModulesByLoadOrder(aGameMode: TwbGameMode; aDataPath: string; aIncludeTemplates: Boolean = False):  TwbModuleInfos;
var
  i, j : Integer;
begin
  wbLoadModules(aGameMode, aDataPath);
  Result := Copy(_GameModeToModuleConfig[aGameMode]._ModulesLoadOrder);
  i := Length(_GameModeToModuleConfig[aGameMode]._AdditionalModules);
  if i > 0 then begin
    j := Length(Result);
    SetLength(Result, j + i);
    for i := 0 to Pred(i) do
      Result[j + i] := _GameModeToModuleConfig[aGameMode]._AdditionalModules[i];
  end;
  if aIncludeTemplates then begin
    i := Length(_GameModeToModuleConfig[aGameMode]._TemplateModules);
    if i > 0 then begin
      j := Length(Result);
      SetLength(Result, j + i);
      for i := 0 to Pred(i) do
        Result[j + i] := _GameModeToModuleConfig[aGameMode]._TemplateModules[i];
    end;
  end;
end;

{ TwbModuleInfo }

procedure TwbModuleInfo.Activate(aActivateMasters: Boolean);
begin
  Include(miFlags, mfActive);
  if aActivateMasters then
    ActivateMasters(True);
end;

procedure TwbModuleInfo.ActivateMasters(aRecursive: Boolean);
var
  i: Integer;
begin
  for i := High(miMasters) downto Low(miMasters) do
    if Assigned(miMasters[i]) then
      with miMasters[i]^ do
        if not (mfActive in miFlags) then
          Activate(aRecursive);
end;

class function TwbModuleInfo.AddNewModule(const aFileName: string; aTemplate: Boolean; aGameModeConfig: PTwbGameModeConfig): PwbModuleInfo;
begin
  Result := AllocMem(SizeOf(TwbModuleInfo));
  with Result^ do begin
    miOriginalName := aFileName;
    miName := aFileName;

    miExtension := meUnknown;
    if miName.EndsWith(csDotEsm, True) then
      miExtension := meESM
    else if miName.EndsWith(csDotEsp, True) then
      miExtension := meESP
    else if miName.EndsWith(csDotEsu, True) then
      miExtension := meESU
    else if miName.EndsWith(csDotEsl, True) and wbIsEslSupported then
      miExtension := meESL;

    if miExtension in [meESM, meESL] then
      Include(miFlags, mfIsESM);

    miDateTime := Now;
    Include(miFlags, mfValid);
    if aTemplate then
      Include(miFlags, mfTemplate)
    else
      Include(miFlags, mfNew);

    miOfficialIndex := High(Integer);
    miCCIndex := High(Integer);
    miPluginsTxtIndex := High(Integer);
    miLoadOrderTxtIndex := High(Integer);
    miCombinedIndex := High(Integer);

    miFileID := TwbFileID.Create(-1);
    miLoadOrder := High(Integer);
  end;
  if aTemplate then begin
    SetLength(_GameModeToModuleConfig[aGameModeConfig.wbGameMode]._TemplateModules, Succ(Length(_GameModeToModuleConfig[aGameModeConfig.wbGameMode]._TemplateModules)));
    _GameModeToModuleConfig[aGameModeConfig.wbGameMode]._TemplateModules[High(_GameModeToModuleConfig[aGameModeConfig.wbGameMode]._TemplateModules)] := Result;
    Result.miLoadOrder := 10000 + High(_GameModeToModuleConfig[aGameModeConfig.wbGameMode]._TemplateModules);
  end else begin
    SetLength(_GameModeToModuleConfig[aGameModeConfig.wbGameMode]._AdditionalModules, Succ(Length(_GameModeToModuleConfig[aGameModeConfig.wbGameMode]._AdditionalModules)));
    _GameModeToModuleConfig[aGameModeConfig.wbGameMode]._AdditionalModules[High(_GameModeToModuleConfig[aGameModeConfig.wbGameMode]._AdditionalModules)] := Result;
    aGameModeConfig._ModulesByName.AddObject(aFileName, Pointer(Result));
  end;
end;

function TwbModuleInfo.Description: string;
begin
  Result := Trim(LoadOrderDescription + ' ' + FlagsDescription);
end;

function TwbModuleInfo.FlagsDescription: string;
begin
  Result := '';
  if mfGhost in miFlags then
    Result := Result + '<Ghost>';
  if mfHasESMFlag in miFlags then
    Result := Result + '<ESM>';
  if mfHasESLFlag in miFlags then
    Result := Result + '<ESL>';
  if mfHasOverlayFlag in miFlags then
    Result := Result + '<Overlay>';
  if mfHasLocalizedFlag in miFlags then
    Result := Result + '<Localized>';
  if mfMastersMissing in miFlags then
    Result := Result + '<MissingMasters>';
end;

function TwbModuleInfo.GetCRC32(out aCRC32: TwbCRC32; aGameModeConfig: PTwbGameModeConfig): Boolean;
begin
  if Assigned(miFile) then
    aCRC32 := _File.CRC32
  else begin
    if miCRC32 = 0 then
      miCRC32 := wbCRC32File(aGameModeConfig.wbDataPath + miOriginalName);
    aCRC32 := miCRC32;
  end;
  Result := aCRC32.IsValid;
end;

function TwbModuleInfo.HasCRC32(aCRC32: TwbCRC32; aGameModeConfig: PTwbGameModeConfig): Boolean;
begin
  if Assigned(miFile) then
    Exit(_File.CRC32 = aCRC32);
  if miCRC32 = 0 then
    miCRC32 := wbCRC32File(aGameModeConfig.wbDataPath + miOriginalName);
  Result := aCRC32 = miCRC32;
end;

function TwbModuleInfo.HasIndex: Boolean;
begin
  Result := IsValid and (mfHasIndex in miFlags);
end;

function TwbModuleInfo.IsActive: Boolean;
begin
  Result := IsValid and (mfActive in miFlags);
end;

function TwbModuleInfo.IsTemplate: Boolean;
begin
  Result := IsValid and (mfTemplate in miFlags);
end;

function TwbModuleInfo.IsValid: Boolean;
begin
  Result := not ((mfInvalid in miFlags) or (@Self = @_InvalidModule));
end;

function TwbModuleInfo.LoadOrderDescription: string;
begin
  if mfTemplate in miFlags then
    Exit('[Template]');

  Result := '';
  if miOfficialIndex = Low(Integer) then
    Result := Result + '[GameMaster]'
  else if miOfficialIndex = Succ(Low(Integer)) then
    Result := Result + '[Hardcoded]'
  else if miOfficialIndex = _UpdateIndex then
    Result := Result + '[Update]'
  else if miOfficialIndex < High(Integer) then
    Result := Result + '[DLC:'+miOfficialIndex.ToString+']';
  if miCCIndex < High(Integer) then
    Result := Result + '[CC:'+miCCIndex.ToString+']';
  if Result = '' then begin
    if mfIsESM in miFlags then
      Result := Result + '[ESM]';

    if miPluginsTxtIndex < High(Integer) then
      Result := Result + '[Plugins.txt:'+miPluginsTxtIndex.ToString+']';
    if miLoadOrderTxtIndex < High(Integer) then
      Result := Result + '[LoadOrder.txt:'+miLoadOrderTxtIndex.ToString+']';

    if (Result = '') or (Result = '[ESM]') then
      Result := Result + '[Time:'+FormatDateTime('yyyy-mm-dd hh:mm:ss', miDateTime)+']';
  end;
end;

function TwbModuleInfo.ToString(aInclDesc: Boolean): string;
begin
  Result := miName;
  if aInclDesc then
    Result := Trim(Result + '    ' + Description);
end;

function TwbModuleInfo._File: IwbFile;

begin
  if not Supports(miFile, IwbFile, Result) then
    Result := nil;
end;

{ TwbModuleInfosHelper }

procedure TwbModuleInfosHelper.ActivateMasters;
var
  i: Integer;
begin
  for i := Low(Self) to High(Self) do
    with Self[i]^ do
      if mfActive in miFlags then
        ActivateMasters(True);
end;

procedure TwbModuleInfosHelper.DeactivateAll;
begin
  ExcludeAll(mfActive);
end;

var
  _NextFullSlot: Integer;
  _NextLightSlot: Integer;
  _SimulatedLoadDisabled: Boolean;

procedure TwbModuleInfosHelper.DisableSimulatedLoad(aGameMode: TwbGameMode);
var
  i: Integer;
begin
  if _SimulatedLoadDisabled then
    Exit;
  _SimulatedLoadDisabled := True;
  for i := Low(_GameModeToModuleConfig[aGameMode]._Modules) to High(_GameModeToModuleConfig[aGameMode]._Modules) do
    with _GameModeToModuleConfig[aGameMode]._Modules[i] do begin
      Exclude(miFlags, mfLoaded);
      Exclude(miFlags, mfLoading);
      miFileID := TwbFileID.Create(-1);
      miLoadOrder := High(Integer);
    end;
  _NextFullSlot := 0;
  _NextLightSlot := 0;
end;

procedure TwbModuleInfosHelper.ExcludeAll(aFlag: TwbModuleFlag);
var
  i: Integer;
begin
  for i := Low(Self) to High(Self) do
    with Self[i]^ do
      Exclude(miFlags, aFlag);
end;

function TwbModuleInfosHelper.FilteredBy(const aFunc: TFunc<PwbModuleInfo, Boolean>): TwbModuleInfos;
var
  i, j: Integer;
begin
  SetLength(Result, Length(Self));
  j := 0;
  for i := Low(Self) to High(Self) do
    if aFunc(Self[i]) then begin
      Result[j] := Self[i];
      Inc(j);
    end;
  SetLength(Result, j);
end;

function TwbModuleInfosHelper.FilteredByFlag(aFlag: TwbModuleFlag; aHasFlag: Boolean = True): TwbModuleInfos;
var
  i, j: Integer;
begin
  SetLength(Result, Length(Self));
  j := 0;
  for i := Low(Self) to High(Self) do
    if (not (aFlag in Self[i]^.miFlags)) xor aHasFlag then begin
      Result[j] := Self[i];
      Inc(j);
    end;
  SetLength(Result, j);
end;

procedure TwbModuleInfosHelper.IncludeAll(aFlag: TwbModuleFlag);
var
  i: Integer;
begin
  for i := Low(Self) to High(Self) do
    with Self[i]^ do
      Include(miFlags, aFlag);
end;

function TwbModuleInfosHelper.SimulateLoad(aGameMode: TwbGameMode): TwbModuleInfos;
var
  NewLoadOrder      : TwbModuleInfos;
  NewLoadOrderCount : Integer;

  procedure Load(aModule: PwbModuleInfo);
  var
    i: Integer;
  begin
    with aModule^ do begin
      if mfLoaded in miFlags then
        Exit;
      if mfLoading in miFlags then
        raise Exception.Create('Modules contain circular references. Can''t load "'+miName+'"');
      Include(miFlags, mfLoading);
      try
        for i := Low(miMasters) to High(miMasters) do
          if Assigned(miMasters[i]) then
            Load(miMasters[i])
          else
            raise Exception.Create('Module "'+miName+'" requires master "'+miMasterNames[i]+'" which can not be found');
        Include(miFlags, mfLoaded);
        miLoadOrder := NewLoadOrderCount;
        NewLoadOrder[NewLoadOrderCount] := aModule;
        Inc(NewLoadOrderCount);
        if not (wbPseudoESL or wbPseudoOverlay) then
          if (mfHasOverlayFlag in miFlags) and not wbIgnoreOverlay then begin
            miFileID := TwbFileID.Invalid;
          end else if (mfHasESLFlag in miFlags) and not wbIgnoreESL then begin
            if _NextLightSlot > $FFF then
              raise Exception.Create('Too many light modules');
            miFileID := TwbFileID.Create($FE, _NextLightSlot);
            Inc(_NextLightSlot);
          end else begin
            if _NextFullSlot > $FD then
              raise Exception.Create('Too many full modules');
            miFileID := TwbFileID.Create(_NextFullSlot);
            Inc(_NextFullSlot);
          end;
      finally
        Exclude(miFlags, mfLoading);
      end;
    end;
  end;

begin
  if _SimulatedLoadDisabled then
    raise Exception.Create('Simulated Load has been disabled');

  for var lModuleIdx := Low(_GameModeToModuleConfig[aGameMode]._Modules) to High(_GameModeToModuleConfig[aGameMode]._Modules) do
    with _GameModeToModuleConfig[aGameMode]._Modules[lModuleIdx] do begin
      Exclude(miFlags, mfLoaded);
      Exclude(miFlags, mfLoading);
      miFileID := TwbFileID.Create(-1);
      miLoadOrder := High(Integer);
    end;
  _NextFullSlot := 0;
  _NextLightSlot := 0;
  SetLength(NewLoadOrder, Length(_GameModeToModuleConfig[aGameMode]._Modules));
  NewLoadOrderCount := 0;
  for var lSelfIdx := Low(Self) to High(Self) do
    with Self[lSelfIdx]^ do
      if miFlags * [mfActive, mfForceLoad] <> [] then
        Load(Self[lSelfIdx]);
  SetLength(NewLoadOrder, NewLoadOrderCount);

  var lActiveCount := 0;
  for var lNewLoadOrderIdx := Low(NewLoadOrder) to High(NewLoadOrder) do
    with NewLoadOrder[lNewLoadOrderIdx]^ do
      if miFlags * [mfActive] <> [] then
        Inc(lActiveCount);
  if lActiveCount < 1 then
    Exit(nil);

  Result := NewLoadOrder;
end;

function TwbModuleInfosHelper.ToStrings(aInclDesc: Boolean): TDynStrings;
var
  i: Integer;
begin
  SetLength(Result ,Length(Self));
  for i := Low(Self) to High(Self) do
    Result[i] := Self[i].ToString(aInclDesc);
end;

procedure FreeAllocatedModules(var aList: TwbModuleInfos);
var
  i: Integer;
begin
  for i := Low(aList) to High(aList) do
    Dispose(aList[i]);
  aList := nil;
end;

initialization
finalization
  for var el := Low(wbGameModeToConfig) to High(wbGameModeToConfig) do begin
    FreeAndNil(wbGameModeToConfig[el]._ModulesByName);

    FreeAllocatedModules(_GameModeToModuleConfig[el]._TemplateModules);
    FreeAllocatedModules(_GameModeToModuleConfig[el]._AdditionalModules);
  end;
end.

