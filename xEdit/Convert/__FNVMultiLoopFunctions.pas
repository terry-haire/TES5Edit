unit __FNVMultiLoopFunctions;

interface
uses Classes, SysUtils, StrUtils, Windows, __ScriptAdapterFunctions, wbInterface;

function Recursive2(e: IwbContainer; slstring: String): String;
function RecursiveNAVI(e: IwbContainer; NPCList: TStringList): TStringList;

implementation

function Recursive2(e: IwbContainer; slstring: String): String;
var
i: integer;
ielement: IwbContainer;
begin
	for i := 0 to (ElementCount(e)-1) do
	begin
		ielement := ElementByIndex(e, i) as IwbContainer;
		slstring := (slstring
//    stringreplace(
//     ,'"', '|CITATION|', [rfReplaceAll])
    + ';' + stringreplace(stringreplace(stringreplace(path(ielement), #13#10, '\r\n', [rfReplaceAll]), ';' , '\comment\', [rfReplaceAll]) ,'"', '|CITATION|', [rfReplaceAll])
    + ';' + stringreplace(stringreplace(stringreplace(GetEditValue(ielement), #13#10, '\r\n', [rfReplaceAll]), ';' , '\comment\', [rfReplaceAll]) ,'"', '|CITATION|', [rfReplaceAll])
    + ';' + IntToStr(i));
		if ElementCount(ielement) > 0 then slstring := (Recursive2(ielement, slstring));
	end;
	Result := slstring;
end;

function RecursiveNAVI(e: IwbContainer; NPCList: TStringList): TStringList;
var
i: integer;
ielement: IwbContainer;
begin
	for i := 0 to (ElementCount(e)-1) do
	begin
		ielement := ElementByIndex(e, i) as IwbContainer;
		NPCList.Add(Path(ielement));
		NPCList.Add(GetEditValue(ielement));
		if ElementCount(ielement) > 0 then NPCList := (RecursiveNAVI(ielement, NPCList));
	end;
	Result := NPCList;
end;

end.
