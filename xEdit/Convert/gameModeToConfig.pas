unit gameModeToConfig;

interface
uses
  SysUtils;

type
  TMyEnum = (meFirst, meSecond, meThird);

  TMyRecord = record
    Name: string;
    Value: Integer;
  end;

const
  enumToRec: array[TMyEnum] of TMyRecord = (
    (Name: 'First'; Value: 1),
    (Name: 'Second'; Value: 2),
    (Name: 'Third'; Value: 3)
  );

var
  rec: TMyRecord;
