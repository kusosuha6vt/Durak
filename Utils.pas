unit Utils;

interface

uses GraphABC;
procedure initBrush;
procedure DrawConsole(msg: String);

const
 consoleX = 30;  // координаты консоли в нижней части
 consoleY = 610;

implementation

procedure initBrush;
begin
  SetPenColor(clBlack);
  SetPenWidth(1);
  SetPenStyle(psSolid);
  SetFontColor(clBlack);
  SetFontSize(10);
  SetBrushStyle(bsSolid);
  SetBrushColor(clWhite);
end;

procedure DrawConsole(msg: string);  // печать строки в нижней части экрана
begin
  initBrush;
  SetFontSize(15);
  SetFontColor(clBlack);
  SetBrushColor(clWhite);
  Line(0, 600, 900, 600);
  TextOut(consoleX, consoleY, msg);
end;

end.