unit wbConvert;

interface

uses
  wbInterface,
  frmViewMain;

type
  TConverter = class
    private
      var gamePropertiesSrc, gamePropertiesDst: TGameProperties;
      var form: TfrmMain;
  end;

procedure ConvertElement(var form: TfrmMain; var iFileDst: IwbFile; e: IwbElement);
procedure ConvertInitialize(var form: TfrmMain);
procedure ConvertFinalize(var form: TfrmMain);

implementation

uses
  Classes,
  SysUtils;

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
rec: IwbRecord;
loadordername, grupname: String;

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

function Recursive(e: IwbContainerElementRef; slstring: String): String;
var
i, j: integer;
element: IInterface;
iElement: IwbElement;
iContainer, iContainer2: IwbContainerElementRef;
_TXST: IInterface;
s, valuestr: String;
begin
//  e.FullPath;

	for i := 0 to (e.ElementCount-1) do
	begin
    ////////////////////////////////////////////////////////////////////////////
    ///  All Data
    ////////////////////////////////////////////////////////////////////////////
		ielement := e.Elements[i];
		slstring := (slstring
//    stringreplace(
//     ,'"', '|CITATION|', [rfReplaceAll])
    + ';' + stringreplace(stringreplace(stringreplace(ielement.Path, #13#10, '\r\n', [rfReplaceAll]), ';' , '\comment\', [rfReplaceAll]) ,'"', '|CITATION|', [rfReplaceAll])
    + ';' + stringreplace(stringreplace(stringreplace(ielement.EditValue, #13#10, '\r\n', [rfReplaceAll]), ';' , '\comment\', [rfReplaceAll]) ,'"', '|CITATION|', [rfReplaceAll])
    + ';' + IntToStr(i));

    ////////////////////////////////////////////////////////////////////////////
    ///  Material Swap
    ////////////////////////////////////////////////////////////////////////////
    if ielement.Name = 'Alternate Texture' then
    begin
      if Supports(IInterface(ielement), IwbContainerElementRef, iContainer) then
        if Assigned(iContainer.ElementByPath['3D Name']) then
        begin
          s := ielement.Container.Container.Elements[0].EditValue;
          if LastDelimiter('.', s) <> (Length(s) - 3) then s := '';
          slNifs.Add(s);
          _TXST := iContainer.ElementByPath['New Texture'].LinksTo;

          if Supports(_TXST, IwbContainerElementRef, iContainer2) then
          begin
            s := s + ';' + iContainer2.ElementEditValues['EDID']
            + ';' + iContainer.ElementEditValues['3D Name']
            + ';' + iContainer2.ElementEditValues['Textures (RGB/A)\TX00']
            + ';' + iContainer2.ElementEditValues['Textures (RGB/A)\TX01']
            + ';' + iContainer2.ElementEditValues['Textures (RGB/A)\TX02']
            + ';' + iContainer2.ElementEditValues['Textures (RGB/A)\TX03']
            + ';' + iContainer2.ElementEditValues['Textures (RGB/A)\TX04']
            + ';' + iContainer2.ElementEditValues['Textures (RGB/A)\TX05'] + ';';
            if Assigned(iContainer2.ElementByPath['DNAM\No Specular Map']) then
              s := s + 'No Specular Map';
            slvalues.Add(s);
            sl3DNames.Add(iContainer.ElementEditValues['3D Name']);
          end;
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
    if Supports(IInterface(ielement), IwbContainerElementRef, iContainer) then
		  if iContainer.ElementCount > 0 then slstring := (Recursive(iContainer, slstring));
	end;
	Result := slstring;
end;

function savelist2(var form: TfrmMain; rec: IwbRecord; k: integer; grupname: String): integer;
var
filename: String;
begin
	filename := (wbProgramPath + 'data\unsorted\' + rec._File.FileName + '_LoadOrder_' + IntToHex(rec._File.LoadOrder, 2) + '_' + IntToStr(k) + '.csv');
	form.AddMessage('Saving list to ' + filename);
	NPCList.SaveToFile(filename);
	NPCList.Clear;
	slfilelist.Add(stringreplace(filename, (wbProgramPath + 'data\unsorted\'), '', [rfReplaceAll]));
	Result := k + 1;
end;

function Initialize: integer;
begin
	NPCList := TStringList.Create;
	slfilelist := TStringList.Create;
  slSignatures := TStringList.Create;
  slGrups := TStringList.Create;
  slvalues := TStringList.Create;
  slNifs := TStringList.Create;
  sl3DNames := TStringList.Create;
  slReferences := TStringList.Create;
  slExtensions := TStringList.Create;
  slExtensions.LoadFromFile(wbProgramPath + 'ElementConverions\' + '__FileExtensions.csv');
	k := 0;
  Result := 0;
end;

function Recursive2(e: IwbContainerElementRef; slstring: String): String;
var
i: integer;
ielement: IwbElement;
iContainer: IwbContainerElementRef;
begin
	for i := 0 to (e.ElementCount-1) do
	begin
		ielement := e.Elements[i];
		slstring := (slstring
//    stringreplace(
//     ,'"', '|CITATION|', [rfReplaceAll])
    + ';' + stringreplace(stringreplace(stringreplace(ielement.Path, #13#10, '\r\n', [rfReplaceAll]), ';' , '\comment\', [rfReplaceAll]) ,'"', '|CITATION|', [rfReplaceAll])
    + ';' + stringreplace(stringreplace(stringreplace(ielement.EditValue, #13#10, '\r\n', [rfReplaceAll]), ';' , '\comment\', [rfReplaceAll]) ,'"', '|CITATION|', [rfReplaceAll])
    + ';' + IntToStr(i));

    if Supports(IInterface(ielement), IwbContainerElementRef, iContainer) then
		  if iContainer.ElementCount > 0 then
        slstring := Recursive2(iContainer, slstring);
	end;
	Result := slstring;
end;

function RecursiveNAVI(e: IwbContainerElementRef; NPCList: TStringList): TStringList;
var
i: integer;
ielement: IwbElement;
iContainer: IwbContainerElementRef;
begin
	for i := 0 to (e.ElementCount-1) do
	begin
		ielement := e.Elements[i];
		NPCList.Add(ielement.Path);
		NPCList.Add(ielement.EditValue);

    if Supports(IInterface(ielement), IwbContainerElementRef, iContainer) then
		  if iContainer.ElementCount > 0 then
        NPCList := (RecursiveNAVI(iContainer, NPCList));
	end;
	Result := NPCList;
end;

function Process(var form: TfrmMain; e: IwbMainRecord): integer;
var
slstring: String;
iContainer: IwbContainerElementRef;
begin
	// Compare to previous record
  if (Assigned(rec) AND (loadordername <> e._File.FileName)) then
	begin
		if NPCList.Count > 0 then k := savelist2(form, rec, k, grupname);
    k := 0;
		rec := Nil;
		loadordername := e._File.FileName;
		form.AddMessage('Went To Different File');
	end;
	// Compare to previous record            stringreplace(stringreplace(FullPath(e), #13#10, '\r\n', [rfReplaceAll]), ';' , '\comment\', [rfReplaceAll])
	slstring := (e.Signature + ';' + IntToStr(e.LoadOrderFormID.ToCardinal) + ';' +
               IntToStr(e.ReferencedByCount) + ';' +
               stringreplace(
                  stringreplace(
                      stringreplace(
                          e.FullPath, #13#10, '\r\n', [rfReplaceAll]), ';' ,
                          '\comment\', [rfReplaceAll]) ,'"', '|CITATION|',
                          [rfReplaceAll]));
	rec := e;
	loadordername := rec._File.FileName;
  if ansipos('GRUP', rec.FullPath) <> 0 then	grupname := copy(rec.FullPath, (ansipos('GRUP', rec.FullPath) + 19), 4)
  else grupname := rec.Signature;
  slSignatures.Add(rec.Signature);
  slGrups.Add(grupname);

  if Supports(e, IwbContainerElementRef, iContainer) then
    if e.Signature <> 'NAVI' then NPCList.Add(Recursive(iContainer, slstring)) else
    begin
      if NPCList.Count > 0 then k := savelist2(form, rec, k, grupname);
      NPCList.Add(e.Signature);
      NPCList.Add(IntToStr(e.LoadOrderFormID.ToCardinal));
      NPCList.Add(IntToStr(e.ReferencedByCount));
      NPCList.Add(e.FullPath);
      RecursiveNAVI(iContainer, NPCList);
      k := savelist2(form, rec, k, grupname);
    end;

	if NPCList.Count > 4999 then k := savelist2(form, rec, k, grupname);
  Result := 0;
end;

function Finalize(var form: TfrmMain): integer;
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
    form.AddMessage('Saving ' + wbProgramPath + 'ElementConverions\MaterialSwaps.csv');
    slvalues.SaveToFile(wbProgramPath + 'ElementConverions\MaterialSwaps.csv');
    form.AddMessage('Saving ' + wbProgramPath + 'ElementConverions\MaterialSwapsNifs.csv');
    slNifs.SaveToFile(wbProgramPath + 'ElementConverions\MaterialSwapsNifs.csv');
    form.AddMessage('Saving ' + wbProgramPath + 'ElementConverions\MaterialSwaps3Names.csv');
    sl3DNames.SaveToFile(wbProgramPath + 'ElementConverions\MaterialSwaps3Names.csv');
  end;
  if slReferences.Count > 1 then
  begin
    form.AddMessage('Saving ' + wbProgramPath + 'ElementConverions\' + '__FileReferenceList.csv');
    slReferences.SaveToFile(wbProgramPath + 'ElementConverions\' + '__FileReferenceList.csv');
  end;

  //////////////////////////////////////////////////////////////////////////////
  ///  Free Lists
  //////////////////////////////////////////////////////////////////////////////
  slvalues.Free;
  slNifs.Free;
  sl3DNames.Free;
  slReferences.Free;
  slExtensions.Free;


	if NPCList.Count > 0 then k := savelist2(form, rec, k, grupname);
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

    if slstring.Count = 0 then
    begin
      form.AddMessage('0 count slstring in ' + slfilelist[i]);
      Result := 0;
      Exit;
    end;

    if slstring.Count = 1 then
    begin
      if slstring[0] = 'NAVI' then
      begin
        _Signature := 'NAVI';
        _Grupname := 'NAVI';
        slSorted.AddStrings(NPCList);
        NPCList.Clear;
        slstring.Clear;
      end;
    end;
    if slstring.Count > 0 then
    begin
      _Signature := slstring[0];
      if ansipos('GRUP', slstring[3]) <> 0 then	_Grupname := (copy(slstring[3], (ansipos('GRUP', slstring[3]) + 19), 4))
      else _Grupname := _Signature;
    end;
    j := 0;
    while(j < NPCList.Count) do
    begin
      slstring.DelimitedText := NPCList[j];
      if ((_Signature <> '') AND (_Signature = slstring[0])) then
      begin
        if slSignatures.Count < NPCList.Count then form.AddMessage('ERROR1');
        slSorted.Add(NPCList[j]);
        NPCList.Delete(j);
      end
      else if _Signature = '' then
      begin
        form.AddMessage('ERROR: Empty _Signature String');
        Result := 0;
        Exit;
      end
      else j := (j + 1);
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
    form.AddMessage('SAVED: ' + filename);
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

procedure ConvertElement(var form: TfrmMain; var iFileDst: IwbFile; e: IwbElement);
var
iMainRecord: IwbMainRecord;
begin
//  form.AddMessage('Processing' + e.FullPath);
  if Supports(e, IwbMainRecord, iMainRecord) then
  begin
    // NOTE: 1380288 Decompression fails
    if iMainRecord.FormID.ToCardinal <> 1380288 then
      Process(form, iMainRecord);
  end;
end;

procedure ConvertInitialize(var form: TfrmMain);
begin
  Initialize;
end;

procedure ConvertFinalize(var form: TfrmMain);
begin
  Finalize(form);
end;

end.
