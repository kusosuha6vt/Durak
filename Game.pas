unit Game;

interface

uses
  GraphABC, Card,
  Table, Utils;

const
  PHx1 = 10;
  PHx2 = 890;
  PHy = 430;
  CHy = 10;
  MCy1 = 200;
  MCy2 = 250;
  STx = 750;
  Sty = 200;
  CardMove = 50;
 
 
type
  PlayersT = (Computer, Player);

var
  gameReg: integer;  /// 0 -> ввод имени, 1 -> игра
  playerHand: array of CardR;
  computerHand: array of CardR;
  stock: array of CardR;
  bita: array of CardR;
  trump: suitT;
  name: string;  // имя игрока
  gameEnd: integer;  // если не ноль,нужно прекратить игру
  moves: integer;
  selectedCard: integer;
  midCards1: array of CardR;
  midCards2: array of CardR;
  curAttack: PlayersT;
  curMove: PlayersT;
  
  
function startGame: integer;  // начало игры

implementation

procedure AddBita(card: CardR);
begin
  card.sX := -CWIDTH;
  card.sY := MCy1;
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
  var d := 0;
  if v.Length > 1 then
    d := (x2 - CWidth - x1) div (v.Length - 1);
  d := Min(d, CWidth + 5);
  for var i := 0 to v.Length - 1 do
  begin
    v[i].sX := x1 + i * d;
    v[i].sY := y;
  end;
end;

procedure updateCards;
begin
  // sort playerHand
  Sort(playerHand, cardLess);
  Sort(computerHand, cardLess);
  
  setCoords(playerHand, PHx1, PHx2, PHy);
  setCoords(computerHand, PHx1, PHx2, CHy);
  setCoords(midCards1, PHx1, PHx2, MCy1);
  setCoords(midCards2, PHx1, PHx2, MCy2);
end;

procedure initVars;  // инициализация всех переменных в 0
begin
  bita := new CardR[0];
  midCards1 := new CardR[0];
  midCards2 := new CardR[0];
  gameReg := 0;
  OnKeyDown := emptyKeyDown;
  OnKeyPress := emptyKeyPress;
  Randomize;
//  curAttack := PlayersT(Random(2));
  curAttack := Computer;
  curMove := curAttack;
  name := '';
  gameEnd := 0;
  selectedCard := -1;
  moves := 0;
  stock := new CardR[36];
  for var i := 0 to 35 do begin
    stock[i].x := 450;
    stock[i].y := -200;
    stock[i].sX := STx;
    stock[i].sY := STy;
    stock[i].front := false;
    stock[i].rank := (i div 4) + 6;
    stock[i].suit := SuitT(i mod 4);
  end;
  Randomize;
  Shuffle(stock);
  playerHand := new CardR[6];
  computerHand := new CardR[6];
  for var i := 0 to 5 do begin
    playerHand[i] := stock[i * 2];
    playerHand[i].front := true;
    computerHand[i] := stock[i * 2 + 1];
  end;
  stock := stock.Slice(12, 1);
  trump := stock[0].suit;
  updateCards;
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
  if (key = VK_ESCAPE) then
  begin
    if selectedCard <> -1 then begin
      if (selectedCard >= 0) and (selectedCard < playerHand.Length) then
      begin
        playerHand[selectedCard].sY := PHy;
      end;
      selectedCard := -1;
    end else
      gameEnd := 1;
  end;
  ComputerAttackPlayerMove(key);
  PlayerAttackPlayerMove(key);
  
  // unselect card
  if (selectedCard >= 0) and (selectedCard < playerHand.Length) then
  begin
    playerHand[selectedCard].sY := PHy;
  end;
  if key = VK_LEFT then
  begin
    selectedCard := Max(selectedCard, 0);
    selectedCard := Max(0, selectedCard - 1);
  end;
  if key = VK_RIGHT then
  begin
    selectedCard := Min(playerHand.Length - 1, selectedCard + 1);
  end;
  // select again
  if (selectedCard >= 0) and (selectedCard < playerHand.Length) then
  begin
    playerHand[selectedCard].sY := PHy - 30;
  end;
end;

procedure startCardDistribution;
begin
  gameReg := 1;
  OnKeyPress := emptyKeyPress;
  OnKeyDown := gameKeyDown;
end;

procedure DrawConsoleReg;
begin
  if gameReg = 0 then
  begin
    DrawConsole('Введите имя и нажмите Enter: ' + name);
  end;
  if gameReg = 1 then
  begin
    DrawConsole('Управление: L,R,U стрелки, Enter,Esc. Move: ' + curMove.ToString + ' attack: ' + curAttack.ToString);
  end;
  if gameReg > 1 then
  begin
    DrawConsole(' move: ' + curMove.ToString + ' attack: ' + curAttack.ToString);
  end;
end;

procedure drawGame;   /// Рисует фрейм игры
begin
  for var i := 0 to playerHand.Length - 1 do
  begin
    DrawCard(playerHand[i]);
  end;
  for var i := 0 to computerHand.Length - 1 do
  begin
    DrawCard(computerHand[i]);
  end;
  for var i := 0 to stock.Length - 1 do
  begin
    DrawCard(stock[i]);
  end;
  for var i := 0 to midCards1.Length - 1 do
  begin
    DrawCard(midCards1[i]);
  end;
  for var i := 0 to midCards2.Length - 1 do
  begin
    DrawCard(midCards2[i]);
  end;
  for var i := 0 to bita.Length - 1 do
  begin
    DrawCard(bita[i]);
  end;
  DrawConsoleReg;
end;

procedure animCard(var card: CardR);
begin
  var (dx, dy) := (card.sX - card.x, card.sY - card.y);
  dx := Min(Abs(dx), CardMove) * Sign(dx);
  dy := Min(Abs(dy), CardMove) * Sign(dy);
  card.x += dx;
  card.y += dy;
end;

procedure animCards;
begin
  for var i := 0 to playerHand.Length - 1 do
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
  var j := 0;
  var i := 0;
  while i < v1.Length do
  begin
    if (j < v2.Length) and (v2[j] = v1[i]) then
    begin
      swap(v1[i], v1[v1.High]);
      SetLength(v1, v1.Length - 1);
      j += 1;
      i -= 1;
    end;
    i += 1;
  end;
end;

procedure AllToBita;
begin
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

function canPodkid(card: cardR): boolean;
begin
  var res := (midCards1.Length + midCards2.Length = 0);
  for var i := 0 to midcards1.Length - 1 do
  begin
    if midCards1[i].Rank = card.rank then
      res := true;
  end;
  for var i := 0 to midCards2.Length - 1 do
  begin
    if midCards2[i].Rank = card.rank then
      res := true;
  end;
  Result := res;
end;

procedure PlayerAttackPlayerMove(key: integer);
begin
  // Нажат Enter
  // Все делается по нажатиям
  // TODO нажатия
  // Либо UP, Либо Enter. Либо подкидывание, либо первый ход.
  if (curAttack <> Player) or (curMove <> Player) then
    exit;
  if key = VK_ENTER then
  begin
    if midCards1.Length = 0 then
      exit;
    if midCards1.Length = midCards2.Length then
    begin
      allToBita;
      curAttack := Computer;
      curMove := Computer;
      FillHand;
      exit;
    end;
    curMove := Computer;
  end
  else if key = VK_UP then
  begin
    if (selectedCard < 0) or (selectedCard >= playerHand.Length) or (not canPodkid(playerHand[selectedCard])) or (midCards1.Length - midCards2.Length = computerHand.Length) then
      exit;
    Add(midCards1, playerHand[selectedCard]);
    remove(playerHand, selectedCard);
    updateCards;
  end;
end;

procedure PlayerAttackComputerMove;
begin
  var b := midCards2.Length;
  // Нужно отбиться от Карт игрока
  SetLength(midCards2, midCards1.Length);
  for var i := b to midcards1.High do
    midCards2[i].front := false;  // false значит, что карта еще не определена
  var can := true;
  for var i := b to midCards1.High do
  begin
    var j := -1;
    for var k := b to midCards1.High do
    begin
      if (not midCards2[k].front) and ((j = -1) or ((j <> -1) and cardBetter(midCards1[k], midCards1[j], trump))) then
        j := k;
    end;
    // find least good card
    var f := -1;
    for var k := 0 to computerHand.High do
    begin
      if (not computerHand[k].front) and cardCanBeat(midCards1[j], computerHand[k], trump) and ((f = -1) or ((f <> -1) and cardBetter(computerHand[f], computerHand[k], trump))) then
        f := k;
    end;
    if f = -1 then begin
      can := false;
      break;
    end;
    computerHand[f].front := true;
    midCards2[j] := computerHand[f];
  end;
  
  // Нужно либо все взять, либо передать ход игроку для подкидывания.
  if (not can) then
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
      computerHand[k] := midCards1[i];
      computerHand[k].front := false;
      k += 1;
    end;
    for var i := 0 to b - 1 do
    begin
      computerHand[k] := midCards2[i];
      computerHand[k].front := false;
      k += 1;
    end;
    SetLength(midCards1, 0);
    SetLength(midCards2, 0);
    updateCards;
    curAttack := Player;
    curMove := Player;
    FillHand;
  end else
  begin
    // Можем отбиться, ход игрока
    // Удаляем computerHand
    var i := 0;
    while i < computerHand.Length - 1 do
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
    curMove := Player;
  end;
end;

procedure FillHand;
begin
  var i := stock.High;
  while (i >= 0) and (playerHand.Length < 6) do
  begin
    SetLength(playerHand, playerHand.Length + 1);
    playerHand[playerHand.High] := stock[i];
    playerHand[playerHand.High].front := true;
    i -= 1;
  end;
  while (i >= 0) and (computerHand.Length < 6) do
  begin
    SetLength(computerHand, computerHand.Length + 1);
    computerHand[computerHand.High] := stock[i];
    computerHand[computerHand.High].front := false;
    i -= 1;
  end;
  if i < stock.High then
  begin
    SetLength(stock, i + 1);
    updateCards;
  end;
end;

procedure ComputerAttackPlayerMove(key: integer);
begin
  // Стрелка вверх - ответить
  // Enter - кончить ход (либо бита, либо я все беру)
  // - Проверить, что можно текущей картой ответить
  if (curAttack <> Computer) or (curMove <> Player) then
    exit;
  if key = VK_UP then
  begin
    if (0 > selectedCard) or (selectedCard >= playerHand.Length) or (midCards1.Length <= midCards2.Length) then
      exit;
    if cardCanBeat(midCards1[midCards2.Length], playerHand[selectedCard], trump) then
    begin
      Add(midCards2, playerHand[selectedCard]);
      remove(playerHand, selectedCard);
      updateCards;
    end;
  end else if key = VK_ENTER then
  begin
    if midCards1.Length = midCards2.Length then
    begin
      allToBita;
      curMove := Computer;
      curAttack := Player;
      FillHand;
      exit;
    end;
    // Взять
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
    curAttack := Computer;
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
        if midCards2.Length - midCards1.Length = playerHand.Length then
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
  var f := 0;
  while gameEnd = 0 do  // пока не нажмем esc
  begin
    f += 1;
    if f mod 100 = 1 then
    begin
    end;
    initBrush;
    ClearWindow;  // отрисовываем игру, меняем анимацию при необходимости
    drawGame;
    Redraw;
    animCards;
    if (curAttack = Computer) and (curMove = Computer) then
      ComputerAttackComputerMove
    else
      if (curAttack = Player) and (curMove = Computer) then
        PlayerAttackComputerMove;
  end;
  Result := gameEnd;  // возвращаем причину завершения (тут возможно вернуть только 1, но вдруг нужно будет добавить другую причину)
end;

end.