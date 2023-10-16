unit __FNVConversionFunctions;

interface
uses Classes, SysUtils, StrUtils, Windows; //Remove before use in xEdit
//
function formatelementpath(elementpathstring: String): String;
//procedure CleanConditions(const rec: IInterface);
//
implementation

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
//
//procedure CleanConditionsHelper(const rec: IInterface; const sl: TStringList; const index: Integer);
//var
//rContainer, r: IInterface;
//j, k: Integer;
//path, path2: String;
//begin
//  if index < sl.Count then
//    path := sl[index];
//  if (index + 1) < sl.Count then
//    path2 := sl[(index + 1)];
//  rContainer := rec; /// First time rec path should be sl[0] as should index
//  if Assigned(rContainer) then
//  begin
//    if path = 'Conditions' then
//    for j := (ElementCount(rContainer) - 1) downto 0 do
//    begin
//      r := ElementByIndex(rContainer, j);
//      r := ElementByPath(r, 'CTDA\Function');
//      if Assigned(r) then
//      begin
//        if GetEditValue(r) = 'GetWantBlocking' then
//        begin
//          /// Removal code here
//          r := ElementByIndex(rContainer, j); /// Condition
//          if ElementCount(rContainer) = 1 then
//          begin
//            if sl.Count = 1 then
//              Remove(rContainer) /// If only a conditions record remove it
//            else
//            begin
//              k := (sl.Count - 2); /// Path before conditions
//              while (formatelementpath(Name(rContainer)) <> sl[0]) do
//              begin
//                r           := GetContainer(r);
//                rContainer  := GetContainer(rContainer);
//                if formatelementpath(Name(rContainer)) = sl[k] then
//                begin
//                  if ElementCount(rContainer) > 1 then
//                  begin
//                    Remove(r);
//                    Exit;
//                  end
//                  else if k = 0 then Remove(rContainer);
//                  k := k - 1;
//                end;
//              end;
//            end;
//          end
//          else
//            Remove(r); /// Remove Condition
//        end;
//      end;
//    end
//    else
//    for j := (ElementCount(rContainer) - 1) downto 0 do
//    begin
//      r := ElementByIndex(rContainer, j);
//      r := ElementByPath(r, path2);
//      if Assigned(r) then
//        if (index + 1) < sl.Count then
//          CleanConditionsHelper(r, sl, (index + 1));
//    end;
//  end;
//end;
//
//procedure CleanConditions2(const rec: IInterface);
//var
//sl: TStringList;
//s: String;
//begin
//  sl := TStringList.Create;
//  sl.Delimiter := ';';
//  sl.StrictDelimiter := True;
//  s := Signature(rec);
//
//  if
//  (  (s = 'CPTH')
//  OR (s = 'IDLE')
//  OR (s = 'PACK')
//  OR (s = 'PERK')
//  OR (s = 'QUST')
//  OR (s = 'RCPE')
//  ) then
//  begin
//    sl.DelimitedText := 'Conditions';
//    CleanConditionsHelper(ElementByPath(rec, sl[0]), sl, 0);
//  end;
//
//  if
//  (
//     (s = 'ALCH')
//  OR (s = 'SPEL')
//  OR (s = 'ENCH')
//  OR (s = 'PERK')
//  OR (s = 'INGR')
//  ) then
//  begin
//    sl.DelimitedText := 'Effects;Conditions';
//    CleanConditionsHelper(ElementByPath(rec, sl[0]), sl, 0);
//  end;
//
//  if s = 'QUST' then
//  begin
//    sl.DelimitedText := 'Stages;Log Entries;Conditions';
//    CleanConditionsHelper(ElementByPath(rec, sl[0]), sl, 0);
//    sl.DelimitedText := 'Objectives;Targets;Conditions';
//    CleanConditionsHelper(ElementByPath(rec, sl[0]), sl, 0);
//  end;
//
//  if s = 'MESG' then
//  begin
//    sl.DelimitedText := 'Menu Buttons;Conditions';
//    CleanConditionsHelper(ElementByPath(rec, sl[0]), sl, 0);
//  end;
//
//  if s = 'MESG' then
//  begin
//    sl.DelimitedText := 'Effects;Perk Conditions;Conditions';
//    CleanConditionsHelper(ElementByPath(rec, sl[0]), sl, 0);
//  end;
//
//
//end;
//
//
//
//////////////////////////////////////////////////////////////////////////////////
///// Clean Conditions
//////////////////////////////////////////////////////////////////////////////////
//procedure CleanConditions(const rec: IInterface);
//var
//rEffects,
//rEffect,
//rPerkConditions,
//rPerkCondition,
//rConditions,
//rCondition,
//rCTDA: IInterface;
//
//s: String;
//
//i, j, k: Integer;
//begin
//  s := Signature(rec);
//  if
//  (
//     (s = 'ALCH')
//  OR (s = 'SPEL')
//  OR (s = 'ENCH')
//  OR (s = 'PERK')
//  OR (s = 'INGR')
//  ) then
//  begin
//    rEffects := ElementByPath(rec, 'Effects');
//    for i := (ElementCount(rEffects) - 1) downto 0 do
//    begin
//      rEffect := ElementByIndex(rEffects, i);
//      rConditions := ElementByPath(rEffect, 'Conditions');
//      if Assigned(rConditions) then
//      begin
//        for j := (ElementCount(rConditions) - 1) downto 0 do
//        begin
//          rCondition := ElementByIndex(rConditions, j);
//          rCTDA := ElementByPath(rCondition, 'CTDA\Function');
//          if Assigned(rCTDA) then
//          begin
//            if GetEditValue(rCTDA) = 'GetWantBlocking' then
//            begin
//              if ElementCount(rConditions) = 1 then
//                Remove(rEffect)
//              else
//                Remove(rCondition);
//            end;
//          end;
//        end;
//      end;
//    end;
//  end;
//
//  if s = 'PERK' then
//  begin
//    rEffects := ElementByPath(rec, 'Effects');
//    for i := (ElementCount(rEffects) - 1) downto 0 do
//    begin
//      rEffect := ElementByIndex(rEffects, i);
//      rPerkConditions := ElementByPath(rEffect, 'Perk Conditions');
//      if Assigned(rPerkConditions) then
//      begin
//        for k := (ElementCount(rPerkConditions) - 1) downto 0 do
//        begin
//          rPerkCondition := ElementByIndex(rPerkConditions, k);
//          rConditions := ElementByPath(rPerkCondition, 'Conditions');
//          if Assigned(rConditions) then
//          begin
//            for j := (ElementCount(rConditions) - 1) downto 0 do
//            begin
//              rCondition := ElementByIndex(rConditions, j);
//              rCTDA := ElementByPath(rCondition, 'CTDA\Function');
//              if Assigned(rCTDA) then
//              begin
//                if GetEditValue(rCTDA) = 'GetWantBlocking' then
//                begin
//                  if ElementCount(rConditions) = 1 then
//                  begin
//                    if ElementCount(rPerkConditions) = 1 then
//                      Remove(rPerkConditions)
//                    else
//                      Remove(rPerkCondition);
//                  end
//                  else
//                    Remove(rCondition);
//                end;
//              end;
//            end;
//          end;
//        end;
//      end;
//    end;
//  end;
//end;

end.