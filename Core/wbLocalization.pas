{******************************************************************************

  This Source Code Form is subject to the terms of the Mozilla Public License, 
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain 
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

unit wbLocalization;

{$I wbDefines.inc}

interface

uses
  Classes, SysUtils, StrUtils, Math,
  wbInterface, wbBSA;

const
  sStringID = 'STRINGID:';

type
  TwbLStringType = (
    lsDLString,
    lsILString,
    lsString
  );

  TwbLocalizationFile = class
  private
    fEncoding    : array [Boolean] of TEncoding;
    fName        : string;
    fLanguage    : string;
    fFileName    : string;
    fFileType    : TwbLStringType;
    fStrings     : TStrings;
    fModified    : Boolean;
    fNextID      : Cardinal;

    procedure Init;
    function FileStringType(aFileName: string): TwbLStringType;
    function ReadZString(aStream: TMemoryStream): string;
    function ReadLenZString(aStream: TMemoryStream): string;
    procedure WriteZString(aStream: TMemoryStream; const aString: string);
    procedure WriteLenZString(aStream: TMemoryStream; const aString: string);
    procedure ReadDirectory(aStream: TMemoryStream);
  protected
    function Get(Index: Cardinal): string;
    procedure Put(Index: Cardinal; const S: string);
  public
    property Strings[Index: Cardinal]: string read Get write Put; default;
    property Items: TStrings read fStrings;
    property Name: string read fName;
    property FileName: string read fFileName;
    property Modified: Boolean read fModified write fModified;
    property NextID: Cardinal read fNextID;
    constructor Create(const aFileName: string); overload;
    constructor Create(const aFileName: string; aData: TBytes); overload;
    destructor Destroy; override;
    function Count: Integer;
    function IndexToID(Index: Integer): Cardinal;
    function IDExists(ID: Cardinal): Boolean;
    function AddString(ID: Cardinal; const S: string): Boolean;
    function Find(ID: Cardinal; out s: string): Boolean;
    procedure WriteToStream(const aStream: TStream);
    procedure ExportToFile(const aFileName: string);
  end;

  TwbLocalizationHandler = class
  private
    lFiles       : TStringList;
    lGameModeConfig: PTwbGameModeConfig;
    fReuseDup    : Boolean;
  protected
    function Get(Index: Integer): TwbLocalizationFile;
    function GetStringsPath: string;
  public
    Generation: Integer;
    NoTranslate: Boolean;
    property _Files[Index: Integer]: TwbLocalizationFile read Get; default;
    property StringsPath: string read GetStringsPath;
    property ReuseDup: Boolean read fReuseDup write fReuseDup;
    constructor Create(aGameModeConfig: PTwbGameModeConfig);
    destructor Destroy; override;
    procedure Clear;
    function Count: Integer;
    function LocalizedValueDecider(aElement: IwbElement): TwbLStringType;
    procedure AvailableLanguages(aLanguages : TStringList);
    procedure AvailableLocalizationFiles(aFiles: TStringList);
    procedure LoadForFile(aFileName: string);
    function AddLocalization(const aFileName: string): TwbLocalizationFile; overload;
    function AddLocalization(const aFileName: string; aData: TBytes): TwbLocalizationFile; overload;
    function GetValue(ID: Cardinal; aElement: IwbElement; out aValue: string): Boolean;
    function SetValue(ID: Cardinal; aElement: IwbElement; aValue: string): Cardinal;
    function AddValue(aValue: string; aElement: IwbElement): Cardinal;
    function GetLocalizationFileNameByElement(aElement: IwbElement): string;
    function GetLocalizationFileNameByType(aPluginFile: string; ls: TwbLStringType): string;
    procedure GetStringsFromFile(aFileName: string; const aList: TStrings);
  end;

const
  wbLocalizationExtension: array [TwbLStringType] of string = (
    '.DLSTRINGS',
    '.ILSTRINGS',
    '.STRINGS'
  );

var
//  wbLocalizationHandler: TwbLocalizationHandler;
  wbGameModeToLocalizationHandler: array[TwbGameMode] of TwbLocalizationHandler;

implementation

uses
  WideStrUtils;

constructor TwbLocalizationFile.Create(const aFileName: string);
var
  fs: TFileStream;
  fStream: TMemoryStream;
  Buffer: PByte;
begin
  fFileName := aFileName;
  Init;
  // cache file in mem
  fStream := TMemoryStream.Create;
  try
    fs := TFileStream.Create(aFileName, fmOpenRead or fmShareDenyNone);
    GetMem(Buffer, fs.Size);
    try
      fs.ReadBuffer(Buffer^, fs.Size);
      fStream.WriteBuffer(Buffer^, fs.Size);
      fStream.Position := 0;
      ReadDirectory(fStream);
    finally
      if Assigned(Buffer) then FreeMem(Buffer);
    end;
  finally
    FreeAndNil(fs);
    FreeAndNil(fStream);
  end;
end;

constructor TwbLocalizationFile.Create(const aFileName: string; aData: TBytes);
var
  fStream: TMemoryStream;
begin
  fFileName := aFileName;
  Init;
  fStream := TMemoryStream.Create;
  try
    fStream.WriteBuffer(aData[0], length(aData));
    fStream.Position := 0;
    ReadDirectory(fStream);
  finally
    FreeAndNil(fStream);
  end;
end;

destructor TwbLocalizationFile.Destroy;
begin
  FreeAndNil(fStrings);
  inherited;
end;

procedure TwbLocalizationFile.Init;
var
  i: Integer;
  s: string;
begin
  fModified := false;
  fName := ExtractFileName(fFileName);

  fLanguage := ChangeFileExt(fName, '');
  i := Length(fLanguage);
  while (i > 0) and (fLanguage[i]<>'_') do
    Dec(i);
  Delete(fLanguage, 1, i);

  fEncoding[False] := nil;
  fEncoding[True] := nil;

  s := ChangeFileExt(fFileName, '.cpoverride');
  if FileExists(s) then try
    with TStringList.Create do try
      LoadFromFile(s);
      if Count > 0 then begin
        s := Strings[0].Trim;
        if s <> '' then
          fEncoding[False] := wbMBCSEncoding(s);
      end;
    finally
      Free;
    end;
  except end;

  s := '';

  if Assigned(fEncoding[False]) then
    s := Format('[%s] Using encoding (from override): %s', [fName, fEncoding[False].EncodingName])
  else begin
    fEncoding[False] := wbEncodingForLanguage(fLanguage, False);
    s := Format('[%s] Using encoding (from language): %s', [fName, fEncoding[False].EncodingName]);
  end;

  fEncoding[True] := wbEncodingForLanguage(fLanguage, True);
  if fEncoding[True] = fEncoding[False] then
    fEncoding[True] := nil;

  if Assigned(fEncoding[True]) then
    s := s + ' with fallback (from languange) to: ' + fEncoding[True].EncodingName;

  wbProgress(s);

  fFileType := FileStringType(fFileName);
  fStrings := TwbFastStringList.Create;
  fNextID := 1;
end;

function TwbLocalizationFile.FileStringType(aFileName: string): TwbLStringType;
var
  ext: string;
  i: TwbLStringType;
begin
  Result := lsString;
  ext := ExtractFileExt(aFileName);
  for i := Low(TwbLStringType) to High(TwbLStringType) do
    if SameText(ext, wbLocalizationExtension[i]) then
      Result := i;
end;

function TwbLocalizationFile.Find(ID: Cardinal; out s: string): Boolean;
var
  idx: integer;
begin
  s := '';
  idx := fStrings.IndexOfObject(Pointer(ID));
  Result := idx >= 0;
  if Result then
    s := fStrings[idx]
  else
    s := '<Error: Unknown lstring ID ' + IntToHex(ID, 8) + '>';
end;

function TwbLocalizationFile.ReadZString(aStream: TMemoryStream): string;
var
  Position : Integer;
  p: PByte;
  i, j: Integer;
  b: TBytes;
begin
  Position := aStream.Position;
  p := @PByte(aStream.Memory)[Position];
  i := 0;
  j := aStream.Size - Position;
  while (i < j) and (p[i] <> 0) do
    Inc(i);
  if i > 0 then begin
    b := BytesOf(p, i);
    try
      Result := fEncoding[False].GetString(b);
    except
      on E: EEncodingError do begin
        if not Assigned(fEncoding[True]) then
          raise;
        Result := fEncoding[True].GetString(b);
      end;
    end;
  end else
    Result := '';
  aStream.Position := Position + Succ(i);
end;

function TwbLocalizationFile.ReadLenZString(aStream: TMemoryStream): string;
var
  Position : Integer;
  p: PByte;
  i: Integer;
  b: TBytes;
begin
  Position := aStream.Position;
  p := @PByte(aStream.Memory)[Position];
  i := PInteger(p)^;
  Inc(PInteger(p), 1);
  Dec(i);
  if i > 0 then begin
    b := BytesOf(p, i);
    try
      Result := fEncoding[False].GetString(b);
    except
      on E: EEncodingError do begin
        if not Assigned(fEncoding[True]) then
          raise;
        Result := fEncoding[True].GetString(b);
      end;
    end;
  end else
    Result := '';
  aStream.Position := Position + Succ(i) + SizeOf(Integer);
end;

procedure TwbLocalizationFile.WriteZString(aStream: TMemoryStream; const aString: string);
var
  b: TBytes;
  i: Integer;
const
  z: Byte = 0;
begin
  b := fEncoding[False].GetBytes(aString);
  i := Length(b);
  if i > 0 then
    aStream.WriteBuffer(b[0], i);
  aStream.WriteBuffer(z, SizeOf(z));
end;

procedure TwbLocalizationFile.WriteLenZString(aStream: TMemoryStream; const aString: string);
var
  b    : TBytes;
  i, j : Integer;
const
  z: Byte = 0;
begin
  b := fEncoding[False].GetBytes(aString);
  i := Length(b);
  j := Succ(i);
  aStream.WriteBuffer(j, SizeOf(j));
  if i > 0 then
    aStream.WriteBuffer(b[0], i);
  aStream.WriteBuffer(z, SizeOf(z));
end;

procedure TwbLocalizationFile.ReadDirectory(aStream: TMemoryStream);
var
  i: integer;
  scount, id, offset: Cardinal;
  oldPos: int64;
  s: string;
begin
  if aStream.Size < 8 then
    Exit;

  aStream.Read(scount, 4); // number of strings
  aStream.Position := aStream.Position + 4; // skip dataSize
  if scount > 0 then
    for i := 0 to scount - 1 do begin
      aStream.Read(id, 4); // string ID
      aStream.Read(offset, 4); // offset of string relative to data (header + dirsize)
      oldPos := aStream.Position;
      aStream.Position := 8 + scount*8 + offset; // header + dirsize + offset
      if fFileType = lsString then
        s := ReadZString(aStream)
      else
        s := ReadLenZString(aStream);
      fStrings.AddObject(s, pointer(id));
      if Succ(id) > fNextID then
        fNextID := Succ(id);
      aStream.Position := oldPos;
    end;
end;

procedure TwbLocalizationFile.WriteToStream(const aStream: TStream);
var
  dir, data: TMemoryStream;
  i: integer;
  c: Cardinal;
begin
  dir := TMemoryStream.Create;
  data := TMemoryStream.Create;
  c := fStrings.Count;
  dir.WriteBuffer(c, SizeOf(c)); // number of strings
  dir.WriteBuffer(c, SizeOf(c)); // dataSize, will overwrite later
  try
    for i := 0 to Pred(fStrings.Count) do begin
      c := Cardinal(fStrings.Objects[i]);
      dir.WriteBuffer(c, SizeOf(c)); // ID
      c := data.Position;
      dir.WriteBuffer(c, SizeOf(c)); // relative position
      if fFileType = lsString then
        WriteZString(data, fStrings[i])
      else
        WriteLenZString(data, fStrings[i]);
    end;
    c := data.Size;
    dir.Position := 4;
    dir.WriteBuffer(c, SizeOf(c)); // dataSize

    aStream.CopyFrom(dir, 0);
    aStream.CopyFrom(data, 0);
  finally
    FreeAndNil(dir);
    FreeAndNil(data);
  end;
end;

function TwbLocalizationFile.Count: Integer;
begin
  Result := fStrings.Count;
end;

function TwbLocalizationFile.IndexToID(Index: Integer): Cardinal;
begin
  if Index < Count then
    Result := Cardinal(fStrings.Objects[Index])
  else
    Result := 0;
end;

function TwbLocalizationFile.IDExists(ID: Cardinal): Boolean;
begin
  Result := fStrings.IndexOfObject(Pointer(ID)) >= 0;
end;

function TwbLocalizationFile.Get(Index: Cardinal): string;
var
  idx: integer;
begin
  Result := '';
  idx := fStrings.IndexOfObject(Pointer(Index));
  if idx >= 0 then
    Result := fStrings[idx]
  else
    Result := '<Error: Unknown lstring ID ' + IntToHex(Index, 8) + '>';
end;

procedure TwbLocalizationFile.Put(Index: Cardinal; const S: string);
var
  idx: integer;
begin
  idx := fStrings.IndexOfObject(Pointer(Index));
  if idx >= 0 then
    if fStrings[idx] <> S then begin
      fStrings[idx] := S;
      fModified := true;
    end;
end;

function TwbLocalizationFile.AddString(ID: Cardinal; const S: string): Boolean;
begin
  Result := false;
  if ID < NextID then
    Exit;

  fStrings.AddObject(S, Pointer(ID));
  fNextID := Succ(ID);
  fModified := true;

  Result := true;
end;

procedure TwbLocalizationFile.ExportToFile(const aFileName: string);
var
  i: integer;
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    for i := 0 to Pred(fStrings.Count) do begin
      sl.Add('[' + IntToHex(Integer(fStrings.Objects[i]), 8) + ']');
      sl.Add(fStrings[i]);
    end;
    sl.SaveToFile(aFileName);
  finally
    FreeAndNil(sl);
  end;
end;

constructor TwbLocalizationHandler.Create(aGameModeConfig: PTwbGameModeConfig);
begin
  lFiles := TwbFastStringListIC.CreateSorted;
  fReuseDup := false;
  NoTranslate := false;
  lGameModeConfig := aGameModeConfig;
end;

destructor TwbLocalizationHandler.Destroy;
begin
  Clear;
  FreeAndNil(lFiles);
end;

function TwbLocalizationHandler.Count: Integer;
begin
  TMonitor.Enter(Self);
  try
    Result := lFiles.Count;
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TwbLocalizationHandler.Clear;
var
  i: integer;
begin
  TMonitor.Enter(Self);
  try
    for i := 0 to Pred(Count) do
      _Files[i].Destroy;
    lFiles.Clear;
    Inc(Generation);
  finally
    TMonitor.Exit(Self);
  end;
end;

function TwbLocalizationHandler.Get(Index: Integer): TwbLocalizationFile;
begin
  TMonitor.Enter(Self);
  try
    if Index < Count then
      Result := TwbLocalizationFile(lFiles.Objects[Index])
    else
      Result := nil;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TwbLocalizationHandler.AddLocalization(const aFileName: string): TwbLocalizationFile;
var
  i: Integer;
  s: string;
begin
  s := ExtractFileName(aFileName);
  TMonitor.Enter(Self);
  try
    if lFiles.Find(s, i) then
      Result := lFiles.Objects[i] as TwbLocalizationFile
    else begin
      Result := TwbLocalizationFile.Create(aFileName);
      lFiles.AddObject(s, Result);
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TwbLocalizationHandler.AddLocalization(const aFileName: string; aData: TBytes): TwbLocalizationFile;
var
  i: Integer;
  s: string;
begin
  s := ExtractFileName(aFileName);
  TMonitor.Enter(Self);
  try
    if lFiles.Find(s, i) then
      Result := lFiles.Objects[i] as TwbLocalizationFile
    else begin
      wbLockProcessMessages;
      try
        Result := TwbLocalizationFile.Create(aFileName, aData);
        lFiles.AddObject(s, Result);
      finally
        wbUnLockProcessMessages;
      end;
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TwbLocalizationHandler.LocalizedValueDecider(aElement: IwbElement): TwbLStringType;
var
  sigElement, sigRecord: TwbSignature;
  aRecord: IwbSubRecord;
begin
  if Supports(aElement, IwbSubRecord, aRecord) then
    sigElement := aRecord.Signature
  else
    sigElement := '';

  sigRecord := aElement.ContainingMainRecord.Signature;

  if (sigRecord <> 'LSCR') and (sigElement = 'DESC') then Result := lsDLString else // DESC always from dlstrings except LSCR
  if (sigRecord = 'QUST') and (sigElement = 'CNAM') then Result := lsDLString else // quest log entry
  if (sigRecord = 'BOOK') and (sigElement = 'CNAM') then Result := lsDLString else // Book CNAM description
  if (sigRecord = 'INFO') and (sigElement <> 'RNAM') then Result := lsILString else // dialog, RNAM are lsString, others lsILString
    Result := lsString; // others
end;

function TwbLocalizationHandler.GetStringsPath: string;
begin
  Result := lGameModeConfig.wbDataPath + 'Strings\';
end;

procedure TwbLocalizationHandler.AvailableLanguages(aLanguages : TStringList);
var
  F  : TSearchRec;
  p  : integer;
  s  : string;

  procedure ParseString;
  begin
    p := LastDelimiter('_', s);
    if p > 0 then begin
      s := Copy(s, p + 1, length(s));
      if s = '' then
        Exit;
      s := AnsiUpperCase(s[1]) + Copy(s, 2, Length(s));
      if aLanguages.IndexOf(s) < 0 then
        aLanguages.Add(s);
    end;
  end;

var
  sl : TStringList;
  i  : Integer;
begin
  TMonitor.Enter(Self);
  try
    if Assigned(lGameModeConfig.wbContainerHandler) then begin
      sl := TStringList.Create;
      try
        lGameModeConfig.wbContainerHandler.ContainerResourceList('', sl, 'strings');
        for i := 0 to Pred(sl.Count) do begin
          s := sl[i];
          if s.EndsWith('strings', True) then begin
            s := ChangeFileExt(s, '').ToLower;
            ParseString;
          end;
        end;
      finally
        sl.Free;
      end;
    end else begin
      if FindFirst(StringsPath + '*.*STRINGS', faAnyFile, F) = 0 then try
        repeat
          s := LowerCase(ChangeFileExt(F.Name, ''));
          ParseString;
        until FindNext(F) <> 0;
      finally
        FindClose(F);
      end;
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TwbLocalizationHandler.AvailableLocalizationFiles(aFiles: TStringList);
var
  F: TSearchRec;
  sl : TStringList;
  i  : Integer;
  s  : string;
begin
  TMonitor.Enter(Self);
  try
    if Assigned(lGameModeConfig.wbContainerHandler) then begin
      sl := TStringList.Create;
      try
        lGameModeConfig.wbContainerHandler.ContainerResourceList('', sl, 'strings');
        for i := 0 to Pred(sl.Count) do begin
          s := sl[i];
          if s.EndsWith('strings', True) then
            aFiles.Add(ExtractFileName(s));
        end;
      finally
        sl.Free;
      end;
    end else begin
      if FindFirst(StringsPath + '*.*STRINGS', faAnyFile, F) = 0 then try
        repeat
          aFiles.Add(F.Name);
        until FindNext(F) <> 0;
      finally
        FindClose(F);
      end;
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TwbLocalizationHandler.LoadForFile(aFileName: string);
var
  ls   : TwbLStringType;
  i    : Integer;
  s    : string;
  res  : TDynResources;
begin
  if not Assigned(lGameModeConfig.wbContainerHandler) then
    Exit;

  TMonitor.Enter(Self);
  try
    for ls := Low(TwbLStringType) to High(TwbLStringType) do begin
      s := GetLocalizationFileNameByType(aFileName, ls);
      if not lFiles.Find(ExtractFileName(s), i) then begin
        res := lGameModeConfig.wbContainerHandler.OpenResource(s);
        if length(res) > 0 then
          AddLocalization(lGameModeConfig.wbDataPath + s, res[High(res)].GetData);
      end;
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TwbLocalizationHandler.GetLocalizationFileNameByType(aPluginFile: string; ls: TwbLStringType): string;
begin
  Result := Format('%s_%s%s', [
    ChangeFileExt(aPluginFile, ''),
    lGameModeConfig.wbLanguage,
    wbLocalizationExtension[ls]
  ]);
  // relative path to Data folder
  Result := 'Strings\' + Result;
end;

function TwbLocalizationHandler.GetLocalizationFileNameByElement(aElement: IwbElement): string;
begin
  Result := '';

  if not Assigned(aElement) then
    Exit;

  Result := GetLocalizationFileNameByType(aElement._File.FileName, LocalizedValueDecider(aElement));
end;

// create a new lstring from aValue for aElement
function TwbLocalizationHandler.AddValue(aValue: string; aElement: IwbElement): Cardinal;
var
  ls: TwbLStringType;
  FileName: string;
  wblf: array [TwbLStringType] of TwbLocalizationFile;
  idx: integer;
  data: TBytes;
  ID: Cardinal;
begin
  Result := 0;

  if not Assigned(aElement) then
    Exit;

  if aValue = '' then
    Exit;

  TMonitor.Enter(Self);
  // create localization files if absent
  try
    ID := 1;
    for ls := Low(TwbLStringType) to High(TwbLStringType) do begin
      FileName := GetLocalizationFileNameByType(aElement._File.FileName, ls);
      idx := lFiles.IndexOf(ExtractFileName(FileName));
      if idx < 0 then begin
        wblf[ls] := AddLocalization(lGameModeConfig.wbDataPath + FileName, data);
        wblf[ls].Modified := true;
      end else
        wblf[ls] := _Files[idx];

      if wblf[ls].NextID > ID then
        ID := wblf[ls].NextID;
    end;

    ls := LocalizedValueDecider(aElement);

    // detect a duplicate string
    if ReuseDup then begin
      idx := wblf[ls].fStrings.IndexOf(aValue);
      if idx >= 0 then
        ID := Cardinal(wblf[ls].fStrings.Objects[idx])
      else
        wblf[ls].AddString(ID, aValue);
    end else
      wblf[ls].AddString(ID, aValue);

    Result := ID;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TwbLocalizationHandler.SetValue(ID: Cardinal; aElement: IwbElement; aValue: string): Cardinal;
var
  idx: integer;
  FileName: string;
begin
  Result := ID;

  if not Assigned(aElement) then
    Exit;

  TMonitor.Enter(Self);
  try
    FileName := GetLocalizationFileNameByElement(aElement);
    idx := lFiles.IndexOf(ExtractFileName(FileName));

    if (idx < 0 ) or (ID = 0) then begin
      // new string
      Result := AddValue(aValue, aElement);
      Exit;
    end;

    if not _Files[idx].IDExists(ID) then
      // string doesn't exist, create new
      Result := AddValue(aValue, aElement)
    else
      // modify existing
      _Files[idx][ID] := aValue;
  finally
    TMonitor.Exit(Self);
  end;
end;


function TwbLocalizationHandler.GetValue(ID: Cardinal; aElement: IwbElement; out aValue: string): Boolean;
var
  lFileName: string;
  idx: integer;
begin
  aValue := '';

  if NoTranslate then begin
    aValue := IntToHex(ID, 8);
    Exit(True);
  end;

  if ID = 0 then
    Exit(True);

  lFileName := ExtractFileName(GetLocalizationFileNameByElement(aElement));

  if lFileName = '' then
    Exit(False);

  TMonitor.Enter(Self);
  try
    idx := lFiles.IndexOf(lFileName);

    // load strings files if absent
    if idx < 0 then begin
      LoadForFile(aElement._File.FileName);
      // get file again
      idx := lFiles.IndexOf(lFileName);
    end;

    if idx < 0 then begin
      aValue := '<Error: No strings file for lstring ID ' + IntToHex(ID, 8) + '>';
      Exit(False);
    end;

    Result := _Files[idx].Find(ID, aValue);
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TwbLocalizationHandler.GetStringsFromFile(aFileName: string; const aList: TStrings);
var
  i: integer;
begin
  if not Assigned(aList) then
    Exit;

  TMonitor.Enter(Self);
  try
    for i := 0 to Pred(lFiles.Count) do
      if SameText(lFiles[i], aFileName) then begin
        aList.Assign(_Files[i].fStrings);
        Break;
      end;
  finally
    TMonitor.Exit(Self);
  end;
end;


initialization
//  wbLocalizationHandler := TwbLocalizationHandler.Create;
finalization
//  FreeAndNil(wbLocalizationHandler);
end.
