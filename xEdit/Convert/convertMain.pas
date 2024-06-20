unit convertMain;

interface

procedure Main;

implementation

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
  __FNVConversionFunctions,
  __FNVMultiLoop3,
  __FNVMultiLoopFunctions,
  __ScriptAdapterFunctions,
  __FNVImportFuctionsTextv2,
  __FNVImportCleanup,
  converterFileManager,
  wbBSA,
  wbCommandLine,
  wbSort,
  wbInterface,
  wbSaveInterface,
  wbImplementation,
  wbLocalization,
  wbHelpers,
  wbLoadOrder,
  wbHardcoded,
  wbDefinitionsCommon,
  wbDefinitionsFNV,
  wbDefinitionsFNVSaves,
  wbDefinitionsFO3,
  wbDefinitionsFO3Saves,
  wbDefinitionsFO4,
  wbDefinitionsFO4Saves,
  wbDefinitionsFO76,
  wbDefinitionsTES3,
  wbDefinitionsTES4,
  wbDefinitionsTES4Saves,
  wbDefinitionsTES5,
  wbDefinitionsTES5Saves,
  wbDefinitionsSF1;

const
  IMAGE_FILE_LARGE_ADDRESS_AWARE = $0020;

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
  if not ProgressLocked then
    WriteLn(ErrOutput, FormatDateTime('<hh:nn:ss.zzz>', Now - StartTime), ' ', aStatus);
end;

type
  TExportFormat = (efUESPWiki, efRaw);
  TwbDefProfile = string;
  TwbExportPass = ( epRead, epSimple, epShared, epChapters, epRemaining, epNothing);
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

function CheckAppPath: string;

  function CheckPath(const aStartFrom: string): string;
  var
    s: string;
  begin
    Result := '';
    s := aStartFrom;
    while Length(s) > 3 do begin
      if FileExists(s + wbGameExeName) and DirectoryExists(s + DataName[wbGameMode = gmTES3]) then begin
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

function CheckParamPath: string; // for Dump, do we have bsa in the same directory
var
  s: string;
  F : TSearchRec;
begin
  Result := '';
  s := ParamStr(ParamCount);
  s := ChangeFileExt(s, '*' + wbArchiveExtension);
  if FindFirst(s, faAnyfile, F)=0 then begin
    Result := ExtractFilePath(ParamStr(ParamCount));
    SysUtils.FindClose(F);
  end;
end;

procedure DoInitPath;
const
  sBethRegKey             = '\SOFTWARE\Bethesda Softworks\';
  sUninstallRegKey        = '\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\';
  sSureAIRegKey           = '\Software\SureAI\';

var
  regPath, regKey, client: string;
  ProgramPath : String;
  DataPath    : String;
begin
  ProgramPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));

  if not wbFindCmdLineParam('D', DataPath) then begin
    DataPath := CheckAppPath;

    if (DataPath = '') then with TRegistry.Create do try
      Access  := KEY_READ or KEY_WOW64_32KEY;
      RootKey := HKEY_LOCAL_MACHINE;
      client  := 'Steam';

      case wbGameMode of
      gmTES3, gmTES4, gmFO3, gmFNV, gmTES5, gmFO4, gmSSE, gmTES5VR, gmFO4VR, gmSF1: begin
        regPath := sBethRegKey + wbGameNameReg + '\';
      end;
      gmEnderal, gmEnderalSE: begin
        RootKey := HKEY_CURRENT_USER;
        regPath := sSureAIRegKey + wbGameNameReg + '\';
      end;
      gmFO76: begin
        regPath := sUninstallRegKey + wbGameNameReg + '\';
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

      case wbGameMode of
      gmTES3, gmTES4, gmFO3, gmFNV, gmTES5, gmFO4, gmSSE, gmTES5VR, gmFO4VR, gmSF1:
                  regKey := 'Installed Path';
      gmEnderal, gmEnderalSE:  regKey := 'Install_Path';
      gmFO76:     regKey := 'Path';
      end;

      DataPath := ReadString(regKey);
      DataPath := StringReplace(DataPath, '"', '', [rfReplaceAll]);

      if DataPath = '' then begin
        ReportProgress(Format('Warning: Could not determine %s installation path, no "%s" registry key', [wbGameName2, regKey]));
      end;
    finally
      Free;
    end;

    if (DataPath <> '') then
      DataPath := IncludeTrailingPathDelimiter(DataPath) + 'Data\';

  end else
    DataPath := IncludeTrailingPathDelimiter(DataPath);

  wbDataPath := DataPath;
end;


procedure Main;
var
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
  wbRequireLoadOrder := true;
  wbVWDInTemporary := true;

  try
    try
      t := ExtractFileName(ParamStr(0)).ToLowerInvariant;

      wbToolSource := tsPlugins;
      wbToolMode := TwbToolMode.tmConvert;
      wbGameMode := TwbGameMode.gmFNV;
      wbDisplayShorterNames := True;

      wbToolName := GetEnumName(TypeInfo(TwbToolMode), Ord(wbToolMode) );
      Delete(wbToolName, 1 ,2);
      wbSourceName := GetEnumName(TypeInfo(TwbToolSource), Ord(wbToolSource) );
      Delete(wbSourceName, 1 ,2);
      wbAppName := GetEnumName(TypeInfo(TwbGameMode), Ord(wbGameMode) );
      Delete(wbAppName, 1 ,2);

      wbLoadBSAs := False;
      tss := [tsPlugins, tsSaves];
      tms := [tmDump, tmExport];

      if FindCmdLineSwitch('sr') then
        wbSimpleRecords := True;

      wbLanguage := 'English';

      wbGameExeName := '';
      case wbGameMode of
        gmFNV: begin
          wbGameName := 'FalloutNV';
          case wbToolSource of
            tsSaves:   DefineFNVSaves;
            tsPlugins: DefineFNV;
          end;
        end;
        gmFO3: begin
          wbGameName := 'Fallout3';
          case wbToolSource of
            tsSaves:   DefineFO3Saves;
            tsPlugins: DefineFO3;
          end;
        end;
        gmTES3: begin
          wbGameName := 'Morrowind';
          wbLoadBSAs := false;
          tms := [tmDump];
          tss := [tsPlugins];
          DefineTES3;
        end;
        gmTES4: begin
          wbGameName := 'Oblivion';
          case wbToolSource of
            tsSaves:   DefineTES4Saves;
            tsPlugins: DefineTES4;
          end;
        end;
        gmTES5: begin
          wbGameName := 'Skyrim';
          wbGameExeName := 'TESV';
          case wbToolSource of
            tsSaves:   DefineTES5Saves;
            tsPlugins: DefineTES5;
          end;
        end;
        gmEnderal: begin
          wbGameName := 'Enderal';
          wbGameExeName := 'TESV';
          wbGameMasterEsm := 'Skyrim.esm';
          case wbToolSource of
            tsSaves:   DefineTES5Saves;
            tsPlugins: DefineTES5;
          end;
        end;
        gmTES5VR: begin
          wbGameName := 'Skyrim';
          wbGameName2 := 'Skyrim VR';
          wbGameExeName := 'SkyrimVR';
          tss := [tsPlugins];
          case wbToolSource of
            //tsSaves:   DefineTES5Saves;
            tsPlugins: DefineTES5;
          end;
        end;
        gmFO4: begin
          wbGameName := 'Fallout4';
          wbCreateContainedIn := False;
          case wbToolSource of
            tsSaves:   DefineFO4Saves;
            tsPlugins: DefineFO4;
          end;
        end;
        gmFO4VR: begin
          wbGameName := 'Fallout4';
          wbGameExeName := 'Fallout4VR';
          wbGameName2 := 'Fallout4VR';
          wbGameNameReg := 'Fallout 4 VR';
          wbCreateContainedIn := False;
          tss := [tsPlugins];
          case wbToolSource of
            //tsSaves:   DefineFO4Saves;
            tsPlugins: DefineFO4;
          end;
        end;
        gmSSE: begin
          wbGameName := 'Skyrim';
          wbGameExeName := 'SkyrimSE';
          wbGameName2 := 'Skyrim Special Edition';
          case wbToolSource of
            tsSaves:   DefineTES5Saves;
            tsPlugins: DefineTES5;
          end;
        end;
        gmEnderalSE: begin
          wbAppName := 'EnderalSE';
          wbGameName := 'Enderal';
          wbGameExeName := 'SkyrimSE';
          wbGameName2 := 'Enderal Special Edition';
          wbGameNameReg := 'EnderalSE';
          wbGameMasterEsm := 'Skyrim.esm';
          case wbToolSource of
            tsSaves:   DefineTES5Saves;
            tsPlugins: DefineTES5;
          end;
        end;
        gmFO76: begin
          wbGameName := 'Fallout76';
          wbGameNameReg := 'Fallout 76';
          wbGameMasterEsm := 'SeventySix.esm';
          wbCreateContainedIn := False;
          tss := [tsPlugins];
          case wbToolSource of
            tsPlugins: DefineFO76;
          end;
        end;
        gmSF1: begin
          wbGameName := 'Starfield';
          wbCreateContainedIn := False;
          case wbToolSource of
            tsPlugins: DefineSF1;
          end;
        end;
      else
        WriteLn(ErrOutput, 'Application name must contain FNV, FO3, FO4, FO4VR, FO76, SSE, TES4, TES5 or TES5VR to select game.');
        Exit;
      end;

      if wbGameName2 = '' then
        wbGameName2 := wbGameName;

      if wbGameNameReg = '' then
        wbGameNameReg := wbGameName2;

      if wbGameMasterEsm = '' then
        wbGameMasterEsm := wbGameName + csDotEsm;

      if wbGameExeName = '' then
        wbGameExeName := wbGameName;
      wbGameExeName := wbGameExeName + csDotExe;

      if wbGameMode in [gmFO4, gmFO4vr, gmFO76, gmSF1] then
        wbArchiveExtension := '.ba2';

      DoInitPath;
      if (wbToolMode in [tmDump]) and (wbDataPath = '') then // Dump can be run in any directory configuration
        wbDataPath := CheckParamPath;

      wbLoadModules;

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

      if wbGameMode in [gmFO4, gmFO4vr, gmFO76, gmSF1] then
        wbLanguage := 'En';

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

      if wbFindCmdLineParam('l', s) then begin
        wbLanguage := s;
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

        if (s <> '') and not SameText(s, wbLanguage) then
          wbLanguage := s;
      end;

      wbEncodingTrans := wbEncodingForLanguage(wbLanguage, False);

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

      s := ParamStr(ParamCount);

      NeedsSyntaxInfo := False;

      if not FileExists(s) then
        if FileExists(wbDataPath + s) then
          s := wbDataPath + s;

      if not Assigned(wbContainerHandler) then
        wbContainerHandler := wbCreateContainerHandler;

      StartTime := Now;
      ReportProgress('Application name : ' + wbApplicationTitle);
      if Assigned(GroupToSkip) and (GroupToSkip.Count>0) then
        ReportProgress('['+s+']   Excluding groups : '+GroupToSkip.CommaText);
      if Assigned(RecordToSkip) and (RecordToSkip.Count>0) then
        ReportProgress('['+s+']   Excluding records : '+RecordToSkip.CommaText);
      if Assigned(SubRecordToSkip) and (SubRecordToSkip.Count>0) then
        ReportProgress('['+s+']   Excluding SubRecords : '+SubRecordToSkip.CommaText);

      var gameMode := wbGameMode;

      if wbToolMode in [tmDump, tmConvert] then begin

        Masters := TStringList.Create;
        try
          IsLocalized := False;
          wbMastersForFile(s, Masters, gameMode, nil, nil, @IsLocalized);
          if not IsLocalized then
            for i := 0 to Pred(Masters.Count) do begin
              wbMastersForFile(Masters[i], nil, gameMode, nil, nil, @IsLocalized);
              if IsLocalized then
                Break;
            end;
          Masters.Add(ExtractFileName(s));
          if IsLocalized and not wbLoadBSAs and not FindCmdLineSwitch('nobsa') then begin
            for i := 0 to Pred(Masters.Count) do begin
              t := ExtractFilePath(s) + 'Strings\' + ChangeFileExt(Masters[i], '') + '_' + wbLanguage + '.STRINGS';
              if not FileExists(t) then begin
                wbLoadBSAs := True;
                Break;
              end;
            end;
          end;
          if wbLoadBSAs then begin

            if wbLoadAllBSAs then begin
              n := TStringList.Create;
              try
                m := TStringList.Create;
                try
                  bsaCount := 0;
                  if FileExists(wbTheGameIniFileName) then begin
                    if FileExists(wbCustomIniFileName) then
                      bsaCount := FindBSAs(wbTheGameIniFileName, wbCustomIniFileName, wbDataPath, n, m)
                    else
                      bsaCount := FindBSAs(wbTheGameIniFileName, wbDataPath, n, m);
                  end;

                  if (bsaCount > 0) then begin
                    for i := 0 to Pred(n.Count) do begin
                      ReportProgress('[' + n[i] + '] Loading Resources.');
                      wbContainerHandler.AddBSA(MakeDataFileName(n[i], wbDataPath));
                    end;
                  end;
                finally
                  FreeAndNil(m);
                end;
              finally
                FreeAndNil(n);
              end;
            end;

            for i := 0 to Pred(Masters.Count) do begin
              if wbLoadAllBSAs then begin
                n := TStringList.Create;
                try
                  m := TStringList.Create;
                  try
                    if HasBSAs(ChangeFileExt(Masters[i], ''), wbDataPath,
                        wbGameMode in [gmTES5, gmEnderal, gmTES5vr, gmSSE], wbGameMode in [gmTES5, gmEnderal, gmTES5vr, gmSSE], n, m)>0 then begin
                      for j := 0 to Pred(n.Count) do begin
                        ReportProgress('[' + n[j] + '] Loading Resources.');
                        wbContainerHandler.AddBSA(MakeDataFileName(n[j], wbDataPath));
                      end;
                    end;
                  finally
                    FreeAndNil(m);
                  end;
                finally
                  FreeAndNil(n);
                end;
              end else begin
                n := TStringList.Create;
                try
                  m := TStringList.Create;
                  try
                    if HasBSAs(ChangeFileExt(Masters[i], ''), wbDataPath, true, false, n, m)>0 then begin
                      for j := 0 to Pred(n.Count) do begin
                        ReportProgress('[' + n[j] + '] Loading Resources.');
                        wbContainerHandler.AddBSA(MakeDataFileName(n[j], wbDataPath));
                      end;
                    end;
                    m.Clear;
                    n.Clear;
                    if HasBSAs(ChangeFileExt(Masters[i], '')+' - Interface', wbDataPath, true, false, n, m)>0 then begin
                      for j := 0 to Pred(n.Count) do begin
                        ReportProgress('[' + n[j] + '] Loading Resources.');
                        wbContainerHandler.AddBSA(MakeDataFileName(n[j], wbDataPath));
                      end;
                    end;
                    m.Clear;
                    n.Clear;
                    if HasBSAs(ChangeFileExt(Masters[i], '')+' - Localization', wbDataPath, true, false, n, m)>0 then begin
                      for j := 0 to Pred(n.Count) do begin
                        ReportProgress('[' + n[j] + '] Loading Resources.');
                        wbContainerHandler.AddBSA(MakeDataFileName(n[j], wbDataPath));
                      end;
                    end;
                    m.Clear;
                    n.Clear;
                    if HasBSAs(ChangeFileExt(Masters[i], '')+' - Wwise', wbDataPath, false, false, n, m)>0 then begin
                      for j := 0 to Pred(n.Count) do begin
                        ReportProgress('[' + n[j] + '] Loading Resources.');
                        wbContainerHandler.AddBSA(MakeDataFileName(n[j], wbDataPath));
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
          FreeAndNil(Masters);
        end;
      end;

      ReportProgress('[' + wbDataPath + '] Setting Resource Path.');
      wbContainerHandler.AddFolder(wbDataPath);

      wbResourcesLoaded;

      if wbToolMode in [tmDump, tmConvert] then
        _File := wbFile(s, gameMode, High(Integer));

      var aCount: Cardinal := 0;

      with wbModuleByName(wbGameMasterEsm)^ do
        if mfHasFile in miFlags then begin
          b := TwbHardcodedContainer.GetHardCodedDat;
          if Length(b) > 0 then
            wbFile(wbGameExeName, gameMode, 0, wbGameMasterEsm, [fsIsHardcoded], b);
        end;

      ReportProgress('Finished loading record. Starting Dump.');

      ExtractInitialize();

      __FNVMultiLoop3.ExtractFile(_File, aCount, True);

      ExtractFinalize();

      ReportProgress('All Done.');
    except
      on e: Exception do
        ReportProgress('Unexpected Error: <'+e.ClassName+': '+e.Message+'>');
    end;
  finally
//    if DebugHook <> 0 then begin
//      ReportProgress('Press enter to continue...');
//      ReadLn;
//    end;
  end;
end;

end.
