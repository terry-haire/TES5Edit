unit __FNVMultiLoop3;

///  Current Method for Acquiring data for use with importer
///  Creates List per Amount And sorts
///  Can move the sorting function into the savelist function to speed up
///  WIP

interface
uses
  __FNVMultiLoopFunctions,
  __FNVConversionFunctions,
  Classes,
  SysUtils,
  StrUtils,
  Windows,
  __ScriptAdapterFunctions,
  System.JSON,
  System.IOUtils,
  wbInterface; //Remove before use in xEdit

function Recursive(e: IwbContainer; slstring: String): String;
function ExtractInitialize: integer;
function ExtractFinalize: integer;
function ExtractFileHeader(f: IwbFile): integer;
function ExtractSingleCell(_File: IwbFile; formIDHex: string): TStringList;
procedure ExtractFile(TargetFile: IwbFile; var aCount: Cardinal; abShowMessages: Boolean; xeConvertCell: String = '');

implementation

var
slfilelist,
slSignatures,
slvalues,
slNifs,
sl3DNames,
slReferences,
slExtensions: TStringList;


function ToSafeString(s: String): String;
begin
  s := stringreplace(s, #13#10, '\r\n', [rfReplaceAll]);
  s := stringreplace(s, ';' , '\comment\', [rfReplaceAll]);
  s := stringreplace(s ,'"', '|CITATION|', [rfReplaceAll]);
  s := stringreplace(s,''#$D'', '\r\n', [rfReplaceAll]);

  Result := s;
end;


function RecursiveReferences(e: IwbContainer; slstring: TStringList; depth: Integer): TStringList;
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

    if ielement.Name = 'XTEL - Teleport Destination' then
      Continue;

    var linkedRec := ielement.LinksTo;

    if Assigned(linkedRec) then begin
      var r := linkedRec as IwbMainRecord;

      if (r.Signature <> 'CELL') and (not r.ElementExists['Cell']) then begin
        var formIDStr := r.FormID.ToString();

        if slstring.IndexOf(formIDStr) = -1 then begin
          slstring.Add(r.FormID.ToString());

          if depth < 6 then begin
            RecursiveReferences(r, slstring, depth + 1);
          end;
        end;
      end;
    end;

    ////////////////////////////////////////////////////////////////////////////
    ///  Exit Condition
    ////////////////////////////////////////////////////////////////////////////
    if Supports(ielement, IwbContainer, iContainer) and (iContainer.ElementCount > 0) then
      RecursiveReferences(iContainer, slstring, depth + 1);
	end;

	Result := slstring;
end;


function ExtractSingleCell(_File: IwbFile; formIDHex: string): TStringList;
begin
  if formIDHex = '' then begin
    Result := nil;

    Exit;
  end;

  var formID := TwbFormID.FromStr(formIDHex);

  var formIDCardinal := formID.ToCardinal;

  var rec := _File.RecordByFormID[formID, True, True];

  var formIDs := TStringList.Create;

  formIDs.Add(formID.ToString());

  RecursiveReferences(rec, formIDs, 0);

  for var j := 0 to _File.RecordCount - 1 do begin
    var r := _File.Records[j];

    if (r.ElementExists['Cell']) and (r.ElementByPath['Cell'].NativeValue = formID.ToCardinal) then begin
      var formIDStr := r.FormID.ToString();

      if formIDs.IndexOf(formIDStr) = -1 then begin
        formIDs.Add(formIDStr);

        RecursiveReferences(r, formIDs, 0);
      end;

    end;
  end;

  formIDs.Sort;

  for var i := 0 to formIDs.Count - 1 do begin
    var formID2 := TwbFormID.FromStr(formIDs[i]);

    AddMessage(_File.RecordByFormID[formID2, True, True].Name)
  end;

  Result := formIDs;
end;


function Recursive(e: IwbContainer; slstring: String): String;
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

		slstring := (slstring
//    stringreplace(
//     ,'"', '|CITATION|', [rfReplaceAll])
    + ';' + ToSafeString(ielement.Path)
    + ';' + ToSafeString(ielement.EditValue)
    + ';' + IntToStr(i));

    ////////////////////////////////////////////////////////////////////////////
    ///  Material Swap
    ////////////////////////////////////////////////////////////////////////////
    if (ielement.Name = 'Alternate Texture') and Supports(ielement, IwbContainer, iContainer) then
    begin
      if Assigned(iContainer.ElementByPath['3D Name']) then
      begin
        s := ielement.Container.Container.Elements[0].EditValue;
        if LastDelimiter('.', s) <> (Length(s) - 3) then s := '';
        slNifs.Add(s);
        _TXST := iContainer.ElementByPath['New Texture'].LinksTo as IwbContainer;
        s := s + ';' + GetElementEditValues(_TXST, 'EDID')
        + ';' + GetElementEditValues(iContainer, '3D Name')
        + ';' + GetElementEditValues(_TXST, 'Textures (RGB/A)\TX00')
        + ';' + GetElementEditValues(_TXST, 'Textures (RGB/A)\TX01')
        + ';' + GetElementEditValues(_TXST, 'Textures (RGB/A)\TX02')
        + ';' + GetElementEditValues(_TXST, 'Textures (RGB/A)\TX03')
        + ';' + GetElementEditValues(_TXST, 'Textures (RGB/A)\TX04')
        + ';' + GetElementEditValues(_TXST, 'Textures (RGB/A)\TX05') + ';';
        if Assigned(_TXST.ElementByPath['DNAM\No Specular Map']) then
          s := s + 'No Specular Map';
        slvalues.Add(s);
        sl3DNames.Add(GetElementEditValues(iContainer, '3D Name'));
      end;
    end;

    ////////////////////////////////////////////////////////////////////////////
    ///  File Reference
    ////////////////////////////////////////////////////////////////////////////
    valuestr := ielement.EditValue;
    if ((Length(valuestr) > 4) AND (LastDelimiter('.', valuestr) <> 0)) then
    for j := 0 to (slExtensions.Count - 1) do
    begin
      if Copy(valuestr, (Length(valuestr) - Length(slExtensions[j]) + 1), MaxInt) = slExtensions[j] then
      begin
        slReferences.Add(formatelementpath(ielement.Path) + ';' + valuestr);
        Break;
      end;
    end;

    ////////////////////////////////////////////////////////////////////////////
    ///  Exit Condition
    ////////////////////////////////////////////////////////////////////////////
    if Supports(ielement, IwbContainer, iContainer) and (iContainer.ElementCount > 0) then
      slstring := (Recursive(iContainer, slstring));
	end;
	Result := slstring;
end;
//
function savelist2(TargetFile: IwbFile; kLocal: integer; sl: TStringList): integer;
var
filename: String;
begin
	filename := (wbProgramPath + 'data\unsorted\' + TargetFile.FileName + '_LoadOrder_' + IntToHex(GetLoadOrder(TargetFile), 2) + '_' + IntToStr(kLocal) + '.csv');
	AddMessage('Saving list to ' + filename);
	sl.SaveToFile(filename);
	sl.Clear;
	slfilelist.Add(stringreplace(filename, (wbProgramPath + 'data\unsorted\'), '', [rfReplaceAll]));
	Result := kLocal + 1;
end;

function ExtractInitialize: integer;
begin
  ForceDirectories(wbProgramPath + '\data\unsorted');

	slfilelist := TStringList.Create;
  slSignatures := TStringList.Create;
  slvalues := TStringList.Create;
  slNifs := TStringList.Create;
  sl3DNames := TStringList.Create;
  slReferences := TStringList.Create;
  slExtensions := TStringList.Create;
  slExtensions.LoadFromFile(wbProgramPath + 'ElementConversions\' + '__FileExtensions.csv');
  Result := 0;
end;

function ExtractFileHeader(f: IwbFile): integer;
begin
  var JSONObject := TJSONObject.Create;

  try
    var masters := TJSONArray.Create;

    JSONObject.AddPair('loadorder', f.LoadOrder);
    JSONObject.AddPair('masters', masters);

    for var i := Low(f.AllMasters) to High(f.AllMasters) do begin
      var masterJSON := TJSONObject.Create;
      var master := f.AllMasters[i];

      masterJSON.AddPair('name', master.FileName);
      masterJSON.AddPair('loadorder', master.LoadOrder);

      masters.Add(masterJSON);
    end;

    var JSONString := JSONObject.ToString;
    var FileName := wbProgramPath + '\data\'+ f.FileName + '.json';

    TFile.WriteAllText(FileName, JSONString);
  finally
    // Make sure to free the JSON object after use
    JSONObject.Free;
  end;
end;

function ExtractRecordData(TargetFile: IwbFile; e: IwbMainRecord; formIDsToProcess: TStringList): TStringList;
var
slstring: String;
begin
  if Assigned(formIDsToProcess) and (formIDsToProcess.IndexOf(e.FormID.ToString) = -1) then begin
    Exit;
  end;

  if (e.Signature = 'DIST') and (wbGameMode = gmFO76) then begin
    Exit;
  end;

  var sl := TStringList.Create;

	// Compare to previous record
	slstring := (Signature(e) + ';' + IntToStr(GetLoadOrderFormID(e)) + ';' + IntToStr(ReferencedByCount(e)) + ';' + ToSafeString(FullPath(e)));

	var rec := e;

  slSignatures.Add(Signature(rec));

  if Signature(e) = 'NAVI' then begin
    sl.Add(Signature(e));
    sl.Add(IntToStr(GetLoadOrderFormID(e)));
    sl.Add(IntToStr(ReferencedByCount(e)));
    sl.Add(FullPath(e));
    RecursiveNAVI(e, sl);
  end else begin
    slstring := Recursive(e, slstring);

    sl.Add(slstring);
  end;

  Result := sl;
end;

function ExtractFinalize: integer;
var
i, j: Integer;
_Signature, _Grupname, filename: String;
slSorted, slfilelist2, slstring: TStringList;

begin

  //////////////////////////////////////////////////////////////////////////////
  ///  Save Lists
  //////////////////////////////////////////////////////////////////////////////
  if slvalues.Count > 0 then
  begin
    AddMessage('Saving ' + wbProgramPath + 'ElementConversions\MaterialSwaps.csv');
    slvalues.SaveToFile(wbProgramPath + 'ElementConversions\MaterialSwaps.csv');
    AddMessage('Saving ' + wbProgramPath + 'ElementConversions\MaterialSwapsNifs.csv');
    slNifs.SaveToFile(wbProgramPath + 'ElementConversions\MaterialSwapsNifs.csv');
    AddMessage('Saving ' + wbProgramPath + 'ElementConversions\MaterialSwaps3Names.csv');
    sl3DNames.SaveToFile(wbProgramPath + 'ElementConversions\MaterialSwaps3Names.csv');
  end;
  if slReferences.Count > 1 then
  begin
    AddMessage('Saving ' + wbProgramPath + 'ElementConversions\' + '__FileReferenceList.csv');
    slReferences.SaveToFile(wbProgramPath + 'ElementConversions\' + '__FileReferenceList.csv');
  end;

  //////////////////////////////////////////////////////////////////////////////
  ///  Free Lists
  //////////////////////////////////////////////////////////////////////////////
  slvalues.Free;
  slNifs.Free;
  sl3DNames.Free;
  slReferences.Free;
  slExtensions.Free;

  var recordList := TStringList.Create;

  slSorted := TStringList.Create;
  slfilelist2 := TStringList.Create;
  slstring := TStringList.Create;
  slstring.Delimiter := ';';
  slstring.StrictDelimiter := True;

  //////////////////////////////////////////////////////////////////////////////
  ///  Sort by Signature
  //////////////////////////////////////////////////////////////////////////////
  i := 0;
  while (i < slfilelist.Count) do
  begin
    if recordList.Count = 0 then
      recordList.LoadFromFile(wbProgramPath + 'data\unsorted\' + slfilelist[i]);

    slstring.DelimitedText := recordList[0];

    if slstring.Count = 0 then begin
      raise Exception.Create('0 count slstring in ' + slfilelist[i]);
    end;

    if slstring.Count = 1 then begin
      if slstring[0] = 'NAVI' then
      begin
        _Signature := 'NAVI';
        _Grupname := 'NAVI';
        slSorted.AddStrings(recordList);
        recordList.Clear;
        slstring.Clear;
      end;
    end;

    if slstring.Count > 0 then begin
      _Signature := slstring[0];

      if (slstring.Count >= 4) and (ansipos('GRUP', slstring[3]) <> 0) then	begin
        _Grupname := (copy(slstring[3], (ansipos('GRUP', slstring[3]) + 19), 4))
      end else begin
        _Grupname := _Signature;
      end;
    end;

    j := 0;
    while(j < recordList.Count) do
    begin
      slstring.DelimitedText := recordList[j];

      if ((_Signature <> '') AND (_Signature = slstring[0])) then begin
        if slSignatures.Count < recordList.Count then
          AddMessage('ERROR1');

        slSorted.Add(recordList[j]);
        recordList.Delete(j);
      end else if _Signature = '' then begin
        raise Exception.Create('Empty _Signature String: ' + slstring.DelimitedText);
      end else begin
        j := (j + 1);
      end;
    end;
    filename := (Copy(slfilelist[i], 1, LastDelimiter('_', slfilelist[i]))
    + 'GRUP_'
    + _Grupname
    + '_SIG_'
    + _Signature
    + '_'
    + IntToStr(i)
    + '.csv');
    slSorted.SaveToFile(wbProgramPath + 'data\' + filename);
    AddMessage('SAVED: ' + filename);
    slSorted.Clear;
    slfilelist2.Add(filename);
    if recordList.Count = 0 then i := (i + 1);
  end;

  recordList.Free;
	slfilelist2.SaveToFile(wbProgramPath + 'data\' + '_filelist.csv');
	slfilelist.Free;
  slSignatures.Free;
  slSorted.Free;
  slfilelist2.Free;
  Result := 0;
end;


procedure ExtractFile(TargetFile: IwbFile; var aCount: Cardinal; abShowMessages: Boolean; xeConvertCell: String = '');
begin
  ExtractFileHeader(TargetFile);

  var formIDsToProcess := ExtractSingleCell(TargetFile, xeConvertCell);
  var NPCList := TStringList.Create;
  var kLocal := 0;

  for var j := 0 to TargetFile.RecordCount - 1 do begin
    var Result: Variant;

    if not abShowMessages then
      wbProgressUnlock;

    try
      Inc(wbHideStartTime);

      try
        var rec := TargetFile.Records[j] as IwbMainRecord;

        if Signature(rec) = 'NAVI' then begin
          if NPCList.Count > 0 then
            kLocal := savelist2(TargetFile, kLocal, NPCList);
        end;

        var sl := ExtractRecordData(TargetFile, rec, formIDsToProcess);

        if Signature(rec) = 'NAVI' then begin
          kLocal := savelist2(TargetFile, kLocal, sl);
        end;

        NPCList.AddStrings(sl);

        sl.Free;

        if NPCList.Count > 4999 then
          kLocal := savelist2(TargetFile, kLocal, NPCList);
      finally
        Dec(wbHideStartTime);
      end;
    finally
      if not abShowMessages then
        wbProgressLock;
    end;

    Inc(aCount);

    wbCurrentProgress := 'Processed Records: ' + aCount.ToString;

    wbTick;
  end;

	if NPCList.Count > 0 then
    kLocal := savelist2(TargetFile, kLocal, NPCList);

	NPCList.Free;
end;

end.
