unit Game;

interface

uses
  GraphABC, Card,
  Table, Utils;

const
  PHx1 = 10;  // координаты, куда будут ставиться карты
  PHx2 = 890;
  PHy = 430;
  CHy = 10;
  MCy1 = 200;
  MCy2 = 250;
  STx = 750;
  Sty = 200;
  CardMove = 50;  // ограничение на скорость анимации
 
 
type
  PlayersT = (Computer, Player);  // игроки

var
  gameReg: integer;  // 0 -> ввод имени, 1 -> игра
  playerHand: array of CardR;  // все карты игрока
  computerHand: array of CardR;  // все карты компьютера
  stock: array of CardR;   // все карты из колоды
  bita: array of CardR;  // бита
  trump: suitT;  // козырь
  name: string;  // имя игрока
  gameEnd: integer;  // если не ноль,нужно прекратить игру
  moves: integer;  // количество ходов 
  selectedCard: integer;  // выбранная карта в руке
  midCards1: array of CardR;  // первый ряд карт (атака)
  midCards2: array of CardR;  // второй ряд (для отбивания карт атаки)
  curAttack: PlayersT;  // Кто сейчас атакует (оставшийся игрок отбивается)
  curMove: PlayersT;  // текущий ход чей
  
  
function startGame: integer;  // начало игры

implementation

procedure AddBita(card: CardR);  // добавить карту в биту
begin
  card.sX := -CWIDTH;
  card.sY := MCy1;  // бита за пределами поля
  Add(bita, card);
end;

procedure emptyKeyPress(ch: char);  // Пустой обработчик, чтобы пользователь что-то не нажал случайно
begin
end;

procedure emptyKeyDown(key: integer);  // Пустой обработчик, чтобы пользователь что-то не нажал случайно
begin
end;

procedure FillHand; forward;

procedure setCoords(var v: array of CardR; x1, x2, y: integer);
begin
  // вспомогательная функция для распределения карт между x1, y1
  var d := 0;
  if v.Length > 1 then  // иначе деление на ноль
    d := (x2 - CWidth - x1) div (v.Length - 1);  // промежутков: v.Length - 1
  d := Min(d, CWidth + 5);
  for var i := 0 to v.Length - 1 do
  begin
    v[i].sX := x1 + i * d;  // устанавливаем координаты
    v[i].sY := y;
  end;
end;

procedure updateCards;
begin
  // сортируем колоды  для удобства
  Sort(playerHand, cardLess);
  Sort(computerHand, cardLess);
  
  setCoords(playerHand, PHx1, PHx2, PHy);  // устанавливаем координаты
  setCoords(computerHand, PHx1, PHx2, CHy);
  setCoords(midCards1, PHx1, PHx2, MCy1);
  setCoords(midCards2, PHx1, PHx2, MCy2);
end;

procedure initVars;  // инициализация всех переменных в 0
begin
  bita := new CardR[0];
  midCards1 := new CardR[0];
  midCards2 := new CardR[0];
  gameReg := 0;  // режим 0 - ввод имени
  OnKeyDown := emptyKeyDown;
  OnKeyPress := emptyKeyPress;
  Randomize;
  curAttack := PlayersT(Random(2));  // случайный игрок ходит
  curMove := curAttack;
  name := '';
  gameEnd := 0;
  selectedCard := -1;  // -1 значит,что карта не выбрана
  moves := 0;
  stock := new CardR[36];
  for var i := 0 to 35 do begin
    stock[i].x := 450;
    stock[i].y := -200;  // изначально карты вверху экрана
    stock[i].sX := STx;
    stock[i].sY := STy;
    stock[i].front := false;
    stock[i].rank := (i div 4) + 6;  // ранк
    stock[i].suit := SuitT(i mod 4);  // масть
  end;
  Randomize;
  Shuffle(stock);  // Мешаем карты
  playerHand := new CardR[6];  // устанавливаем по 6 карт
  computerHand := new CardR[6];
  for var i := 0 to 5 do begin
    playerHand[i] := stock[i * 2];
    playerHand[i].front := true;
    computerHand[i] := stock[i * 2 + 1];
  end;
  stock := stock.Slice(12, 1);  // Первые 12 - в руках у игроков
  trump := stock[0].suit;
  updateCards;  // обновляем координаты карт
  stock[0].front := true;
  stock[0].sY -= 50;
end;

procedure startCardDistribution; forward;

procedure enterNameKeyDown(key: integer);
begin
  if key = VK_Enter then  // При Enter меняем режим
    startCardDistribution;
  if (key = VK_Back) and (name.Length > 0) then // При baсkspace удалем последний символ
  begin
    name := name[:^1];
  end;
end;

procedure enterNameKeyPress(ch: char);
begin
  if (name.Length <= 15) and (ch.IsLetter or (ch = ' ')) then  // Ввод имени
    name := name + ch;  
end;

procedure startEnterName;  // Начало ввода имени
begin
  gameReg := 0;
  OnKeyDown := enterNameKeyDown;
  OnKeyPress := enterNameKeyPress;
end;

procedure ComputerAttackPlayerMove(key: integer); forward;
procedure PlayerAttackPlayerMove(key: integer); forward;

procedure gameKeyDown(key: integer);
begin
  if (key = VK_ESCAPE) then  // Esc
  begin
    if selectedCard <> -1 then begin  // карта выбрана
      if (selectedCard >= 0) and (selectedCard < playerHand.Length) then
      begin
        playerHand[selectedCard].sY := PHy;  // Делаем ее обычной
      end;
      selectedCard := -1;  // -1
    end else begin
      gameEnd := 1;  // выходим в меню
      exit;
    end;
  end;
  ComputerAttackPlayerMove(key);  // Ход игрока слушает события
  PlayerAttackPlayerMove(key);
  
  // unselect card
  if (selectedCard >= 0) and (selectedCard < playerHand.Length) then
  begin
    playerHand[selectedCard].sY := PHy;
  end;
  if key = VK_LEFT then
  begin  // Либо сдвигаем влево ,либо выделяем 0
    selectedCard := Max(selectedCard, 0);
    selectedCard := Max(0, selectedCard - 1);
  end;
  if key = VK_RIGHT then
  begin  // Сдвигаем вправо
    selectedCard := Min(playerHand.Length - 1, selectedCard + 1);
  end;
  // select again
  if (selectedCard >= 0) and (selectedCard < playerHand.Length) then
  begin // выделяем результат
    playerHand[selectedCard].sY := PHy - 30;
  end;
end;

procedure AllKeyDown(key: integer);
begin  // Все обработчики
  if gameReg = 2 then
    gameEnd := 1
  else
    gameKeyDown(key);
end;

procedure startCardDistribution;
begin
  gameReg := 1;  // раздача карт
  OnKeyPress := emptyKeyPress;
  OnKeyDown := AllKeyDown;
end;

procedure DrawWin;
begin  // экран завершения игры
  SetBrushColor(clSeaShell);
  var x1 := 100;
  var x2 := 800;
  var y1 := 50;
  var y2 := 550;
  RoundRect(x1, y1, x2, y2, 30, 30);
  SetFontSize(40);
  DrawTextCentered(x1, y1, x2, y2, if playerHand.Length = 0 then 'Вы выиграли за ' + moves + ' ходов' else 'Вы проиграли за ' + moves + ' ходов');
  DrawConsole('Нажмите на любую клавишу для выхода в главное меню');
end;

procedure DrawConsoleReg;  // Вывод консоли
begin
  if gameReg = 0 then
  begin
    DrawConsole('Введите имя и нажмите Enter: ' + name);
  end;
  if gameReg = 1 then
  begin
    DrawConsole('L, R, U стрелки: выбор карты; Esc: отменить/выйти; Enter: конец хода');
  end;
  if gameReg = 2 then
  begin
    DrawConsole('Игра завершена!');
  end;
end;

// Вспомогательный массив
var tmp := new CardR[100];

// Копируем массив в tmp
function copyTmp(const v: array of CardR): integer;
begin
  var k := v.Length;
  for var i := 0 to k - 1 do
  begin
    tmp[i] := v[i];
  end;
  Result := k;
end;

procedure drawGame;   // Рисует фрейм игры
begin
  // Может показаться глупо копировать массив и выводить, но это нужно
  // Т.к события и главный цикл находятся в разных потоках,то происходит datarace
  // И довольно часто возникает ситуация, что во время цикла с отрисовкой длина массива уменьшается
  // Но цикл идет до большего значения - происходит index out of range error.
  // Это костыль, который делает эту ошибку сильно менее вероятной, но до конца не избавляется от нее
  var k := copyTmp(playerHand);  // Вывод руки игрока
  for var i := 0 to k - 1 do
  begin
    DrawCard(tmp[i]);
  end;
  k := copyTmp(computerHand);  // вывод руки компьютера
  for var i := 0 to k - 1 do
  begin
    DrawCard(tmp[i]);
  end;
  k := copyTmp(stock);
  for var i := 0 to Min(k - 1, 1) do  // Вывод колоды. Нет смысла рисовать больше 2 карт
  begin
    DrawCard(tmp[i]);
  end;
  k := copyTmp(midCards1);
  if (k = 0) and (curMove = Player) and (curAttack = Player) and (gameReg = 1) then  // Надпись
  begin
    initBrush;
    SetFontSize(20);
    SetFontColor(clGreen);
    DrawTextCentered(0, 0, 900, 600, 'Ваш ход');
  end;
  initBrush;
  SetFontSize(15);
  SetFontColor(clGreen);
  if (gameReg=1) then
  TextOut(StX, StY + CHEIGHT, 'Ходов: ' + moves.ToString);  // вывод кол-ва ходов
  for var i := 0 to k - 1 do
  begin
    DrawCard(tmp[i]);  // вывод атакующих карт
  end;
  k := copyTmp(midCards2);
  for var i := 0 to k - 1 do
  begin
    DrawCard(tmp[i]);  // вывод отбивающих карт
  end;
  k := copyTmp(bita);  // бита
  for var i := 0 to k - 1 do
  begin
    if (tmp[i].x > -CWIDTH) or (tmp[i].y > -CHEIGHT) then
      DrawCard(tmp[i]);  // оптимизация. Если карта за экраном, то не рисуем ее
  end;
  DrawConsoleReg;
end;

procedure drawScreen;  // вывод экрана
begin
  if gameReg = 2 then
    DrawWin
  else
    DrawGame;
end;

procedure animCard(var card: CardR);
begin
  // Продвигаем карту ближе к месту назначения
  var (dx, dy) := (card.sX - card.x, card.sY - card.y);
  dx := Min(Abs(dx), CardMove) * Sign(dx);
  dy := Min(Abs(dy), CardMove) * Sign(dy);
  card.x += dx;
  card.y += dy;
end;

procedure animCards;
begin
  for var i := 0 to playerHand.Length - 1 do  // анимация всех карт
    animCard(playerHand[i]);
  for var i := 0 to computerHand.Length - 1 do
    animCard(computerHand[i]);
  for var i := 0 to stock.Length - 1 do
    animCard(stock[i]);
  for var i := 0 to midCards1.Length - 1 do
    animCard(midCards1[i]);
  for var i := 0 to midCards2.Length - 1 do
    animCard(midCards2[i]);
  for var i := 0 to bita.Length - 1 do
    animCard(bita[i]);
end;

procedure removeAll(var v1: array of CardR; const v2: array of CardR);
begin
  var i := 0;  // указатель в v2
  var j := 0;  // указатель в v1
  while i < v1.Length do
  begin
    if (j < v2.Length) and (v1[i] = v2[j]) then  // удалить
    begin
      remove(v1, i);  // удалем i
      j += 1;
      i -= 1;
    end;
    i += 1;
  end;
end;

procedure AllToBita;
begin // скинуть все карты из центра в биту
  for var i := 0 to midCards1.Length - 1 do
  begin
    AddBita(midCards1[i]);
  end;
  for var i := 0 to midCards2.Length - 1 do
  begin
    if midCards2[i].front then
      AddBita(midCards2[i]);
  end;
  SetLength(midCards1, 0);
  SetLength(midCards2, 0);
end;

function canPodkid(card: cardR): boolean;  // можно ли подкинуть
begin
  var res := (midCards1.Length + midCards2.Length = 0);  // если ы центре пусто, то да
  for var i := 0 to midcards1.Length - 1 do
  begin
    if midCards1[i].Rank = card.rank then  // если встретили ранк,то тоже да
      res := true;
  end;
  for var i := 0 to midCards2.Length - 1 do
  begin
    if midCards2[i].Rank = card.rank then
      res := true;
  end;
  Result := res;
end;

procedure PlayerAttackPlayerMove(key: integer);  // Атака игрока,ход игрока
begin
  // Все делается по нажатиям
  // Либо UP, Либо Enter. Либо подкидывание, либо первый ход.
  if (curAttack <> Player) or (curMove <> Player) then
    exit;
  if key = VK_ENTER then
  begin
    if midCards1.Length = 0 then  // Нельзя
      exit;
    if midCards1.Length = midCards2.Length then  // Передача хода
    begin
      allToBita;  // бита
      curAttack := Computer;
      curMove := Computer;
      FillHand;  // дополняем до 6
      exit;
    end;
    curMove := Computer;  // что-то подкинули, передаем ход
  end
  else if key = VK_UP then  // карту подбрасываем
  begin
    if (selectedCard < 0) or (selectedCard >= playerHand.Length) or (not canPodkid(playerHand[selectedCard])) or (midCards1.Length - midCards2.Length = computerHand.Length) then
      exit;
    Add(midCards1, playerHand[selectedCard]);
    remove(playerHand, selectedCard);
    updateCards;
  end;
end;

procedure PlayerAttackComputerMove;  // атака игрока, компьютер отбивается
begin
  var b := midCards2.Length;
  // Нужно отбиться от Карт игрока
  
  // алгоритм: выбираем самую слабую не отбитую карту, самую слабую карту,которая может это отбить
  SetLength(midCards2, midCards1.Length);
  for var i := b to midcards1.High do
    midCards2[i].front := false;  // false значит, что карта еще не определена
  var can := true;
  for var i := b to midCards1.High do
  begin
    var j := -1;  // j - позиция самой слабой карты в атаке (еще не отбитой)
    for var k := b to midCards1.High do
    begin
      if (not midCards2[k].front) and ((j = -1) or ((j <> -1) and cardBetter(midCards1[k], midCards1[j], trump))) then
        j := k;
    end;
    
    var f := -1;  // f - позиция самой слабой карты,которая отобьет j
    for var k := 0 to computerHand.High do
    begin
      if (not computerHand[k].front) and cardCanBeat(midCards1[j], computerHand[k], trump) and ((f = -1) or ((f <> -1) and cardBetter(computerHand[f], computerHand[k], trump))) then
        f := k;
    end;
    if f = -1 then begin  // не смогли найти, значит все забираем в руку
      can := false;
      break;
    end;
    computerHand[f].front := true;
    midCards2[j] := computerHand[f];
  end;
  
  
  if (not can) then  // не смогли отбиться
  begin
    // Все взять в computerHand;
    // все из midCards
    // первую часть из midCards2;
    var k := computerHand.Length;
    SetLength(computerHand, k + midCards1.Length + b);
    for var i := 0 to k - 1 do
      computerHand[i].front := false;
    for var i := 0 to midCards1.High do
    begin
      computerHand[k] := midCards1[i];  // копируем
      computerHand[k].front := false;
      k += 1;
    end;
    for var i := 0 to b - 1 do
    begin
      computerHand[k] := midCards2[i];  // копируем
      computerHand[k].front := false;
      k += 1;
    end;
    SetLength(midCards1, 0);
    SetLength(midCards2, 0);
    updateCards;
    curAttack := Player;  // передача хода
    curMove := Player;
    FillHand;
  end else
  begin
    // Можем отбиться, ход игрока
    // Удаляем мусор из computerHand
    var i := 0;
    while i < computerHand.Length do
    begin
      if computerHand[i].front then
      begin
        remove(computerHand, i);
        i -= 1;
      end;
      i += 1;
    end;
    updateCards;
    curAttack := Player;
    curMove := Player;  // передача хода
  end;
end;

procedure FillHand;
begin
  // дополним руки игроков до 6
  if (stock.Length = 0) and ((playerHand.Length = 0) or (computerHand.Length = 0)) then
  begin
    gameReg := 2;  //  конец игры
    if (playerHand.Length = 0) then
      addRecord(name, moves);
    exit;
  end;
  moves += 1;
  var i := stock.High;  // Будем брать с конца
  while (i >= 0) and (playerHand.Length < 6) do
  begin
    SetLength(playerHand, playerHand.Length + 1);
    playerHand[playerHand.High] := stock[i];
    playerHand[playerHand.High].front := true;
    i -= 1;  // копируем 
  end;
  while (i >= 0) and (computerHand.Length < 6) do
  begin
    SetLength(computerHand, computerHand.Length + 1);
    computerHand[computerHand.High] := stock[i];
    computerHand[computerHand.High].front := false;
    i -= 1;  // копируем
  end;
  if i < stock.High then
  begin
    SetLength(stock, i + 1);   //  обновление координат
    updateCards;
  end;
end;

procedure ComputerAttackPlayerMove(key: integer);  // комп. атакует, игрок ходит
begin
  if (curAttack <> Computer) or (curMove <> Player) then
    exit;
  if key = VK_UP then  // подкидывание
  begin
    // нельзя подбрасывать,если карт у противника не хватает
    if (0 > selectedCard) or (selectedCard >= playerHand.Length) or (midCards1.Length <= midCards2.Length) then
      exit;
    if cardCanBeat(midCards1[midCards2.Length], playerHand[selectedCard], trump) then
    begin
      Add(midCards2, playerHand[selectedCard]);  // подкидываем
      remove(playerHand, selectedCard);
      updateCards;
    end;
  end else if key = VK_ENTER then  // передача хода
  begin
    if midCards1.Length = midCards2.Length then  // ничего не добавилось,значит бита
    begin
      allToBita;
      curMove := Computer;
      curAttack := Player;
      FillHand;
      exit;
    end;
    // Взять в руку
    var j := playerHand.Length;
    SetLength(playerHand, j + midCards1.Length + midCards2.Length);
    for var i := 0 to midCards1.High do
    begin
      playerHand[j] := midCards1[i];
      j += 1;
    end;
    for var i := 0 to midCards2.High do
    begin
      playerHand[j] := midCards2[i];
      j += 1;
    end;
    SetLength(midCards1, 0);
    SetLength(midCards2, 0);
    curAttack := Computer;  // ходит опять комп.
    curMove := Computer;
    FillHand;
    updateCards;
  end;
end;

procedure ComputerAttackComputerMove;
begin
  // Компьютер должен или начать атаку, либо подкинуть
  if midCards1.Length = 0 then
  begin
    // Move weakest card
    SetLength(midCards1, 1);
    SetLength(midCards2, 0);
    midCards1[0] := computerHand[0];
    for var i := 1 to computerHand.Length - 1 do
    begin
      if cardBetter(computerHand[i], midCards1[0], trump) then
      begin
        SetLength(midCards1, 1);
        midCards1[0] := computerHand[i];
      end else if (midCards1[0].rank = computerHand[i].rank) and (not cardBetter(computerHand[i], midCards1[0], trump)) and not (not cardBetter(midCards1[0], computerHand[i], trump)) then
      begin
        SetLength(midCards1, midCards1.Length + 1);
        midCards1[midCards1.Length - 1] := computerHand[i];
      end;
    end;
    removeAll(computerHand, midCards1);
    for var i := 0 to midCards1.Length - 1 do begin
      midCards1[i].front := true;
    end;
    updateCards;
  end else
  begin  // Компьютер подкидывает
    var i := 0;
    while i <= computerHand.Length - 1 do
    begin
      if canPodkid(computerHand[i]) then
      begin
        computerHand[i].front := true;
        Add(midCards1, computerHand[i]);
        remove(computerHand, i);
        i -= 1;
        if midCards1.Length - midCards2.Length = playerHand.Length then
          break;
      end;
      i += 1;
    end;
    updateCards;
  end;
  if midCards1.Length = midCards2.Length then
  begin
    // Ничего не подкинули, значит бита, ход игрока
    allToBita;
    curMove := Player;
    curAttack := Player;
    FillHand;
  end else
  begin
    // Игрок должен ответить
    curMove := Player;
  end;
end;

function startGame: integer;  // Начало игры 
begin
  initVars;  // инициализируем переменные
  startEnterName;  // Режим - ввод имени
  while gameEnd = 0 do  // пока не нажмем esc
  begin
    initBrush;
    ClearWindow;  // отрисовываем игру, меняем анимацию при необходимости
    drawScreen;
    Redraw;
    if gameReg = 1 then
    begin
      animCards;  // анимация карт
      if (curAttack = Computer) and (curMove = Computer) then  // выбираем ход
        ComputerAttackComputerMove
      else
        if (curAttack = Player) and (curMove = Computer) then
          PlayerAttackComputerMove;
    end;
  end;
  Result := gameEnd;  // возвращаем причину завершения (тут возможно вернуть только 1, но вдруг нужно будет добавить другую причину)
end;

end.