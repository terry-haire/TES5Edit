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
    if Assigned(ielement) then
      if Assigned(LinksTo(ielement)) then
      begin
//        sform := '$00' + Copy(IntToHex(FormID(LinksTo(ielement).ContainingMainRecord), 8), 3, 6);
//        if StrToInt(sform) < 2048 then begin
//          sform := Copy(sform, 2, 8);
//          SetEditValue(ielement, sform);
//        end;
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

procedure FixFallout3LockLevel(e: IwbMainRecord);
var
  subrec: IwbElement;
begin
  subrec := e.ElementByPath['XLOC\Level'];

  if not Assigned(subrec) then
    Exit;

  if subrec.NativeValue > 0 then begin
    if subrec.NativeValue <= 20 then
      subrec.NativeValue := 25
    else if subrec.NativeValue <= 40 then
      subrec.NativeValue := 25
    else if subrec.NativeValue <= 60 then
      subrec.NativeValue := 50
    else if subrec.NativeValue <= 80 then
      subrec.NativeValue := 75
    else if subrec.NativeValue <= 99 then
      subrec.NativeValue := 100
  end;
end;

function IsRefError(e: IwbElement): boolean;
begin
  if not Assigned(e) then begin
    Result := False;

    Exit;
  end;

  Result := Copy(e.Value, 12, MaxInt) = '<Error: Could not be resolved>';
end;

procedure ApplyLandLayersWorkaround(e: IwbMainRecord);
var
  layers: IwbContainer;
  layerElement: IwbElement;
  i: Integer;
  toRemove: TList;
begin
  layers := e.ElementByPath['Layers'] as IwbContainer;

  if (not Assigned(layers)) or (layers.ElementCount = 0) then
    Exit;

  for i := layers.ElementCount - 1 downto 0 do begin
    layerElement := (layers.Elements[i] as IwbContainer).ElementByPath['ATXT\Layer'];

    if not Assigned(layerElement) then
      layerElement := (layers.Elements[i] as IwbContainer).ElementByPath['BTXT\Layer'];

    if not Assigned(layerElement) then
      raise Exception.Create('Layer not found');

//    // Layers must be between -1 and 2.
//    layerElement.NativeValue := i - 1;

    if (layerElement.NativeValue < -1) or (layerElement.NativeValue > 2) then begin
      layers.Elements[i].Remove;
    end;
//    if (layerElement.NativeValue < -1) then begin
//      layerElement.NativeValue := -1;
//    end else if (layerElement.NativeValue > 2) then begin
//      layerElement.NativeValue := 2;
//    end;

  end;
end;

procedure FNVImportCleanRecord(e: IwbMainRecord);
var
i: Integer;
begin
  if Signature(e) = 'TREE' then begin
    //    for i := (ReferencedByCount(e) - 1) downto 0 do
    //    begin
    //      if Signature(e.ReferencedBy[i]) = 'REFR' then
    //        Remove(e.ReferencedBy[i]);
    ////      if Signature(ReferencedByIndex(e, i)) = 'REGN' then
    //    end;
  end else if Signature(e) = 'SNDR' then begin
    Remove(e);

    Exit;
  end else if Signature(e) = 'CAMS' then begin
    Remove(e);

    Exit;
  end else if Signature(e) = 'CPTH' then begin
    Remove(e);

    Exit;
  end else if Signature(e) = 'VTYP' then begin
    Remove(e);

    Exit;
  end else if Signature(e) = 'QUST' then begin
    Remove(e);

    Exit;
  end else if Signature(e) = 'PACK' then begin
    Remove(e);

    Exit;
  end else if Signature(e) = 'NAVM' then begin
    Remove(e);

    Exit;
  end else if Signature(e) = 'GLOB' then begin
    e.ElementByPath['EDID'].EditValue := 'nv-' + e.ElementByPath['EDID'].EditValue;
  end else if Signature(e) = 'LAND' then begin
    ApplyLandLayersWorkaround(e);
  end else if Signature(e) = 'REFR' then begin
    e.RemoveElement('XLTW');

    var nameElem := e.ElementByPath['NAME'];

    if Assigned(nameElem) then begin
      var nameValue := nameElem.Value;

      if (Copy(nameValue, 12, MaxInt) = '<Error: Could not be resolved>') or (nameValue = 'NULL - Null Reference [00000000]') then begin
        Remove(e);

        Exit;
      end;
    end;

    if IsRefError(e.ElementByPath['XTEL\Door']) then begin
      e.ElementByPath['XTEL'].Remove;
    end;

    if IsRefError(e.ElementByPath['XMBR']) then begin
      e.ElementByPath['XMBR'].Remove;
    end;


    for i := (ElementCount(e) - 1) downto 0 do
      if (
        (Name(ElementByIndex(e, i)) = 'Patrol') or
        (Name(ElementByIndex(e, i)) = 'XNDP - Navigation Door Link') or
        (Name(ElementByIndex(e, i)) = 'XESP - Enable Parent') or
        (Name(ElementByIndex(e, i)) = 'XOWN - Owner')
      ) then
        Remove(ElementByIndex(e,i));

    FixFallout3LockLevel(e);
  end else if Signature(e) = 'PGRE' then begin
    for i := (ElementCount(e) - 1) downto 0 do
      if (
        (Name(ElementByIndex(e, i)) = 'Reflected/Refracted By') or
        (Name(ElementByIndex(e, i)) = 'XOWN - Owner')
      ) then
        Remove(ElementByIndex(e,i));
  end else if Signature(e) = 'WRLD' then begin
    e.Add('NAM2').EditValue := '00000018';
    e.Add('NAM3').EditValue := '00000018';
    e.Add('ZNAM').EditValue := '0001ED25';
    e.Add('CNAM').EditValue := '0000015F';
  end else if Signature(e) = 'ACHR' then begin
    Remove(e);

    Exit;
  end else if Signature(e) = 'CELL' then begin
    e.RemoveElement('XCAS');
    e.RemoveElement('XCLR');

    if Assigned(e.ElementByPath['XCIM']) then
      e.ElementByPath['XCIM'].EditValue := '001A65F2';

    for i := (ElementCount(e) - 1) downto 0 do
      if (
        (Name(ElementByIndex(e, i)) = 'Reflected/Refracted By') or
        (Name(ElementByIndex(e, i)) = 'XOWN - Owner')
      ) then
        Remove(ElementByIndex(e,i));
  end;
  
  if (StrToInt('$' + Copy(IntToHex(FixedFormID(e), 8), 3, 6)) < 2048) and (e._File.Name = 'FalloutNV.esm') then begin
    if (Signature(e) <> 'TES4') then
      Remove(e)
  end else begin
    Recursive(e);
  end;

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
