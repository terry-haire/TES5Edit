unit __FNVImportFuctionsTextv2;

//Current Method for Importing data

interface

uses
  wbInterface,
  converterFileManager;

type
  TFuncType = function(aFileName: string; aIsESL: Boolean): IwbFile of object;

function FNVImportInitialize(Files: TwbFiles; AddNewFileName: TFuncType; fromCSVs: Boolean = True; FromFile: IwbFile = nil): integer;
function FNVImportFinalize: integer;
procedure AssignConvertedData(
  _Signature: string;
  ToFileManaged: TConverterManagedFile;
  ToFile: IwbFile;
  rec: IwbContainer;
  originalloadorder: string;
  fileloadorder: string;
  originalFormID: string;
  var newrec: IwbContainer;
  var OriginRec1: IwbContainer;
  var OriginRec2: IwbContainer;
  elementpathstring: string;
  elementvaluestring: string;
  elementinteger: string;
  elementisflag: string;
  elementnewrec: string
);

implementation
uses
  __ScriptAdapterFunctions,
  Classes,
  SysUtils,
  StrUtils,
  Windows,
  wbImplementation,
  System.RegularExpressions,
  __FNVImportCleanup,
  __FNVMultiloop3;

var
/// Lookup Lists
slPathsLookup,
slTemporaryDelimited,
slEntryLength,
slShortLookup,
slShortLookupPos,

/// Columns
slSingleValues,
slNewRec,
slNewRecSig,
slSingleRec,
slOldNewValMatch,
slNewPathorOrder,
slOldVal,
slNewVal,
slOldIndex,
slNewIndex,
slReplaceAnyVal,
slReplaceAnyIndex,
slIsFlag,

/// Sources
slfilelist,

/// Logs
slloadorders,
slReferences,
slfailed,
slrecordconversions,
slFileExtensions: TStringList;

//fileToMasterLoToCurrentLo:

previousrec, previousrec2: IwbContainer;
debugmode, ExitAfterFail, SaveOnExit, OverwriteRecs: Boolean;
iAliasCounter: Integer;
_Files: TwbFiles;

function FileByLoadOrder(Files: TwbFiles; loadOrder: Integer): IwbFile;
var
  i: Integer;
begin
  for i := Low(Files) to High(Files) do
    if Files[i].LoadOrder = loadOrder then begin
      Result := Files[i];

      Exit;
    end;
end;

function GetNewRecEDID(const rec: IwbMainRecord; const elementnewrec: String): String;
begin
  Result := GetFileName(GetFile(rec));
  Result := Copy(Result, 1, (LastDelimiter('.', Result) - 1)) + '_';
  Result := Result + elementnewrec + '_' + Copy(IntToHex(FormID(rec), 8), 3, 6);
  Result := Result + '_' + EditorID(rec);
end;

function OccurrencesOfChar(const S: string; const C: char): integer;
var
  i: Integer;
begin
  result := 0;
  for i := 1 to Length(S) do
    if S[i] = C then
      inc(result);
end;

function AddAlias(const rec: IwbContainer; const val: String): String;
var
rRef: IwbMainRecord;
rAlias, rContainer: IwbContainer;
s: String;
begin
  /// ElementValueString needs to be formatted to formid
  rContainer := ElementByPath(rec, 'Aliases') as IwbContainer;

  rRef := RecordByFormID(GetFile(rec), TwbFormID.FromCardinal(StrToInt('$' + val)), True);
  if Assigned(rContainer) then
    rAlias := ElementAssign(rContainer, MaxInt, Nil, False) as IwbContainer
  else
  begin
    rContainer := Add(rec, 'Aliases', True) as IwbContainer;
    rAlias := ElementByIndex(rContainer, 0) as IwbContainer;
  end;
  if Assigned(rAlias) then
  begin
    SetEditValue(Add(rAlias, 'ALST', True), IntToStr(iAliasCounter));
    if Assigned(rRef) then
    begin
      if GetFileName(GetFile(rRef)) = GetFileName(GetFile(rec)) then
      begin
        /// Set Target May have to change element path
        s := Signature(rRef);
        SetEditValue(Add(rAlias, 'ALFR', True), val);
      end;
    end;
  end;
  Result := IntToStr(iAliasCounter);
  Inc(iAliasCounter);
end;

procedure AddElementData(
  StartingRow: Integer;
  EndingRow: Integer;
  elementvaluestring: String;
  elementinteger: String;

  _Signature: string;
  ToFileManaged: TConverterManagedFile;
  ToFile: IwbFile;
  rec: IwbContainer;
  originalloadorder: string;
  fileloadorder: string;
  originalFormID: string;
  var newrec: IwbContainer;
  var OriginRec1: IwbContainer;
  var OriginRec2: IwbContainer
);
var
k, l: Integer;
NewPath, NewVal, NewIndex, NewRecStr, IsFlag: String;
begin
  NewVal := elementvaluestring;
  for k := StartingRow to EndingRow do
  begin
    if slNewPathorOrder[k] <> '' then
    begin
      if NewPath <> '' then
      begin
//        if NewVal = '' then
//          NewVal := elementvaluestring;
        if NewIndex = '' then
          NewIndex := elementinteger;
        if IsFlag = '' then
          IsFlag := 'FALSE';
//        NewPath := '';
        //NewVal := elementvaluestring;
//        NewRec := '';
//        IsFlag := '';

        wbGameMode := gmFO4;
        AssignConvertedData(
          _Signature,
          ToFileManaged,
          ToFile,
          rec,
          originalloadorder,
          fileloadorder,
          originalFormID,
          newrec,
          OriginRec1,
          OriginRec2,
          NewPath,
          NewVal,
          NewIndex,
          IsFlag,
          NewRecStr
        );
        wbGameMode := gmFNV;
      end;
      NewPath := slNewPathorOrder[k];
    end;
    if slReplaceAnyVal[k] = 'TRUE' then
      NewVal := slNewVal[k];
    if slOldVal[k] = 'File' then
      if slNewVal[k] = 'File' then
      begin
        NewVal := elementvaluestring;
        if AnsiPos('.', elementvaluestring) <> 0 then
          for l := 0 to (slFileExtensions.Count - 1) do
          begin
            if LowerCase(Copy(elementvaluestring, LastDelimiter('.', elementvaluestring), MaxInt)) = slFileExtensions[l] then
            begin
              if slFileExtensions[l] = '.mp3' then
                NewVal := Copy(elementvaluestring, 1, (LastDelimiter('.', elementvaluestring) - 1)) + '.xwm';
              if slFileExtensions[l] = '.kf' then
                NewVal := Copy(elementvaluestring, 1, (LastDelimiter('.', elementvaluestring) - 1)) + '.hkx';
              if slFileExtensions[l] = '.egt' then
                NewVal := Copy(elementvaluestring, 1, (LastDelimiter('.', elementvaluestring) - 1)) + '.ssf';
              if slFileExtensions[l] = '.psa' then
                NewVal := Copy(elementvaluestring, 1, (LastDelimiter('.', elementvaluestring) - 1)) + '.hkx'; // Death pose
              // Missing speedtree (.spt)
            end;
          end;
        NewVal := 'new_vegas\' + NewVal;
      end;
    if elementvaluestring = slOldVal[k] then
      NewVal := slNewVal[k];
    if elementinteger = slOldIndex[k] then
    begin
      NewIndex := slNewIndex[k];
    end;
    if slNewIndex[k] <> '' then
    begin
      if slReplaceAnyIndex[k] <> 'TRUE' then
        NewIndex := slNewIndex[k];
    end;
    if slIsFlag[k] = 'TRUE' then
    begin
      IsFlag := 'TRUE';
    end;
    NewRecStr := slNewRec[k];
    if AnsiPos('#0', NewPath) <> 0 then
    begin
      if ((OccurrencesOfChar(NewPath, '#') = 1)
      AND (AnsiPos('Parameter #', NewPath) = 0)
      AND (AnsiPos('Attribute #', NewPath) = 0)
      AND (AnsiPos('Skill #', NewPath) = 0)
      AND (AnsiPos('Voice #', NewPath) = 0)
      AND (AnsiPos('Default Hair Style #', NewPath) = 0)
      AND (AnsiPos('Default Hair Color #', NewPath) = 0)
      AND (AnsiPos('ANAM\Related Camera Path #', NewPath) = 0)
      AND (AnsiPos('DATA\Particle Shader - Initial Velocity #', NewPath) = 0)
      AND (AnsiPos('DATA\Particle Shader - Acceleration #', NewPath) = 0)
      AND (AnsiPos('ANAM\Related Idle Animation #', NewPath) = 0)
      AND (AnsiPos('XORD\Plane #', NewPath) = 0)
      AND (AnsiPos('XPOD\References #', NewPath) = 0)
      AND (AnsiPos('NAM0\Type #', NewPath) = 0)
      ) then
      begin
        NewPath := StringReplace(NewPath, '#0', ('#' + elementinteger), [rfIgnoreCase]);
        elementinteger := IntToStr(MaxInt);
        if NewIndex <> '' then
        begin
          if NewIndex = '-2' then
            NewPath := '';
        end
        else
          NewIndex := IntToStr(MaxInt);
      end;
    end;
  end;
//  if NewVal = '' then
//    NewVal := elementvaluestring;
  if NewIndex = '' then
    NewIndex := elementinteger;
  if IsFlag = '' then
    IsFlag := 'FALSE';

  wbGameMode := gmFO4;
  AssignConvertedData(
    _Signature,
    ToFileManaged,
    ToFile,
    rec,
    originalloadorder,
    fileloadorder,
    originalFormID,
    newrec,
    OriginRec1,
    OriginRec2,
    NewPath,
    NewVal,
    NewIndex,
    IsFlag,
    NewRecStr
  );
  wbGameMode := gmFNV;
end;

function Build_slstring(
  elementpathstring: String;
  elementvaluestring: String;
  elementinteger: String;

  _Signature: string;
  ToFileManaged: TConverterManagedFile;
  ToFile: IwbFile;
  rec: IwbContainer;
  originalloadorder: string;
  fileloadorder: string;
  originalFormID: string;
  var newrec: IwbContainer;
  var OriginRec1: IwbContainer;
  var OriginRec2: IwbContainer
): TStringList;
var
i, j, StartingRow, EndingRow: Integer;
begin
//      if elementpathstring = 'Parent\PNAM\Use Map Data' then
//      begin
//        AddMessage(elementpathstring);
//        for i := 0 to (slShortLookup.Count - 1) do
//          AddMessage(slShortLookup[i]);
//      end;
  Result := TStringList.Create;
  j := -1;
  for i := 0 to (slShortLookup.Count - 1) do
    if AnsiPos(slShortLookup[i], elementpathstring) <> 0 then
    begin
      j := StrToInt(slShortLookupPos[i]);
      Break;
    end;
  if j <> -1 then
  for i := j to (slPathsLookup.Count - 1) do
  begin
    if slPathsLookup[i] = elementpathstring then
    begin
      StartingRow := StrToInt(slEntryLength[i]);
      if i < (slPathsLookup.Count - 1) then
        EndingRow := (StrToInt(slEntryLength[(i + 1)]) - 1)
      else
        EndingRow := (slNewRec.Count - 1);
      //////////////////////////////////////////////////////////////////////////
      ///  Empty New Path
      //////////////////////////////////////////////////////////////////////////
//      AddMessage(IntToStr(slNewPathorOrder.Count));
      if StartingRow > (slNewPathorOrder.Count - 1) then
        Exit;
      if slNewPathorOrder[StartingRow] = '' then
      begin
        if i = (slPathsLookup.Count - 1) then
          Exit
        else
        begin
          elementpathstring := '';
          Continue;
        end;
      end;
      if slNewRec[StartingRow] <> '1' then
      begin
        AddElementData(
          StartingRow,
          EndingRow,
          elementvaluestring,
          elementinteger,

          _Signature,
          ToFileManaged,
          ToFile,
          rec,
          originalloadorder,
          fileloadorder,
          originalFormID,
          newrec,
          OriginRec1,
          OriginRec2
        );
      end;
      Exit;
    end;
  end;

  wbGameMode := gmFO4;
  AssignConvertedData(
    _Signature,
    ToFileManaged,
    ToFile,
    rec,
    originalloadorder,
    fileloadorder,
    originalFormID,
    newrec,
    OriginRec1,
    OriginRec2,
    elementpathstring,
    elementvaluestring,
    elementinteger,
    'FALSE',
    ''
  );
  wbGameMode := gmFNV;
end;

function formatelementpath(elementpathstring: String): String;
var
pos1, pos2: integer;
originalpath: String;
begin
  originalpath := elementpathstring;
	if ((ansipos(' - ', elementpathstring) <> 0) AND (ansipos('\', elementpathstring) <> 0)) then
	begin
		pos1 := ansipos(' - ', elementpathstring);
		pos2 := ansipos('\', copy(elementpathstring, pos1, MaxInt));
		if pos2 = 0 then elementpathstring := copy(elementpathstring, 1, (pos1 - 1))
		else elementpathstring := copy(elementpathstring, 1, (pos1 - 1)) + copy(elementpathstring, (pos1 + pos2 - 1),  MaxInt);
		formatelementpath(elementpathstring);
	end
	else
	if ((ansipos(' - ', elementpathstring) <> 0) AND (ansipos('\', elementpathstring) = 0)) then
	begin
		elementpathstring := copy(elementpathstring, 1, (ansipos(' - ', elementpathstring) - 1));
		formatelementpath(elementpathstring);
	end;
	elementpathstring := stringreplace(elementpathstring, ' \ ', '\', [rfReplaceAll]);
	elementpathstring := stringreplace(elementpathstring, '\ ', '\', [rfReplaceAll]);
//	elementpathstring := stringreplace(elementpathstring, 'Destructable', 'Destructible', [rfReplaceAll]);
	if ansipos('Record Flags\NavMesh Generation', elementpathstring) <> 0 then
	begin
		elementpathstring := elementpathstring + copy(originalpath, (ansipos('NavMesh Generation', originalpath) + 18), MaxInt);
		if ansipos('(0x', elementpathstring) <> 0 then elementpathstring := copy(elementpathstring, 1, (ansipos('(0x', elementpathstring) - 2));
	end;
	if ansipos('(0x', elementpathstring) <> 0 then elementpathstring := copy(elementpathstring, 1, (ansipos('(0x', elementpathstring) - 2));
  if ansipos('NVEX\Connection #', elementpathstring) <> 0 then elementpathstring := '';
  if ansipos('NVDP\Door #', elementpathstring) <> 0 then elementpathstring := '';
	Result := elementpathstring;

end;

function CheckForErrors(element: IwbContainer): String;
var
i: Integer;
elementNext: IwbElement;
elementcur: IwbContainer;
begin
	for i := 0 to (ElementCount(element)-1) do
	begin
    elementNext := ElementByIndex(element, i);
    Result := Check(elementNext);

    if Result <> '' then begin
      if AnsiPos('Record Header', Path(elementNext)) = 0 then
      begin
        Result := formatelementpath(Path(elementNext)) + #13#10 + Result;
        Exit;
      end;
    end;

    if Supports(elementNext, IwbContainer, elementcur) and (ElementCount(elementcur) > 0) then
        Result := CheckForErrors(elementcur);
	end;
end;

function ExitSequence(const _rec: IwbContainer; const _cont: IwbContainer; const _formid: String; const _path: String; const _value: String; const _integer: String; const _flag: String): Integer;
begin
  var showNonCriticalErrors := False;

  if showNonCriticalErrors then begin
    AddMessage('FAILED');
    AddMessage('PATH     : ' + _path);
    AddMessage('VALUE    : ' + _value);
    AddMessage('INTEGER  : ' + _integer);
    AddMessage('ISFLAG   : ' + _flag);

    if Assigned(_cont) then
      AddMessage('CONTPATH : ' + Copy(formatelementpath(Path(_cont)), 6, MaxInt))
    else
      AddMessage('Container not Assigned');

    if Assigned(_rec) then
      AddMessage(Name(_rec))
    else
      AddMessage('Record not Assigned');
  end;

	slfailed.Add(_formid + ';' + _integer + ';' + _path); // formid + elementpathstring

  if (SaveOnExit AND ExitAfterFail) then begin
    slReferences.SaveToFile(wbProgramPath + 'data\' + '__ReferenceList.csv');
	  slfailed.SaveToFile(wbProgramPath + 'data\' + '__FailedList.csv');
	  slloadorders.SaveToFile(wbProgramPath + 'data\' + '__Loadorders.csv');
  end;

  if ExitAfterFail then
    Result := 1
  else
    Result := 0;

//  raise Exception.Create('Error occured');
end;

function RetrieveIndexPath(s: String): String;
var
i: Integer;
begin
  i := ansipos(']\[', s);
  if i <> 0 then s := Copy(s, (i + 3), MaxInt);
  i := ansipos('\[', s);
  if i <> 0 then
  begin
    i := ansipos('\[', s);
    if ((i <> 0) AND (i < AnsiPos(']', s))) then
      s := Copy(s, 1, LastDelimiter(';', s)) + Copy(s, (i + 2), MaxInt);
    i := ansipos('\[', s);
    if ((i <> 0) AND (i > AnsiPos(']', s))) then
    begin
      s := Copy(s, 1, (AnsiPos(']', s) - 1)) + ';' + Copy(s, ansipos('\[', s), MaxInt);
      s := RetrieveIndexPath(s);
    end
    else s := Copy(s, 1, (AnsiPos(']', s) - 1));
  end;
  if AnsiPos(']', s) <> 0 then s := Copy(s, 1, (AnsiPos(']', s) - 1));
  if s = '' then
  begin
    AddMessage('Warning: RetrieveIndexPath returned nothing');
    s := '0'
  end;
  Result := s;
end;

/// Before ElementPathstring check
//function CreateElementCTDA(

procedure AssignRecordFlagByName(subrec_container: IwbContainer; elementpathstring: string);
var
  flagDef: IwbFlagDef;
  flagsDef: IwbFlagsDef;
  aname: string;
begin
  if not Supports(subrec_container.ValueDef, IwbFlagsDef, flagsDef) then
    Exit;

  aname := Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt);

  flagsDef.FindFlag(aname, flagDef);

  flagsDef.FindFlag(aname, flagDef);
end;

procedure AssignRecordFlag(elementinteger: integer; subrec_container: IwbContainer; elementpathstring: string);
var
  elementvaluestring: string;
  k: integer;
  subrec: IwbElement;
begin
  if elementinteger = 0 then begin
    raise Exception.Create('Record flag index is 0');
  end;

  elementvaluestring := GetEditValue(subrec_container);

  if Length(elementvaluestring) < elementinteger then begin
    if elementinteger - Length(elementvaluestring) <> 1 then begin
      for k := Length(elementvaluestring) to (elementinteger - 2) do
        elementvaluestring := elementvaluestring + '0';

      elementvaluestring := elementvaluestring + '1';
    end else
      elementvaluestring := elementvaluestring + '1';
  end else begin
    elementvaluestring[elementinteger] := '1';
  end;

  SetEditValue(subrec_container, elementvaluestring);

  elementvaluestring := '';
  subrec := ElementByPath(subrec_container, Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt));
//      AddMessage(GetElementEditValues(rec, 'Record Header\Record Flags'));

  if not Assigned(subrec) or (elementpathstring <> formatelementpath(Copy(Path(subrec), 8, MaxInt))) and
      (formatelementpath(Copy(Path(subrec), 8, MaxInt)) <> 'Record Header\Record Flags\NavMesh Generation') then
//    raise Exception.Create('Failed to assign record flag');
    AddMessage('Failed to assign record flag');
end;

procedure CreateElementQuick1(const rec: IwbContainer; const elementpathstring: String; const elementvaluestring: String; ToFileManaged: TConverterManagedFile);
var
subrec: IwbElement;
begin
  subrec := Add(rec, elementpathstring, True);

  if not Assigned(subrec) then
    subrec := rec.ElementByPath[elementpathstring];

  if not Assigned(subrec) then begin
    if (elementpathstring = 'XCLP') or (elementpathstring = 'XCHG') then begin
      Exit;
    end;

//    raise Exception.Create('Could not make element');
    Exit;
  end;

  if (elementpathstring = 'XTRI') then begin
    Exit;
  end else if (elementpathstring = 'XRGB') then begin
    Exit;
  end;

  // Invalid ref in FNV?
  if (elementpathstring = 'NAME') and (
    (elementvaluestring = '010A1A9D') or
    (elementvaluestring = '01174163') or
    (elementvaluestring = '0106BC6A') or
    (elementvaluestring = '01047B54') or
    (elementvaluestring = '0110C4A7') or
    (elementvaluestring = '01174130') or
    (elementvaluestring = '0111B9C6') or
    (elementvaluestring = '01025E88')
  ) then
    // PASS
  else if not subrec.IsEditable then begin
    if elementvaluestring = '' then begin
      // PASS
    end else if elementpathstring = 'Cell' then begin
      if subrec.NativeValue <> StrToInt('$' + elementvaluestring) then
        raise Exception.Create('Cell value does not match');
    // NOTE: Was working in previous version.
    end else if elementpathstring = 'XRGD' then
      // PASS
    else
      raise Exception.Create('Element not editable');
  end else begin
    if (elementpathstring = 'NAME') and (elementvaluestring <> '' ) and not Assigned(ToFileManaged.RecordByNewFormIDHex(elementvaluestring)) then begin
      // PASS
      AddMessage('Reference not found: ' + elementvaluestring);
    end else begin
      if (elementvaluestring = '') or ((elementpathstring = 'NAME') and (Signature(ToFileManaged.RecordByNewFormIDHex(elementvaluestring)) = 'SNDR')) then begin
        Exit;
      end;

      try
        SetEditValue(subrec, elementvaluestring);
      except
        On E :Exception do
        begin
          if Copy(E.Message, 12, MaxInt) <> '< Error: Could not be resolved >' then
          begin
            AddMessage('Failed to set edit value: ' + E.Message);
          end;
        end;
      end;
    end;
  end;
  previousrec := subrec as IwbContainer;
end;

function StartsWith(const Str, Prefix: string): Boolean;
begin
  Result := Copy(Str, 1, Length(Prefix)) = Prefix;
end;

procedure AssignElementByPath(container: IwbContainer; path: string);
var
  containerRef: IwbContainerElementRef;
  i: integer;
begin

    container.ElementByPath[path];
//    container.ResolvedValueDef;
//    containerRef := container as IwbContainerElementRef;
//    //DoInit(True);
//
//    for i := 0 to Pred(containerRef.ElementCount) do
//      if SameText(mrDef.Members[i].Name, aName) or SameText(mrDef.Members[i].DefaultSignature, aName) then begin
//        Result := GetElementBySortOrder(i + GetAdditionalElementCount);
//        if not Assigned(Result) then begin
//          Assign(i, nil, False);
//          Result := GetElementBySortOrder(i + GetAdditionalElementCount);
//
//          if wbSortSubRecords and (Length(cntElements) > 1) then
//            wbMergeSortPtr(@cntElements[0], Length(cntElements), CompareSubRecords);
//        end;
//
//        Exit;
//      end;
end;

////////////////////////////////////////////////////////////////////////////////
///  Procedure for Creating and modifying Elements
////////////////////////////////////////////////////////////////////////////////
function CreateElement(
  rec: IwbContainer;
  originalloadorder: String;
  fileloadorder: String;
  elementpathstring: String;
  elementvaluestring: String;
  elementinteger: integer;
  elementisflag: String;
  ToFileManaged: TConverterManagedFile;
  originalFormID: String
): Integer;
var
subrec: IwbElement;
subrec_container: IwbContainer;
containerpathstring: String;
k: integer;
begin
  Result := 0;

  //////////////////////////////////////////////////////////////////////////////
  ///  Temp solution for snam
  //////////////////////////////////////////////////////////////////////////////
  if elementpathstring = 'SNAM' then
    if elementvaluestring = '' then
      elementpathstring := '';

  //////////////////////////////////////////////////////////////////////////////
  ///  Temp solution for CREA RNAM
  //////////////////////////////////////////////////////////////////////////////
  if elementpathstring = 'RNAM' then
    if Signature(rec.ContainingMainRecord) = 'NPC_' then
    begin
		  if Length(elementvaluestring) <> 8 then
        elementpathstring := '';
    end;

  if Signature(rec.ContainingMainRecord) = 'REGN' then
    if elementpathstring = 'WNAM' then
      if elementvaluestring = '' then
        elementpathstring := '';

  if Signature(rec.ContainingMainRecord) = 'WATR' then
    if elementpathstring = 'TNAM' then
      if elementvaluestring = '' then
        elementpathstring := '';

  // Ignore MODT (seems to be for referring to BSA in new vegas?)
  if StartsWith(elementpathstring, 'Model\MODT') then
    elementpathstring := '';

  if elementpathstring = 'Destructible\DEST\Unused' then
    elementpathstring := ''
  else if elementpathstring = 'Destructible\Stages\Stage\Model' then
    elementinteger := 2
  else if elementpathstring = 'Destructible\Stages\Stage\DSTF' then
    elementinteger := 3
  else if elementpathstring = 'Destructible\Stages\Stage\Model\DMDT\Texture #0' then begin

//    AssignElementByPath(rec, 'Destructible\Stages\Stage\Model\DMDT\Textures');
//    previousrec := rec.ElementByPath['Destructible\Stages\Stage\Model\DMDT\Textures'] as IwbContainer;
//    rec.AddIfMissing(previousrec, False);
    elementpathstring := 'Destructible\Stages\Stage\Model\DMDT\Textures\Texture #0'
  end else if AnsiPos('Conditions\Condition\CTDA\', elementpathstring) <> 0 then begin
    Exit;
  end else if StartsWith(elementpathstring, 'Radial Blur\') then begin
    Exit;
  end else if StartsWith(elementpathstring, 'HDR\') then begin
    Exit;
  end else if StartsWith(elementpathstring, 'Cinematic\') then begin
    Exit;
  end else if StartsWith(elementpathstring, 'DNAM\') then begin
    Exit;
  end else if StartsWith(elementpathstring, 'Magic Effect Data\DATA\Actor Value') then begin
    Exit;
  end else if StartsWith(elementpathstring, 'Effects\Effect\DATA\') then begin
    Exit;
  // Invalid ref in NV source esm?
  end else if (elementpathstring = 'WNAM') and (elementvaluestring = '[0002F222] <Error: Could not be resolved>') then begin
    Exit;
  end else if (elementpathstring = 'WNAM') and (AnsiPos('<Error: Could not be resolved>', elementvaluestring) <> 0) then begin
    Exit;
  end else if (elementpathstring = 'Region Data Entries\Region Data Entry\RDSA\Sound\Sound') and (AnsiPos('<Error: Could not be resolved>', elementvaluestring) <> 0) then begin
    Exit;
  end else if (elementpathstring = 'Sounds\SNAM\Sound') and (AnsiPos('<Error: Could not be resolved>', elementvaluestring) <> 0) then begin
    Exit;
  end else if elementpathstring = 'Destructible\Stages\Stage\DSTD\Flags\Destroy' then begin
    elementisflag := 'TRUE';
    elementinteger := 3;
  end else if StartsWith(elementpathstring, 'Textures (RGB/A)\') and (Signature(rec.ContainingMainRecord) = 'TXST') then begin
    elementvaluestring := 'new_vegas\' + elementvaluestring;
  end else if StartsWith(elementpathstring, 'Parent\PNAM\Flags\Needs Water Adjustment') then begin
    Exit;
  end else if (elementpathstring = 'XCLR\Region') and (elementvaluestring = '[REFR:0006D4AB] (places RockCanyonRockPile01rad349 [STAT:000464C9] in GRUP Cell Temporary Children of [CELL:00000F73] (in Wasteland "Wasteland" [WRLD:0000003C] at -15,10))')  then begin
    Exit;
  end else if (elementpathstring = 'XCCM') and (elementvaluestring = 'WastelandClimate [CLMT:00017907]')  then begin
    Exit;
  end else if (StartsWith(elementpathstring, 'Layers\') and ((AnsiPos('[LVLN:', elementvaluestring) <> 0) or (AnsiPos('[REFR:', elementvaluestring) <> 0)))  then begin
    Exit;
  end;

  //////////////////////////////////////////////////////////////////////////////
  ///  Temp Solution for Conditions
  //////////////////////////////////////////////////////////////////////////////
  if AnsiPos('Conditions\Condition\CTDA\', elementpathstring) <> 0 then
  begin
    if ((Name(previousrec) = 'Effects') OR (Name(previousrec) = 'Conditions')) then
      elementpathstring := '';
    if not Assigned(previousrec) then elementpathstring := '';
    if Name(previousrec) = 'CTDA - ' then
      subrec_container := previousrec;
    if Name(GetContainer(previousrec)) = 'CTDA - ' then
      subrec_container := GetContainer(previousrec);
    if Assigned(subrec_container) then
    begin
      if GetElementEditValues(subrec_container, 'Function') = 'GetWantBlocking' then
      begin
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementpathstring := '';
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementpathstring := '';
      end;
      if GetElementEditValues(subrec_container, 'Function') = 'HasPerk' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementinteger := 5;
      if GetElementEditValues(subrec_container, 'Function') = 'HasPerk' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementpathstring := '';
      if GetElementEditValues(subrec_container, 'Function') = 'GetIsID' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementinteger := 5;
      if GetElementEditValues(subrec_container, 'Function') = 'GetIsID' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'GetIsReference' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementinteger := 5;
      if GetElementEditValues(subrec_container, 'Function') = 'GetIsReference' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'GetItemCount' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementinteger := 5;
      if GetElementEditValues(subrec_container, 'Function') = 'GetItemCount' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'GetVATSValue' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementpathstring := '';
      if GetElementEditValues(subrec_container, 'Function') = 'GetVATSValue' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementpathstring := '';
      if GetElementEditValues(subrec_container, 'Function') = 'GetWantBlocking' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Comparison Value' then
        begin
          try
            StrToInt(elementvaluestring);
          except
            elementvaluestring := '';
          end;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetVMQuestVariable' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
        begin
          elementinteger := 5;
          if elementvaluestring = 'NULL - Null Reference [00000000]' then
          begin
            elementpathstring := '';
            SetElementEditValues(subrec_container, 'Function', 'GetWantBlocking');
          end;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetVMQuestVariable' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
        begin
          elementpathstring := '';
          elementinteger := 6;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetInCell' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
        begin
          elementinteger := 5;
          if elementvaluestring = 'NULL - Null Reference [00000000]' then elementvaluestring := 'aaaMarkers "Marker Cell" [CELL:F4058955]';
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetInCell' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'GetDead' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementinteger := 5;
      if GetElementEditValues(subrec_container, 'Function') = 'GetDead' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'GetLocked' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementinteger := 5;
      if GetElementEditValues(subrec_container, 'Function') = 'GetLocked' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'GetDisabled' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementinteger := 5;
      if GetElementEditValues(subrec_container, 'Function') = 'GetDisabled' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'GetInWorldspace' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
        begin
          elementinteger := 5;
          if elementvaluestring = 'NULL - Null Reference [00000000]' then
          begin
            elementpathstring := '';
            SetElementEditValues(subrec_container, 'Function', 'GetWantBlocking');
          end;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetInWorldspace' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
        begin
          elementpathstring := '';
          elementinteger := 6;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetUnconscious' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementinteger := 5;
      if GetElementEditValues(subrec_container, 'Function') = 'GetUnconscious' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'GetDeadCount' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
        begin
          elementinteger := 5;
          if elementvaluestring = 'NULL - Null Reference [00000000]' then
          begin
            elementpathstring := '';
            SetElementEditValues(subrec_container, 'Function', 'GetWantBlocking');
          end;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetDeadCount' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
        begin
          elementpathstring := '';
          elementinteger := 6;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetObjectiveCompleted' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementinteger := 5;
      if GetElementEditValues(subrec_container, 'Function') = 'GetObjectiveCompleted' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
        begin
          elementvaluestring := '';
          elementinteger := 6;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetObjectiveDisplayed' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementinteger := 5;
      if GetElementEditValues(subrec_container, 'Function') = 'GetObjectiveDisplayed' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
        begin
          elementvaluestring := '';
          elementinteger := 6;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetDestructionStage' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementinteger := 5;
      if GetElementEditValues(subrec_container, 'Function') = 'GetDestructionStage' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'GetPos' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementinteger := 5;
      if GetElementEditValues(subrec_container, 'Function') = 'GetPos' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'GetGlobalValue' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementinteger := 5;
      if GetElementEditValues(subrec_container, 'Function') = 'GetGlobalValue' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'GetIsCreatureType' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
        begin
          elementvaluestring := '';
          elementinteger := 5;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetIsCreatureType' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'GetEquipped' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementinteger := 5;
      if GetElementEditValues(subrec_container, 'Function') = 'GetEquipped' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'GetValue' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
        begin
          elementvaluestring := '';
          elementinteger := 5;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetValue' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'IsInCombat' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
        begin
          elementvaluestring := '';
          elementinteger := 5;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'IsInCombat' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'GetIsUsedItemType' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementinteger := 5;
      if GetElementEditValues(subrec_container, 'Function') = 'GetIsUsedItemType' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'GetStage' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
        begin
          elementinteger := 5;
          if elementvaluestring = 'NULL - Null Reference [00000000]' then
          begin
            elementpathstring := '';
            SetElementEditValues(subrec_container, 'Function', 'GetWantBlocking');
          end;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetStage' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
        begin
          elementpathstring := '';
          elementinteger := 6;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetQuestRunning' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
        begin
          elementinteger := 5;
          if elementvaluestring = 'NULL - Null Reference [00000000]' then
          begin
            elementpathstring := '';
            SetElementEditValues(subrec_container, 'Function', 'GetWantBlocking');
          end;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetQuestRunning' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
        begin
          elementpathstring := '';
          elementinteger := 6;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetQuestCompleted' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
        begin
          elementinteger := 5;
          if elementvaluestring = 'NULL - Null Reference [00000000]' then
          begin
            elementpathstring := '';
            SetElementEditValues(subrec_container, 'Function', 'GetWantBlocking');
          end;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetQuestCompleted' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
        begin
          elementpathstring := '';
          elementinteger := 6;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetFactionReaction' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
        begin
          elementinteger := 5;
          if elementvaluestring = 'NULL - Null Reference [00000000]' then
          begin
            elementpathstring := '';
            SetElementEditValues(subrec_container, 'Function', 'GetWantBlocking');
          end;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetFactionReaction' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
        begin
          elementinteger := 6;
          if elementvaluestring = 'NULL - Null Reference [00000000]' then
          begin
            elementpathstring := '';
            SetElementEditValues(subrec_container, 'Function', 'GetWantBlocking');
          end;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetStageDone' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
        begin
          elementinteger := 5;
          if elementvaluestring = 'NULL - Null Reference [00000000]' then
          begin
            elementpathstring := '';
            SetElementEditValues(subrec_container, 'Function', 'GetWantBlocking');
          end;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetStageDone' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
          if elementvaluestring = '0 <Warning: Could not resolve Parameter 1>' then
            elementpathstring := '';
      if GetElementEditValues(subrec_container, 'Function') = 'GetFactionReaction' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
        begin
          elementvaluestring := '';
          elementinteger := 5;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetFactionReaction' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
        begin
          elementvaluestring := '';
          elementinteger := 6;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'IsWeaponSkillType' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
        begin
          elementvaluestring := '';
          elementinteger := 5;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'IsWeaponSkillType' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
        begin
          elementvaluestring := '';
          elementinteger := 6;
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetPermanentValue' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
        begin
          elementinteger := 5;
          if elementvaluestring = 'Strength'      then elementvaluestring := 'Strength "Strength" [AVIF:F40002C2]';
          if elementvaluestring = 'Perception'    then elementvaluestring := 'Perception "Perception" [AVIF:F40002C3]';
          if elementvaluestring = 'Endurance'     then elementvaluestring := 'Endurance "Endurance" [AVIF:F40002C4]';
          if elementvaluestring = 'Charisma'      then elementvaluestring := 'Charisma "Charisma" [AVIF:F40002C5]';
          if elementvaluestring = 'Intelligence'  then elementvaluestring := 'Intelligence "Intelligence" [AVIF:F40002C6]';
          if elementvaluestring = 'Agility'       then elementvaluestring := 'Agility "Agility" [AVIF:F40002C7]';
          if elementvaluestring = 'Luck'          then elementvaluestring := 'Luck "Luck" [AVIF:F40002C8]';
          if elementvaluestring = 'Survival'      then elementvaluestring := '';
          if elementvaluestring = 'Explosives'    then elementvaluestring := '';
          if elementvaluestring = 'Sneak'         then elementvaluestring := '';
          if elementvaluestring = 'Science'      then elementvaluestring := '';
          if elementvaluestring = 'Melee Weapons'      then elementvaluestring := '';
          if elementvaluestring = 'Unarmed'      then elementvaluestring := '';
          if elementvaluestring = 'Energy Weapons'      then elementvaluestring := '';
          if elementvaluestring = 'Guns'      then elementvaluestring := '';
          if elementvaluestring = 'Lockpick'      then elementvaluestring := '';
          if elementvaluestring = 'Medicine'      then elementvaluestring := '';
          if elementvaluestring = 'Speech'      then elementvaluestring := '';
          if elementvaluestring = 'Barter'      then elementvaluestring := '';
          if elementvaluestring = 'Repair'      then elementvaluestring := '';
          if elementvaluestring = 'Survival'      then elementvaluestring := '';
          if elementvaluestring = 'Survival'      then elementvaluestring := '';
          if elementvaluestring = 'Survival'      then elementvaluestring := '';
          if elementvaluestring = 'Survival'      then elementvaluestring := '';
          if elementvaluestring = 'Survival'      then elementvaluestring := '';
          if elementvaluestring = 'Survival'      then elementvaluestring := '';
          if elementvaluestring = 'Survival'      then elementvaluestring := '';
          if elementvaluestring = 'Survival'      then elementvaluestring := '';
          if elementvaluestring = 'Survival'      then elementvaluestring := '';
          if elementvaluestring = 'Survival'      then elementvaluestring := '';
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetPermanentValue' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'GetIsObjectType' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
        begin
          elementinteger := 5;
          if elementvaluestring = 'NPC' then elementvaluestring := 'Actor';
        end;
      if GetElementEditValues(subrec_container, 'Function') = 'GetIsObjectType' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      if GetElementEditValues(subrec_container, 'Function') = 'IsInList' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #1' then
          elementinteger := 5;
      if GetElementEditValues(subrec_container, 'Function') = 'IsInList' then
        if Copy(elementpathstring, (LastDelimiter('\', elementpathstring) + 1), MaxInt) = 'Parameter #2' then
          elementinteger := 6;
      subrec_container := Nil;
    end;
  end;

	if elementpathstring <> '' then
	begin
    //TEMPORARY
//    if ((Signature(rec) = 'ACTI') AND (elementpathstring = 'Record Header\Record Flags\Persistent')) then Exit;
//    if ((Signature(rec) = 'AMMO') AND (elementpathstring = 'ICON')) then Exit;
//    if ((Signature(rec) = 'AVIF') AND (elementpathstring = 'ICON')) then Exit;
    //TEMPORARY
		//AddMessage(Path(previousrec));
		//AddMessage(IntToStr(elementinteger));

    ////////////////////////////////////////////////////////////////////////////
    ///  Subrec Creation / Selection
    ////////////////////////////////////////////////////////////////////////////

		subrec := ElementByPath(rec, elementpathstring);
		if not Assigned(subrec) then
			subrec := Add(rec, elementpathstring, True);

		begin
			containerpathstring := elementpathstring;
			containerpathstring := copy(containerpathstring, 1, (LastDelimiter('\', containerpathstring) - 1));
			subrec_container := previousrec;

      if not Assigned(subrec_container) then begin
        subrec_container := ElementByPath(rec, containerpathstring) as IwbContainer;

        if elementpathstring = 'Destructible\Stages' then
          elementinteger := 2;
      end;

			if (subrec_container <> nil) and (ansipos(containerpathstring, formatelementpath(Copy(Path(subrec_container), 8, MaxInt))) <> 0) then begin
				While (containerpathstring <> formatelementpath(Copy(Path(subrec_container), 8, MaxInt))) do
					subrec_container := GetContainer(subrec_container);

				if not Assigned(subrec) then
          subrec := ElementByIndex(subrec_container, elementinteger);

				if (
          (subrec = nil)
          OR (IndexOf(GetContainer(subrec), subrec) <> elementinteger)
          OR (not Assigned(subrec))
  //				OR (elementpathstring = 'Effects\Effect\Conditions\Condition\CIS1')
  //				OR (elementpathstring = 'Effects\Effect\Conditions\Condition\CIS2')
          OR (elementpathstring = 'Effects\Effect\Conditions')
          OR (elementpathstring = 'Conditions')
  //        OR (elementpathstring = 'Conditions\Condition\CIS1')
  //        OR (elementpathstring = 'Conditions\Condition\CIS2')
          OR (elementpathstring = 'Stages\Stage\Log Entries')
          OR (elementpathstring = 'Stages\Stage\Log Entries\Log Entry\Conditions')
          OR (elementpathstring = 'Objectives\Objective\Targets\Target\Conditions')
          OR (elementpathstring = 'Menu Buttons\Menu Button\Conditions')
          OR (elementpathstring = 'Ranks\Rank\MNAM')
          OR (elementpathstring = 'Ranks\Rank\FNAM')
          OR (elementpathstring = 'Ranks\Rank\INAM')
          OR (elementpathstring = 'Leveled List Entries\Leveled List Entry\COED')
          OR (elementpathstring = 'Effects\Effect\Perk Conditions')
          OR (elementpathstring = 'Effects\Effect\Perk Conditions\Perk Condition\PRKC')
          OR (elementpathstring = 'Effects\Effect\Function Parameters\EPFT')
          OR (elementpathstring = 'Textures (RGB/A)\TX03')
          OR (elementpathstring = 'Items\Item\COED')
          OR (elementpathstring = 'Material Substitutions\Substitution\SNAM')
          OR (elementpathstring = 'Body Data\Male Body Data\Parts\Part\Model')
          OR (elementpathstring = 'Body Data\Male Body Data\Parts\Part\Model\MODT')
          OR (elementpathstring = 'Body Data\Female Body Data\Parts\Part\Model')
          OR (elementpathstring = 'Body Data\Female Body Data\Parts\Part\Model\MODT')
  //        OR (elementpathstring = 'Stages\Stage\Log Entries\Log Entry\Conditions\Condition\CIS1')
  //        OR (elementpathstring = 'Stages\Stage\Log Entries\Log Entry\Conditions\Condition\CIS2')
				) then begin
//          AddMessage(Path(subrec_container));
//          AddMessage(elementpathstring);
//          AddMessage(IntToStr(elementinteger));
          try
            subrec := ElementAssign(subrec_container, elementinteger, nil, False);
          except
            AddMessage('EXCEPTION in ElementAssign: Try MaxInt (2147483647) as elementinteger');
//            Result :=
            ExitSequence(rec, subrec_container, originalFormID, elementpathstring, elementvaluestring, IntToStr(elementinteger), elementisflag);
            Exit;
          end;
        end
				else subrec := ElementByIndex(subrec_container, elementinteger);
//        AddMessage(Path(subrec));
			end
			else
			begin
				//AddMessage(elementpathstring);
				//AddMessage(formatelementpath(Copy(Path(subrec_container), 8, MaxInt)));
			end;
		end;

    ////////////////////////////////////////////////////////////////////////////
    ///  Check if value is valid
    ////////////////////////////////////////////////////////////////////////////
//    if ((AnsiPos('Flags\', elementpathstring) <> 0)
//    AND (LastDelimiter('\', elementpathstring) = (AnsiPos('Flags\', elementpathstring) + 5))
//    AND Assigned(subrec_container)) then
//    if FlagValues(subrec_container) <> '' then
    if elementisflag = 'TRUE' then begin
      AssignRecordFlag(elementinteger, subrec_container, elementpathstring);

      Exit;
    end;


    if not Assigned(subrec) and Assigned(subrec_container) then begin
      AssignRecordFlagByName(subrec_container, elementpathstring);
    end;

    ////////////////////////////////////////////////////////////////////////////
    ///  Temporary solution for Alpha Layers
    ////////////////////////////////////////////////////////////////////////////
    if elementpathstring = 'Layers\Alpha Layer' then
    begin
      Remove(subrec);
      subrec := RecordByFormID(_Files[0], TwbFormID.FromCardinal($000138DE), True); // Fallout4.esm LAND Record
      subrec := ElementByPath(subrec as IwbContainer, 'Layers\Alpha Layer');
      subrec := ElementAssign(subrec_container, elementinteger, subrec, False);
    end;

    ////////////////////////////////////////////////////////////////////////////
    ///  Temporary Solution for XMRC may not be neeeded
    ////////////////////////////////////////////////////////////////////////////
//    if elementpathstring = 'XMRC' then
//    begin
//      if Signature(rec) = 'ACHR' then
//      begin
//        ElementAssign()
//      end;
//    end;
//    AddMessage(Path(subrec));
//    if Path(subrec) = 'REGN \ Region Data Entries \ Region Data Entry \ RDMO - Music' then
//    begin
//      AddMessage('YES');
//      if elementpathstring = 'Region Data Entries\Region Data Entry\RDWT' then
//      begin
//        Remove(subrec);
//        subrec := RecordByFormID(FileByIndex(0), $000138DE, True); // Fallout4.esm LAND Record
//        subrec := ElementByPath(subrec, 'Layers\Alpha Layer');
//        subrec := ElementAssign(subrec_container, elementinteger, subrec, False);
//        SetElementEditValues(subrec_container, 'RDAT\Type', 'Weather');
//        AddMessage(GetElementEditValues(subrec_container, 'RDAT\Type'));
//      end;
//    end;
//      elementpathstring := 'Region Data Entries\Region Data Entry\RDMO';
    if elementpathstring = 'Region Areas\Region Area\RPLD' then
    begin
      if not Assigned(subrec)
        then subrec := Add(subrec_container, 'RPLD', True);
    end;
    if AnsiPos('Region Areas\Region Area\RPLD\Point #', elementpathstring) <> 0 then
    begin
//      AddMessage(Path(subrec));
//      AddMessage(Path(previousrec));
//      AddMessage(Path(subrec));
      if LastDelimiter('#', elementpathstring) > LastDelimiter('\', elementpathstring) then
      begin
        if (ElementCount(subrec_container) - 1) < StrToInt(Copy(elementpathstring, (LastDelimiter('#', elementpathstring) + 1), MaxInt)) then
          for k := (ElementCount(subrec_container) - 1) to (StrToInt(Copy(elementpathstring, (LastDelimiter('#', elementpathstring) + 1), MaxInt))) do
          begin
            subrec := ElementAssign(subrec_container, MaxInt, Nil, False);
          end;
        if (ElementCount(subrec_container) - 1) > StrToInt(Copy(elementpathstring, (LastDelimiter('#', elementpathstring) + 1), MaxInt)) then
        begin
          Remove(subrec);
          subrec := ElementByIndex(subrec_container, (StrToInt(Copy(elementpathstring, (LastDelimiter('#', elementpathstring) + 1), MaxInt))));
        end;
      end;
    end;

    ////////////////////////////////////////////////////////////////////////////
    ///  Temporary Solution for XATO
    ////////////////////////////////////////////////////////////////////////////
    if elementpathstring = 'ATTX' then
    begin
      if Signature(rec.ContainingMainRecord) = 'ACHR' then
      begin
        subrec := LinksTo(ElementByPath(rec, 'NAME'));
        subrec := Add(subrec as IwbContainer, 'ATTX', True);
      end;
    end;

    ////////////////////////////////////////////////////////////////////////////
    ///  Check if subrecord is at expected path
    ////////////////////////////////////////////////////////////////////////////
		if Assigned(subrec) then
			if elementpathstring <> formatelementpath(Copy(Path(subrec), 8, MaxInt)) then
			begin
				if (formatelementpath(Copy(Path(subrec), 8, MaxInt)) <> 'Record Header\Record Flags\NavMesh Generation') and
          (formatelementpath(Copy(Path(subrec), 8, MaxInt)) <> 'Destructible\DEST\DEST Count') and
          (formatelementpath(Copy(Path(subrec), 8, MaxInt)) <> 'Destructible\Stages\Stage\DSTD\Model Damage Stage')
          then
				begin
          AddMessage('subrec ' + elementpathstring + ' got assigned to wrong path ' + formatelementpath(Copy(Path(subrec), 8, MaxInt)));
          Exit;
//          raise Exception.Create('subrec ' + elementpathstring + ' got assigned to wrong path ' + formatelementpath(Copy(Path(subrec), 8, MaxInt)));
				end;
			end;

//    AddMessage(Path(subrec_container));

    ////////////////////////////////////////////////////////////////////////////
    ///  Check if subrecord exists
    ////////////////////////////////////////////////////////////////////////////
		if not Assigned(subrec) then
		begin
			//AddMessage(elementpathstring + ' not assigned');
			if Assigned(subrec_container) then
			begin
				if IndexOf(subrec_container, LastElement(subrec_container)) > 0 then
				for k := 0 to IndexOf(subrec_container, LastElement(subrec_container)) do
					if formatelementpath(Copy(Path(ElementByIndex(subrec_container, k) as IwbContainer), 8, MaxInt)) = elementpathstring then
            subrec := ElementByIndex(subrec_container, k);
			end;
			if not Assigned(subrec) then
			begin
        AddMessage('Failed to Assign Record');
//        Result :=
        ExitSequence(rec, subrec_container, originalFormID, elementpathstring, elementvaluestring, IntToStr(elementinteger), elementisflag);
        Exit;
				//Halt;
			end;
		end;

		if Path(subrec) <> '' then
      Supports(subrec, IwbContainer, previousrec);

    ////////////////////////////////////////////////////////////////////////////
    ///  QUST Targets / Aliases
    ////////////////////////////////////////////////////////////////////////////
    if Signature(rec.ContainingMainRecord) = 'QUST' then
      if elementpathstring = 'Objectives\Objective\Targets\Target\QSTA\Alias' then
        elementvaluestring := AddAlias(rec, elementvaluestring);

    ////////////////////////////////////////////////////////////////////////////
    ///  Temporary Solution for XTEL references
    ////////////////////////////////////////////////////////////////////////////
    if elementpathstring = 'XTEL\Door' then
    begin
      var door := ToFileManaged.RecordByNewFormIDHex(elementvaluestring);

      if Assigned(door) and (not GetIsPersistent(door)) then begin
        if GetFileName(GetFile(ToFileManaged.RecordByNewFormIDHex(elementvaluestring))) <>
        GetFileName(GetFile(rec)) then
        begin
          AddMessage('XTEL\Door reference not in file');
          Result := 1;
          Exit;
        end;
        SetIsPersistent((ToFileManaged.RecordByNewFormIDHex(elementvaluestring)), True);
      end;
    end;

    ////////////////////////////////////////////////////////////////////////////
    ///  Temp Solution for persistent records
    ////////////////////////////////////////////////////////////////////////////
    if elementpathstring = 'Record Header\Record Flags' then
    begin
      if GetIsPersistent(rec.ContainingMainRecord) then
        elementvaluestring := '00000000001'
    end;

    ////////////////////////////////////////////////////////////////////////////
    ///  Temp Solution for Floats
    ////////////////////////////////////////////////////////////////////////////
    if elementpathstring = 'FNAM\Armor Rating' then
      elementvaluestring := Copy(elementvaluestring, 1, (AnsiPos('.', elementvaluestring) - 1));
    if elementpathstring = 'DAMA\Resistance\Value' then
      elementvaluestring := Copy(elementvaluestring, 1, (AnsiPos('.', elementvaluestring) - 1));

    ////////////////////////////////////////////////////////////////////////////
    ///  Temp Solution for AMMO
    ///  AMMO must be assigned after MISC
    ////////////////////////////////////////////////////////////////////////////
    if elementpathstring = 'NAM1' then
    begin
      if Signature(rec.ContainingMainRecord) = 'AMMO' then
      begin
        if ((elementvaluestring <> 'NULL - Null Reference [00000000]') AND (elementvaluestring <> '')) then
          elementvaluestring := GetElementEditValues(

            /// Misc Record
            ToFileManaged.RecordByNewFormIDHex(elementvaluestring)

            /// Casing Model Path
            ,'Model\MODL')
        else
          elementvaluestring := '';
      end;
    end;

    ////////////////////////////////////////////////////////////////////////////
    ///  Assign Value
    ////////////////////////////////////////////////////////////////////////////
		//if elementvaluestring = 'Portal Box' then elementvaluestring := '1';
		//if elementvaluestring = 'Subject (0)' then elementvaluestring := '0';
		if ((IsEditable(subrec)) and (elementvaluestring <> '')) then begin
      // Reference.
      if (subrec.EditValue = 'NULL - Null Reference [00000000]') then begin
        if (elementvaluestring <> 'NULL - Null Reference [00000000]') and (Copy(elementvaluestring, 12, MaxInt) <> '<Error: Could not be resolved>') then begin
          var targetRecord := ToFileManaged.RecordByNewFormIDHex(elementvaluestring);

          if Assigned(targetRecord) then
            try
              subrec.EditValue := elementvaluestring;
            except
              on E: Exception do
                AddMessage('Failed to set edit value: ' + E.Message);
            end;
        end;
      // Other value.
      end else begin
        SetEditValue(subrec, elementvaluestring);
      end;
    end;
	end;
end;

function ConvertSignature(S: String; slrecordconversions: TStringList): String;
var
slrecordconversiondelimited: TStringList;
i: integer;
begin
	Result := '';
	slrecordconversiondelimited := TStringList.Create;
	slrecordconversiondelimited.Delimiter := ';';
	slrecordconversiondelimited.StrictDelimiter := true;
	for i := 1 to (slrecordconversions.Count - 1) do
	begin
		slrecordconversiondelimited.DelimitedText := slrecordconversions[i];
		if S = slrecordconversiondelimited[0] then Result := slrecordconversiondelimited[1];
	end;
	slrecordconversiondelimited.Free;
end;

function OccurrencesOfElement(const S: string; const C: char): integer;
var
  i: Integer;
begin
  result := 0;
  for i := 1 to Length(S) do
    if S[i] = C then
      inc(result);
end;

////////////////////////////////////////////////////////////////////////////////
///  Procedure that Adds References from slReferences
////////////////////////////////////////////////////////////////////////////////

function AddMissingReferences(slReferences: TStringList): TStringList;
var
ToFile: IwbFile;
rec: IwbContainer;
slLookup: TStringList;
i, j: Integer;
begin
  Result := TStringList.Create;
  slLookup := TStringList.Create;
	slLookup.Delimiter := ';';
	slLookup.StrictDelimiter := true;
  for i := 0 to (slReferences.Count - 1) do
  begin
    slLookup.DelimitedText := slReferences[i];
    ToFile := FileByLoadOrder(_Files, StrToInt(slLookup[2]));
    if GetFileName(ToFile) <> slLookup[3] then
    begin
      AddMessage('ERROR: File Mismatch');
      Result.Add(slReferences[i]);
      Continue;
      //Exit;
    end;
    rec := RecordByFormID(ToFile, TwbFormID.FromCardinal(StrToInt(slLookup[1])), True);
    for j := 5 to (slLookup.Count - 1) do
    begin
      rec := ElementByIndex(rec, StrToInt(slLookup[j])) as IwbContainer;
    end;
    if Name(rec) <> slLookup[4] then
    begin
      AddMessage('ERROR: Name Mismatch ' + Name(rec) + ' AND ' + slLookup[4] + ' IN ' + Name(rec.ContainingMainRecord));
      Result.Add(slReferences[i]);
      Continue;
      //Exit;
    end;
    if not Assigned(RecordByFormID(ToFile, TwbFormID.FromCardinal(StrToInt('$' + Copy(slLookup[0], 1, 8))), True)) then
    begin
      AddMessage('ERROR: The Referenced Record Does Not Exist');
      Result.Add(slReferences[i]);
      Continue;
    end;
    try
      SetEditValue(rec, slLookup[0]);
    except
      On E :Exception do
      begin
        AddMessage(E.Message);
        AddMessage('ERROR: Value not set');
        Result.Add(slReferences[i]);
        Continue;
      end;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
/// Sort FileList
////////////////////////////////////////////////////////////////////////////////

procedure SortFileList();
var
  i, j: Integer;
  SortOrderList, SortedList: TStringList;
begin
  SortOrderList := TStringList.Create;
  SortedList := TStringList.Create;
  SortOrderList.LoadFromFile(wbProgramPath + 'ElementConversions\' + '__RecordOrder.csv');

  for j := 0 to (SortOrderList.Count - 1) do
  begin
    // Filter these records.
    if (
      (SortOrderList[j] = '') or
      (SortOrderList[j] = 'AVIF') or
      (SortOrderList[j] = 'GMST') or
      (SortOrderList[j] = 'MGEF') or
      (SortOrderList[j] = 'CREA') or
      (SortOrderList[j] = 'NPC_') or
      (SortOrderList[j] = 'IMAD') or
      (SortOrderList[j] = 'SNDR') or
      (SortOrderList[j] = 'PERK') or
      (SortOrderList[j] = 'ACHR') or
      (SortOrderList[j] = 'ACRE')
    ) then
      Continue;

    for i := 0 to (slfilelist.Count - 1) do
    begin
      if slfilelist[i] = '' then
        Continue;

      if SortOrderList[j] = Copy(slfilelist[i], (LastDelimiter('_', slfilelist[i]) - 4), 4) then
      begin
        SortedList.Add(slfilelist[i]);
      end;
    end;
  end;

  slfilelist.Clear;
  slfilelist.AddStrings(SortedList);
  SortedList.Free;
  SortOrderList.Free;
end;

function CreateSortedFormIDsList(f: IwbFile): TStringList;
begin
  var SortedList := TStringList.Create;

  if not Assigned(f) then begin
    Result := SortedList;

    Exit;
  end;

  wbGameMode := gmFNV;

  var SortOrderList := TStringList.Create;

  SortOrderList.LoadFromFile(wbProgramPath + 'ElementConversions\' + '__RecordOrder.csv');

  for var j := 0 to (SortOrderList.Count - 1) do
  begin
    // Filter these records.
    if (
      (SortOrderList[j] = '') or
      (SortOrderList[j] = 'AVIF') or
      (SortOrderList[j] = 'GMST') or
      (SortOrderList[j] = 'MGEF') or
      (SortOrderList[j] = 'CREA') or
      (SortOrderList[j] = 'NPC_') or
      (SortOrderList[j] = 'IMAD') or
      (SortOrderList[j] = 'SNDR') or
      (SortOrderList[j] = 'PERK') or
      (SortOrderList[j] = 'ACHR') or
      (SortOrderList[j] = 'ACRE')
    ) then
      Continue;

    for var i := 0 to (f.RecordCount - 1) do begin
      var rec := f.Records[i] as IwbMainRecord;

      if SortOrderList[j] = rec.Signature then begin
        SortedList.Add(rec.FormID.ToString());
      end;
    end;
  end;

  SortOrderList.Free;

  Result := SortedList;
end;

////////////////////////////////////////////////////////////////////////////////
/// Clean LVLN
////////////////////////////////////////////////////////////////////////////////
procedure CleanLVLN(const rec: IwbContainer);
var
rContainer, rLLE: IwbContainer;
i: Integer;

begin
  rContainer := ElementByPath(rec, 'Leveled List Entries') as IwbContainer;
  for i := (ElementCount(rContainer) - 1) downto 0 do
  begin
    rLLE := ElementByIndex(rContainer, i) as IwbContainer;
    if GetElementEditValues(rLLE, 'LVLO\Reference') = 'NULL - Null Reference [00000000]' then
    begin
      if ElementCount(rContainer) = 1 then
        Remove(rContainer)
      else
        Remove(rLLE);
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
/// Clean IPDS
////////////////////////////////////////////////////////////////////////////////
procedure CleanIPDS(const rec: IwbContainer);
var
rContainer, rPNAM: IwbContainer;
i: Integer;

begin
  rContainer := ElementByPath(rec, 'Data') as IwbContainer;
  for i := (ElementCount(rContainer) - 1) downto 0 do
  begin
    rPNAM := ElementByIndex(rContainer, i) as IwbContainer;
    if GetEditValue(ElementByIndex(rPNAM, 1)) = 'NULL - Null Reference [00000000]' then
    begin
      if ElementCount(rContainer) = 1 then
        Remove(rContainer)
      else
        Remove(rPNAM);
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
/// Clean Conditions
////////////////////////////////////////////////////////////////////////////////
procedure CleanConditionsHelper(const rec: IwbContainer; const sl: TStringList; const index: Integer);
var
rContainer, r: IwbContainer;
j, k: Integer;
path, path2: String;
begin
  if index < sl.Count then
    path := sl[index];
  if (index + 1) < sl.Count then
    path2 := sl[(index + 1)];
  rContainer := rec; /// First time rec path should be sl[0] as should index
  if Assigned(rContainer) then
  begin
    if path = 'Conditions' then
    for j := (ElementCount(rContainer) - 1) downto 0 do
    begin
      r := ElementByIndex(rContainer, j) as IwbContainer;
      r := ElementByPath(r, 'CTDA\Function') as IwbContainer;
      if Assigned(r) then
      begin
        if GetEditValue(r) = 'GetWantBlocking' then
        begin
          /// Removal code here
          r := ElementByIndex(rContainer, j) as IwbContainer; /// Condition
          if ElementCount(rContainer) = 1 then
          begin
            if sl.Count = 1 then
              Remove(rContainer) /// If only a conditions record remove it
            else
            begin
              k := (sl.Count - 2); /// Path before conditions
              while (formatelementpath(Name(rContainer)) <> sl[0]) do
              begin
                r           := GetContainer(r);
                rContainer  := GetContainer(rContainer);
                if formatelementpath(Name(rContainer)) = sl[k] then
                begin
                  if ElementCount(rContainer) > 1 then
                  begin
                    Remove(r);
                    Exit;
                  end
                  else if k = 0 then Remove(rContainer);
                  k := k - 1;
                end;
              end;
            end;
          end
          else
            Remove(r); /// Remove Condition
        end;
      end;
    end
    else
    for j := (ElementCount(rContainer) - 1) downto 0 do
    begin
      r := ElementByIndex(rContainer, j) as IwbContainer;
      r := ElementByPath(r, path2) as IwbContainer;
      if Assigned(r) then
        if (index + 1) < sl.Count then
          CleanConditionsHelper(r, sl, (index + 1));
    end;
  end;
end;

procedure CleanConditions2(const rec: IwbContainer);
var
sl: TStringList;
s: String;
begin
  sl := TStringList.Create;
  sl.Delimiter := ';';
  sl.StrictDelimiter := True;
  s := Signature(rec.ContainingMainRecord);

  if
  (  (s = 'CPTH')
  OR (s = 'IDLE')
  OR (s = 'PACK')
  OR (s = 'PERK')
  OR (s = 'QUST')
  OR (s = 'RCPE')
  ) then
  begin
    sl.DelimitedText := 'Conditions';
    CleanConditionsHelper(ElementByPath(rec, sl[0]) as IwbContainer, sl, 0);
  end;

  if
  (
     (s = 'ALCH')
  OR (s = 'SPEL')
  OR (s = 'ENCH')
  OR (s = 'PERK')
  OR (s = 'INGR')
  ) then
  begin
    sl.DelimitedText := 'Effects;Conditions';
    CleanConditionsHelper(ElementByPath(rec, sl[0]) as IwbContainer, sl, 0);
  end;

  if s = 'QUST' then
  begin
    sl.DelimitedText := 'Stages;Log Entries;Conditions';
    CleanConditionsHelper(ElementByPath(rec, sl[0]) as IwbContainer, sl, 0);
    sl.DelimitedText := 'Objectives;Targets;Conditions';
    CleanConditionsHelper(ElementByPath(rec, sl[0]) as IwbContainer, sl, 0);
  end;

  if s = 'MESG' then
  begin
    sl.DelimitedText := 'Menu Buttons;Conditions';
    CleanConditionsHelper(ElementByPath(rec, sl[0]) as IwbContainer, sl, 0);
  end;

  if s = 'MESG' then
  begin
    sl.DelimitedText := 'Effects;Perk Conditions;Conditions';
    CleanConditionsHelper(ElementByPath(rec, sl[0]) as IwbContainer, sl, 0);
  end;


end;


function GetOriginalFormIDHex(fromRec: IwbMainRecord): String;
begin
  Result := IntToHex(fromRec.LoadOrderFormID.ToCardinal, 8);
end;

function GetCellSignature(fromRec: IwbMainRecord): string;
begin
  wbGameMode := gmFNV;
  var flags := fromRec.ElementByPath['Record Header\Record Flags'].EditValue;

  if flags[11] = '1' then begin
    Result := 'CELL[P]';
    wbGameMode := gmFO4;

    Exit;
  end;

  Result:= 'CELL[' +
    fromRec.ElementByPath['XCLC\X'].EditValue + ',' +
    fromRec.ElementByPath['XCLC\Y'].EditValue + ']';

  wbGameMode := gmFO4;
end;

function GetCellChildParent(f: IwbFile; fileloadorder: string; recordPath: string; ToFileManaged: TConverterManagedFile): IwbMainRecord;
var
  ExtractedValue: string;
  Match: TMatch;
begin
  // Use a regular expression to match the pattern
  Match := TRegEx.Match(recordPath, '\[CELL:(\w+)\]');
  if Match.Success then
  begin
    ExtractedValue := Match.Groups.Item[1].Value;

    Result := ToFileManaged.RecordByOldFormIDHex(ExtractedValue);

    if Result = nil then
      raise Exception.Create('Could not find cell child parent for ' + recordPath);
  end
  else
    raise Exception.Create('Could not find cell child parent for ' + recordPath);
end;


procedure RemoveRecordsToSkip(f: IwbFile);
var
  slRecordsToSkip, slRecordDelimited: TStringList;
  i: Integer;
  rec: IwbMainRecord;
begin
  if f.FileName <> 'FalloutNV.esm' then begin
    Exit;
  end;


  slRecordsToSkip := TStringList.Create;
  slRecordsToSkip.LoadFromFile(wbProgramPath + '\ElementConversions\__RecordsToSkip.csv');

	slRecordDelimited := TStringList.Create;
	slRecordDelimited.Delimiter := ';';
	slRecordDelimited.StrictDelimiter := true;

  for i := 0 to slRecordsToSkip.Count - 1 do begin
    slRecordDelimited.DelimitedText := slRecordsToSkip[i];

    rec := RecordByFormID(f, TwbFormID.FromCardinal(StrToInt('$' + f.LoadOrderFileID.ToString() + slRecordDelimited[1])), True);

    if not Assigned(rec) then
      Continue;

    rec.Remove;
  end;

  slRecordsToSkip.Free;
  slRecordDelimited.Free;
end;

function IsEditorReference(formIdHex: string): Boolean;
begin
  Result := StrToInt('$' + Copy(IntToHex(StrToInt(formIdHex), 8), 3, 6)) < 2048
end;

procedure CreateRecord(
  originalloadorder: string;
  newfilename: string;
  ToFile: IwbFile;
  _Signature: string;
  var fileloadorder: string;
  var rec: IwbContainer;
  var elementvaluestring: string;
  ToFileManaged: TConverterManagedFile;
  fromRec: IwbMainRecord
);
var
  Local_k: Integer;
  Local_k1: Integer;
  Local_k2: Integer;
begin
  fileloadorder := IntToHex(GetLoadOrder(ToFile), 2);

  wbGameMode := gmFNV;
  var recordpath := ToSafeString(FullPath(fromRec));
  wbGameMode := gmFO4;

  if ansipos('GRUP Top ', recordpath) <> 0 then
    recordpath := copy(recordpath, (ansipos('GRUP Top "', recordpath) + 10), MaxInt)
  else
    recordpath := '';
  if recordpath <> '' then
  begin
    // Need to add record to its parent.
    if (_Signature = 'REFR') or (_Signature = 'ACHR') or (_Signature = 'ACRE') or (_Signature = 'PGRE') or (_Signature = 'LAND') or (_Signature = 'NAVM') then
      rec := GetCellChildParent(ToFile, fileloadorder, recordpath, ToFileManaged).Add(_Signature, True) as IwbContainer
    else
    // Add record directly to file.
    begin
      rec := ToFile.Add(_Signature, True) as IwbContainer;
      // Top GRUP
      rec := Add(rec, _Signature, True) as IwbContainer;
    end;
    if not Assigned(rec) then
    // If part of subgrup
    begin
      if ansipos('[CELL:', recordpath) <> 0 then
        recordpath := copy(recordpath, (ansipos('[CELL:', recordpath) + 6), 8)
      else if ansipos('[WRLD:', recordpath) <> 0 then
        recordpath := copy(recordpath, (ansipos('[WRLD:', recordpath) + 6), 8)
      else if ansipos('[DIAL:', recordpath) <> 0 then
        recordpath := copy(recordpath, (ansipos('[DIAL:', recordpath) + 6), 8)
      else if ansipos('[QUST:', recordpath) <> 0 then
        recordpath := copy(recordpath, (ansipos('[QUST:', recordpath) + 6), 8)
      else begin
        raise Exception.Create('ERROR: Could not find match');
      end;

      if copy(recordpath, 1, 2) = originalloadorder then begin
        rec := RecordByFormID(ToFile, TwbFormID.FromCardinal(StrToInt('$' + fileloadorder + copy(recordpath, 3, 6))), True);
        if Assigned(rec) then
        begin
          if GetFile(rec) <> ToFile then
          begin
            raise Exception.Create('ERROR: rec in wrong file');
          end;
        end;
      end else begin
        for Local_k := 0 to ((slloadorders.Count) div 3 - 1) do
        begin
          if fileloadorder = slloadorders[(Local_k * 3)] then
          begin
            if Assigned(rec) then
            begin
              rec := RecordByFormID(ToFile, TwbFormID.FromCardinal(StrToInt('$' + slloadorders[(Local_k * 3 + 2)] + copy(recordpath, 3, 6))), True);
              if GetFile(rec) <> ToFile then
              begin
                raise Exception.Create('ERROR: rec in wrong file Using FOR LOOP');
              end;
            end;
          end;
        end;
      end;
      rec := Add(rec, _Signature, True) as IwbContainer;
    end;
  end
  else
    rec := Add(ToFile, _Signature, True) as IwbMainRecord;
  if not Assigned(rec) then
  begin
    if _Signature = 'TES4' then
    begin
      rec := RecordByIndex(ToFile, 0) as IwbMainRecord;

      if not Assigned(rec) then
        raise Exception.Create('File header not found');

      Exit;
    end;
    if not Assigned(rec) then
    begin
      raise Exception.Create('ERROR: Record Not Assigned');
    end;
  end;

  wbGameMode := gmFNV;
  var isCellWithWorldspace := (fromRec.Signature = 'CELL') and Assigned(fromRec.ElementByPath['Worldspace']);
  wbGameMode := gmFO4;

  if isCellWithWorldspace then
  begin
    Remove(rec);

    var worldspaceElem := fromRec.ElementByPath['Worldspace'];
    var formID := TwbFormID.FromCardinal(worldspaceElem.NativeValue).ToString();

    wbGameMode := gmFNV;
    rec := ToFileManaged.RecordByOldFormIDHex(formID);
    elementvaluestring := ToFileManaged.GetNewFormID(formID).ToString();
    wbGameMode := gmFO4;

    if Signature(rec.ContainingMainRecord) <> 'WRLD' then begin
      raise Exception.Create('Mismatch in For WRLD');
    end;
    rec := Add(rec, GetCellSignature(fromRec), True) as IwbContainer;
  end;
  //////////////////////////////////////////////////////////////////////////
  ///  Temporary solution for Effect Shaders
  //////////////////////////////////////////////////////////////////////////
  if Signature(rec.ContainingMainRecord) = 'EFSH' then
  begin
    Remove(rec);
    rec := RecordByFormID(_Files[0], TwbFormID.FromCardinal($36902), True);
    // Fallout4.esm EFSH Record
    rec := wbCopyElementToFile(rec, ToFile, False, True, '', '', '', '', False) as IwbContainer;
  end;
  //////////////////////////////////////////////////////////////////////////
  ///  Set FormID
  //////////////////////////////////////////////////////////////////////////
  wbGameMode := gmFNV;
  var originalFormID := IntToHex(GetLoadOrderFormID(fromRec));
  wbGameMode := gmFO4;

  var newFormID := ToFileManaged.GetNewFormID(originalFormID);

  SetLoadOrderFormID(rec.ContainingMainRecord, newFormID);
end;


function CreateFile(converterFM: TConverterFileManager; newfilename: String; AddNewFileName: TFuncType): TConverterManagedFile;
begin
  if converterFM.HasFile(newfilename) then begin
    Result := converterFM.GetManagedFileByFilename(newfilename);

    Exit;
  end;

  Result := converterFM.AddFile(newfilename);
end;


function GetNewElementValue(value: String; ToFileManaged: TConverterManagedFile): String;
begin
  var s := value;
  var k := AnsiPos('[', s);

  if k <> 0 then begin
    if AnsiPos(']', s) = (k + 14) then
    begin
      s := Copy(s, (k + 6), 8);

      try
        StrToInt('$' + s);
      except on E: EConvertError do begin
          // Not a reference

          Result := value;

          Exit;
        end;
      end;

      if copy(s, 1, 2) = 'F4' then // Fallout 4 Reference
      begin
        s := '00' + Copy(s, 3, 6);
      end else begin
        s := ToFileManaged.GetNewFormID(s).ToString();
      end;
    end;
  end;

  Result := s;
end;


procedure SaveConvertedFile(_File: IwbFile);
begin
  var s := _File.FileName;

  var CRC := _File.CRC32;

  var FileStream := TBufferedFileStream.Create(wbGameModeToConfig[gmFO4].wbDataPath + s, fmCreate, 1024 * 1024);

  try
    try
      AddMessage('Saving: ' + s);
      _File.WriteToStream(FileStream, rmSetInternal);

      AddMessage('Saved');
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do begin
      SysUtils.DeleteFile(wbGameModeToConfig[gmFO4].wbDataPath + s);

      AddMessage('Error saving ' + s + ': ' + E.Message);
    end;
  end;
end;

procedure CreateRecords(
  slContinueFrom: TStringList; 
  converterFM: TConverterFileManager; 
  FirstFileLoop: Boolean; 
  AddNewFileName: TFuncType; 
  var fileloadorder: string; 
  var rec: IwbContainer; 
  var elementvaluestring: string; 
  fromCSVs: Boolean;
  FromFile: IwbFile;
  var ToFile: IwbFile
);
begin
  AddMessage('Creating Records...');
  if slContinueFrom.Count <> 0 then begin
    AddMessage('Skipped Because slContinuefrom count is not 0');

		var newfilename := copy(slContinueFrom[0], 1, (ansipos('_LoadOrder', slContinueFrom[0]) - 1));

    converterFM.AddFile(newfilename, True);

    Exit;
  end;

  var recordStringList := TStringList.Create;

  ////////////////////////////////////////////////////////////////////////////
  ///  Initialize
  ////////////////////////////////////////////////////////////////////////////
  var sortedFormIDs := CreateSortedFormIDsList(FromFile);

  var newfilename := FromFile.FIleName;
  var filename := newfilename;

  if (newfilename = 'FalloutNV.Hardcoded.keep.this.with.the.exe.and.otherwise.ignore.it.I.really.mean.it.dat') then
    newfilename := 'FalloutNV.esm';

  ////////////////////////////////////////////////////////////////////////////
  ///  Create File
  ////////////////////////////////////////////////////////////////////////////
  var ToFileManaged := CreateFile(converterFM, newfilename, AddNewFileName);
  ToFile := ToFileManaged.f;

  ////////////////////////////////////////////////////////////////////////////
  ///  Debug Options
  ////////////////////////////////////////////////////////////////////////////
  var m := sortedFormIDs.Count - 1;

  // Create records.
  for var i := 0 to m do
  begin
    if i mod 1000 = 0 then
      AddMessage(IntToStr(i) + '/' + IntToStr(m) + ' records created');

    var formIDstr := sortedFormIDs[i];

    wbGameMode := gmFNV;

    var fromRec := FromFile.RecordByFormID[TwbFormID.FromStr(formIDstr), True, True];

    Assert(fromRec._File.FileName = FromFile.FileName);

    var originalloadorder := Copy(IntToHex(FromFile.LoadOrder), 7, 2);
    var _Signature := ConvertSignature(fromRec.Signature, slrecordconversions);

    if _Signature = '' then
      Continue;

    wbGameMode := gmFO4;

    CreateRecord(originalloadorder, newfilename, ToFile, _Signature, fileloadorder, rec, elementvaluestring, ToFileManaged, fromRec);
  end;

  AddMessage(filename);

  if Assigned(sortedFormIDs) then
    sortedFormIDs.Free;

  recordStringList.Free;
end;


procedure UpdateElementConversions(var _ConversionFile: string; _Signature: string; var sl: TStringList; var sl2: TStringList);
begin                    
  var LastSingleValueIndex := 5;
  _ConversionFile := _Signature;
  slPathsLookup.Clear;
  slEntryLength.Clear;
  slShortLookup.Clear;
  slShortLookupPos.Clear;

  slSingleValues.Clear;
  slNewRec.Clear;
  slNewRecSig.Clear;
  slSingleRec.Clear;
  slOldNewValMatch.Clear;
  slNewPathorOrder.Clear;
  slOldVal.Clear;
  slNewVal.Clear;
  slOldIndex.Clear;
  slNewIndex.Clear;
  slReplaceAnyVal.Clear;
  slReplaceAnyIndex.Clear;
  slIsFlag.Clear;
  sl.Clear;
  sl2.Clear;
  slSingleValues.Add('slSingleValues');
  slNewRec.Add('slNewRec');
  slNewRecSig.Add('slNewRecSig');
  slSingleRec.Add('slSingleRec');
  slOldNewValMatch.Add('slOldNewValMatch');
  slNewPathorOrder.Add('slNewPathorOrder');
  slOldVal.Add('slOldVal');
  slNewVal.Add('slNewVal');
  slOldIndex.Add('slOldIndex');
  slNewIndex.Add('slNewIndex');
  slReplaceAnyVal.Add('slReplaceAnyVal');
  slReplaceAnyIndex.Add('slReplaceAnyIndex');
  slIsFlag.Add('slIsFlag');
  sl.LoadFromFile(wbProgramPath + 'ElementConversions\Proto\' + '__ElementConversions.csv');
  sl2.LoadFromFile(wbProgramPath + 'ElementConversions\Proto\' + _Signature + '.csv');
  if sl2.Count > 3 then /// Skip Notes, Column identifiers and column notes
  begin
    sl2.Delete(0);
    sl2.Delete(0);
    sl2.Delete(0);
    sl.AddStrings(sl2);
  end;
  slTemporaryDelimited.Clear;
  slTemporaryDelimited.Delimiter := ';';
  slTemporaryDelimited.StrictDelimiter := True;
  slTemporaryDelimited.DelimitedText := sl[1];  /// Column Identifiers
  for var i := 1 to (slTemporaryDelimited.Count - 1) do /// Skip Notes
  begin
    if slTemporaryDelimited[i] = slNewRec[0] then
      slNewRec.Add(IntToStr(i));
    if slTemporaryDelimited[i] = slNewRecSig[0] then
      slNewRecSig.Add(IntToStr(i));
    if slTemporaryDelimited[i] = slSingleRec[0] then
      slSingleRec.Add(IntToStr(i));
    if slTemporaryDelimited[i] = slOldNewValMatch[0] then
      slOldNewValMatch.Add(IntToStr(i));
    if slTemporaryDelimited[i] = slNewPathorOrder[0] then
      slNewPathorOrder.Add(IntToStr(i));
    if slTemporaryDelimited[i] = slNewVal[0] then
      slNewVal.Add(IntToStr(i));
    if slTemporaryDelimited[i] = slOldVal[0] then
      slOldVal.Add(IntToStr(i));
    if slTemporaryDelimited[i] = slOldIndex[0] then
      slOldIndex.Add(IntToStr(i));
    if slTemporaryDelimited[i] = slNewIndex[0] then
      slNewIndex.Add(IntToStr(i));
    if slTemporaryDelimited[i] = slReplaceAnyVal[0] then
      slReplaceAnyVal.Add(IntToStr(i));
    if slTemporaryDelimited[i] = slReplaceAnyIndex[0] then
      slReplaceAnyIndex.Add(IntToStr(i));
    if slTemporaryDelimited[i] = slIsFlag[0] then
      slIsFlag.Add(IntToStr(i));

  end;
  for var i := 3 to (sl.Count - 1) do /// Skip Notes, Column identifiers and column notes
  begin
    slTemporaryDelimited.DelimitedText := sl[i];
    if slTemporaryDelimited[1] <> '' then
    begin
      slPathsLookup.Add(slTemporaryDelimited[1]);
      slEntryLength.Add(IntToStr(i - 1));
      for var j := 2 to LastSingleValueIndex do
      begin
        slSingleValues.Add(slTemporaryDelimited[j]);
      end;
      var s := slPathsLookup[(slPathsLookup.Count - 1)];
      if AnsiPos('\', s) <> 0 then
        s := Copy(s, 1, (AnsiPos('\', s) - 1));
      for var j := 0 to slShortLookup.Count do
      begin
        if j = slShortLookup.Count then
        begin
          slShortLookup.Add(s);
          slShortLookupPos.Add(IntToStr(slPathsLookup.Count - 1));
        end
        else
        if s = slShortLookup[j] then
          Break;
      end;
    end;
    slNewRec.Add(slTemporaryDelimited[StrToInt(slNewRec[1])]);
    slNewRecSig.Add(slTemporaryDelimited[StrToInt(slNewRecSig[1])]);
    slSingleRec.Add(slTemporaryDelimited[StrToInt(slSingleRec[1])]);
    slOldNewValMatch.Add(slTemporaryDelimited[StrToInt(slOldNewValMatch[1])]);
    slNewPathorOrder.Add(slTemporaryDelimited[StrToInt(slNewPathorOrder[1])]);
    slOldVal.Add(slTemporaryDelimited[StrToInt(slOldVal[1])]);
    slNewVal.Add(slTemporaryDelimited[StrToInt(slNewVal[1])]);
    slOldIndex.Add(slTemporaryDelimited[StrToInt(slOldIndex[1])]);
    slNewIndex.Add(slTemporaryDelimited[StrToInt(slNewIndex[1])]);
    slReplaceAnyVal.Add(slTemporaryDelimited[StrToInt(slReplaceAnyVal[1])]);
    slReplaceAnyIndex.Add(slTemporaryDelimited[StrToInt(slReplaceAnyVal[1])]);
    slIsFlag.Add(slTemporaryDelimited[StrToInt(slIsFlag[1])]);
  end;
end;



function ConvertData(
  e: IwbContainer;

  _Signature: string;
  ToFileManaged: TConverterManagedFile;
  ToFile: IwbFile;
  rec: IwbContainer;
  originalloadorder: string;
  fileloadorder: string;
  originalFormID: string;
  var newrec: IwbContainer;
  var OriginRec1: IwbContainer;
  var OriginRec2: IwbContainer
): String;
var
i, j, elementCount: integer;
ielement: IwbElement;
iContainer, _TXST: IwbContainer;
s, valuestr: String;
begin
	for i := 0 to (e.ElementCount-1) do
	begin

    ////////////////////////////////////////////////////////////////////////////
    ///  All Data
    ////////////////////////////////////////////////////////////////////////////
		ielement := e.Elements[i];

//		slstring := (slstring
////    stringreplace(
////     ,'"', '|CITATION|', [rfReplaceAll])
//    + ';' + ToSafeString(ielement.Path)
//    + ';' + ToSafeString(ielement.EditValue)
//    + ';' + IntToStr(i));

    ////////////////////////////////////////////////////////////////////////////
    ///  Material Swap
    ////////////////////////////////////////////////////////////////////////////
//    if (ielement.Name = 'Alternate Texture') and Supports(ielement, IwbContainer, iContainer) then
//    begin
//      if Assigned(iContainer.ElementByPath['3D Name']) and (useAdditionalLists) then begin
//        s := ielement.Container.Container.Elements[0].EditValue;
//        if LastDelimiter('.', s) <> (Length(s) - 3) then s := '';
//        slNifs.Add(s);
//        _TXST := iContainer.ElementByPath['New Texture'].LinksTo as IwbContainer;
//        s := s + ';' + GetElementEditValues(_TXST, 'EDID')
//        + ';' + GetElementEditValues(iContainer, '3D Name')
//        + ';' + GetElementEditValues(_TXST, 'Textures (RGB/A)\TX00')
//        + ';' + GetElementEditValues(_TXST, 'Textures (RGB/A)\TX01')
//        + ';' + GetElementEditValues(_TXST, 'Textures (RGB/A)\TX02')
//        + ';' + GetElementEditValues(_TXST, 'Textures (RGB/A)\TX03')
//        + ';' + GetElementEditValues(_TXST, 'Textures (RGB/A)\TX04')
//        + ';' + GetElementEditValues(_TXST, 'Textures (RGB/A)\TX05') + ';';
//        if Assigned(_TXST.ElementByPath['DNAM\No Specular Map']) then
//          s := s + 'No Specular Map';
//        slvalues.Add(s);
//        sl3DNames.Add(GetElementEditValues(iContainer, '3D Name'));
//      end;
//    end;

    ////////////////////////////////////////////////////////////////////////////
    ///  File Reference
    ////////////////////////////////////////////////////////////////////////////
//    valuestr := ielement.EditValue;
//    if ((Length(valuestr) > 4) AND (LastDelimiter('.', valuestr) <> 0)) then
//    for j := 0 to (slExtensions.Count - 1) do
//    begin
//      if Copy(valuestr, (Length(valuestr) - Length(slExtensions[j]) + 1), MaxInt) = slExtensions[j] then
//      begin
//        if useAdditionalLists then
//          slReferences.Add(formatelementpath(ielement.Path) + ';' + valuestr);
//
//        Break;
//      end;
//    end;


    var elementpathstring := copy(ToSafeString(ielement.Path), 8, MaxInt);
    var elementvaluestring := ToSafeString(ielement.EditValue);
    var elementinteger := IntToStr(i);
    elementpathstring := formatelementpath(elementpathstring);
    elementvaluestring := stringreplace(elementvaluestring, '\r\n', #13#10, [rfReplaceAll]);
    elementvaluestring := stringreplace(elementvaluestring, '\comment\', ';', [rfReplaceAll]);
    elementvaluestring := stringreplace(elementvaluestring, '|CITATION|', '"', [rfReplaceAll]);

    ////////////////////////////////////////////////////////////////////////
    ///  Numbered Array
    ////////////////////////////////////////////////////////////////////////
    if AnsiPos('#', elementpathstring) <> 0 then
    begin
      if ((OccurrencesOfChar(elementpathstring, '#') = 1)
      AND (AnsiPos('Parameter #', elementpathstring) = 0)
      AND (AnsiPos('Attribute #', elementpathstring) = 0)
      AND (AnsiPos('Skill #', elementpathstring) = 0)
      AND (AnsiPos('Voice #', elementpathstring) = 0)
      AND (AnsiPos('Default Hair Style #', elementpathstring) = 0)
      AND (AnsiPos('Default Hair Color #', elementpathstring) = 0)
      AND (AnsiPos('ANAM\Related Camera Path #', elementpathstring) = 0)
      AND (AnsiPos('DATA\Particle Shader - Initial Velocity #', elementpathstring) = 0)
      AND (AnsiPos('DATA\Particle Shader - Acceleration #', elementpathstring) = 0)
      AND (AnsiPos('ANAM\Related Idle Animation #', elementpathstring) = 0)
      AND (AnsiPos('XORD\Plane #', elementpathstring) = 0)
      AND (AnsiPos('XPOD\Room #', elementpathstring) = 0)
      AND (AnsiPos('NAM0\Type #', elementpathstring) = 0)
      ) then
      begin
        elementinteger := Copy(elementpathstring, (LastDelimiter('#', elementpathstring) + 1), MaxInt);
        if AnsiPos('\', elementinteger) <> 0 then
          elementinteger := Copy(elementinteger, 1, (AnsiPos('\', elementinteger) - 1));
        elementpathstring := StringReplace(elementpathstring, ('#' + elementinteger), '#0', [rfIgnoreCase]);
      end;
    end;

    ////////////////////////////////////////////////////////////////////////
    ///  Convert
    ////////////////////////////////////////////////////////////////////////
    Build_slstring(
      elementpathstring,
      elementvaluestring,
      elementinteger,

      _Signature,
      ToFileManaged,
      ToFile,
      rec,
      originalloadorder,
      fileloadorder,
      originalFormID,
      newrec,
      OriginRec1,
      OriginRec2
    );
    Inc(j);

    ////////////////////////////////////////////////////////////////////////////
    ///  Exit Condition
    ////////////////////////////////////////////////////////////////////////////
    if Supports(ielement, IwbContainer, iContainer) and (iContainer.ElementCount > 0) then
      ConvertData(
        iContainer,

        _Signature,
        ToFileManaged,
        ToFile,
        rec,
        originalloadorder,
        fileloadorder,
        originalFormID,
        newrec,
        OriginRec1,
        OriginRec2
      );
	end;
end;


procedure AssignConvertedData(
  _Signature: string;
  ToFileManaged: TConverterManagedFile;
  ToFile: IwbFile;
  rec: IwbContainer;
  originalloadorder: string;
  fileloadorder: string;
  originalFormID: string;
  var newrec: IwbContainer;
  var OriginRec1: IwbContainer;
  var OriginRec2: IwbContainer;
  elementpathstring: string;
  elementvaluestring: string;
  elementinteger: string;
  elementisflag: string;
  elementnewrec: string
);
begin
  if _Signature = 'REFR' then begin
    elementvaluestring := GetNewElementValue(elementvaluestring, ToFileManaged);

    if Length(elementpathstring) = 4 then begin
      CreateElementQuick1(rec, elementpathstring, elementvaluestring, ToFileManaged);
    end else begin
      CreateElement(rec, originalloadorder, fileloadorder, elementpathstring, elementvaluestring, StrToInt(elementinteger), elementisflag, ToFileManaged, originalFormID);
    end;

    Exit;
  end;

  var originalElementvaluestring := elementvaluestring;
//        	elementvaluestring := stringreplace(elementvaluestring, '\r\n', #13#10, [rfReplaceAll]);
//        	elementvaluestring := stringreplace(elementvaluestring, '\comment\', ';', [rfReplaceAll]);
//        	elementvaluestring := stringreplace(elementvaluestring, '|CITATION|', '"', [rfReplaceAll]);


  ////////////////////////////////////////////////////////////////////////
  ///  Caravan card list
  ////////////////////////////////////////////////////////////////////////
  if AnsiPos('[CCRD:', elementvaluestring) <> 0 then
  begin
    if elementpathstring = 'Leveled List Entries\Leveled List Entry\LVLO\Reference' then
      Exit;
  end;

  try
    StrToInt(elementinteger);
  except
    AddMessage('elementinteger is not a number');
    AddMessage('PATH    : ' + elementpathstring);
    AddMessage('VALUE   : ' + elementvaluestring);
    AddMessage('INTEGER : ' + elementinteger);
    AddMessage('ISFLAG  : ' + elementisflag);

    Exit;
  end;

  if elementnewrec <> '' then
  begin
    slTemporaryDelimited.Clear;
    slTemporaryDelimited.Delimiter := '\';
    slTemporaryDelimited.StrictDelimiter := True;
    slTemporaryDelimited.DelimitedText := elementnewrec;  /// Column Identifiers
    if slTemporaryDelimited.Count > 1 then
    begin
      OriginRec1 := rec;
      if Assigned(newrec) then
        OriginRec2 := previousrec2
      else
        OriginRec2 := previousrec;

      for var k := 0 to slTemporaryDelimited.Count - 2 do begin
        elementnewrec := slTemporaryDelimited[k];
        var s := GetNewRecEDID(rec.ContainingMainRecord, elementnewrec);
        rec := MainRecordByEditorID(Add(ToFile, Copy(elementnewrec, 1, 4), True) as IwbGroupRecord, s);
      end;

      elementnewrec := slTemporaryDelimited[(slTemporaryDelimited.Count - 1)];

      if elementnewrec <> 'Return' then begin
        var s := GetNewRecEDID(rec.ContainingMainRecord, elementnewrec);
        newrec := MainRecordByEditorID(Add(ToFile, Copy(elementnewrec, 1, 4), True) as IwbGroupRecord, s);
      end;
    end;
  end;


  ////////////////////////////////////////////////////////////////////////
  ///  Assign elements
  ////////////////////////////////////////////////////////////////////////
  if elementpathstring <> '' then begin
    if Assigned(newrec) then
    begin
      if ((Copy(elementnewrec, 1, 4) <> Signature(newrec.ContainingMainRecord))
      AND (elementnewrec <> 'Return')) then
      begin
        newrec := Nil;
        previousrec := previousrec2;
      end;
    end;
  end;

  if elementnewrec <> '' then begin
    if elementnewrec <> 'Return' then
    begin
      if not Assigned(newrec) then previousrec2 := previousrec;
//              if AnsiPos('Female world model', elementpathstring) = 1 then s := s + '_4';
//              AddMessage('Name of prev rec is ' + Path(previousrec));
      var s := GetNewRecEDID(rec.ContainingMainRecord, elementnewrec);
      newrec := MainRecordByEditorID(Add(ToFile, Copy(elementnewrec, 1, 4), True) as IwbGroupRecord, s);
      if not Assigned(newrec) then
      begin
        newrec := MasterOrSelf(rec.ContainingMainRecord);
//                if GetFileName(GetFile(newrec)) <> GetFileName(GetFile(rec))
        newrec := Add(ToFile, Copy(elementnewrec, 1, 4), True) as IwbContainer; // Top GRUP
        newrec := Add(newrec, Copy(elementnewrec, 1, 4), True) as IwbContainer;
        Add(newrec, 'EDID', True);
        SetElementEditValues(newrec, 'EDID', s);
      end;
//              AddMessage(s);
      if AnsiPos('MSWP', elementnewrec) = 1 then
      begin
        if elementpathstring = 'Material Substitutions\Substitution\BNAM' then
        begin
          s := GetEditValue(ElementByIndex(GetContainer(previousrec2), 0));
          s := Copy(s, 1, Length(s) - 4) + '\'; // new_vegas\ should already have been added in MODL
//                  if AnsiPos('new_vegas\', s) <> 1 then // new_vegas\ should already have been added in MODL
//                    s := 'new_vegas\' + Copy(s, 1, Length(s) - 4) + '\';
          s := StringReplace(s, '\\', '\', [rfReplaceAll]);
          elementvaluestring := s + stringreplace(elementvaluestring, ':', '#', [rfReplaceAll]) + '.BGSM';
        end;
        if elementpathstring = 'Material Substitutions\Substitution\SNAM' then
        begin
          elementvaluestring := 'new_vegas\MSWP\' + Copy(elementvaluestring, 1, (LastDelimiter('[', elementvaluestring) - 2)) + '.BGSM';
        end;
      end;
      if elementpathstring <> 'Return' then begin
        var failed := CreateElement(newrec, originalloadorder, fileloadorder, elementpathstring, elementvaluestring, StrToInt(elementinteger), elementisflag, ToFileManaged, originalFormID);

        if failed = 1 then
          Exit;
      end;
    end
    else
    begin
      elementvaluestring := IntToHex(FormID(newrec.ContainingMainRecord), 8);
      if ((AnsiPos('Return', elementpathstring) <> 1) AND (elementpathstring <> '')) then
      begin
        var failed := CreateElement(rec, originalloadorder, fileloadorder, elementpathstring, elementvaluestring, StrToInt(elementinteger), elementisflag, ToFileManaged, originalFormID);

        if failed = 1 then Exit;
      end;
    end;
//            newrec := rec;
  end
  else if (elementpathstring <> '') then
  begin
      var newValue := GetNewElementValue(originalElementvaluestring, ToFileManaged);

      var failed := CreateElement(rec, originalloadorder, fileloadorder, elementpathstring, newValue, StrToInt(elementinteger), elementisflag, ToFileManaged, originalFormID);
      if failed = 1 then
        Exit;
  end;

  if Assigned(OriginRec1) then
  begin
    rec := OriginRec1;
    if Assigned(newrec) then
      previousrec2 := OriginRec2
    else
      previousrec := OriginRec2;
    OriginRec1 := Nil;
    OriginRec2 := Nil;
  end;
end;


procedure AssignValuesForRecord(
  ToFile: IwbFile;
  ToFileManaged: TConverterManagedFile;
  fileloadorder: string; 
  originalloadorder: string; 
  _Signature: string; 
  filename: string; 
  display_progress: Boolean; 
  slContinueFrom: TStringList; 
  i: Integer;
  var newrec: IwbContainer;
  var OriginRec1: IwbContainer;
  var OriginRec2: IwbContainer;
  fromRec: IwbMainRecord
);
begin
  var fromRecFormID := IntToStr(GetLoadOrderFormID(fromRec));

  //////////////////////////////////////////////////////////////////////////
  ///  Get Record
  //////////////////////////////////////////////////////////////////////////
  if IsEditorReference(fromRecFormID) and (ToFile.Name = 'FalloutNV.esm') then
    Exit;

  var originalFormID := GetOriginalFormIDHex(fromRec);
  var newFormID := ToFileManaged.GetNewFormID(originalFormID);

  var rec: IwbContainer := ToFileManaged.RecordByNewFormID(newFormID);

  if GetFileName(GetFile(rec)) <> GetFileName(ToFile) then begin
    if GetFileName(GetFile(rec)) = '' then begin
      AddMessage('WARNING: empty record filename');

      Exit;
    end else begin
      AddMessage(fileloadorder);
      AddMessage(originalloadorder);
      AddMessage('Record filename: ' + GetFileName(GetFile(rec)));
      AddMessage('Target filename: ' + GetFileName(ToFile));
      AddMessage(originalFormID);
      AddMessage(Name(rec));
      AddMessage('FATAL ERROR: Rec selected in wrong file');

      Exit;
    end;
  end;

  if OverwriteRecs and (_Signature <> 'CELL') then begin
    var recFormID := rec.ContainingMainRecord.LoadOrderFormID;

    newrec := GetContainer(rec);
    Remove(rec);
    rec := Add(newrec, _Signature, True) as IwbContainer;

    if not Assigned(rec) then
      raise Exception.Create('Record could not be created');

    newrec := Nil;
    SetLoadOrderFormID(rec.ContainingMainRecord, recFormID);
    if not Assigned(rec) then begin
      raise Exception.Create('Overwrite Failed');
    end;
  end;

  //////////////////////////////////////////////////////////////////////////
  ///  Convert Element Data For Fallout 4
  //////////////////////////////////////////////////////////////////////////
  wbGameMode := gmFNV;
  ConvertData(
    fromRec,
    _Signature,
    ToFileManaged,
    ToFile,
    rec,
    originalloadorder,
    fileloadorder,
    originalFormID,
    newrec,
    OriginRec1,
    OriginRec2
  );
  wbGameMode := gmFO4;

  if Assigned(newrec) then
  begin
    newrec := Nil;
    previousrec := previousrec2;
  end;

  if Signature(rec.ContainingMainRecord) = 'IDLM' then
    if ElementCount(ElementByPath(rec, 'IDLA') as IwbContainer) = 1 then
      if GetEditValue(ElementByPath(rec, 'IDLA\Animation #0')) = 'NULL - Null Reference [00000000]' then
        Remove(ElementByPath(rec, 'IDLA'));

  if Signature(rec.ContainingMainRecord) = 'LTEX' then
    if GetElementEditValues(rec, 'TNAM') = 'NULL - Null Reference [00000000]' then
      Remove(ElementByPath(rec, 'TNAM'));

  if Signature(rec.ContainingMainRecord) = 'LVLN' then
    CleanLVLN(rec);

  if Signature(rec.ContainingMainRecord) = 'IPDS' then
    CleanIPDS(rec);

  if Signature(rec.ContainingMainRecord) = 'MGEF' then
    if GetElementEditValues(rec, 'Magic Effect Data\DATA\Actor Value') = 'FFFF - None Reference [FFFFFFFF]' then
      SetElementEditValues(rec, 'Magic Effect Data\DATA\Actor Value', '00000000');

  if Signature(rec.ContainingMainRecord) = 'SPEL' then
    if Assigned(ElementByPath(rec, 'Effects')) then
      if ElementCount(ElementByPath(rec, 'Effects') as IwbContainer) = 1 then
        if GetElementEditValues(rec, 'Effects\Effect\EFID') = 'NULL - Null Reference [00000000]' then
          SetElementEditValues(rec, 'Effects\Effect\EFID', 'AshPileOnDeathEffect "Ash Pile On Death" [MGEF:001A692F]');

  if Signature(rec.ContainingMainRecord) = 'WRLD' then
    if GetElementEditValues(rec, 'ZNAM') = 'NULL - Null Reference [00000000]' then
      Remove(ElementByPath(rec, 'ZNAM'));

  /// Music
  if Signature(rec.ContainingMainRecord) = 'CELL' then
    if GetElementEditValues(rec, 'XCMO') = 'NULL - Null Reference [00000000]' then
      Remove(ElementByPath(rec, 'XCMO'));

  CleanConditions2(rec);

  iAliasCounter := 1;

  if CheckForErrors(rec.ContainingMainRecord) <> '' then
  begin
    AddMessage(Name(rec));
    AddMessage(CheckForErrors(rec));
      
    Exit;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
///  INITIALIZE
///  WRLD / CELL / REFR
////////////////////////////////////////////////////////////////////////////////

function FNVImportInitialize(Files: TwbFiles; AddNewFileName: TFuncType; fromCSVs: Boolean = True; FromFile: IwbFile = nil): integer;
var
///  s is for temporary strings
///  k is for temporary loops
i, j, k, l, m, LastSingleValueIndex: integer;

elementpathstring,
filename,
fileloadorder,
originalloadorder,
elementvaluestring,
newfilename,
elementinteger,
elementisflag,
_Signature,
_ConversionFile,
elementnewrec,
s: String;

rec, OriginRec1, newrec, OriginRec2: IwbContainer;
ToFile: IwbFile;

slContinueFrom, sl, sl2: TStringList;

display_progress, FirstFileLoop: Boolean;
begin
  AddMessage('Initializing...');

  _Files := Files;

  var converterFM := TConverterFileManager.Create(AddNewFileName, Files);

  //////////////////////////////////////////////////////////////////////////////
  ///  Method 2
  //////////////////////////////////////////////////////////////////////////////
  iAliasCounter := 1;
  slSingleValues := TStringList.Create;
  slNewRec := TStringList.Create;
  slNewRecSig := TStringList.Create;
  slSingleRec := TStringList.Create;
  slOldNewValMatch := TStringList.Create;
  slNewPathorOrder := TStringList.Create;
  slOldVal := TStringList.Create;
  slNewVal := TStringList.Create;
  slOldIndex := TStringList.Create;
  slNewIndex := TStringList.Create;
  slReplaceAnyVal := TStringList.Create;
  slReplaceAnyIndex := TStringList.Create;
  slIsFlag := TStringList.Create;
  sl := TStringList.Create;
  sl2 := TStringList.Create;
  slPathsLookup := TStringList.Create;
  slEntryLength := TStringList.Create;
  slTemporaryDelimited := TStringList.Create;

  //////////////////////////////////////////////////////////////////////////////
  ///  Create Lists
  //////////////////////////////////////////////////////////////////////////////
	slloadorders := TStringList.Create;
	slReferences := TStringList.Create;
	slfailed := TStringList.Create;
	slfilelist := TStringList.Create;

  // Create a dummy to enter loops.
  slfilelist.Add('');
    
  SortFileList;
	slrecordconversions := TStringList.Create;
	slrecordconversions.LoadFromFile(wbProgramPath + 'ElementConversions\' + '__RecordConversions.csv');
  slContinueFrom := TStringList.Create;
  slContinueFrom.Delimiter := ';';
	slContinueFrom.StrictDelimiter := true;
  slFileExtensions := TStringList.Create;
  slFileExtensions.LoadFromFile(wbProgramPath + 'ElementConversions\' + '__FileExtensions.csv');
  slShortLookup := TStringList.Create;
  slShortLookupPos := TStringList.Create;

  //////////////////////////////////////////////////////////////////////////////
  ///  Debug Options
  //////////////////////////////////////////////////////////////////////////////
  if FileExists(wbProgramPath + 'data\__ContinueFrom.csv') then
  begin
    slContinueFrom.LoadFromFile(wbProgramPath + 'data\__ContinueFrom.csv');
    if slContinueFrom.Count > 0 then
    begin
      raise Exception.Create('Only __ContinueFrom.csv works if using CSVs');
    end;
  end;
  debugmode := True;
  display_progress := True;
  FirstFileLoop := True;
  ExitAfterFail := True;
  SaveOnExit := True;
  OverwriteRecs := True;

  if debugmode then
  begin
    if slContinueFrom.Count > 0 then
    begin
      for k := 0 to (slfilelist.Count - 1) do
      begin
        if slContinueFrom[0] = slfilelist[k] then
        begin
          for l := 0 to (k - 1) do
            slfilelist.Delete(0);
          Break;
        end;
      end;
    end;
  end;

  if SaveOnExit then
  begin
    if FileExists(wbProgramPath + 'data\' + '__FailedList.csv') then
      slfailed.LoadFromFile(wbProgramPath + 'data\' + '__FailedList.csv');
    if FileExists(wbProgramPath + 'data\' + '__ReferenceList.csv') then
      slReferences.LoadFromFile(wbProgramPath + 'data\' + '__ReferenceList.csv');
    if FileExists(wbProgramPath + 'data\' + '__Loadorders.csv') then
      slloadorders.LoadFromFile(wbProgramPath + 'data\' + '__Loadorders.csv');
  end;

	//CreatePathLookupList();

  //////////////////////////////////////////////////////////////////////////////
  ///  Start Import
  //////////////////////////////////////////////////////////////////////////////
  CreateRecords(slContinueFrom, converterFM, FirstFileLoop, AddNewFileName, fileloadorder, rec, elementvaluestring, fromCSVs, FromFile, ToFile);

  //////////////////////////////////////////////////////////////////////////////
  ///  Setup next Loop
  //////////////////////////////////////////////////////////////////////////////
  FirstFileLoop := True;

  var sortedFormIDs: TStringList := nil;
  sortedFormIDs := CreateSortedFormIDsList(FromFile);

  var lMax := 0;
  
  AddMessage('Assigning Values...');
  ////////////////////////////////////////////////////////////////////////////
  ///  Initialize
  ////////////////////////////////////////////////////////////////////////////
  filename := '';

  originalloadorder := Copy(IntToHex(FromFile.LoadOrder), 7, 2);
  newfilename := FromFile.FIleName;

  if (newfilename = 'FalloutNV.Hardcoded.keep.this.with.the.exe.and.otherwise.ignore.it.I.really.mean.it.dat') then
    newfilename := 'FalloutNV.esm';

  ////////////////////////////////////////////////////////////////////////////
  ///  Get File
  ////////////////////////////////////////////////////////////////////////////
  for k := 0 to (Length(_Files) - 1) do
    if GetFileName(_Files[k]) = newfilename then
    begin
      ToFile := _Files[k];
    end;
  if not Assigned(ToFile) then
    for k := 0 to (Length(_Files) - 1) do
      if Copy(GetFileName(_Files[k]), 1, (Length(GetFileName(_Files[k])) - 3)) = Copy(newfilename, 1, (Length(newfilename) - 3)) then
      begin
        ToFile := _Files[k];
      end;

  if not Assigned(ToFile) then
  begin
    raise Exception.Create('File ' + newfilename + ' not found');
  end;

  var ToFileManaged := converterFM.GetManagedFileByFilename(newfilename);

  m := sortedFormIDs.Count - 1;

  fileloadorder := IntToHex(GetLoadOrder(ToFile), 2);

  for i := 0 to m do begin
    if i mod 1000 = 0 then
      AddMessage(IntToStr(i) + '/' + IntToStr(m) + ' records converted');

    var formIDstr := sortedFormIDs[i];

    wbGameMode := gmFNV;

    var fromRec := FromFile.RecordByFormID[TwbFormID.FromStr(formIDstr), True, True];

    Assert(fromRec._File.FileName = FromFile.FileName);

    originalloadorder := Copy(IntToHex(FromFile.LoadOrder), 7, 2);

    _Signature := ConvertSignature(fromRec.Signature, slrecordconversions);

    if _Signature = '' then
      Continue;
          
    if _Signature <> _ConversionFile then
      UpdateElementConversions(_ConversionFile, _Signature, sl, sl2);

    wbGameMode := gmFO4;
          
    AssignValuesForRecord(
      ToFile,
      ToFileManaged,
      fileloadorder,
      originalloadorder,
      _Signature,
      filename,
      display_progress,
      slContinueFrom,
      i,
      newrec,
      OriginRec1,
      OriginRec2,
      fromRec
    );
  end;

  slContinueFrom.Free;

  if Assigned(ToFile) then begin
    RemoveRecordsToSkip(ToFile);

    for i := ToFile.RecordCount - 1 downto 0 do
      FNVImportCleanRecord(ToFile.Records[i]);

    if Assigned(ToFile) then begin
      SaveConvertedFile(ToFile);
    end;
  end;

  Result := 0;
end;

////////////////////////////////////////////////////////////////////////////////
//PROCESS
////////////////////////////////////////////////////////////////////////////////
//function Process(e: IInterface): integer;

function FNVImportFinalize: integer;
//var i: integer;
var
slFailedReferences: TStringList;
//i: integer;
begin
  AddMessage('Finalizing...');
  slReferences.SaveToFile(wbProgramPath + 'data\' + '__ReferenceList.csv');
	slfailed.SaveToFile(wbProgramPath + 'data\' + '__FailedList.csv');
	slloadorders.SaveToFile(wbProgramPath + 'data\' + '__Loadorders.csv');
  slFailedReferences := TStringList.Create;
//  slFailedReferences := AddMissingReferences(slReferences);
  if slFailedReferences.Count > 0 then
  begin
    AddMessage('WARNING: One or more References Still Need to be Added');
    slFailedReferences.SaveToFile(wbProgramPath + 'data\' + '__FailedReferences.csv');
  end;
	/// Lookup Lists
	slPathsLookup.Free;
	slTemporaryDelimited.Free;
	slEntryLength.Free;
	slShortLookup.Free;
	slShortLookupPos.Free;

	/// Columns
	slSingleValues.Free;
	slNewRec.Free;
	slNewRecSig.Free;
	slSingleRec.Free;
	slOldNewValMatch.Free;
	slNewPathorOrder.Free;
	slOldVal.Free;
	slNewVal.Free;
	slOldIndex.Free;
	slNewIndex.Free;
	slReplaceAnyVal.Free;
	slReplaceAnyIndex.Free;
	slIsFlag.Free;

	/// Sources
	slfilelist.Free;

	/// Logs
	slloadorders.Free;
	slReferences.Free;
	slfailed.Free;
	slrecordconversions.Free;
	slFileExtensions.Free;
  Result := 0;
end;

end.
