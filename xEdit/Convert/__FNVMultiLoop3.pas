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
function ExtractRecordData(TargetFile: IwbFile; e: IwbMainRecord; formIDsToProcess: TStringList): TStringList;

implementation

var
slSignatures,
slvalues,
slNifs,
sl3DNames,
slReferences,
slExtensions: TStringList;

useAdditionalLists: Boolean = False;


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
      if Assigned(iContainer.ElementByPath['3D Name']) and (useAdditionalLists) then begin
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
        if useAdditionalLists then
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

function ExtractInitialize: integer;
begin
  ForceDirectories(wbProgramPath + '\data\unsorted');

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
begin
  if Assigned(formIDsToProcess) and (formIDsToProcess.IndexOf(e.FormID.ToString) = -1) then begin
    Exit;
  end;

  if (e.Signature = 'DIST') and (wbGameMode = gmFO76) then begin
    Exit;
  end;

  var sl := TStringList.Create;

	// Compare to previous record
	var slstring := (Signature(e) + ';' + IntToStr(GetLoadOrderFormID(e)) + ';' + IntToStr(ReferencedByCount(e)) + ';' + ToSafeString(FullPath(e)));

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

begin

  //////////////////////////////////////////////////////////////////////////////
  ///  Save Lists (debugging)
  //////////////////////////////////////////////////////////////////////////////
//  if slvalues.Count > 0 then
//  begin
//    AddMessage('Saving ' + wbProgramPath + 'ElementConversions\MaterialSwaps.csv');
//    slvalues.SaveToFile(wbProgramPath + 'ElementConversions\MaterialSwaps.csv');
//    AddMessage('Saving ' + wbProgramPath + 'ElementConversions\MaterialSwapsNifs.csv');
//    slNifs.SaveToFile(wbProgramPath + 'ElementConversions\MaterialSwapsNifs.csv');
//    AddMessage('Saving ' + wbProgramPath + 'ElementConversions\MaterialSwaps3Names.csv');
//    sl3DNames.SaveToFile(wbProgramPath + 'ElementConversions\MaterialSwaps3Names.csv');
//  end;
//  if slReferences.Count > 1 then
//  begin
//    AddMessage('Saving ' + wbProgramPath + 'ElementConversions\' + '__FileReferenceList.csv');
//    slReferences.SaveToFile(wbProgramPath + 'ElementConversions\' + '__FileReferenceList.csv');
//  end;

  //////////////////////////////////////////////////////////////////////////////
  ///  Free Lists
  //////////////////////////////////////////////////////////////////////////////
  slvalues.Free;
  slNifs.Free;
  sl3DNames.Free;
  slReferences.Free;
  slExtensions.Free;

  slSignatures.Free;
  Result := 0;
end;

end.
