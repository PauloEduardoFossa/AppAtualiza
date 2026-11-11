unit View.GlyphIcons;

// Gera um TImageList a partir de glifos da fonte "Segoe MDL2 Assets" (Windows 10/11),
// sem precisar de arquivos de imagem. Cada glifo vira 2 imagens: normal (cor pedida)
// no indice I e desabilitada (cinza) no indice I + Length(AGlifos).

interface

uses
  System.Classes, Vcl.Graphics, Vcl.Controls;

const
  FONTE_ICONES = 'Segoe MDL2 Assets';

function FonteDeIconesDisponivel: Boolean;

function CriarImageListGlifos(AOwner: TComponent; const AGlifos: array of Word;
  const ACores: array of TColor; ATamanho: Integer; ACorDesabilitado: TColor): TImageList;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Types, Vcl.ImgList, Vcl.Forms;

type
  TBitmap = Vcl.Graphics.TBitmap; // Winapi.Windows tambem declara TBitmap

function FonteDeIconesDisponivel: Boolean;
begin
  Result := Screen.Fonts.IndexOf(FONTE_ICONES) >= 0;
end;

// Desenha o glifo em branco sobre preto e converte a luminosidade em alpha,
// pintando com ACor (bitmap 32 bits com alpha pre-multiplicado).
function RenderizarGlifo(AGlifo: Word; ACor: TColor; ATamanho: Integer): TBitmap;
var
  X, Y: Integer;
  P: PRGBQuad;
  Cor: TColor;
  R, G, B, A: Byte;
  Tam: TSize;
  Texto: string;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf32bit;
  Result.SetSize(ATamanho, ATamanho);
  Result.Canvas.Brush.Color := clBlack;
  Result.Canvas.FillRect(Rect(0, 0, ATamanho, ATamanho));
  Result.Canvas.Font.Name := FONTE_ICONES;
  Result.Canvas.Font.Height := -(ATamanho - 4);
  Result.Canvas.Font.Color := clWhite;
  Result.Canvas.Font.Quality := fqAntialiased;
  Result.Canvas.Brush.Style := bsClear;
  Texto := Char(AGlifo);
  Tam := Result.Canvas.TextExtent(Texto);
  Result.Canvas.TextOut((ATamanho - Tam.cx) div 2, (ATamanho - Tam.cy) div 2, Texto);

  Cor := ColorToRGB(ACor);
  R := GetRValue(Cor);
  G := GetGValue(Cor);
  B := GetBValue(Cor);
  for Y := 0 to ATamanho - 1 do
  begin
    P := Result.ScanLine[Y];
    for X := 0 to ATamanho - 1 do
    begin
      A := P^.rgbGreen; // luminosidade do pixel branco-sobre-preto
      P^.rgbRed := (R * A) div 255;
      P^.rgbGreen := (G * A) div 255;
      P^.rgbBlue := (B * A) div 255;
      P^.rgbReserved := A;
      Inc(P);
    end;
  end;
  Result.AlphaFormat := afPremultiplied;
end;

function CriarImageListGlifos(AOwner: TComponent; const AGlifos: array of Word;
  const ACores: array of TColor; ATamanho: Integer; ACorDesabilitado: TColor): TImageList;
var
  I: Integer;
  Bmp: TBitmap;
begin
  Result := TImageList.Create(AOwner);
  Result.ColorDepth := cd32Bit;
  Result.Width := ATamanho;
  Result.Height := ATamanho;
  for I := 0 to High(AGlifos) do
  begin
    Bmp := RenderizarGlifo(AGlifos[I], ACores[I], ATamanho);
    try
      Result.Add(Bmp, nil);
    finally
      Bmp.Free;
    end;
  end;
  for I := 0 to High(AGlifos) do
  begin
    Bmp := RenderizarGlifo(AGlifos[I], ACorDesabilitado, ATamanho);
    try
      Result.Add(Bmp, nil);
    finally
      Bmp.Free;
    end;
  end;
end;

end.
