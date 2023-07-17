uses GraphABC, Card, Menu, Game;

begin
  Window.Title := 'Дурак';
  SetWindowSize(900,650);
  Window.CenterOnScreen;
  SetConsoleIO;  /// Чтобы выводить отладочную информацию
  LockDrawing;  /// Чтобы не было мерцания
  var c: CardR;
  c.front := true;
  c.rank := 6;
  c.suit := Hearts;
  DrawCard(c);
  Redraw;
  DrawStartup;  /// Заставка
  var mode := 0;  /// 0 -> Меню, 1 -> Игра
  while true do   /// Пока не нажат выход
  begin
    var res := 0;   /// Игра может попросить включить меню или меню попросит включить игру
    if mode = 0 then begin   /// меню
      res := MainCycle;
      if res = -1 then break;   /// -1 -> нажат выход
      mode := 1;   /// Иначе нажата игра
    end
    else
    if mode = 1 then begin
      res := startGame;   /// нажат выход в меню
      mode := 0;
    end;
  end;
  halt;
end.