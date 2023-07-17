unit Card;

interface

uses GraphABC, Utils;

type
  RankT = 6..14;
  SuitT = (Hearts, Spades, Diamonds, Clubs);
  CardR = record
    x: integer;
    y: integer;
    sX: integer;
    sY: integer;
    rank: RankT;
    suit: SuitT;
    front: boolean;
  end;


const
  CWidth = 100;
  CHeight = 155;
  Rounding = 10;
  FontSize = 15;
  
var
  NoColor: Color = ARGB(0, 0, 0, 0);
  TriangleDown := new Point[3];
  TriangleUp := new Point[3];
  Point3 := new Point[3];
  Point4 := new Point[4];

procedure DrawCard(const card: CardR);

function cardLess(const card1: CardR; const card2: CardR): boolean;

function cardBetter(const card1: CardR; const card2: CardR; trunc: SuitT): boolean;

function cardCanBeat(const card1: CardR; const card2: CardR; trunc: SuitT): boolean;

procedure remove(var v: array of cardR; index: integer); forward;
procedure Add(var v: array of CardR; card: CardR); forward;

implementation

procedure remove(var v: array of cardR; index: integer);
begin
  swap(v[index], v[v.Length - 1]);
  SetLength(v, v.Length - 1);
end;

procedure Add(var v: array of CardR; card: CardR);
begin
  SetLength(v, v.Length + 1);
  v[v.High] := card;
end;

function cardLess(const card1: CardR; const card2: CardR): boolean;
begin
  if card1.suit <> card2.suit then
    Result := (card1.suit < card2.suit)
  else 
    Result := (card1.rank < card2.rank);
end;

function cardBetter(const card1: CardR; const card2: CardR; trunc: SuitT): boolean;
begin
  if (card1.suit = trunc) <> (card2.suit = trunc) then
    Result := (card2.suit = trunc)
  else
    Result := (card1.rank < card2.rank);
end;

function cardCanBeat(const card1: CardR; const card2: CardR; trunc: suitT): boolean;
begin
  if (card1.suit = trunc) <> (card2.suit = trunc) then
    Result := (card2.suit = trunc)
  else
    Result := ((card2.suit = card1.suit) and (card1.rank < card2.rank));
end;

procedure DrawCardBack(const card: CardR);
begin
  var (x2, y2) := (card.x + CWidth, card.y + CHeight);
  SetHatchBrushBackgroundColor(clGhostWhite);
  SetBrushStyle(bsHatch);
  SetBrushHatch(bhForwardDiagonal);
  SetBrushColor(clGreen);
  FillRoundRect(card.x, card.y, x2, y2, Rounding, Rounding);
  SetBrushColor(clGreen);
  SetBrushHatch(bhBackwardDiagonal);
  SetHatchBrushBackgroundColor(NoColor);
  RoundRect(card.x, card.y, x2, y2, Rounding, Rounding);
end;

procedure DrawSuiteSmall(suit: SuitT; x, y: integer);
begin
  case suit of
    Hearts: begin
      FillCircle(x - 5, y - 5, 5);
      FillCircle(x + 5, y - 5, 5);
      Point3[0].X := x - 10;
      Point3[0].Y := y - 4;
      Point3[1].X := x + 10;
      Point3[1].Y := y - 4;
      Point3[2].X := x;
      Point3[2].Y := y + 9;
      FillPolygon(Point3);
    end;
    Spades: begin
      FillCircle(x - 5, y + 2, 5);
      FillCircle(x + 5, y + 2, 5);
      Point3[0].X := x - 10;
      Point3[0].Y := y + 1;
      Point3[1].X := x + 10;
      Point3[1].Y := y + 1;
      Point3[2].X := x;
      Point3[2].Y := y - 12;
      FillPolygon(Point3);
      
      // triangle
      Point3[0].X := x - 4;
      Point3[0].Y := y + 11;
      Point3[1].X := x + 4;
      Point3[1].Y := y + 11;
      Point3[2].X := x;
      Point3[2].Y := y - 3;
      FillPolygon(Point3);
    end;
    Diamonds: begin
      Point4[0].X := x;
      Point4[0].Y := y - 10;
      Point4[1].X := x + 8;
      Point4[1].Y := y;
      Point4[2].X := x;
      Point4[2].Y := y + 10;
      Point4[3].X := x - 8;
      Point4[3].Y := y;
      FillPolygon(Point4);
    end;
    Clubs: begin
      FillCircle(x - 5, y + 2, 5);
      FillCircle(x + 5, y + 2, 5);
      FillCircle(x, y - 6, 5);
      Point3[0].X := x - 4;
      Point3[0].Y := y + 11;
      Point3[1].X := x + 4;
      Point3[1].Y := y + 11;
      Point3[2].X := x;
      Point3[2].Y := y - 3;
      FillPolygon(Point3);
    end;
  end;
end;

procedure DrawCardFront(const card: cardR);
begin
  var (x2, y2) := (card.x + CWidth, card.y + CHeight);
  SetBrushColor(clGhostWhite);
  RoundRect(card.x, card.y, x2, y2, Rounding, Rounding);
  var text: String;
  if card.rank = 1 then
    Println('!');
  case (card.rank + 0) of
    1..10: text := card.rank.ToString;
    11: text := 'J';
    12: text := 'Q';
    13: text := 'K';
    14: text := 'A';
    else text := 'N';
  end;
  SetFontSize(FontSize);
  SetFontStyle(fsBold);
  var suitColor := (card.suit = Hearts) or (card.suit = Diamonds) ? clRed : clBlack;
  SetFontColor(suitColor);
  DrawTextCentered(card.x + 2 - 50, card.y + 4, card.x + 23 + 50, card.y + 25, text);
  DrawTextCentered(card.x + CWIDTH - 23 - 50, card.y + CHEIGHT - 25, card.x + CWIDTH - 2 + 50, card.y + CHEIGHT - 4, text);
  SetBrushColor(suitColor);
  DrawSuiteSmall(card.suit, card.x + 50, card.y + 30);
  DrawSuiteSmall(card.suit, card.x + 50, card.y + CHEIGHT - 30);
  DrawSuiteSmall(card.suit, card.x + 20, card.y + CHEIGHT div 2);
  DrawSuiteSmall(card.suit, card.x + CWIDTH - 20, card.y + CHEIGHT div 2);
end;

procedure DrawCard(const card: CardR);
begin
  initBrush;
  if not card.front then
  begin
    // Paint face down
    DrawCardBack(card)
  end else
    DrawCardFront(card);
end;

end.