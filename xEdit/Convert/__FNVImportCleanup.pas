unit __FNVImportCleanup;

interface

uses
  wbInterface;

procedure FNVImportCleanRecord(e: IwbMainRecord);

implementation
uses Classes, SysUtils, StrUtils, Windows, __ScriptAdapterFunctions, wbImplementation;

var
bChangeEDID: Boolean;


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
	elementpathstring := stringreplace(elementpathstring, 'Destructable', 'Destructible', [rfReplaceAll]);
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

procedure Recursive(e: IwbContainer);
var
  i: integer;
  sform: String;
  ielement: IwbElement;
  container: IwbContainer;
begin
	for i := 0 to (ElementCount(e)-1) do
	begin
		ielement := ElementByIndex(e, i);
//    if Name(ielement) = 'Items' then Remove(ielement);
    if Assigned(ielement) then
//    if Name(ielement) = 'Destructible' then Remove(ielement);
      if bChangeEDID then
        if Name(ielement) = 'EDID - Editor ID' then
          if (GetEditValue(ielement) <> '') then begin
            SetEditValue(ielement, ('nv-' + GetEditValue(ielement)));
          end;
//    if ((Name(ielement) <> 'Record Header')
//    AND (Name(ielement) <> 'OBND - Object Bounds')
//    AND (Name(ielement) <> 'X1')
//    AND (Name(ielement) <> 'X2')
//    AND (Name(ielement) <> 'Y1')
//    AND (Name(ielement) <> 'Y2')
//    AND (Name(ielement) <> 'Z1')
//    AND (Name(ielement) <> 'Z2')
//    AND (Name(ielement) <> 'Signature')
//    AND (Name(ielement) <> 'Data Size')
//    AND (Name(ielement) <> 'Record Flags')
//    AND (Name(ielement) <> 'FormID')
//    AND (Name(ielement) <> 'Version Control Info 1')
//    AND (Name(ielement) <> 'Form Version')
//    AND (Name(ielement) <> 'Version Control Info 2')
//    AND (Name(ielement) <> 'Model')
//    AND (Name(ielement) <> 'MODL - Model Filename')
////    AND (Name(ielement) <> 'MODT - Texture Files Hashes')
//    AND (Name(ielement) <> 'EDID - Editor ID')) then
//      Remove(ielement);
    if Assigned(ielement) then
      if Assigned(LinksTo(ielement)) then
      begin
        sform := '$00' + Copy(IntToHex(FormID(LinksTo(ielement).ContainingMainRecord), 8), 3, 6);
        if StrToInt(sform) < 2048 then begin
          sform := Copy(sform, 2, 8);
          SetEditValue(ielement, sform);
        end;
//        if AnsiPos('[', GetEditValue(ielement)) = (AnsiPos(']', GetEditValue(ielement)) - 14) then
//          if StrToInt('$' + Copy(GetEditValue(ielement), (AnsiPos('[', GetEditValue(ielement)) + 8), 6)) < 2048 then
//            if GetEditValue(ielement) <> 'NULL - Null Reference [00000000]' then
//              SetEditValue(ielement, '00' + Copy(GetEditValue(ielement), (AnsiPos('[', GetEditValue(ielement)) + 8), 6));
//        if AnsiPos('[', GetEditValue(ielement)) = (AnsiPos(']', GetEditValue(ielement)) - 9) then
//          if StrToInt('$' + Copy(GetEditValue(ielement), (AnsiPos('[', GetEditValue(ielement)) + 3), 6)) < 2048 then
//            if GetEditValue(ielement) <> 'NULL - Null Reference [00000000]' then
//              SetEditValue(ielement, '00' + Copy(GetEditValue(ielement), (AnsiPos('[', GetEditValue(ielement)) + 3), 6));
      end;

    if Assigned(ielement) then
      if AnsiPos(' - Texture Files Hashes', Name(ielement)) = 5 then
        Remove(ielement);
    if Assigned(ielement) then
      if Copy(GetEditValue(ielement), 12, MaxInt) = '< Error: Could not be resolved >' then
      begin
        Remove(ielement);
      end;
    if Assigned(ielement) then
      if Supports(ielement, IwbContainer, container) then begin
        if ElementCount(container) > 0 then
          Recursive(container);
      end;
	end;
end;

function Initialize: integer;
begin
  bChangeEDID := False;
	Result := 0;
end;

procedure FNVImportCleanRecord(e: IwbMainRecord);
var
i: Integer;
begin
  if e.GetFile.FileName <> 'FalloutNV.esm' then
    Exit;

  if Signature(e) = 'TREE' then begin
    for i := (ReferencedByCount(e) - 1) downto 0 do
    begin
      if Signature(e.ReferencedBy[i]) = 'REFR' then
        Remove(e.ReferencedBy[i]);
//      if Signature(ReferencedByIndex(e, i)) = 'REGN' then
    end;
  end else if Signature(e) = 'REFR' then begin
    if (Copy(e.ElementByPath['NAME'].Value, 12, MaxInt) = '<Error: Could not be resolved>') or (e.ElementByPath['NAME'].Value = 'NULL - Null Reference [00000000]') then begin
      Remove(e);

      Exit;
    end;

    for i := (ElementCount(e) - 1) downto 0 do
      if (
        (Name(ElementByIndex(e, i)) = 'Patrol') or
        (Name(ElementByIndex(e, i)) = 'XNDP - Navigation Door Link') or
        (Name(ElementByIndex(e, i)) = 'XESP - Enable Parent') or
        (Name(ElementByIndex(e, i)) = 'XOWN - Owner')
      ) then
        Remove(ElementByIndex(e,i));
  end else if Signature(e) = 'PGRE' then begin
    for i := (ElementCount(e) - 1) downto 0 do
      if (
        (Name(ElementByIndex(e, i)) = 'Reflected/Refracted By') or
        (Name(ElementByIndex(e, i)) = 'XOWN - Owner')
      ) then
        Remove(ElementByIndex(e,i));
  end else if Signature(e) = 'WRLD' then begin
    e.ElementByPath['NAM3'].EditValue := '00000018';
  end else if Signature(e) = 'ACHR' then begin
    Remove(e);

    Exit;
  end;

  if StrToInt('$' + Copy(IntToHex(FixedFormID(e), 8), 3, 6)) < 2048 then
    if (Signature(e) <> 'TES4') then
      Remove(e)
  else
    Recursive(e);

  if Signature(e) = 'MSTT' then begin
    if AnsiPos('FX', StringReplace(GetElementEditValues(e, 'EDID'), 'nv-', '', [rfReplaceAll])) = 1 then
      Remove(e);
  end;
end;

function Finalize: integer;
begin
	Result := 0;
end;

end.
