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
function ExtractRecordData(e: IwbMainRecord): integer;
function ExtractInitialize: integer;
function ExtractFinalize: integer;
function ExtractFileHeader(f: IwbFile): integer;
function ExtractSingleCell(_File: IwbFile; formIDHex: string): TStringList;

implementation

var
NPCList,
slfilelist,
slSignatures,
slGrups,
slvalues,
slNifs,
sl3DNames,
slReferences,
slExtensions: TStringList;
k: integer;
rec: IwbMainRecord;
loadordername, grupname: String;


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
function savelist2(rec: IwbMainRecord; k: integer; grupname: String): integer;
var
filename: String;
begin
	filename := (wbProgramPath + 'data\unsorted\' + GetFileName(rec) + '_LoadOrder_' + IntToHex(GetLoadOrder(GetFile(rec)), 2) + '_' + IntToStr(k) + '.csv');
	AddMessage('Saving list to ' + filename);
	NPCList.SaveToFile(filename);
	NPCList.Clear;
	slfilelist.Add(stringreplace(filename, (wbProgramPath + 'data\unsorted\'), '', [rfReplaceAll]));
	Result := k + 1;
end;

function ExtractInitialize: integer;
begin
  ForceDirectories(wbProgramPath + '\data\unsorted');

	NPCList := TStringList.Create;
	slfilelist := TStringList.Create;
  slSignatures := TStringList.Create;
  slGrups := TStringList.Create;
  slvalues := TStringList.Create;
  slNifs := TStringList.Create;
  sl3DNames := TStringList.Create;
  slReferences := TStringList.Create;
  slExtensions := TStringList.Create;
  slExtensions.LoadFromFile(wbProgramPath + 'ElementConversions\' + '__FileExtensions.csv');
	k := 0;
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

function ExtractRecordData(e: IwbMainRecord): integer;
var
slstring: String;
begin
  if (e.Signature = 'DIST') and (wbGameMode = gmFO76) then begin
    Exit;
  end;

//  if (e.FixedFormID.ToString(True) = '00151033') or (e.FixedFormID.ToString(True) = '00151034') or (e.FixedFormID.ToString(True) = '00150FC0') then begin
//    Result := 0;
//
//    Exit;
//  end;

  //AddMessage(e.FixedFormID.ToString(True));

	// Compare to previous record
  if (Assigned(rec) AND (loadordername <> GetFileName(e))) then
	begin
		if NPCList.Count > 0 then k := savelist2(rec, k, grupname);
    k := 0;
		rec := Nil;
		loadordername := GetFileName(e);
		AddMessage('Went To Different File');
	end;
	// Compare to previous record            stringreplace(stringreplace(FullPath(e), #13#10, '\r\n', [rfReplaceAll]), ';' , '\comment\', [rfReplaceAll])
	slstring := (Signature(e) + ';' + IntToStr(GetLoadOrderFormID(e)) + ';' + IntToStr(ReferencedByCount(e)) + ';' + ToSafeString(FullPath(e)));
  if GetLoadOrderFormID(e) = 1211171 then
    AddMessage('a');

	rec := e;
	loadordername := GetFileName(rec);
  if ansipos('GRUP', FullPath(rec)) <> 0 then	grupname := (copy(FullPath(rec), (ansipos('GRUP', FullPath(rec)) + 19), 4))
  else grupname := Signature(rec);
  slSignatures.Add(Signature(rec));
  slGrups.Add(grupname);

  if e.LoadOrderFormID.ToCardinal = 1380288 then begin
      NPCList.Add(
        'LAND;1380288;0; \ [00] FalloutNV.esm \ [53] GRUP Top |CITATION|WRLD|CITATION| \' +
        ' [19] GRUP World Children of TheStripWorldNew |CITATION|The Strip|CITATION| [WRLD:0013B308] \' +
        ' [4] GRUP Exterior Cell Block 0, -1 \ [15] GRUP Exterior Cell Sub-Block 3, -1 \' +
        ' [91] GRUP Cell Children of [CELL:0014F962] (in TheStripWorldNew |CITATION|The Strip|CITATION| [WRLD:0013B308] at -6,26) \' +
        ' [0] GRUP Cell Temporary Children of [CELL:0014F962] (in TheStripWorldNew |CITATION|The Strip|CITATION| [WRLD:0013B308] at -6,26) \' +
        ' [0] [LAND:00150FC0];LAND \ Cell;[CELL:0014F962] (in TheStripWorldNew |CITATION|The Strip|CITATION| [WRLD:0013B308] at -6,26);0;LAND \' +
        ' Record Header;;1;LAND \ Record Header \ Signature;LAND;0;LAND \ Record Header \ Data Size;4088;1;LAND \ Record Header \ Record Flags;' +
        '0000000000000000001;2;LAND \ Record Header \ Record Flags \ Compressed;1;0;LAND \ Record Header \ FormID;[LAND:00150FC0];3;' +
        'LAND \ Record Header \ Version Control Master FormID;350220;4;LAND \ Record Header \ Form Version;15;5;LAND \ Record Header \ Version Control Info 2;0;6'
      );
  end else if e.LoadOrderFormID.ToCardinal = 1380403 then begin
      NPCList.Add(
        'LAND;1380403;0; \ [00] FalloutNV.esm \ [53] GRUP Top |CITATION|WRLD|CITATION| \ [19] GRUP World Children of TheStripWorldNew |CITATION|The Strip|CITATION| [WRLD:0013B308] \ [5] GRUP Exterior Cell Block -1, -1 \ [1] GRUP Exterior Cell Sub-Block -3, -4 \ [1' +
        '17] GRUP Cell Children of [CELL:0014F8EF] (in TheStripWorldNew |CITATION|The Strip|CITATION| [WRLD:0013B308] at -27,-24) \ [0] GRUP Cell Temporary Children of [CELL:0014F8EF] (in TheStripWorldNew |CITATION|The Strip|CITATION| [WRLD:0013B308] at -27,-24) \' +
        ' [0] [LAND:00151033];LAND \ Cell;[CELL:0014F8EF] (in TheStripWorldNew |CITATION|The Strip|CITATION| [WRLD:0013B308] at -27,-24);0;LAND \ Record Header;;1;LAND \ Record Header \ Signature;LAND;0;LAND \ Record Header \ Data Size;3779;1;LAND \ Record Header ' +
        '\ Record Flags;0000000000000000001;2;LAND \ Record Header \ Record Flags \ Compressed;1;0;LAND \ Record Header \ FormID;[LAND:00151033];3;LAND \ Record Header \ Version Control Master FormID;350220;4;LAND \ Record Header \ Form Version;15;5;LAND \ Record ' +
        'Header \ Version Control Info 2;0;6;LAND \ DATA - Unknown;19 00 00 00;2;LAND \ VNML - Vertex Normals;BE 17 69 C8 0E 70 CD 08 73 C1 03 6D AF 03 61 AA 05 5C AB 09 5D AA 0E 5C AC 0F 5D AF 0E 60 B2 05 63 B2 FD 64 AB F6 5C A5 F0 56 A1 F1 51 9E F2 4E 9C F3 4C 9' +
        '8 F3 47 97 F1 44 94 EF 3F 91 EC 39 8F E7 33 8F E4 30 90 DF 30 91 DE 32 92 DF 34 92 E4 37 90 EC 38 90 FA 3B 96 0A 44 B0 2F 55 EB 54 5C 17 5D 52 B5 0F 65 C3 0A 6E C8 03 71 BE 00 6C B1 00 62 AD 05 5F AF 0C 60 AF 14 5F AD 19 5C AB 14 5B AC 0B 5D AA FE 5C A6 F' +
        '0 57 A4 ED 54 A2 EC 52 9F F0 4F 9C F0 4B 98 F2 47 96 F2 43 93 EF 3D 90 EE 37 8E EB 32 8D E9 2F 8E E7 30 90 E5 34 91 E9 38 91 F2 3B 93 02 3F 96 14 42 A5 30 49 CE 4F 55 FF 60 52 21 63 48 B3 05 64 BD 03 6B C2 FD 6E BE F6 6B B4 F9 64 B0 FD 62 B3 05 64 B3 0C 6' +
        '3 AD 0F 5E A7 0D 59 A5 04 57 A3 F8 55 A3 F2 54 A3 EE 53 A2 EF 53 9F F1 50 9B F2 4B 98 F3 47 95 F2 42 92 F1 3C 8F F0 36 8C F1 31 8C F3 30 8C F6 31 8E FB 37 91 01 3D 96 12 42 9C 22 45 A6 36 46 BA 4B 49 DF 5D 4E 0D 65 4B 23 62 47 B3 00 64 BB FF 6A BD FA 6B B' +
        'A F4 68 B5 F1 64 B6 F5 66 B9 FD 68 B4 FF 65 AD FE 5F A5 FB 57 A1 F9 52 A1 F6 52 A1 F4 52 A3 F5 54 A2 F9 54 9F FA 51 9B FC 4B 97 FA 46 94 F8 41 91 F8 3B 8E F8 36 8C FF 33 8C 06 32 8E 11 35 93 1C 39 9A 29 3E A3 36 42 AC 42 43 B8 4E 44 C6 58 45 EA 65 49 0D 6' +
        '5 4A 22 61 4A B4 05 65 B9 06 68 B9 01 68 B7 FA 67 B4 F8 64 B9 F7 68 B9 F4 68 B3 F1 63 AB EC 5B A5 EB 55 A3 F0 54 A1 F4 52 A1 F6 53 A4 F8 56 A4 FF 57 9F 02 51 9B 03 4C 96 02 45 94 01 41 90 01 3B 90 09 39 90 14 36 92 22 35 97 2E 35 9E 38 38 A8 43 3C B0 4C 3' +
        'E B9 53 3F BF 57 40 CE 5F 43 E9 65 48 09 65 4B 1A 5F 4F B6 15 64 B9 14 66 B5 12 64 B2 0C 62 B2 06 63 B3 FC 64 B5 F1 64 B0 E8 5E AB E2 58 A8 E6 57 A5 EB 55 A3 EF 53 A3 F3 55 A7 F8 59 A7 FE 59 A1 01 54 9B 04 4C 96 04 45 94 06 41 93 0C 3F 94 16 3D 97 25 3B 9' +
        'B 32 38 9E 3A 36 A4 42 38 AB 48 3B B3 4D 3F BA 52 41 C0 57 42 D0 5F 44 E6 65 47 00 64 4D 0D 5E 54 B5 20 60 B8 1C 64 B7 1C 63 B1 1D 5E AD 14 5D AB 08 5D AB F8 5D AA E7 59 AA E4 58 AA E5 59 A7 E7 56 A5 EB 55 A6 EE 57 AA F2 5C A9 F3 5B A3 F6 55 9C F8 4D 97 F' +
        'C 46 95 02 44 95 0A 43 97 16 43 9A 23 42 9A 29 3E 9B 30 3B 9D 32 3D A3 38 41 AE 42 46 B6 49 48 C3 54 48 D2 5D 47 E5 63 4A F5 64 4C F7 5C 56 B1 20 5D B7 1F 62 B9 1F 64 B1 1E 5E A9 1B 57 A5 10 56 A2 02 54 A4 F9 56 A7 F3 59 A8 EE 59 A8 EA 58 A6 EB 56 A8 EA 5' +
        '8 AB E9 5A AA E7 59 A4 E7 53 9F E6 4C 9A ED 48 99 F5 48 98 FE 48 99 06 49 98 0A 47 97 0C 45 95 0E 41 96 12 42 9F 20 4B AB 2F 50 BC 41 54 CA 52 4F D9 5C 4D E5 63 4A EB 61 4E E4 5B 53 B0 14 5F B6 15 64 B9 17 66 B1 1A 5F A7 17 57 A1 14 50 A0 0E 50 A1 0A 52 A' +
        '3 04 56 A4 FE 57 A4 F8 56 A5 F0 56 A6 EF 57 AA EA 59 A8 E5 57 A3 E2 50 9F E2 4B 9E E2 4A 9C E9 4A 9C EE 4B 9B F3 4B 99 F5 48 96 F4 44 95 F4 43 9A 00 4A A3 12 53 B6 2D 5C CA 44 5B D9 54 56 E5 5E 4F E7 61 4D E1 60 4C D6 58 50 AF 03 61 B6 04 66 BB 09 69 B3 0' +
        'E 63 A6 10 57 A1 11 51 9F 13 4E 9F 10 50 A1 0C 52 A2 07 54 A0 02 53 A2 FE 54 A4 FB 56 A5 F5 57 A4 EE 54 A1 E9 4F 9E E7 4B 9E E7 4B 9F E6 4C 9E ED 4D 9C F2 4C 98 F4 47 96 F6 44 98 FF 48 A0 0C 52 B5 29 5D CE 43 5F DE 52 5A EB 5C 54 EB 5F 51 E8 60 4F DC 5C 4' +
        'E D0 57 4D AF F5 61 B9 F7 68 BF FA 6C B5 FD 65 A8 02 5B A2 07 54 9E 09 50 9E 09 4F 9F 07 51 9F 05 51 A0 05 52 A1 07 52 A2 04 54 A2 00 54 A0 FB 52 9D F4 4D 9C F3 4C 9C F5 4C 9E F6 4F A0 F9 51 9E 00 4F 99 06 49 9A 12 48 A0 20 4B B3 37 54 D0 4D 57 E0 57 56 E' +
        'E 5E 52 EF 5F 52 EF 60 51 E6 5D 51 D9 5A 50 CA 53 4E B2 E8 60 BB EB 68 C1 EC 6C B8 EE 66 AC F2 5D A3 F5 55 9F F7 50 9E F8 4F 9F F9 50 A1 FE 53 A2 02 54 A2 08 54 A1 0A 52 9F 05 51 9D 00 4F 9C FF 4D 9B FE 4C 9D 02 4E 9F 07 50 A3 0E 54 A3 17 53 A3 25 4D A6 3' +
        '2 49 B2 43 49 CA 55 4C DD 5D 4D EB 62 4D ED 61 4E EF 60 51 E9 5B 54 E0 56 57 D1 50 55 C2 48 53 B3 E3 60 BF E3 68 C1 E4 6A B9 E4 64 AD E4 5B A5 E4 53 A1 E7 50 A0 EA 4F A2 EF 52 A4 F6 56 A6 FE 58 A4 08 56 A0 09 52 9D 07 4F 9C 01 4D 9B 00 4C 9E 05 4F A0 0C 5' +
        '1 A4 18 53 AB 25 55 B1 32 54 B2 3D 4E B6 47 49 C3 54 48 D2 5C 49 E2 61 4B E5 5F 4F E6 5B 54 E0 54 59 D9 49 60 D2 3F 63 C3 31 63 B4 29 5C B4 E5 61 BF E3 68 C2 E3 6A B6 DF 61 AC DD 57 A7 E0 53 A3 E5 51 A2 E8 51 A5 EB 55 A9 F1 5A AB FB 5E A8 01 5B A1 07 53 9' +
        'C 06 4D 9B 04 4B 9D 06 4F A1 0C 52 A7 18 56 AE 28 57 B8 37 58 BE 42 55 BC 46 50 C0 4E 4C C5 52 4C D1 56 4F D7 55 54 D6 4D 5B D1 40 62 CA 30 67 C6 27 69 BF 1D 68 B6 0F 65 AD 08 5F B3 EE 63 BE ED 6A BC E8 68 B1 E3 5E AB E3 58 A7 E6 56 A4 EB 54 A2 F1 53 A6 F' +
        '3 58 AD F5 5F AF FA 61 AB FE 5E A2 00 54 9C 04 4E 9C 09 4D 9F 0F 50 A5 16 55 B0 1F 5C B9 2F 5D C1 3A 5D C0 3B 5B BE 3E 58 BC 40 55 BE 41 55 C2 3B 5D C3 30 63 BC 22 65 B9 12 67 BD 07 6B BD 03 6B BA 02 69 B1 00 62 AC FF 5E B3 FA 64 BB F7 69 B7 F0 66 AF F0 5' +
        'F A9 F2 5A A7 F4 59 A6 F8 58 A4 FD 56 A7 00 59 AC FD 5E B1 FA 62 AB F8 5D A4 F8 56 A0 02 52 9F 0C 50 A3 14 53 A9 1B 57 B1 1B 5F BC 18 68 BA 1A 66 BA 18 66 B8 1A 64 B4 1A 61 B1 17 60 B0 14 5F B2 04 63 B1 FA 62 B4 F3 64 B9 F0 67 C0 F0 6C BB F3 69 B2 F7 63 A' +
        'D FB 5F B5 FA 65 B7 F7 67 B5 F7 65 AF F7 60 A9 F8 5B A8 F8 5B A8 FB 5A A5 FE 58 A5 FC 58 AA F8 5C AD F1 5E AB EA 5B A7 EC 57 A6 F0 57 A3 FB 55 A4 05 57 A7 06 59 AA 05 5C B4 FC 65 B9 F7 68 B8 F6 67 B7 F4 66 B3 F7 63 AF FA 60 AE FE 60 AB FB 5E AD F5 5F B3 E' +
        'E 63 BC F0 69 C0 F3 6C BD F2 6A B5 F7 65 B0 FB 62 B3 F4 63 BA F5 69 B7 FA 67 AE FC 60 A8 FB 5B A8 FB 5B A8 FB 5B A5 F8 57 A4 F6 56 A8 F2 59 A9 ED 5A A9 E8 58 A9 E5 57 A9 E6 57 AA EA 59 A8 F0 59 A7 F3 59 AB F5 5D B1 F7 62 B7 F4 66 B7 F1 66 B8 F2 67 B7 F7 6' +
        '7 B5 03 65 AF 09 61 AB 0A 5D AA 08 5C B1 07 62 BD 03 6B BE 01 6C BD FD 6B B9 01 68 B7 09 67 B3 FB 64 BB FD 6A B9 FF 68 AF 03 61 A9 05 5B A8 05 5B A7 02 59 A3 00 55 A3 FE 55 A5 FB 58 A7 F9 59 A6 F8 58 A6 F6 58 A9 F5 5A AA F7 5C A8 F8 5B A8 FB 5B AD FE 5F B' +
        '2 00 64 B4 03 65 B8 04 68 BB 09 69 BF 14 6B BD 1C 67 B3 1E 60 AE 21 5A AF 24 5A B3 27 5C B9 21 63 BC 19 67 BD 17 68 BE 16 69 C5 26 69 B5 FD 65 BD FF 6B BB 03 6A B2 06 63 AA 08 5C A7 07 59 A5 05 58 A3 06 55 A2 07 54 A5 08 57 A7 08 59 A6 08 58 A6 0A 58 A9 0' +
        'B 5A AA 0B 5C AA 0E 5C AA 11 5B AE 12 5E B5 12 64 B8 14 66 BC 19 67 C3 22 69 C8 27 6A C1 29 65 B9 29 60 B5 2E 5A B4 33 57 B6 35 57 B8 37 58 BD 31 5F C0 30 62 C9 34 65 D4 3C 66 B4 FD 65 C0 FD 6D BF 02 6C B3 06 64 AA 07 5C A7 08 59 A6 08 58 A4 0A 56 A4 0D 5' +
        '5 A6 10 57 A8 12 59 A8 16 58 A9 1A 57 AA 1B 59 AD 1D 5B AE 1F 5B AF 24 5A B1 27 5A B4 24 5F BB 22 64 C4 29 67 C9 2D 68 C7 2B 68 C3 26 68 BB 28 62 B9 2C 5F B9 34 5B B9 39 57 BA 3C 56 BC 3C 58 C2 3C 5C CD 3D 62 D5 3D 66 B7 FA 67 C3 FD 6F C2 00 6E B6 03 66 A' +
        'C 08 5E A7 09 59 A7 0B 59 A6 0D 57 A5 10 56 A7 11 57 AB 14 5B AD 1B 5B AB 21 58 AC 23 58 AF 24 5A B2 26 5B B3 2A 5B B1 2B 59 B4 2A 5B BE 2B 62 C6 2D 67 C9 2E 68 C4 29 67 BE 22 66 BD 20 66 BD 25 64 BD 2A 62 BB 30 5E BA 35 5A BA 36 5A BE 36 5D C5 34 63 CE 2' +
        'E 6B B6 FE 66 C5 FD 70 C4 FD 6F B9 FD 68 AE 00 60 A8 05 5B A8 07 5B A7 0B 59 A5 0C 57 A7 0D 59 AE 13 5E B0 17 5F AE 1D 5B AD 21 59 AE 21 5A B2 22 5D B4 26 5E B1 27 5A B2 28 5B BA 27 62 C5 26 69 C5 20 6B BB 18 67 B9 13 67 BA 0E 68 BE 0D 6B BF 14 6A BD 1C 6' +
        '7 B8 20 62 B5 23 60 B7 1F 62 BA 1B 66 C1 15 6B B5 FD 65 C2 FB 6E C3 F6 6E B8 F6 68 B1 F4 62 AB FC 5D AA 00 5C A9 04 5C A6 08 58 A9 0C 5A AF 0F 60 B2 10 62 B0 14 5F AC 16 5B AD 19 5C B2 1D 5F B5 1E 61 B1 1E 5E B0 22 5B B6 1E 62 BC 16 68 BB 0D 69 B7 09 67 B' +
        '4 02 65 B7 FA 67 BF F9 6C C5 FD 70 BF 02 6C B9 06 68 B1 05 62 B1 03 62 B9 01 68 BB 03 6A B5 F7 65 C0 F6 6C C1 F4 6D B7 F4 66 B1 F1 61 AF F1 60 AD F7 5E AB FB 5E A8 FE 5B AA 00 5C AE 00 60 B2 03 64 B1 04 62 AD 08 5F AD 08 5F B1 08 62 B3 0C 63 B1 0F 61 AE 1' +
        '0 5F AD 0E 5E B4 05 65 B9 00 68 B4 FD 65 AF F7 60 B4 F5 64 C0 F3 6C C7 F3 70 C3 F6 6E B7 F4 66 B1 F1 61 B2 F3 63 B9 F4 68 BC F4 6A B5 F7 65 C1 F7 6D C0 FA 6D B5 F7 65 AF F4 60 AF F2 60 AF F1 60 AD F4 5E A9 F5 5A AA F4 5C B1 F4 62 B5 F7 65 B2 FA 63 AD FB 5' +
        'F AB F8 5D B3 F9 64 B6 FD 67 B2 00 63 AD 00 5F AC FE 5E B1 FD 62 B5 F9 65 B1 F1 61 AF EF 5F B5 EE 64 C2 F0 6D C8 F2 70 C2 F5 6D B5 F4 65 B0 F2 61 B3 F1 63 B9 F2 68 BE F0 6A B6 FA 66 C2 FD 6E BF FC 6C B3 FA 64 AD FB 5F AD F8 5F AF F7 60 AD F8 5F A8 F6 5A A' +
        'A F5 5C B1 F5 62 B7 F7 67 B4 F9 64 AC F8 5E AC F8 5E B5 FA 65 B7 FA 67 B2 FA 63 AD F8 5F AB F8 5D B1 F9 62 B1 F7 62 AE F2 5F AE EF 5E B6 EF 65 C6 F3 6F CD F8 73 C3 FD 6F B4 00 65 AF 00 61 B3 FE 64 B9 FD 68 B7 F6 67 B9 FD 68 C2 FC 6E BD FA 6B B4 FD 65 AD F' +
        'E 5F AC FD 5E AF FA 60 AC F8 5E A7 F8 59 AA FA 5C B3 FA 64 B7 F9 67 B3 F7 64 AC F7 5E AD FB 5F B4 FC 65 B7 FA 67 B1 F7 62 AC F5 5D AD F8 5F B1 FA 62 AF F8 61 AB F8 5D AE F7 5F B9 FA 68 CA FD 72 D1 00 75 C7 06 71 B7 0C 66 AF 0D 60 B1 0C 62 B4 03 65 B2 FD 6' +
        '4 BA F7 69 C0 FA 6D BF FC 6C B5 FD 65 AD FB 5F AB FB 5E AD FA 5F AB F8 5D A9 FB 5B AB FE 5E B1 FD 63 B4 FA 65 B1 F8 62 AD F8 5F B0 FA 61 B4 FD 65 B4 FD 65 AF FA 60 AC F9 5E AF FA 60 B1 FB 62 AF FD 61 AB FE 5E AF FD 61 BB 00 6A CB 03 73 D5 04 77 CE 07 74 B' +
        'A 0C 68 AF 0F 60 AE 0D 5F AF 09 60 AF 03 61 BE FA 6B C4 FC 6F C0 FD 6D B3 F9 64 AB FB 5E AC FB 5E AD FE 5F AC FE 5E AA 00 5C AB 00 5E B1 00 62 B4 00 65 B1 FD 62 AD 00 5F B1 00 62 B5 00 66 B4 00 65 AE 00 60 AB 00 5E AF 00 61 B2 00 64 B0 00 61 AB 00 5E AF 0' +
        '2 61 BE 03 6C CC 05 73 D4 03 76 CC FF 73 BE FD 6C B1 00 63 AD 05 5F AE 08 60 AD 08 5F C6 F7 70 C2 FD 6E BC F9 6A B3 F4 63 AD F3 5F AD F5 5F AD F5 5F AD F5 5F AB F7 5D AB F8 5D B1 FA 62 B2 FA 63 B1 F9 62 AF FA 60 B0 FA 62 B5 F7 65 B3 F3 63 AF F2 60 AD F4 5' +
        'E AF F5 60 B2 F4 62 AF F5 60 AD F5 5E B1 F7 62 BE F9 6C CB F9 72 CF F5 74 C8 EF 70 BD EB 69 B5 EE 64 B3 FB 64 B0 03 62 B0 09 61 CB F9 72 C4 FA 6F B9 F7 68 AE F1 5F AD E9 5C AE E7 5D AF E6 5D AF E6 5D AD E7 5C AF EA 5E B3 EE 63 B3 ED 62 B2 EB 61 AF E9 5E B' +
        '0 E6 5E B3 E0 5F B4 DA 5E B2 DB 5C B1 D9 5A B3 DA 5C B6 DA 5F B3 DD 5E B0 DE 5C B6 E0 61 C2 E3 6A CC E1 6F CC E1 6F C4 DD 69 BF D8 64 BF DE 67 BD E7 68 B8 F8 67 B4 03 65 C9 01 72 C0 FD 6D B4 F5 64 AB EF 5B AA ED 5A AD E9 5C AE E6 5C AF E3 5D AF E5 5D B2 E' +
        '8 60 B5 E9 63 B2 E8 60 AF E4 5C AF DC 5A B0 D7 59 B3 D2 58 B4 D0 59 B5 C9 55 B6 C9 56 B8 C9 58 BA C9 59 B8 C9 58 B7 CF 5A BB D3 60 C7 D3 67 CE D5 6C CC D2 69 C2 D2 64 C0 D2 62 C4 D1 65 CA D9 6B C6 E9 6E BB F6 6A;3;LAND \ VHGT - Vertext Height Map;00 00 E6' +
        ' 43 00 09 07 07 0C 0F 0F 0F 0F 0E 0D 0C 0D 10 12 14 14 17 18 19 1E 21 25 26 24 22 21 20 20 1E 15 0A FE FD 0A 08 08 0C 0E 0E 0D 0E 0F 0F 0E 10 11 12 13 14 17 18 1B 1E 24 26 27 24 21 1F 1D 1B 18 10 04 FB FE 0B 09 09 0B 0D 0D 0C 0D 0F 11 11 12 12 12 12 15 16' +
        ' 19 1B 20 24 27 27 24 1F 1B 18 16 13 0C 01 F9 00 0B 0A 0A 0C 0C 0B 0B 0C 10 12 13 13 12 12 12 14 17 19 1C 20 24 26 24 21 1C 18 15 12 10 0A 00 F9 00 0B 0B 0B 0C 0C 0A 0B 0E 10 12 12 13 12 10 12 14 17 1A 1C 20 20 22 21 1E 1A 15 13 11 0F 09 01 FB FE 0B 0B 0D' +
        ' 0D 0C 0C 0C 0F 10 10 12 12 11 0F 11 13 18 1A 1B 1D 1C 1D 1D 1C 19 15 12 11 0E 09 03 FD FB 0C 0B 0D 0E 0F 0E 0F 10 0F 10 11 11 10 0E 10 13 17 19 1A 19 18 19 1B 1B 19 15 11 10 0C 09 03 02 FA 0D 0B 0C 0F 11 12 12 11 0F 10 10 11 0F 0F 10 13 16 17 17 17 16 18' +
        ' 19 1B 18 13 0F 0C 0A 07 05 04 FB 0D 0B 0C 0F 12 14 13 12 11 11 11 11 10 0F 11 14 15 15 16 15 16 18 1A 19 14 10 0B 08 06 05 05 08 FE 0D 0B 0A 0F 12 14 14 13 12 12 13 11 11 11 12 14 16 14 15 14 16 19 19 16 10 0A 07 04 04 04 06 09 01 0D 09 0A 0E 11 13 14 14' +
        ' 13 13 13 12 12 12 14 15 15 15 13 13 16 17 17 12 0B 07 04 03 03 04 06 0A 03 0C 0A 09 0D 10 13 14 14 13 12 12 12 13 13 15 15 15 14 13 11 13 14 13 0F 08 06 03 04 03 05 07 0B 05 0B 09 0A 0D 10 13 13 14 11 11 10 12 14 14 15 15 13 13 11 0F 0F 11 0F 0C 08 05 05' +
        ' 05 06 07 07 0D 05 0B 09 0A 0E 11 12 13 12 10 0F 0E 11 14 16 15 13 12 10 0E 0C 0D 0E 0D 0B 08 07 08 07 0A 09 0B 0D 04 0B 09 0C 0F 10 11 12 12 0F 0D 0D 10 14 15 15 12 10 0C 0C 0A 0C 0C 0D 0C 08 0C 0B 0B 0A 0A 0C 0E 02 0B 0A 0D 0F 10 10 11 11 0F 0D 0D 10 12' +
        ' 14 13 11 0F 0A 0B 0B 0B 0C 0D 0E 0D 0D 0D 0C 0A 09 0C 0E 00 0B 0C 0D 0E 10 0F 10 11 10 0E 0E 10 10 11 12 10 10 0E 0B 0B 0B 0C 0E 0D 0F 0E 0E 0B 0A 09 0B 0D 03 0B 0A 0D 0F 10 0F 10 11 11 0F 10 10 10 10 0F 10 10 0E 0C 0B 0C 0B 0C 0C 0F 0F 0F 0B 09 0A 0A 0C' +
        ' 01 0B 0A 0C 0F 10 0F 11 12 11 10 10 11 10 0F 0F 10 0F 0D 0C 0C 0B 0A 09 0C 0E 0F 0E 0D 0A 0B 0A 0A 01 0A 0A 0B 0E 10 10 11 12 12 10 10 11 10 0F 0F 0F 0F 0D 0B 0B 0A 08 09 0B 0D 0E 0E 0E 0C 0B 0A 07 00 0B 08 0B 0E 10 10 11 11 11 10 10 10 10 0F 0E 0F 0E 0E' +
        ' 0C 0A 08 09 08 0B 0C 0C 0D 0D 0E 0B 0A 07 01 0A 08 0A 0D 10 10 10 11 11 10 0E 0F 10 0F 0E 0D 0E 0F 0C 09 09 08 0B 0A 0B 0A 0C 0C 0D 0C 0B 08 01 0A 07 0A 0C 10 0F 10 10 11 0F 0D 0E 0F 0F 0E 0D 0D 0F 0D 0A 07 0B 0B 0B 0A 0A 0A 0B 0D 0C 0B 0B 00 0A 08 0A 0C' +
        ' 0E 10 0E 10 11 0E 0D 0C 0F 0F 0E 0C 0D 0E 0E 0A 0B 0B 0C 0C 0B 08 09 0A 0C 0E 0C 0A 01 0A 09 0A 0D 0D 0E 0E 0F 0F 0F 0D 0C 0E 0E 0D 0D 0D 0D 0E 0E 0B 0B 0D 0E 0B 08 08 0A 0D 0D 0C 0A 02 0A 09 0A 0E 0D 0E 0D 0F 10 0E 0C 0C 0D 0F 0E 0B 0C 0D 0F 0E 0C 0C 0E' +
        ' 0D 0B 08 08 0B 0D 0D 0C 0A 01 0A 08 0B 0E 0E 0E 0D 0F 10 0E 0C 0B 0D 10 0D 0B 0C 0D 0F 0E 0C 0E 0E 0E 0A 07 07 0B 0E 0D 0B 0B 01 09 09 0B 0D 0F 0E 0D 10 10 0E 0B 0B 0E 0F 0D 0B 0C 0E 0F 0D 0D 0E 0F 0D 09 06 07 0A 0D 0E 0C 0C 00 0A 09 0A 0E 0E 0F 0E 0F 0F' +
        ' 0E 0C 0C 0E 0E 0C 0C 0D 0E 0E 0D 0D 0E 0F 0C 09 06 05 09 0D 0E 0E 0D 03 08 08 0B 0E 0F 0E 0E 0F 0F 0E 0C 0C 0E 0E 0C 0B 0D 0F 0E 0D 0C 0E 0F 0C 08 06 06 08 0C 0E 0E 0E FF 09 09 0C 0D 0E 0E 0E 0E 0F 0E 0C 0D 0D 0E 0C 0C 0D 0E 0E 0D 0D 0E 0E 0C 08 07 07 09' +
        ' 0C 0C 0D 0D 03 07 09 0D 0F 0E 0E 0E 0E 0F 0D 0C 0D 0D 0E 0D 0D 0D 0E 0E 0D 0C 0E 0E 0B 08 07 08 0B 0A 09 0C 0C FF 08 0B 0E 10 0F 0E 0E 0E 0E 0C 0C 0E 0E 0F 0E 0E 0D 0F 0D 0D 0C 0E 0D 0A 08 07 09 0B 0A 09 07 0A 00 27 00;4'
      );
  end else if e.LoadOrderFormID.ToCardinal = 1380404 then begin
      NPCList.Add(
        'LAND;1380404;0; \ [00] FalloutNV.esm \ [53] GRUP Top |CITATION|WRLD|CITATION| \ [19] GRUP World Children of TheStripWorldNew |CITATION|The Strip|CITATION| [WRLD:0013B308] \ [5] GRUP Exterior Cell Block -1, -1 \ [1] GRUP Exterior Cell Sub-Block -3, -4 \ [1' +
        '15] GRUP Cell Children of [CELL:0014F8EE] (in TheStripWorldNew |CITATION|The Strip|CITATION| [WRLD:0013B308] at -26,-24) \ [0] GRUP Cell Temporary Children of [CELL:0014F8EE] (in TheStripWorldNew |CITATION|The Strip|CITATION| [WRLD:0013B308] at -26,-24) \' +
        ' [0] [LAND:00151034];LAND \ Cell;[CELL:0014F8EE] (in TheStripWorldNew |CITATION|The Strip|CITATION| [WRLD:0013B308] at -26,-24);0;LAND \ Record Header;;1;LAND \ Record Header \ Signature;LAND;0;LAND \ Record Header \ Data Size;4118;1;LAND \ Record Header ' +
        '\ Record Flags;0000000000000000001;2;LAND \ Record Header \ Record Flags \ Compressed;1;0;LAND \ Record Header \ FormID;[LAND:00151034];3;LAND \ Record Header \ Version Control Master FormID;350220;4;LAND \ Record Header \ Form Version;15;5;LAND \ Record ' +
        'Header \ Version Control Info 2;0;6;LAND \ DATA - Unknown;19 00 00 00;2;LAND \ VNML - Vertex Normals;17 5D 52 24 61 48 10 64 4C F4 61 50 D5 52 56 D1 44 5F EB 43 69 19 40 6A 3F 3B 5C 45 39 59 2D 37 68 F0 32 73 BA 2A 60 A5 27 4F A4 2F 49 A9 3C 45 B1 46 45 C' +
        '0 52 47 D4 59 4E EE 5B 56 F6 51 60 E1 43 67 C1 34 60 AE 2D 55 B0 39 4F BE 48 50 CD 51 52 CD 51 52 B4 3F 4E 9D 29 42 92 1D 36 8D 1A 2E 8C 1D 2A 21 63 48 22 62 48 09 63 4D DF 57 55 C0 43 56 C1 36 5F E2 2E 72 1A 2C 74 46 24 63 49 23 61 28 26 72 EE 26 77 BB 2' +
        '2 64 AB 28 54 AB 33 4E B0 3D 4C B6 47 4A BF 4E 4B CF 55 50 DC 51 5A E1 45 65 D1 35 68 BB 2A 61 B5 2F 5A BA 3B 57 C5 47 56 CC 4E 54 BE 42 55 A7 2D 4D 97 1D 40 90 14 36 8E 1A 31 8E 21 2C 23 62 47 1D 63 49 F6 5F 53 CA 4C 55 B1 37 52 B2 2A 5A D9 26 72 18 21 7' +
        '8 45 1A 66 4A 18 63 2A 1D 74 EF 22 79 C1 24 67 B3 2A 5B B1 32 54 B3 38 52 B5 3B 52 BD 43 53 C6 46 57 CA 44 5C CC 38 64 C6 2A 68 C0 2C 63 BC 32 5E C2 3D 5C CA 44 5B C2 3F 5A B0 31 54 9F 21 49 94 15 3E 91 18 38 91 1D 34 91 25 30 22 61 4A 14 5F 51 E7 59 56 B' +
        'A 43 51 A6 2F 4B AC 29 55 D1 29 6E 15 27 76 44 22 65 49 22 61 2B 29 6F F3 2C 76 C9 28 6A B5 24 5F B0 21 5C AB 1C 59 AF 1C 5D B8 23 61 BD 29 63 C1 2D 64 C0 2E 62 C6 30 65 C5 32 64 C6 39 60 C9 40 5E C4 3C 5E BA 33 5B A8 26 52 9B 1A 47 95 1A 3F 94 1D 3A 94 2' +
        '2 37 93 28 33 1A 5F 4F 0A 5A 58 D9 50 5A B0 3C 4D A4 31 47 A9 30 4E CE 39 65 12 3A 6F 42 34 5E 47 33 5B 27 39 6A F0 38 70 C0 25 66 B0 11 60 A6 02 59 A7 F5 59 AE F3 60 B9 F4 68 C4 02 6F C3 17 6C CA 2B 6A CB 38 64 CC 3D 62 CE 41 60 C6 3D 5E BE 37 5C B2 2B 5' +
        'A A4 20 50 9C 1C 47 97 1E 40 96 22 3C 96 27 39 99 31 36 0D 5E 54 F9 54 5E CE 43 5E AF 39 4E A5 37 44 AE 3E 4A D1 4C 59 10 51 5F 3C 47 55 3F 43 57 21 45 65 DE 35 6E B1 17 60 A3 FF 55 A1 EA 50 A6 E0 52 B3 D4 59 C5 D5 67 D9 E0 74 E3 03 7B DD 27 73 DA 3A 69 D' +
        '3 45 60 CC 43 5D C1 3C 5C B7 32 5A AC 26 57 A3 1F 4F 9D 1D 48 9B 23 43 9A 2A 3E 9F 36 3C A2 3F 38 F7 5C 56 E6 4E 60 C8 41 5C B2 3A 51 AD 40 47 B7 4C 45 D9 5B 4E 0C 60 51 30 55 50 35 4D 55 07 43 6B C6 27 69 A4 0A 56 9A F7 4A 9C EB 4A A2 E1 4E B1 D9 5A D0 D' +
        '2 6B F3 E2 7A 07 FD 7E FF 1F 7B EF 3A 6F DB 42 65 CA 42 5D BC 3A 59 B0 30 55 A8 25 53 A2 1D 4F A1 24 4B A1 2C 47 A6 3A 43 AA 45 3D AE 4D 39 E4 5B 53 D6 4E 5A C6 43 5A BC 44 51 B9 4A 4A C3 55 46 E0 63 48 03 63 4E 23 59 52 1F 4E 5F EE 40 6C B5 21 60 9B 09 4' +
        'C 97 00 46 98 FC 47 9E FA 50 AD FB 5F D3 00 76 07 07 7E 1D 14 79 1D 24 76 FF 34 73 E3 3C 6B C8 3A 61 B6 34 58 AC 2C 53 A5 25 4F A5 27 4F A8 2C 4F AB 39 4B B0 43 47 B2 4B 42 B5 51 3E D6 58 50 CC 50 53 C9 4D 53 C6 4C 52 C5 52 4C CE 5B 48 DD 5F 4B F7 61 50 0' +
        'F 58 59 0C 49 66 D6 34 6B A7 18 56 9A 10 49 96 0E 43 9A 14 47 A1 1A 4F B7 2C 5D DD 3B 6A 04 3B 70 22 35 6D 1C 2E 72 0A 2C 76 E7 30 72 C8 30 67 B4 2C 5A A9 29 52 A7 2A 4F A9 2D 50 AC 30 51 B0 35 52 AF 37 50 B0 3A 4E A9 37 49 D0 57 4D CA 53 4E C9 50 50 CA 5' +
        '2 4F CC 54 4F CD 54 4F D7 57 52 EC 57 5A FA 51 61 ED 3F 6C C1 20 69 A5 17 54 9A 14 48 9B 1C 47 A0 28 48 B0 3A 4E C9 4C 54 E3 55 59 FE 56 5C 0A 48 67 0E 35 72 02 28 78 EA 1D 79 C7 1C 6D B3 1D 60 A9 1F 56 A6 21 52 A5 1E 52 A8 1C 56 A6 12 57 A7 0A 59 A3 01 5' +
        '5 9F FA 50 CA 53 4E C5 4F 4F C8 4F 51 CA 4F 52 C7 4C 53 C6 49 55 CE 4A 5A DF 49 62 E8 3F 6B D5 2C 6E B9 1F 64 A5 17 54 9F 1E 4B A1 27 4A AB 36 4C BC 47 4F CF 51 54 E5 57 58 EB 50 5F F0 42 6B F3 2A 77 F1 0B 7D E0 00 7A C8 FD 71 B4 00 65 A8 02 5B A1 00 54 A' +
        '1 FB 53 A0 F2 51 A2 E3 4F A6 D7 4E A6 CC 48 A6 C5 42 C2 48 53 BE 44 53 C2 43 57 C1 41 58 BE 3C 59 BF 3C 5A C5 3B 5F D1 35 69 D3 28 6F C8 1C 6E B6 18 63 AA 1D 58 A5 25 4F A7 2C 4D B1 36 52 BB 3E 56 CC 44 5D D1 38 67 D3 22 71 D2 0B 75 D1 F3 75 DE E0 75 DD D' +
        '4 71 CB D6 6B B9 D8 60 AB DB 56 A3 DC 4E A2 D9 4A A2 D2 46 A4 CC 44 A7 C3 41 A9 BB 3C AA B6 37 B4 29 5C B2 24 5D B8 24 61 B7 23 61 B9 28 61 B9 29 60 B9 21 63 C1 1A 6A C9 12 70 C6 11 6F BA 16 67 AF 1A 5D A6 1D 54 A6 1E 53 AB 1F 58 B4 1C 61 B6 10 65 B6 FB 6' +
        '7 BC E2 66 C3 CB 61 D0 BF 61 D9 B8 60 DE B3 5E D2 B3 58 C2 B7 52 B5 BD 4C AC C3 47 A5 C7 43 A5 C7 42 A2 C8 40 A3 C6 3E A1 C4 39 A3 C0 38 AD 08 5F AE 06 60 B5 06 65 BB 0E 69 BA 19 66 B5 19 62 B2 1A 60 BD 17 68 C9 14 70 C9 14 70 BF 14 6A AF 13 5F A5 10 56 A' +
        '2 0E 53 A6 0A 58 A9 FD 5B AB EC 5B AF D9 58 B4 C9 54 BF BB 53 CD AE 52 D8 A7 50 DE A2 4D D8 A2 4A CB A6 47 BF AC 45 B4 B4 43 AC BD 43 A5 C6 42 A2 CD 43 9C D5 40 99 DB 3F 96 DF 3C AC FF 5E AD 00 5F B9 05 68 C3 0D 6E C1 18 6B B9 21 63 B9 2A 60 BE 30 60 C6 2' +
        'B 67 C7 24 6B BB 1A 67 AE 11 5E A4 0C 56 A1 0C 52 A2 07 54 A2 02 54 A2 F5 54 A2 E7 51 A8 D7 51 B1 C9 52 BF BB 53 CD AF 52 D3 A5 4B D7 9F 45 CF A0 42 C9 A3 41 C0 AB 43 B5 B5 44 AD C4 49 A3 D5 49 9C E5 49 97 F4 45 94 FD 41 AD FB 5F B1 00 63 BE 0A 6B CC 14 7' +
        '1 CD 22 6E C7 2F 66 C3 3A 5E C2 3D 5C C3 3C 5D BF 30 61 B5 21 60 A9 13 5A A3 0A 55 A1 0B 53 A1 0F 52 A1 10 52 9D 0C 4D 9C 02 4D 9D F9 4E A4 EE 54 AC E3 5A B4 CF 58 BB BD 52 C3 AF 4A CB A3 44 CA A3 42 CD A1 42 C5 AA 47 BD B6 4D B0 CA 52 A3 E2 50 9C F6 4D 9' +
        '7 06 46 B1 FF 62 B7 06 67 C7 14 6F D9 20 74 DC 2D 70 D6 38 69 CC 3E 61 C5 41 5B BF 3D 59 B6 34 58 AD 24 58 A4 15 54 A2 10 53 A4 0F 55 A5 17 55 A3 1B 51 9E 1B 4B 9B 18 48 9D 18 4B A0 15 4F A3 0A 54 A2 FB 54 A4 E3 52 A9 CE 4D B4 BA 49 C1 AC 46 C9 A5 43 D5 9' +
        'F 45 D2 A5 4B C9 B1 51 B7 C6 55 A8 DF 54 9E F6 4F B7 09 67 C2 1A 6B D4 29 6F E2 31 70 E8 34 71 DC 37 6C D0 36 67 C4 37 60 BA 35 5A AF 2E 56 A5 23 51 A3 1E 50 A3 1B 51 A7 20 54 AB 25 55 A6 24 51 A1 25 4A 9F 27 47 A0 2A 47 A2 29 49 A0 23 4B 9B 11 4A 98 00 4' +
        '8 9A ED 48 9F DB 48 AB C4 47 BD B0 46 CF A4 47 DF 9D 48 DD A3 4E D1 B0 55 BD C9 5B AA E7 59 C5 26 69 D2 34 6A DD 3C 6A E6 3F 6A E3 39 6D DB 30 6F CB 27 6C C3 23 69 B7 23 61 AA 23 56 A5 23 51 A3 24 4E A8 2A 50 AE 31 52 AD 30 52 A9 2D 50 A4 2B 4B A2 2C 47 A' +
        '2 2D 47 A1 2C 47 9C 21 45 96 14 42 95 09 42 94 FE 41 96 F0 42 9A DF 43 A8 CA 49 BF B6 4E D8 AC 55 EA AB 5B E8 BC 68 D3 D9 6F BE FD 6C D4 3C 66 D9 41 65 E0 43 66 DC 39 6B D7 2C 6F C9 1A 6F C2 0A 6E C0 06 6D B7 09 67 AE 14 5E A7 1F 54 A8 28 51 AC 30 51 AF 3' +
        '4 52 AD 32 51 A8 2E 4E A4 2A 4B A2 2A 49 A0 2A 47 9C 21 45 97 16 42 94 11 3F 92 0B 3D 92 05 3E 91 FF 3D 94 F7 40 9A EF 48 AE E6 5C CE E2 70 F3 EC 7C 03 FD 7E F2 18 7B DB 2E 70 D5 3D 66 D9 3D 68 D2 30 6B CA 21 6D C2 0D 6D BB FA 6A BC EF 69 C1 E6 6A BF EC 6' +
        'B B7 FA 67 AF 0C 60 AB 1E 58 AC 25 57 AD 2A 55 AA 2A 52 A5 27 4E A3 26 4C A1 25 4A 9C 1E 47 97 16 42 95 11 40 93 0D 3E 92 0D 3D 91 0E 3B 91 0E 3B 93 0F 3E 9C 17 49 B0 23 5B DA 35 6C 03 41 6C 0D 49 66 06 4E 63 E4 4B 61 CE 2E 6B CA 23 6D C1 13 6C BB 02 6A B' +
        '5 F4 65 B4 EA 62 B7 E2 62 C0 D9 65 C9 D3 68 C5 DE 6A BC ED 69 B2 FF 63 AE 11 5E AD 18 5C A8 1A 56 A2 19 51 A0 18 4F 9D 16 4B 98 11 45 95 0E 42 93 0D 3F 94 10 3F 94 15 3E 95 1B 3D 95 22 3A 9C 2E 3E A9 3D 45 C6 51 4E F2 60 51 07 63 4F 0C 62 4F F3 58 59 D9 4' +
        '5 62 C1 15 6B BE 0A 6B B6 FF 66 B1 F1 61 B1 EB 60 B0 E9 5F B3 E4 60 BA DC 63 C7 D4 68 CF CF 69 C8 DA 6B C1 E9 6B B7 F8 67 AF 02 61 A6 05 59 A1 07 52 9E 06 50 9B 04 4B 97 05 46 94 06 42 95 0B 42 95 12 41 97 1C 41 99 25 3F 9F 33 3E A8 43 3D BC 55 40 DA 65 4' +
        '2 F6 6A 44 04 69 46 F3 5E 53 D5 48 5E B1 1B 5F BB 03 6A B8 FD 68 AF F7 61 AD F2 5E AF EF 60 AF F0 60 AE EF 5E B4 E9 62 C0 E0 68 CD DA 6D D3 DA 70 C9 E4 6E BE ED 6A B2 F1 62 A9 F5 5B A1 F8 53 9E F9 4F 9B FA 4C 98 FC 47 96 00 44 96 06 45 99 12 47 9B 1E 46 A' +
        '0 2D 45 A8 3D 43 B6 4E 42 CB 5F 3F E1 68 40 F2 6B 41 EB 62 4C D0 4D 57 A9 1C 58 9A EB 47 BC F4 6A B5 F7 65 AE F6 60 AB F8 5D AF F8 61 AF FA 60 AD FC 5F AF FA 60 B9 F3 68 C9 EC 70 D2 E9 73 CE EB 72 BF EE 6B B3 EE 63 A9 EE 5A A3 EE 53 9F F2 50 9C F7 4C 99 F' +
        'A 48 98 FE 47 9A 05 4A 9D 10 4D A2 20 4E A8 32 4C B1 41 4A C3 52 49 D3 5E 48 E2 65 46 DD 5E 4C C8 4D 53 A7 23 52 94 F4 40 95 DB 38 BE F0 6A B6 EF 65 AF F1 60 AE F6 60 B1 FD 62 B2 03 64 AD 08 5F AE 08 5F B5 06 65 C3 00 6F D1 F9 75 CC F6 73 BE F3 6B B0 F1 6' +
        '1 A8 F0 59 A3 F2 55 A1 F6 52 9D FC 4F 9A 00 4A 99 06 49 9D 0C 4D A3 18 52 AB 25 55 B0 33 53 BA 41 53 C7 4B 53 D6 53 55 D1 4E 58 C1 40 59 A6 1F 53 93 FB 40 90 E8 35 91 D8 2E B7 F6 67 B5 EE 64 B1 EF 61 B3 F1 63 B9 FF 68 B7 09 67 B2 11 62 AE 17 5D B3 13 62 B' +
        'E 10 6A C9 09 71 C8 00 71 BB FB 6A AF F7 61 A7 F9 5A A4 FB 56 A3 00 55 9F 05 51 9D 0A 4D 9C 10 4C A1 18 50 AA 20 56 B0 28 59 B6 2D 5B B9 32 5C C4 37 60 C6 33 64 BC 26 63 A8 0D 59 98 F2 46 92 E6 38 8F DF 2E 8F DE 2C B2 FD 64 B1 F7 62 B1 F1 61 B9 FA 68 C2 0' +
        '0 6E C0 0C 6C B8 16 65 B0 19 5E B1 1D 5E BA 16 67 C3 0D 6E C1 05 6D B7 00 67 AD FE 60 A8 FE 5B A6 00 59 A5 05 58 A1 07 53 9F 0A 50 9E 0C 4F A2 0F 53 A8 10 59 AE 11 5E B0 0F 60 B5 0F 64 BB 0E 69 B9 09 68 AD FB 5F 9D EB 4C 95 E1 3C 92 DC 32 8F E1 2F 8D E7 2' +
        'D AF 03 61 AD 00 5F B2 FF 63 BD 00 6B C7 06 71 C8 0A 71 BD 12 69 B4 18 62 AF 17 5E B1 12 61 BB 0A 69 BD 03 6B B8 06 67 AD 08 5F A9 09 5B A9 0B 5A A5 07 58 A2 02 54 9D FE 4F 9D F9 4F A1 F4 52 A8 ED 58 AD E9 5C B0 E9 5F B7 EB 65 B9 ED 67 B6 EC 64 A6 EB 56 9' +
        'A E4 45 93 E3 38 8F E6 33 8D EC 31 8D FD 35 AD 08 5F AD 08 5F B1 09 62 BE 09 6C CB 07 72 CB 08 72 C3 0D 6E B4 11 64 AC 11 5D AF 0E 60 B7 09 67 BE 0A 6B BB 0D 69 B1 14 61 AB 19 5A A7 15 57 A2 0D 54 9D 00 4F 9B F5 4B 9C EB 4A A0 E4 4D A8 DD 53 B0 D7 59 B7 D' +
        'B 60 BB E4 66 BF EC 6A B5 F4 65 A3 F3 54 95 F2 42 90 F5 3A 8E FA 36 90 0B 39 94 1E 3B B0 09 61 AD 0E 5E B2 0E 62 BB 0D 69 C6 05 70 CE 03 74 C5 05 70 B7 09 67 AD 09 5E AC 0B 5D B5 0A 65 C0 0A 6C C0 0F 6C B8 16 65 AE 1B 5C A5 1A 54 9D 0E 4E 98 02 48 97 F7 4' +
        '5 99 ED 46 9F EA 4D A5 E9 54 B0 F0 60 BB F7 6A C3 03 6F C5 0D 6F B4 0A 65 A1 05 53 96 08 44 91 0C 3B 94 1C 3B 9A 2B 3D A6 40 3D B4 03 65 B0 09 62 AF 0C 60 B7 06 67 C2 00 6E CB FE 73 C8 FD 71 B8 00 68 AD 00 5F AD 00 60 B4 03 65 C1 04 6D C5 06 70 BD 0D 6A B' +
        '0 11 60 A2 0E 53 99 09 49 96 02 44 94 FC 41 98 00 48 9E 04 4F A9 11 5A B9 1E 64 C4 27 68 CE 2D 6B C5 26 69 B3 1B 61 A2 14 52 99 13 46 98 21 40 9D 30 3E A7 3F 3F B4 4E 40 BB F6 6A B3 FD 64 AF 00 61 B2 00 64 BF FD 6C CB F9 72 C8 F9 71 B9 FA 68 AD FC 5F AD F' +
        'B 5F B6 FB 66 C2 FD 6E C6 FA 70 C0 FA 6D AF F8 61 A1 F9 53 9A FD 4A 94 FE 42 96 07 44 9C 12 4B A8 24 53 B6 34 58 C2 3B 5D CD 3F 61 C6 34 63 BB 22 64 AD 14 5D A1 0A 52 9D 12 4C 9D 1F 48 A1 2C 46 AA 3B 47 B1 42 49;3;LAND \ VHGT - Vertext Height Map;00 A0 8B' +
        ' 44 00 F7 F9 FF 06 0A 06 00 F8 F2 F5 FD 08 11 14 14 14 11 0C 06 01 02 08 0E 11 10 0B 08 0C 14 1D 26 2A EB F6 FA 02 0A 0E 08 01 F7 F2 F6 FE 08 0F 12 11 10 10 0C 08 05 05 0A 0D 0E 0C 0A 0A 0F 17 1F 23 28 E9 F6 FD 07 0E 11 0B 01 F8 F2 F6 FE 07 0D 0E 0F 0F 0E' +
        ' 0C 0A 09 09 09 0C 0B 0A 09 0D 12 1A 1E 21 23 EA F8 FF 0B 12 14 0D 02 F8 F2 F6 FD 06 0B 0D 0F 0F 0D 0B 0B 0B 0A 09 0A 09 0A 0A 0F 14 1A 1D 1E 21 EC FA 02 0D 15 15 0F 03 F7 F2 F5 FE 07 0C 0F 11 0F 0C 0A 09 09 09 08 09 08 0B 0C 10 15 19 1B 1D 1E ED FE 04 0E' +
        ' 15 16 0F 03 F7 F2 F6 FF 0A 11 13 13 10 0C 07 04 04 06 07 08 0A 0C 0E 11 15 17 1A 1A 1A EF 02 07 0D 12 14 0E 03 F8 F4 F8 04 0F 15 17 15 12 0B 04 FF FF 01 04 08 0B 0E 10 12 14 16 15 16 17 EE 07 09 0C 0F 10 0C 03 FB F7 FE 08 13 18 19 16 12 0B 02 FC FA FE 02' +
        ' 07 0C 0F 12 13 12 12 12 12 13 EF 0A 0A 0B 0C 0C 0A 05 FF FC 00 0D 15 19 19 16 11 09 02 FC FA FC 01 06 0C 10 12 12 11 0F 10 0F 12 EE 0B 0B 0B 0B 0A 0A 06 01 01 06 0E 16 17 17 14 0D 08 03 FE FE FE 00 06 0B 0F 11 12 11 10 10 10 12 EE 0C 0C 0A 0B 0B 0B 07 04' +
        ' 03 0A 0F 14 16 13 10 0C 06 04 03 02 01 03 06 0A 0E 11 13 12 14 12 13 15 F0 0D 0C 0B 0C 0C 0B 09 05 08 0A 0E 12 13 11 0E 0B 07 06 07 06 07 04 06 0A 0E 12 14 15 16 16 16 18 F4 0E 0D 0B 0D 0B 0D 0A 09 08 09 0D 0F 12 11 0D 0C 0B 0C 0B 09 07 06 06 0B 0E 12 15' +
        ' 16 17 18 1A 1B FD 0F 0D 0B 0A 0C 0E 0C 09 07 08 0C 0F 13 11 10 0F 0F 0F 0E 0B 09 07 07 0A 0E 11 13 16 16 18 1A 1B 00 0F 0D 09 09 0B 0C 0C 0A 08 09 0C 10 12 13 12 12 13 12 11 0E 0B 09 09 0A 0D 0E 11 12 13 16 17 1A 01 0E 0C 08 07 08 0A 0B 0B 0A 0B 0E 11 12' +
        ' 13 12 14 15 16 13 10 0E 0E 0D 0C 0D 0C 0D 0D 0F 11 14 17 01 0D 0A 07 04 06 07 0A 0B 0D 0E 11 12 12 11 11 14 17 16 15 12 12 12 12 12 0F 0E 0B 09 09 0D 0F 13 00 0B 08 05 03 04 06 09 0B 0E 11 13 13 12 10 10 13 16 16 15 14 15 17 17 17 14 12 0D 08 07 07 0B 0E' +
        ' FD 08 06 04 04 04 07 08 0B 0E 12 13 13 11 0F 11 12 15 15 15 16 19 1A 1A 1B 1A 17 10 0B 05 03 05 08 F7 07 05 05 05 07 09 09 0A 0D 10 12 11 10 10 11 13 14 15 16 18 1B 1C 1D 1D 1D 1A 14 0B 04 00 FF 03 F6 06 06 07 09 0A 0B 0A 09 0A 0D 0F 10 0F 10 12 13 14 15' +
        ' 18 1B 1B 1D 1D 1F 1E 1A 13 0A 02 FD FD 01 F7 07 09 0A 0B 0D 0D 0B 09 08 09 0C 0E 0E 0F 12 13 14 17 19 1B 1C 1C 1C 1D 1D 18 11 07 FF FC FF 04 FB 09 0B 0D 0D 0E 0D 0D 0A 07 08 09 0A 0C 0F 12 13 14 17 1A 1A 1A 1A 1A 1A 19 15 0E 05 FF FF 04 0B FE 0B 0C 0F 0E' +
        ' 0D 0E 0E 0B 09 06 07 09 0B 0E 11 13 15 16 19 19 18 17 17 16 14 10 0B 04 03 05 0D 15 01 0B 0D 0F 0E 0D 0E 0E 0D 09 07 06 08 0B 0E 11 13 14 16 18 17 15 14 13 12 10 0B 08 06 08 0E 18 1E 03 0A 0D 0E 0E 0C 0D 0F 0D 0B 07 06 08 0C 0F 11 12 13 15 17 16 13 11 0F' +
        ' 0F 0C 09 07 09 0E 17 20 26 02 0C 0C 0E 0B 0B 0C 0E 0E 0B 09 07 09 0C 0F 11 11 12 14 15 15 11 0F 0D 0D 0B 09 09 0D 14 1D 25 2A 01 0D 0D 0D 09 09 0A 0D 0F 0C 09 09 0A 0D 0F 10 10 11 13 14 13 11 0E 0E 0D 0B 0A 0C 11 1A 21 26 28 00 0E 0E 0B 09 07 09 0C 0D 0E' +
        ' 0C 0A 0A 0D 0F 10 0F 11 13 14 14 11 0F 0E 0D 0B 0B 0E 14 1D 22 25 25 FF 0E 0E 0C 07 08 07 0B 0E 0F 0C 0B 09 0C 0F 0F 11 13 15 16 15 13 10 0D 0C 0A 0A 0E 17 1D 22 21 1F FE 0E 0E 0B 0A 07 07 0A 0D 0F 0E 0A 09 0A 0D 10 13 16 18 19 16 13 10 0C 09 08 09 0F 16' +
        ' 1D 1F 1C 19 FF 0C 0E 0D 0A 08 07 09 0E 0E 0D 0B 08 09 0B 10 15 18 1B 1A 16 12 0D 0A 08 07 0A 10 15 1A 1A 19 14 00 0B 0E 0D 0C 08 07 09 0D 0F 0D 0A 08 08 0B 10 15 19 1B 18 13 0F 0C 09 08 0A 0C 11 14 16 16 15 12 00 27 00;4'
      );
  end else if Signature(e) = 'NAVI' then begin
      if NPCList.Count > 0 then
        k := savelist2(rec, k, grupname);
      NPCList.Add(Signature(e));
      NPCList.Add(IntToStr(GetLoadOrderFormID(e)));
      NPCList.Add(IntToStr(ReferencedByCount(e)));
      NPCList.Add(FullPath(e));
      RecursiveNAVI(e, NPCList);
      k := savelist2(rec, k, grupname);
  end else begin
    slstring := Recursive(e, slstring);

    NPCList.Add(slstring);
  end;

	if NPCList.Count > 4999 then
    k := savelist2(rec, k, grupname);
  Result := 0;
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

	if NPCList.Count > 0 then
    k := savelist2(rec, k, grupname);

	rec := Nil;
	NPCList.Clear;
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
    if NPCList.Count = 0 then
      NPCList.LoadFromFile(wbProgramPath + 'data\unsorted\' + slfilelist[i]);

    slstring.DelimitedText := NPCList[0];

    if slstring.Count = 0 then begin
      raise Exception.Create('0 count slstring in ' + slfilelist[i]);
    end;

    if slstring.Count = 1 then begin
      if slstring[0] = 'NAVI' then
      begin
        _Signature := 'NAVI';
        _Grupname := 'NAVI';
        slSorted.AddStrings(NPCList);
        NPCList.Clear;
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
    while(j < NPCList.Count) do
    begin
      slstring.DelimitedText := NPCList[j];

      if ((_Signature <> '') AND (_Signature = slstring[0])) then begin
        if slSignatures.Count < NPCList.Count then
          AddMessage('ERROR1');

        slSorted.Add(NPCList[j]);
        NPCList.Delete(j);
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
    if NPCList.Count = 0 then i := (i + 1);
  end;

	NPCList.Free;
	slfilelist2.SaveToFile(wbProgramPath + 'data\' + '_filelist.csv');
	slfilelist.Free;
  slSignatures.Free;
  slGrups.Free;
  slSorted.Free;
  slfilelist2.Free;
  Result := 0;
end;

end.