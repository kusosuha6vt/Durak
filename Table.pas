﻿unit Table;

interface

type recordR = record
  name: string;
  moves: integer;
end;

const filename = 'table.txt';

function loadRecords: array of recordR;
procedure addRecord(name: string; moves: integer);

implementation

function compareKey(x: recordR): integer;
begin
  Result := x.moves;  // сортируем по убыванию очков
end;

function loadRecords: array of recordR;
begin
  var lines := ReadAllLines(filename);  // читаем все строки
  /// Если последняя линяя - перенос строки,то игнорируем
  if (lines.length > 0) and (lines[lines.length - 1] = '') then begin
    lines := lines[:^1];
  end;
  var data: array of RecordR;
  SetLength(data, lines.Length);
  var i := 0;
  while i < lines.Length do begin  // Копируем всю информацию
    data[i].name := lines[i].Split(';')[0];
    lines[i].Split(';')[1].TryToInteger(data[i].moves);
    i += 1;
  end;
  Sort(data, compareKey);  //  Сортируем результаты
  if data.Length > 10 then  // Если очень много рекордов, то берем лучшие 10
  begin
    SetLength(data, 10);
  end;
  Result := data;
end;

procedure addRecord(name: string; moves: integer);
begin
  var f := OpenAppend(filename);
  // char 10 - перенос строки
  f.Write('' + char(10) + name + ';' + moves);
  CloseFile(f);
end;

end.