{******************************************************************************

  This Source Code Form is subject to the terms of the Mozilla Public License,
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

{$I xdDefines.inc}

{$IFDEF EXCEPTION_LOGGING_ENABLED}
// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
// JCL_DEBUG_EXPERT_INSERTJDBG ON
// JCL_DEBUG_EXPERT_DELETEMAPFILE ON
{$ENDIF}

program xConvert;

{$APPTYPE CONSOLE}

uses
  {$IFDEF EXCEPTION_LOGGING_ENABLED}
  nxExceptionHook,
  {$ENDIF}
  TypInfo,
  Classes,
  SysUtils,
  Windows,
  Registry,
  IniFiles,
  ZlibEx,
  lz4,
  __FNVConversionFunctions in 'xEdit\Convert\__FNVConversionFunctions.pas',
  __FNVMultiLoop3 in 'xEdit\Convert\__FNVMultiLoop3.pas',
  __FNVMultiLoopFunctions in 'xEdit\Convert\__FNVMultiLoopFunctions.pas',
  __ScriptAdapterFunctions in 'xEdit\Convert\__ScriptAdapterFunctions.pas',
  __FNVImportFuctionsTextv2 in 'xEdit\Convert\__FNVImportFuctionsTextv2.pas',
  __FNVImportCleanup in 'xEdit\Convert\__FNVImportCleanup.pas',
  converterFileManager in 'xEdit\Convert\converterFileManager.pas',
  wbBSA in 'Core\wbBSA.pas',
  wbCommandLine in 'Core\wbCommandLine.pas',
  wbSort in 'Core\wbSort.pas',
  wbInterface in 'Core\wbInterface.pas',
  wbSaveInterface in 'Core\wbSaveInterface.pas',
  wbImplementation in 'Core\wbImplementation.pas',
  wbLocalization in 'Core\wbLocalization.pas',
  wbHelpers in 'Core\wbHelpers.pas',
  wbLoadOrder in 'Core\wbLoadOrder.pas',
  wbHardcoded in 'Core\wbHardcoded.pas',
  wbDefinitionsCommon in 'Core\wbDefinitionsCommon.pas',
  wbDefinitionsFNV in 'Core\wbDefinitionsFNV.pas',
  wbDefinitionsFNVSaves in 'Core\wbDefinitionsFNVSaves.pas',
  wbDefinitionsFO3 in 'Core\wbDefinitionsFO3.pas',
  wbDefinitionsFO3Saves in 'Core\wbDefinitionsFO3Saves.pas',
  wbDefinitionsFO4 in 'Core\wbDefinitionsFO4.pas',
  wbDefinitionsFO4Saves in 'Core\wbDefinitionsFO4Saves.pas',
  wbDefinitionsFO76 in 'Core\wbDefinitionsFO76.pas',
  wbDefinitionsTES3 in 'Core\wbDefinitionsTES3.pas',
  wbDefinitionsTES4 in 'Core\wbDefinitionsTES4.pas',
  wbDefinitionsTES4Saves in 'Core\wbDefinitionsTES4Saves.pas',
  wbDefinitionsTES5 in 'Core\wbDefinitionsTES5.pas',
  wbDefinitionsTES5Saves in 'Core\wbDefinitionsTES5Saves.pas',
  wbDefinitionsSF1 in 'Core\wbDefinitionsSF1.pas';

{$R *.res}
{$MAXSTACKSIZE 2097152}

const
  IMAGE_FILE_LARGE_ADDRESS_AWARE = $0020;

{$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE}

var
  StartTime            : TDateTime;
  DumpGroups           : TStringList;
  DumpRecords          : TStringList;
  SkipChildGroups      : TStringList;
  DumpChapters         : TStringList;
  DumpForms            : TStringList;
  DumpCount            : Integer;
  DumpMax              : Integer;
  DumpCheckReport      : Boolean      = False;
  DumpSize             : Boolean      = False;
  DumpHidden           : Boolean      = False;
  DumpSummary          : Boolean      = True;
  DontWriteReport      : Boolean      = False;
  ProgressLocked       : Boolean      = False;
  ReportRecordProgress : Boolean      = True;

procedure ReportProgress(const aStatus: string);
begin
  // TODO: Look at something like GeneralProgressNoAbortCheck.
  if aStatus = '' then
    Exit;

  if not ProgressLocked then
    WriteLn(ErrOutput, FormatDateTime('<hh:nn:ss.zzz>', Now - StartTime), ' ', aStatus);
end;

type
  TExportFormat = (efUESPWiki, efRaw);
  TwbDefProfile = string;
  TwbExportPass = ( epRead, epSimple, epShared, epChapters, epRemaining, epNothing);
  TGameConfig = record
    NeedsSyntaxInfo : Boolean;
    s, t            : string;
    i,j             : integer;
    c               : Integer;
    bsaCount        : Integer;
    _File           : IwbFile;
    Masters         : TStringList;
    IsLocalized     : Boolean;
  //  F               : TSearchRec;
    n,m             : TStringList;
    Pass            : TwbExportPass;
    ts              : TwbToolSource;
    tm              : TwbToolMode;
    gm              : TwbGameMode;
    tss             : TwbSetOfSource;
    tms             : TwbSetOfMode;
    Found           : Boolean;
    b               : TBytes;
    Files           : TwbFiles;
  end;
var
  wbDefProfiles : TStringList = nil;
function StrToTExportFormat(aFormat: string): TExportFormat;
begin
  Result := efRaw;
  if Uppercase(aFormat)='RAW' then
    Result := efRaw
  else if Uppercase(aFormat)='UESPWIKI' then
    Result := efUESPWiki;
end;

const
  UESPWikiTable = '{| class="wikitable" border="1" width="100%"'+#13+#10+
  '! width="3%" | [[Tes5Mod:File Format Conventions|C]]'+#13+#10+
  '! width="10%" | SubRecord'+#13+#10+
  '! width="15%" | Name'+#13+#10+
  '! width="15%" | [[Tes5Mod:File Format Conventions|Type/Size]]'+#13+#10+
  '! width="57%" | Info';
  UESPWikiClose ='|}'+#13+#10;

{==============================================================================}
function CheckForErrors(const aIndent: Integer; const aElement: IwbElement): Boolean;
var
  Error                       : string;
  Container                   : IwbContainerElementRef;
  i                           : Integer;
  GroupRecord                 : IwbGroupRecord;
begin
  Error := aElement.Check;
  Result := Error <> '';
  if Result then
    WriteLn(StringOfChar(' ', aIndent * 2) + aElement.Name, ' -> ', Error);

  if Supports(aElement, IwbContainerElementRef, Container) then begin

    if (wbToolSource in [tsPlugins]) then if (Container.ElementType = etGroupRecord) then
      if Supports(Container, IwbGroupRecord, GroupRecord) then
        if GroupRecord.GroupType = 0 then begin
          if Assigned(DumpGroups) and not DumpGroups.Find(String(TwbSignature(GroupRecord.GroupLabel)), i) then
            Exit;
          ReportProgress('Checking: ' + GroupRecord.Name);
        end
        else
          if Assigned(SkipChildGroups) and Assigned(GroupRecord.ChildrenOf) and
             SkipChildGroups.Find(String(TwbSignature(GroupRecord.ChildrenOf.Signature)), i)
          then
            Exit;

    for i := Pred(Container.ElementCount) downto 0 do
      Result := CheckForErrors(aIndent + 1, Container.Elements[i]) or Result;
  end;

  if Result and (Error = '') then
    WriteLn(StringOfChar(' ', aIndent * 2), 'Above errors were found in: ', aElement.Name);
end;
{==============================================================================}

const
  DataName : array[Boolean] of string = (
    'Data',
    'Data Files'   // gmTES3
  );

function CheckAppPath(aGameModeConfig: PTwbGameModeConfig): string;

  function CheckPath(const aStartFrom: string): string;
  var
    s: string;
  begin
    Result := '';
    s := aStartFrom;
    while Length(s) > 3 do begin
      if FileExists(s + aGameModeConfig.wbGameExeName) and DirectoryExists(s + DataName[aGameModeConfig.wbGameMode = gmTES3]) then begin
        Result := s;
        Exit;
      end;
      s := ExtractFilePath(ExcludeTrailingPathDelimiter(s));
    end;
  end;

var
  CurrentDir, ExeDir: string;
begin
  CurrentDir := IncludeTrailingPathDelimiter(GetCurrentDir);
  Result := CheckPath(CurrentDir);
  if (Result = '') then begin
    ExeDir := ExtractFilePath(ParamStr(0));
    if not SameText(CurrentDir, ExeDir) then
      Result := CheckPath(ExeDir);
  end;
end;

function CheckParamPath(aGameModeConfig: PTwbGameModeConfig): string; // for Dump, do we have bsa in the same directory
var
  s: string;
  F : TSearchRec;
begin
  Result := '';
  s := ParamStr(ParamCount);
  s := ChangeFileExt(s, '*' + aGameModeConfig.wbArchiveExtension);
  if FindFirst(s, faAnyfile, F)=0 then begin
    Result := ExtractFilePath(ParamStr(ParamCount));
    SysUtils.FindClose(F);
  end;
end;

function DoInitPath(gameMode: TwbGameMode): String;
const
  sBethRegKey             = '\SOFTWARE\Bethesda Softworks\';
  sUninstallRegKey        = '\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\';
  sSureAIRegKey           = '\Software\SureAI\';

var
  regPath, regKey, client: string;
  ProgramPath : String;
  DataPath    : String;
begin
  var gameModeConfigP := @wbGameModeToConfig[gameMode];
  var gameModeConfig := wbGameModeToConfig[gameMode];

  ProgramPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));

  if not wbFindCmdLineParam('D', DataPath) then begin
    DataPath := CheckAppPath(gameModeConfigP);

    if (DataPath = '') then with TRegistry.Create do try
      Access  := KEY_READ or KEY_WOW64_32KEY;
      RootKey := HKEY_LOCAL_MACHINE;
      client  := 'Steam';

      case gameMode of
      gmTES3, gmTES4, gmFO3, gmFNV, gmTES5, gmFO4, gmSSE, gmTES5VR, gmFO4VR, gmSF1: begin
        regPath := sBethRegKey + gameModeConfig.wbGameNameReg + '\';
      end;
      gmEnderal, gmEnderalSE: begin
        RootKey := HKEY_CURRENT_USER;
        regPath := sSureAIRegKey + gameModeConfig.wbGameNameReg + '\';
      end;
      gmFO76: begin
        regPath := sUninstallRegKey + gameModeConfig.wbGameNameReg + '\';
        client  := 'Bethesda.net Launcher';
      end;
      end;

      if not OpenKey(regPath, False) then begin
        Access := KEY_READ or KEY_WOW64_64KEY;
        if not OpenKey(regPath, False) then begin
          ReportProgress('Warning: Could not open registry key: ' + regPath);
          Exit;
        end;
      end;

      case gameMode of
      gmTES3, gmTES4, gmFO3, gmFNV, gmTES5, gmFO4, gmSSE, gmTES5VR, gmFO4VR, gmSF1:
                  regKey := 'Installed Path';
      gmEnderal, gmEnderalSE:  regKey := 'Install_Path';
      gmFO76:     regKey := 'Path';
      end;

      DataPath := ReadString(regKey);
      DataPath := StringReplace(DataPath, '"', '', [rfReplaceAll]);

      if DataPath = '' then begin
        ReportProgress(Format('Warning: Could not determine %s installation path, no "%s" registry key', [gameModeConfig.wbGameName2, regKey]));
      end;
    finally
      Free;
    end;

    if (DataPath <> '') then
      DataPath := IncludeTrailingPathDelimiter(DataPath) + 'Data\';

  end else
    DataPath := IncludeTrailingPathDelimiter(DataPath);

  Result := DataPath;

  wbGameModeToConfig[gameMode].wbDataPath := DataPath;
end;

function InitGame(gameMode: TwbGameMode; s: string; aMasters: TStringList): TGameConfig;
begin
    var gameModeOriginal := wbGameMode;

    wbGameMode := gameMode;

    var dataPath := DoInitPath(gameMode);

    var gameModeConfig := wbGameModeToConfig[gameMode];
    var gameModeConfigP := @wbGameModeToConfig[gameMode];

    if wbToolMode in [tmDump, tmConvert] then begin
      try
        Result.IsLocalized := False;

        if Assigned(aMasters) then begin
          // Always add Fallout4.esm.
          aMasters.Insert(0, 'Fallout4.esm');

          // Delete plugin to convert.
          aMasters.Delete(aMasters.Count - 1);

          Result.Masters := aMasters;
        end else begin
          Result.Masters := TStringList.Create;
          wbMastersForFile(s, Result.Masters, gameMode, dataPath, nil, nil, @Result.IsLocalized);
        end;

        if not Result.IsLocalized then
          for var i := 0 to Pred(Result.Masters.Count) do begin
            wbMastersForFile(Result.Masters[i], nil, gameMode, dataPath, nil, nil, @Result.IsLocalized);
            if Result.IsLocalized then
              Break;
          end;

        if not Assigned(aMasters) then
          Result.Masters.Add(ExtractFileName(s));

        if Result.IsLocalized and not wbLoadBSAs and not FindCmdLineSwitch('nobsa') then begin
          for var i := 0 to Pred(Result.Masters.Count) do begin
            var t := ExtractFilePath(s) + 'Strings\' + ChangeFileExt(Result.Masters[i], '') + '_' + gameModeConfig.wbLanguage + '.STRINGS';
            if not FileExists(t) then begin
              wbLoadBSAs := True;
              Break;
            end;
          end;
        end;
        if wbLoadBSAs then begin

          if wbLoadAllBSAs then begin
            var n := TStringList.Create;
            try
              var m := TStringList.Create;
              try
                var bsaCount := 0;
                if FileExists(wbTheGameIniFileName) then begin
                  if FileExists(wbCustomIniFileName) then
                    bsaCount := FindBSAs(wbTheGameIniFileName, wbCustomIniFileName, gameModeConfig.wbDataPath, n, m, gameModeConfigP)
                  else
                    bsaCount := FindBSAs(wbTheGameIniFileName, gameModeConfig.wbDataPath, n, m, gameModeConfigP);
                end;

                if (bsaCount > 0) then begin
                  for var i := 0 to Pred(n.Count) do begin
                    ReportProgress('[' + n[i] + '] Loading Resources.');
                    wbGameModeToConfig[gameMode].wbContainerHandler.AddBSA(MakeDataFileName(n[i], gameModeConfig.wbDataPath));
                  end;
                end;
              finally
                FreeAndNil(m);
              end;
            finally
              FreeAndNil(n);
            end;
          end;

          for var i := 0 to Pred(Result.Masters.Count) do begin
            if wbLoadAllBSAs then begin
              var n := TStringList.Create;
              try
                var m := TStringList.Create;
                try
                  if HasBSAs(ChangeFileExt(Result.Masters[i], ''), gameModeConfig.wbDataPath,
                      wbGameMode in [gmTES5, gmEnderal, gmTES5vr, gmSSE], wbGameMode in [gmTES5, gmEnderal, gmTES5vr, gmSSE], n, m, gameModeConfigP)>0 then begin
                    for var j := 0 to Pred(n.Count) do begin
                      ReportProgress('[' + n[j] + '] Loading Resources.');
                      wbGameModeToConfig[gameMode].wbContainerHandler.AddBSA(MakeDataFileName(n[j], gameModeConfig.wbDataPath));
                    end;
                  end;
                finally
                  FreeAndNil(m);
                end;
              finally
                FreeAndNil(n);
              end;
            end else begin
              var n := TStringList.Create;
              try
                var m := TStringList.Create;
                try
                  if HasBSAs(ChangeFileExt(Result.Masters[i], ''), gameModeConfig.wbDataPath, true, false, n, m, gameModeConfigP)>0 then begin
                    for var j := 0 to Pred(n.Count) do begin
                      ReportProgress('[' + n[j] + '] Loading Resources.');
                      wbGameModeToConfig[gameMode].wbContainerHandler.AddBSA(MakeDataFileName(n[j], gameModeConfig.wbDataPath));
                    end;
                  end;
                  m.Clear;
                  n.Clear;
                  if HasBSAs(ChangeFileExt(Result.Masters[i], '')+' - Interface', gameModeConfig.wbDataPath, true, false, n, m, gameModeConfigP)>0 then begin
                    for var j := 0 to Pred(n.Count) do begin
                      ReportProgress('[' + n[j] + '] Loading Resources.');
                      wbGameModeToConfig[gameMode].wbContainerHandler.AddBSA(MakeDataFileName(n[j], gameModeConfig.wbDataPath));
                    end;
                  end;
                  m.Clear;
                  n.Clear;
                  if HasBSAs(ChangeFileExt(Result.Masters[i], '')+' - Localization', gameModeConfig.wbDataPath, true, false, n, m, gameModeConfigP)>0 then begin
                    for var j := 0 to Pred(n.Count) do begin
                      ReportProgress('[' + n[j] + '] Loading Resources.');
                      wbGameModeToConfig[gameMode].wbContainerHandler.AddBSA(MakeDataFileName(n[j], gameModeConfig.wbDataPath));
                    end;
                  end;
                  m.Clear;
                  n.Clear;
                  if HasBSAs(ChangeFileExt(Result.Masters[i], '')+' - Wwise', gameModeConfig.wbDataPath, false, false, n, m, gameModeConfigP)>0 then begin
                    for var j := 0 to Pred(n.Count) do begin
                      ReportProgress('[' + n[j] + '] Loading Resources.');
                      wbGameModeToConfig[gameMode].wbContainerHandler.AddBSA(MakeDataFileName(n[j], gameModeConfig.wbDataPath));
                    end;
                  end;
                finally
                  FreeAndNil(m);
                end;
              finally
                FreeAndNil(n);
              end;
            end;
          end;
        end;
      finally
        //FreeAndNil(Result.Masters);
      end;
    end;

    ReportProgress('[' + gameModeConfig.wbDataPath + '] Setting Resource Path.');
    wbGameModeToConfig[gameMode].wbContainerHandler.AddFolder(gameModeConfig.wbDataPath);

    wbResourcesLoaded;

    if Assigned(aMasters) then begin
      for var i := 0 to aMasters.Count - 1 do begin
        Result.Files.Add(wbFile(aMasters[i], gameMode, dataPath, High(Integer)));
      end;
    end else begin
      if wbToolMode in [tmDump, tmConvert] then
        Result._File := wbFile(s, gameMode, dataPath, High(Integer));
    end;

    with wbModuleByName(gameModeConfig.wbGameMasterEsm, gameMode, dataPath)^ do
      if mfHasFile in miFlags then begin
        var b := TwbHardcodedContainer.GetHardCodedDat(gameModeConfig.wbGameName);
        if Length(b) > 0 then
          wbFile(gameModeConfig.wbGameExeName, gameMode, dataPath, 0, gameModeConfig.wbGameMasterEsm, [fsIsHardcoded], b);
      end;

    wbGameMode := gameModeOriginal;
end;

procedure InitGameConfig(aGameMode: TwbGameMode; aGameModeConfig: PTwbGameModeConfig);
begin
    aGameModeConfig.wbGameMode := aGameMode;

    var gameModeOriginal := wbGameMode;

    aGameModeConfig.wbLanguage := 'English';

    wbGameMode := aGameMode;

    aGameModeConfig.wbGameExeName := '';
    case aGameMode of
      gmFNV: begin
        aGameModeConfig.wbGameName := 'FalloutNV';
        case wbToolSource of
          tsSaves:   DefineFNVSaves;
          tsPlugins: DefineFNV;
        end;
      end;
      gmFO3: begin
        aGameModeConfig.wbGameName := 'Fallout3';
        case wbToolSource of
          tsSaves:   DefineFO3Saves;
          tsPlugins: DefineFO3;
        end;
      end;
      gmTES3: begin
        aGameModeConfig.wbGameName := 'Morrowind';
        wbLoadBSAs := false;
//        tms := [tmDump];
//        tss := [tsPlugins];
        DefineTES3;
      end;
      gmTES4: begin
        aGameModeConfig.wbGameName := 'Oblivion';
        case wbToolSource of
          tsSaves:   DefineTES4Saves;
          tsPlugins: DefineTES4;
        end;
      end;
      gmTES5: begin
        aGameModeConfig.wbGameName := 'Skyrim';
        aGameModeConfig.wbGameExeName := 'TESV';
        case wbToolSource of
          tsSaves:   DefineTES5Saves;
          tsPlugins: DefineTES5;
        end;
      end;
      gmEnderal: begin
        aGameModeConfig.wbGameName := 'Enderal';
        aGameModeConfig.wbGameExeName := 'TESV';
        aGameModeConfig.wbGameMasterEsm := 'Skyrim.esm';
        case wbToolSource of
          tsSaves:   DefineTES5Saves;
          tsPlugins: DefineTES5;
        end;
      end;
      gmTES5VR: begin
        aGameModeConfig.wbGameName := 'Skyrim';
        aGameModeConfig.wbGameName2 := 'Skyrim VR';
        aGameModeConfig.wbGameExeName := 'SkyrimVR';
//        tss := [tsPlugins];
        case wbToolSource of
          //tsSaves:   DefineTES5Saves;
          tsPlugins: DefineTES5;
        end;
      end;
      gmFO4: begin
        aGameModeConfig.wbGameName := 'Fallout4';
        aGameModeConfig.wbCreateContainedIn := False;
        case wbToolSource of
          tsSaves:   DefineFO4Saves;
          tsPlugins: DefineFO4;
        end;
      end;
      gmFO4VR: begin
        aGameModeConfig.wbGameName := 'Fallout4';
        aGameModeConfig.wbGameExeName := 'Fallout4VR';
        aGameModeConfig.wbGameName2 := 'Fallout4VR';
        aGameModeConfig.wbGameNameReg := 'Fallout 4 VR';
        aGameModeConfig.wbCreateContainedIn := False;
//        tss := [tsPlugins];
        case wbToolSource of
          //tsSaves:   DefineFO4Saves;
          tsPlugins: DefineFO4;
        end;
      end;
      gmSSE: begin
        aGameModeConfig.wbGameName := 'Skyrim';
        aGameModeConfig.wbGameExeName := 'SkyrimSE';
        aGameModeConfig.wbGameName2 := 'Skyrim Special Edition';
        case wbToolSource of
          tsSaves:   DefineTES5Saves;
          tsPlugins: DefineTES5;
        end;
      end;
      gmEnderalSE: begin
        wbAppName := 'EnderalSE';
        aGameModeConfig.wbGameName := 'Enderal';
        aGameModeConfig.wbGameExeName := 'SkyrimSE';
        aGameModeConfig.wbGameName2 := 'Enderal Special Edition';
        aGameModeConfig.wbGameNameReg := 'EnderalSE';
        aGameModeConfig.wbGameMasterEsm := 'Skyrim.esm';
        case wbToolSource of
          tsSaves:   DefineTES5Saves;
          tsPlugins: DefineTES5;
        end;
      end;
      gmFO76: begin
        aGameModeConfig.wbGameName := 'Fallout76';
        aGameModeConfig.wbGameNameReg := 'Fallout 76';
        aGameModeConfig.wbGameMasterEsm := 'SeventySix.esm';
        aGameModeConfig.wbCreateContainedIn := False;
//        tss := [tsPlugins];
        case wbToolSource of
          tsPlugins: DefineFO76;
        end;
      end;
      gmSF1: begin
        aGameModeConfig.wbGameName := 'Starfield';
        aGameModeConfig.wbCreateContainedIn := False;
        case wbToolSource of
          tsPlugins: DefineSF1;
        end;
      end;
    else
      WriteLn(ErrOutput, 'Application name must contain FNV, FO3, FO4, FO4VR, FO76, SSE, TES4, TES5 or TES5VR to select game.');
      Exit;
    end;

    if aGameModeConfig.wbGameName2 = '' then
      aGameModeConfig.wbGameName2 := aGameModeConfig.wbGameName;

    if aGameModeConfig.wbGameNameReg = '' then
      aGameModeConfig.wbGameNameReg := aGameModeConfig.wbGameName2;

    if aGameModeConfig.wbGameMasterEsm = '' then
      aGameModeConfig.wbGameMasterEsm := aGameModeConfig.wbGameName + csDotEsm;

    if aGameModeConfig.wbGameExeName = '' then
      aGameModeConfig.wbGameExeName := aGameModeConfig.wbGameName;
    aGameModeConfig.wbGameExeName := aGameModeConfig.wbGameExeName + csDotExe;

    if aGameMode in [gmFO4, gmFO4vr, gmFO76, gmSF1] then
      wbGameModeToConfig[aGameMode].wbArchiveExtension := '.ba2'
    else
      wbGameModeToConfig[aGameMode].wbArchiveExtension := '.bsa';

    DoInitPath(aGameMode);
    if (wbToolMode in [tmDump]) and (wbGameModeToConfig[aGameMode].wbDataPath = '') then // Dump can be run in any directory configuration
      wbGameModeToConfig[aGameMode].wbDataPath := CheckParamPath(aGameModeConfig);

    wbLoadModules(aGameMode, wbGameModeToConfig[aGameMode].wbDataPath);

    if wbGameMode in [gmFO4, gmFO4vr, gmFO76, gmSF1] then
      aGameModeConfig.wbLanguage := 'En';

    if wbGameMode <= gmEnderal then
      wbAddDefaultLEncodingsIfMissing(False)
    else begin
      wbLEncodingDefault[False] := TEncoding.UTF8;
      case wbGameMode of
      gmSSE, gmTES5VR, gmEnderalSE:
        wbAddLEncodingIfMissing('english', '1252', False);
      else {FO4, FO76}
        wbAddLEncodingIfMissing('en', '1252', False);
      end;
    end;

    wbAddDefaultLEncodingsIfMissing(True);

    var s := '';

    if wbFindCmdLineParam('l', s) then begin
      aGameModeConfig.wbLanguage := s;
    end else begin
      if FileExists(wbTheGameIniFileName) then begin
        with TMemIniFile.Create(wbTheGameIniFileName) do try
          case wbGameMode of
            gmTES4: case ReadInteger('Controls', 'iLanguage', 0) of
              1: s := 'German';
              2: s := 'French';
              3: s := 'Spanish';
              4: s := 'Italian';
            else
              s := 'English';
            end;
          else
            s := Trim(ReadString('General', 'sLanguage', '')).ToLower;
          end;
        finally
          Free;
        end;
      end;

      if FileExists(wbCustomIniFileName) then begin
        with TMemIniFile.Create(wbCustomIniFileName) do try
          case wbGameMode of
            gmTES4: begin
              if ValueExists('Controls', 'iLanguage') then
                case ReadInteger('Controls', 'iLanguage', 0) of
                  1: s := 'German';
                  2: s := 'French';
                  3: s := 'Spanish';
                  4: s := 'Italian';
                else
                  s := 'English';
                end;
            end else begin
              if ValueExists('General', 'sLanguage') then
                s := Trim(ReadString('General', 'sLanguage', '')).ToLower;
            end;
          end;
        finally
          Free;
        end;
      end;

      if (s <> '') and not SameText(s, aGameModeConfig.wbLanguage) then
        aGameModeConfig.wbLanguage := s;
    end;

    wbEncodingTrans := wbEncodingForLanguage(aGameModeConfig.wbLanguage, False);

    wbGameMode := gameModeOriginal;
end;


// From xeInit.pas. Modified to raise an exception if the file is not found.
function xeFindNextValidCmdLineFileName(var aStartIndex  : Integer;
                                        out aValue       : string;
                                      const aDefaultPath : string = '')
                                                         : Boolean;
begin
  Result := wbFindCmdLineParam(aStartIndex, SwitchChars, aValue);
  if Result and not FileExists(aValue) then
    if (aDefaultPath<>'') then
      if FileExists(aDefaultPath+'\'+aValue) then
        aValue := ExpandFileName(aDefaultPath+'\'+aValue)
      else
        raise Exception.Create('Plugin ' + aValue + ' not found')
    else
      raise Exception.Create('Plugin ' + aValue + ' not found');
end;


// From xeInit.pas.
function xeFindNextValidCmdLineModule(var aStartIndex  : Integer;
                                      out aValue       : string;
                                    const aDefaultPath : string;
                                        aGameModeConfig: PTwbGameModeConfig)
                                                       : Boolean;
begin
  repeat
    Result := xeFindNextValidCmdLineFileName(aStartIndex, aValue, aDefaultPath);
  until not Result or wbIsModule(aValue, aGameModeConfig);
  if Result  then
    if (AnsiCompareText(ExtractFilePath(ExpandFileName(aValue)), ExpandFileName(aDefaultPath)) = 0) then begin
      aValue := ExtractFileName(aValue);
      if not Assigned(aGameModeConfig.xeModulesToUse) then
        aGameModeConfig.xeModulesToUse := TStringList.Create;
      aGameModeConfig.xeModulesToUse.Add(aValue);
    end else
      Result := False;
end;

function GetPluginsToConvert(aGameModeConfig: PTwbGameModeConfig): TStringList;
begin
  var xeParamIndex := 0;

  Result := TStringList.Create;

  var s := '';

  while xeFindNextValidCmdLineModule(xeParamIndex, s, aGameModeConfig.wbDataPath, aGameModeConfig) do begin
    Result.Add(s);

    with wbModuleByName(s, aGameModeConfig.wbGameMode, aGameModeConfig.wbDataPath)^ do begin
      if IsValid then begin
        Activate;
        Include(miFlags, mfTaggedForPluginMode);
      end else begin
        raise Exception.Create('Selected plugin "' + s + '" does not exist');
      end;
    end;
  end;
end;

type
  TProcedureWrapper = class
  public
    Files: TwbFiles;

//    constructor Create(AProc: TMyProcedure);
//    procedure Invoke(Sender: TObject);
    function AddNewFileName(aFileName: string; aIsESL: Boolean): IwbFile;

    constructor Create(aFiles: TwbFiles);
  end;


function TProcedureWrapper.AddNewFileName(aFileName: string; aIsESL: Boolean): IwbFile;
var
  LoadOrder : Integer;
begin
  var aGameModeConfig := wbGameModeToConfig[gmFO4];

  Result := nil;

  if FileExists(aGameModeConfig.wbDataPath + aFileName) then begin
    ReportProgress('A file of that name exists already.');
    Exit;
  end;

  LoadOrder := 0;
  if Length(Files) > 0 then
    LoadOrder := Succ(Files[High(Files)].LoadOrder);
{
  if LoadOrder > 254 then begin
    ShowMessage('Maximum plugins count already reached. Adding 1 more would exceed the maximum index of 254');
    Exit;
  end;
}
  Result := wbNewFile(aGameModeConfig.wbDataPath + aFileName, LoadOrder, aIsESL, aGameModeConfig.wbGameMode, aGameModeConfig.wbDataPath);
  SetLength(Files, Succ(Length(Files)));
  Files[High(Files)] := Result;
  Result._AddRef;
end;

constructor TProcedureWrapper.Create(aFiles: TwbFiles);
begin
  Files := aFiles;
end;

var
  NeedsSyntaxInfo : Boolean;
  s, t            : string;
  j               : integer;
  c               : Integer;
  bsaCount        : Integer;
  Masters         : TStringList;
  IsLocalized     : Boolean;
//  F               : TSearchRec;
  n,m             : TStringList;
  Pass            : TwbExportPass;
  ts              : TwbToolSource;
  tm              : TwbToolMode;
  gm              : TwbGameMode;
  tss             : TwbSetOfSource;
  tms             : TwbSetOfMode;
  Found           : Boolean;
  b               : TBytes;
begin
  {$IF CompilerVersion >= 24}
  FormatSettings.DecimalSeparator := '.';
  {$ELSE}
  SysUtils.DecimalSeparator := '.';
  {$IFEND}
  _wbProgressCallback := ReportProgress;
  wbDontSave := True;
  wbAllowInternalEdit := False;
  wbMoreInfoForUnknown := False;
  wbSimpleRecords := True;
  wbHideUnused := False;
  StartTime := Now;
  wbPrettyFormID := False;
  wbDisplayLoadOrderFormID := True;
  //wbHideUnused = false [in Convert]
  wbPrettyFormID := false;
  wbDisplayShorterNames := true;
  wbSortSubRecords := true;
  wbCanSortINFO := true;
  wbSortINFO := true;
  wbEditAllowed := true;
  wbFlagsAsArray := true;
//  wbRequireLoadOrder := true;
  wbVWDInTemporary := true;

  for var el := Low(wbGameModeToLocalizationHandler) to High(wbGameModeToLocalizationHandler) do begin
    wbGameModeToConfig[el].wbCreateContainedIn := True;

    wbGameModeToConfig[el].FilesMap := TwbFastStringList.Create;
    wbGameModeToConfig[el].FilesMap.Sorted := True;
    wbGameModeToConfig[el].FilesMap.Duplicates := dupError;

    var handler := TwbLocalizationHandler.Create(@wbGameModeToConfig[el]);
    wbGameModeToLocalizationHandler[el] := handler;
  end;

  try
    try
      t := ExtractFileName(ParamStr(0)).ToLowerInvariant;

      wbToolSource := tsPlugins;
      wbToolMode := TwbToolMode.tmConvert;
      var gameModeSrc := TwbGameMode.gmFNV;
      var gameModeDst := TwbGameMode.gmFO4;

      wbDisplayShorterNames := True;

      wbToolName := GetEnumName(TypeInfo(TwbToolMode), Ord(wbToolMode) );
      Delete(wbToolName, 1 ,2);
      wbSourceName := GetEnumName(TypeInfo(TwbToolSource), Ord(wbToolSource) );
      Delete(wbSourceName, 1 ,2);
      wbAppName := GetEnumName(TypeInfo(TwbGameMode), Ord(gameModeSrc) );
      Delete(wbAppName, 1 ,2);

      wbLoadBSAs := False;
      tss := [tsPlugins, tsSaves];
      tms := [tmDump, tmExport];

      if FindCmdLineSwitch('sr') then
        wbSimpleRecords := True;

      var SourceName := wbSourceName;
      if SourceName = 'Plugins' then
        SourceName := '';

      wbApplicationTitle := wbAppName + wbToolName + SourceName +  ' ' + VersionString;
      {$IFDEF WIN64}
      wbApplicationTitle := wbApplicationTitle + ' x64';
      {$ENDIF WIN64}
      if wbSubMode <> '' then
        wbApplicationTitle := wbApplicationTitle + ' (' + wbSubMode + ')';

      {$IFDEF EXCEPTION_LOGGING_ENABLED}
      nxEHAppVersion := wbApplicationTitle;
      {$ENDIF}

      wbLoadAllBSAs := FindCmdLineSwitch('allbsa');

      if FindCmdLineSwitch('more') then
        wbMoreInfoForUnknown:= True
      else
        wbMoreInfoForUnknown:= False;

      if wbFindCmdLineParam('xr', s) then
        RecordToSkip.CommaText := s;

      if wbFindCmdLineParam('xsr', s) then
        SubRecordToSkip.CommaText := s;

      if wbFindCmdLineParam('xg', s) then
        GroupToSkip.CommaText := s
      else if FindCmdLineSwitch('xbloat') then begin
        GroupToSkip.Add('LAND');
        GroupToSkip.Add('REGN');
        GroupToSkip.Add('PGRD');
        GroupToSkip.Add('SCEN');
        GroupToSkip.Add('PACK');
        GroupToSkip.Add('PERK');
        GroupToSkip.Add('NAVI');
        GroupToSkip.Add('CELL');
        GroupToSkip.Add('WRLD');
      end;

      if wbFindCmdLineParam('xc', s) then
        ChaptersToSkip.CommaText := s
      else if FindCmdLineSwitch('xcbloat') then begin
        ChaptersToSkip.Add('1001');
      end;

      if wbFindCmdLineParam('cp-general', s) then
        wbEncoding :=  wbMBCSEncoding(s);

      if wbFindCmdLineParam('cp', s) or wbFindCmdLineParam('cp-trans', s) then
        wbEncodingTrans :=  wbMBCSEncoding(s);

      if wbFindCmdLineParam('bts', s) then
        wbBytesToSkip := StrToInt64Def(s, wbBytesToSkip);
      if wbFindCmdLineParam('btd', s) then
        wbBytesToDump := StrToInt64Def(s, wbBytesToDump);

      if wbFindCmdLineParam('do', s) then
        wbDumpOffset := StrToInt64Def(s, wbDumpOffset);

      if wbFindCmdLineParam('top', s) then
        DumpMax := StrToIntDef(s, 0);

      var gameModeConfigP := @wbGameModeToConfig[gameModeSrc];
      var gameModeConfigPFO4 := @wbGameModeToConfig[gameModeDst];

      wbGameMode := gameModeSrc;
      InitGameConfig(gameModeSrc, gameModeConfigP);

      wbGameMode := gameModeDst;
      InitGameConfig(gameModeDst, gameModeConfigPFO4);

      var pluginsToConvert := GetPluginsToConvert(@wbGameModeToConfig[gameModeSrc]);

      if pluginsToConvert.Count = 0 then
        raise Exception.Create('No plugins to convert');

      NeedsSyntaxInfo := False;

      if not Assigned(wbGameModeToConfig[gameModeSrc].wbContainerHandler) then
        wbGameModeToConfig[gameModeSrc].wbContainerHandler := wbCreateContainerHandler(gameModeConfigP);

      if not Assigned(wbGameModeToConfig[gameModeDst].wbContainerHandler) then
        wbGameModeToConfig[gameModeDst].wbContainerHandler := wbCreateContainerHandler(gameModeConfigPFO4);

      StartTime := Now;
      ReportProgress('Application name : ' + wbApplicationTitle);
      if Assigned(GroupToSkip) and (GroupToSkip.Count>0) then
        ReportProgress('['+s+']   Excluding groups : '+GroupToSkip.CommaText);
      if Assigned(RecordToSkip) and (RecordToSkip.Count>0) then
        ReportProgress('['+s+']   Excluding records : '+RecordToSkip.CommaText);
      if Assigned(SubRecordToSkip) and (SubRecordToSkip.Count>0) then
        ReportProgress('['+s+']   Excluding SubRecords : '+SubRecordToSkip.CommaText);

      ExtractInitialize();

      for var i := 0 to pluginsToConvert.Count - 1 do begin
        wbGameMode := gameModeSrc;

        var gameConfig := InitGame(gameModeSrc, pluginsToConvert[i], nil);

        var aCount: Cardinal := 0;

        //__FNVMultiLoop3.ExtractFile(gameConfig._File, aCount, True);

        ExtractFileHeader(gameConfig._File);

        var gameConfig2 := InitGame(gameModeDst, '', gameConfig.Masters);

        var a := TProcedureWrapper.Create(gameConfig2.Files);

        wbGameMode := gameModeDst;
        FNVImportInitialize(gameConfig2.Files, a.AddNewFileName, False, gameConfig._File);
        FNVImportFinalize();
      end;

      ExtractFinalize();

      ReportProgress('All Done.');
    except
      on e: Exception do
        ReportProgress('Unexpected Error: <'+e.ClassName+': '+e.Message+'>');
    end;
  finally
    for var el := Low(wbGameModeToLocalizationHandler) to High(wbGameModeToLocalizationHandler) do begin
      FreeAndNil(wbGameModeToLocalizationHandler[el]);

      FreeAndNil(wbGameModeToConfig[el].FilesMap);

      FreeAndNil(wbGameModeToConfig[wbGameMode].wbGroupOrder);
      wbGameModeToConfig[wbGameMode].wbRecordDefs := nil;
    end;

    if DebugHook <> 0 then begin
      ReportProgress('Press enter to continue...');
      ReadLn;
    end;
  end;
end.
