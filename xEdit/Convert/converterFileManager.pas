unit converterFileManager;

interface
uses
  Classes,
  SysUtils,
  StrUtils,
  Windows,
  System.JSON,
  System.IOUtils,
  Generics.Collections,
  Generics.Defaults,
  wbInterface; //Remove before use in xEdit

type
  TFuncType = function(aFileName: string; aIsESL: Boolean): IwbFile of object;

  TConverterManagedFile = class
  private
    AddNewFileName: TFuncType;
    Files: TwbFiles;
    oldLOToNewLO: TDictionary<Integer, Integer>;
  public
    filename: string;
    f: IwbFile;

    constructor Create(filename: string; AddNewFileName: TFuncType; Files: TwbFiles);
    destructor Destroy; override;

    function GetNewFormID(formID: String): TwbFormID;
    function GetNewFileLO(formID: String): Integer;
    function RecordByNewFormID(newFormID: TwbFormID): IwbMainRecord;
    function RecordByNewFormIDHex(newFormIDHex: String): IwbMainRecord;
  end;

  TConverterFileManager = class
  private
    managedFiles: TList<TConverterManagedFile>;
    AddNewFileName: TFuncType;
    Files: TwbFiles;

    filenameToManagedFile: TDictionary<string, TConverterManagedFile>;
  public
    constructor Create(AddNewFileName: TFuncType; Files: TwbFiles);
    destructor Destroy; override;

    function AddFile(filename: String): TConverterManagedFile;
    procedure AddFiles(filenames: TStringList);

    function HasFile(filename: string): Boolean;
    function GetManagedFileByFilename(filename: string): TConverterManagedFile;

    //function GetNewFormID(hex: String): String;

    // Properties
//    property Field1: Integer read GetField1 write SetField1;
//    property Field2: String read FField2 write FField2;
  end;

implementation

uses
  __ScriptAdapterFunctions;

constructor TConverterManagedFile.Create(filename: string; AddNewFileName: TFuncType; Files: TwbFiles);
begin
  self.filename := filename;
  self.AddNewFileName := AddNewFileName;
  self.Files := Files;

  oldLOToNewLO := TDictionary<Integer, Integer>.Create;

  var filePath := wbProgramPath + '\data\'+ filename + '.json';
  var JSONString := TFile.ReadAllText(filePath);
  var JSONValue := TJSONObject.ParseJSONValue(JSONString);

  if JSONValue is TJSONObject then begin
    f := AddNewFileName(filename, False);

    Files.Add(f);
    self.Files.Add(f);

    AddMasterIfMissing(f, 'Fallout4.esm');

    if (ansipos('.esm', filename) <> 0) then
      SetIsESM(f, True);

    var JSONObject := JSONValue as TJSONObject;

    var masters := JSONObject.GetValue<TJSONArray>('masters');

    for var j := 0 to masters.Count - 1 do begin
      var master := masters[j];

      var masterName := master.GetValue<String>('name');
      var masterLO := master.GetValue<Integer>('loadorder');
      var found := False;

      for var i := Low(Files) to High(Files) do begin
        if Files[i].FileName <> masterName then
          Continue;

        AddMasterIfMissing(f, masterName);

        oldLOToNewLO.Add(masterLO, Files[i].LoadOrder);

        found := True;
      end;

      if not found then
        raise Exception.Create('Required master not found: ' + masterName);
    end;

    oldLOToNewLO.Add(JSONObject.GetValue<Integer>('loadorder'), f.LoadOrder);
  end else begin
    // Handle the case where the JSON is not an object
    raise Exception.Create('JSON not an object');
  end;

  JSONValue.Free;
end;

destructor TConverterManagedFile.Destroy;
begin
  oldLOToNewLO.Free;
end;

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

function TConverterManagedFile.RecordByNewFormID(newFormID: TwbFormID): IwbMainRecord;
begin
  var ValuesList := TList<Integer>.Create;

  ValuesList.AddRange(self.oldLOToNewLO.Values);

  // Sort the list in descending order
  ValuesList.Sort(TComparer<Integer>.Construct(
    function(const Left, Right: Integer): Integer
    begin
      Result := Right - Left; // For descending order
    end));

  // Iterate over the sorted list
  for var loadorder in ValuesList do
  begin
    var loadorderFile := FileByLoadOrder(Files, loadorder);

    var rec := loadorderFile.RecordByFormID[newFormID, True, True];

    if Assigned(rec) and (rec.FormID.toString() = newFormID.ToString()) then begin
      Result := rec;

      break;
    end;
  end;
end;

function TConverterManagedFile.RecordByNewFormIDHex(newFormIDHex: String): IwbMainRecord;
begin
  //var newFormID := self.GetNewFormID(newFormIDHex);
  var newFormID := TwbFormID.FromCardinal(StrToInt('$' + newFormIDHex));

  Result := self.RecordByNewFormID(newFormID);
end;

function TConverterManagedFile.GetNewFileLO(formID: String): Integer;
begin
  var originalLO := Copy(formID, 1, 2);
  var originalFormID := Copy(formID, 3, 6);

  Result := self.oldLOToNewLO[StrToInt('$' + originalLO)];
end;

function TConverterManagedFile.GetNewFormID(formID: String): TwbFormID;
begin
  var originalLO := Copy(formID, 1, 2);
  var originalFormID := Copy(formID, 3, 6);

  var newLO := IntToHex(self.oldLOToNewLO[StrToInt('$' + originalLO)]);

  var newFormIDHex := RightStr(newLO, 2) + originalFormID;

  Result := TwbFormID.FromStr(newFormIDHex);
end;

{ TConverterFileManager }

constructor TConverterFileManager.Create(AddNewFileName: TFuncType; Files: TwbFiles);
begin
  self.AddNewFileName := AddNewFileName;
  self.Files := Files;

  managedFiles := TList<TConverterManagedFile>.Create;
  filenameToManagedFile := TDictionary<string, TConverterManagedFile>.Create;
end;

destructor TConverterFileManager.Destroy;
begin
  managedFiles.Free;
  filenameToManagedFile.Free;
end;

function TConverterFileManager.AddFile(filename: String): TConverterManagedFile;
begin
  Result := TConverterManagedFile.Create(filename, AddNewFileName, Files);

  managedFiles.Add(Result);
  filenameToManagedFile.Add(filename, Result);
end;

procedure TConverterFileManager.AddFiles(filenames: TStringList);
begin
  for var i := 0 to filenames.Count - 1 do begin
    var filename := filenames[i];

    AddFile(filename);
  end;
end;

function TConverterFileManager.HasFile(filename: string): Boolean;
begin
  Result := filenameToManagedFile.ContainsKey(filename);
end;

function TConverterFileManager.GetManagedFileByFilename(filename: string): TConverterManagedFile;
begin
  Result := filenameToManagedFile.Items[filename];
end;

end.
