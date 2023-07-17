unit Menu;

interface

uses GraphABC, Table, Utils;

const
 consoleX = 30;
 consoleY = 610;

var
  menuReg: integer;  // режим Меню
  exitMenu: integer;   // если не 0, то нужно завершить отрисовку меню и вернуться

procedure DrawStartup;
function MainCycle: integer;

implementation

uses Utils;

procedure DrawStartup;  // заставка
begin
  initBrush;
  ClearWindow;
  SetFontSize(50);
  SetFontColor(clPurple);
  DrawTextCentered(0, 0, 900, 600, 'Дурак');
  SetFontSize(20);
  SetFontColor(clBlack);
  TextOut(500, 350, 'Разработал:');
  TextOut(500, 390, 'студент группы ???');
  TextOut(500, 430, '????');
  
  DrawConsole('Заставка. Подождите');
  
  Redraw;
  Sleep(50);
end;

procedure DrawHelp; forward;
procedure RedrawAll; forward;

procedure OnKeyDownMenu(key: integer);  // обработка событий
begin
  if menuReg = 0 then begin  // меню с выбором
    if key = 49 then  // 1, игра
    begin
      exitMenu := 1;
    end;
 
    if key = 50 then begin  // 2, помощь
      menuReg := 1;
    end;
    
    if key = 51 then  // 3, выход
    begin
      exitMenu := -1;
    end;
    
    if key = 52 then // 4, таблица рекордов
    begin
      menuReg := 2;
    end;
  end
  else
  begin
    if (menuReg = 1) or (menuReg = 2) then begin  // Таблица рекордов и помощь
      menuReg := 0;
    end;
  end;
end;

procedure DrawMenu;  //  Вывод меню. Все понятно
begin
  var x1 := 300;
  var x2 := 600;
  var y1 := 50;
  var y2 := 150;
  SetFontColor(clBlack);
  
  SetBrushColor(clPink);
  RoundRect(x1, y1, x2, y2, 30, 30);
  SetFontSize(15);
  DrawTextCentered(x1, y1, x2, y2, 'Начать игру (1)');
  
  y1 += 125;
  y2 += 125;
  RoundRect(x1, y1, x2, y2, 30, 30);
  SetFontSize(15);
  DrawTextCentered(x1, y1, x2, y2, 'Помощь (2)');
  
  y1 += 125;
  y2 += 125;
  RoundRect(x1, y1, x2, y2, 30, 30);
  SetFontSize(15);
  DrawTextCentered(x1, y1, x2, y2, 'Выход (3)');
  
  y1 += 125;
  y2 += 125;
  RoundRect(x1, y1, x2, y2, 30, 30);
  SetFontSize(15);
  DrawTextCentered(x1, y1, x2, y2, 'Таблица рекордов (4)');
  
  DrawConsole('Нажмите на клавишу, указаную в скобках');
end;

procedure DrawHelp;  // Вывод экрана помощи
begin
  SetBrushColor(clPink);
  var x1 := 300;
  var x2 := 600;
  var y1 := 50;
  var y2 := 550;
  RoundRect(x1, y1, x2, y2, 30, 30);
  SetFontSize(15);
  DrawTextCentered(x1, y1, x2, y2, 'Это игра Что Где Когда. В файл db.txt содержатся все вопросы и ответы на игру. Игрок вращает барабан и открывает случайный вопрос, на который нужно дать ответ и ввести с клавиатуры. Если он правильный,то игрок получает очко, иначе - нет. Если стрелка попала на уже использованный вопрос, то берется следующий в обратном направлении от часовой стрелки.');
  DrawConsole('Нажмите на любую клавишу для выхода в главное меню');
end;

procedure DrawRecords();  // Вывод экрана рекордов
begin
  SetBrushColor(clPink);
  var x1 := 50;
  var x2 := 850;
  var y1 := 50;
  var y2 := 550;
  RoundRect(x1, y1, x2, y2, 30, 30);
  SetFontSize(40);
  SetFontColor(clBlack);
  DrawTextCentered(0, 0, 900, 200, 'Таблица рекордов');
  var data := loadRecords;  // загружаем рекорды
  x1 := 100;
  x2 := 730;
  y1 := 150;
  y2 := 150;
  
  SetFontSize(25);
  for var i := 0 to data.Length - 1 do begin // выводим рекорды
    TextOut(x1, y1, data[i].name);
    TextOut(x2, y2, data[i].points);
    y1 += 45;
    y2 += 45;
  end;
  
  DrawConsole('Нажмите любую клавишу для выхода');
end;

procedure RedrawAll;  // Выбор по режиму что рисовать
begin
  ClearWindow;
  if menuReg = 0 then
    drawMenu;
  if menuReg = 1 then
    drawHelp;
  if menuReg = 2 then
    drawRecords;
  Redraw;
end;

function MainCycle: integer;  // цикл с отрисовкой
begin
  exitMenu := 0;
  MenuReg := 0;
  OnKeyDown := OnKeyDownMenu;
  while exitMenu = 0 do begin // Если exitMenu не ноль,то событие начало игры или выход из приложения
    RedrawAll;
  end;
  Result := exitMenu;
end;

end.