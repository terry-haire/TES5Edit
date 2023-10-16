unit __ScriptAdapterFunctions;

interface
uses
  Classes,
  SysUtils,
  StrUtils,
  Windows,
  wbInterface; //Remove before use in xEdit

function GetElementEditValues(e: IwbContainer; s: string): string;
function GetFileName(Obj: IInterface): string;
function GetLoadOrder(_File: IwbFile): Integer;
function GetNewFormID(_File: IwbFile): Cardinal;
function ElementName(Element: IwbContainer): string;
function ElementShortName(Element: IwbContainer): string;
function ElementBaseName(Element: IwbContainer): string;
function ElementDisplayName(Element: IwbContainer): string;
function FullPath(Element: IwbElement): string;
function PathName(Element: IwbElement): string;
function ElementType(Element: IwbContainer): TwbElementType;
procedure AddMessage(s: String);
function Signature(Element: IwbMainRecord): string;
function GetLoadOrderFormID(MainRecord: IwbMainRecord): Cardinal;
function GetFile(Element: IwbElement): IwbFile;
function ElementCount(Container: IwbContainer): Integer;
function ElementByIndex(Container: IwbContainer; Index: Integer): IwbElement;
function GetEditValue(Element: IwbElement): string;
function Path(Element: IwbElement): string;
function ReferencedByCount(MainRecord: IwbMainRecord): Integer;
function FormID(MainRecord: IwbMainRecord): Cardinal;
function EditorID(MainRecord: IwbMainRecord): string;
procedure SetEditorID(MainRecord: IwbMainRecord; const ID: string);
function FixedFormID(MainRecord: IwbMainRecord): Cardinal;
function IndexOf(Container: IwbContainer; Element: IwbElement): Integer;
function Name(Element: IwbElement): string;
function Check(Element: IwbElement): string;
procedure SetEditValue(Element: IwbElement; const Value: string);
function Add(Container: IwbContainer; const aName: string; aSilent: Boolean): IwbElement;
function ElementAssign(Element: IwbElement; Index: Integer; const Element2: IwbElement; onlyIfAbsent: Boolean): IwbElement;
function RecordByFormID(_File: IwbFile; FormID: TwbFormID; const aResolve: Boolean): IwbMainRecord;
function ElementByPath(Container: IwbContainer; const Path: string): IwbElement;
function LinksTo(Element: IwbElement): IwbElement;
procedure Remove(Element: IwbElement);
procedure SetElementEditValues(Container: IwbContainer; const Index: string; const Value: string);
function GetContainer(Element: IwbElement): IwbContainer;
function LastElement(Container: IwbContainer): IwbElement;
function GetIsPersistent(MainRecord: IwbMainRecord): Boolean;
procedure SetIsPersistent(MainRecord: IwbMainRecord; Value: Boolean);
function IsEditable(Element: IwbElement): Boolean;
procedure SetToDefault(Element: IwbElement);
procedure AddMasterIfMissing(_File: IwbFile; const Master: string; DoCheck: Boolean = False);
procedure SetIsESM(_File: IwbFile; Value: Boolean);
function RecordByIndex(_File: IwbFile; Index: Integer): IwbRecord;
function MainRecordByEditorID(GroupRecord: IwbGroupRecord; const EditorID: string): IwbMainRecord;
function MasterOrSelf(MainRecord: IwbMainRecord): IwbMainRecord;
procedure SetLoadOrderFormID(MainRecord: IwbMainRecord; FormID: TwbFormID);


implementation


function GetElementEditValues(e: IwbContainer; s: string): string;
begin
  Result := e.ElementEditValues[s];
end;

function GetFileName(Obj: IInterface): string;
var
  _File: IwbFile;
  Element: IwbElement;
begin
  Result := '';
  if Supports(Obj, IwbFile, _File) then
    Result := _File.FileName
  else if Supports(Obj, IwbElement, Element) then
  begin
    var ElementFile: IwbFile := Element._File;
    if Assigned(ElementFile) then
      Result := ElementFile.FileName;
  end;
end;

function GetLoadOrder(_File: IwbFile): Integer;
begin
  Result := _File.LoadOrder;
end;

function GetNewFormID(_File: IwbFile): Cardinal;
begin
  Result := _File.NewFormID.ToCardinal;
end;

function ElementName(Element: IwbContainer): string;
begin
  Result := Element.Name;
end;

function ElementShortName(Element: IwbContainer): string;
begin
  Result := Element.ShortName;
end;

function ElementBaseName(Element: IwbContainer): string;
begin
  Result := Element.BaseName;
end;

function ElementDisplayName(Element: IwbContainer): string;
begin
  Result := Element.DisplayName[True];
end;

function Path(Element: IwbElement): string;
begin
  Result := Element.Path;
end;

function FullPath(Element: IwbElement): string;
begin
  Result := Element.FullPath;
end;

function ElementType(Element: IwbContainer): TwbElementType;
begin
  Result := Element.ElementType;
end;

procedure AddMessage(s: String);
begin
  wbProgress(s);
end;

function Signature(Element: IwbMainRecord): string;
begin
  Result := string(Element.Signature);
end;

function GetLoadOrderFormID(MainRecord: IwbMainRecord): Cardinal;
begin
  Result := MainRecord.LoadOrderFormID.ToCardinal;
end;

function GetFile(Element: IwbElement): IwbFile;
begin
  Result := Element._File;
end;

function ElementCount(Container: IwbContainer): Integer;
begin
  Result := Container.ElementCount;
end;

function ElementByIndex(Container: IwbContainer; Index: Integer): IwbElement;
begin
  Result := Container.Elements[Index];
end;

function GetEditValue(Element: IwbElement): string;
begin
  Result := Element.EditValue;
end;

function ReferencedByCount(MainRecord: IwbMainRecord): Integer;
begin
  Result := MainRecord.ReferencedByCount;
end;

function FormID(MainRecord: IwbMainRecord): Cardinal;
begin
  Result := MainRecord.FormID.ToCardinal;
end;

function EditorID(MainRecord: IwbMainRecord): string;
begin
  Result := MainRecord.EditorID;
end;

procedure SetEditorID(MainRecord: IwbMainRecord; const ID: string);
begin
  MainRecord.EditorID := ID;
end;

function FixedFormID(MainRecord: IwbMainRecord): Cardinal;
begin
  Result := MainRecord.FixedFormID.ToCardinal;
end;

function ElementByPath(Container: IwbContainer; const Path: string): IwbElement;
begin
  Result := Container.ElementByPath[Path];
end;

function RecordByFormID(_File: IwbFile; FormID: TwbFormID; const aResolve: Boolean): IwbMainRecord;
begin
  Result := _File.RecordByFormID[FormID, aResolve, True];
end;

function ElementAssign(Element: IwbElement; Index: Integer; const Element2: IwbElement; onlyIfAbsent: Boolean): IwbElement;
begin
  Result := Element.Assign(Index, Element2, onlyIfAbsent);
end;

function Add(Container: IwbContainer; const aName: string; aSilent: Boolean): IwbElement;
begin
  Result := Container.Add(aName, aSilent);
end;

procedure SetEditValue(Element: IwbElement; const Value: string);
begin
  Element.EditValue := Value;
end;

function Check(Element: IwbElement): string;
begin
  Result := Element.Check;
end;

function Name(Element: IwbElement): string;
begin
  Result := Element.Name;
end;

function IndexOf(Container: IwbContainer; Element: IwbElement): Integer;
begin
  Result := Container.IndexOf(Element);
end;

function GetContainer(Element: IwbElement): IwbContainer;
begin
  Result := Element.Container;
end;

procedure SetElementEditValues(Container: IwbContainer; const Index: string; const Value: string);
begin
  Container.ElementEditValues[Index] := Value;
end;

procedure Remove(Element: IwbElement);
begin
  Element.Remove;
end;

function LinksTo(Element: IwbElement): IwbElement;
begin
  Result := Element.LinksTo;
end;

function LastElement(Container: IwbContainer): IwbElement;
begin
  Result := Container.LastElement;
end;

function PathName(Element: IwbElement): string;
begin
  Result := Element.PathName;
end;

function GetIsPersistent(MainRecord: IwbMainRecord): Boolean;
begin
  Result := MainRecord.IsPersistent;
end;

procedure SetIsPersistent(MainRecord: IwbMainRecord; Value: Boolean);
begin
  MainRecord.IsPersistent := Value;
end;

function IsEditable(Element: IwbElement): Boolean;
begin
  Result := Element.IsEditable;
end;

procedure SetToDefault(Element: IwbElement);
begin
  Element.SetToDefault;
end;

procedure AddMasterIfMissing(_File: IwbFile; const Master: string; DoCheck: Boolean = False);
begin
  _File.AddMasterIfMissing(Master, DoCheck);
end;

procedure SetIsESM(_File: IwbFile; Value: Boolean);
begin
  _File.IsESM := Value;
end;

function RecordByIndex(_File: IwbFile; Index: Integer): IwbRecord;
begin
  if Index < _File.RecordCount then
    Result := _File.Records[Index]
  else
    Result := nil;
end;

procedure SetLoadOrderFormID(MainRecord: IwbMainRecord; FormID: TwbFormID);
begin
  MainRecord.LoadOrderFormID := FormID;
end;

function MainRecordByEditorID(GroupRecord: IwbGroupRecord; const EditorID: string): IwbMainRecord;
begin
  Result := GroupRecord.MainRecordByEditorID[EditorID];
end;

function MasterOrSelf(MainRecord: IwbMainRecord): IwbMainRecord;
begin
  Result := MainRecord.MasterOrSelf;
end;


end.
