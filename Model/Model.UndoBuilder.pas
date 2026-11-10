unit Model.UndoBuilder;

{ Calcula, ANTES de um comando ser executado, o(s) comando(s) que o desfazem.
  Olha o estado atual da base (RDB$...) para saber o que existia antes. Uma
  instancia por execucao de script: guarda os objetos criados no proprio script
  (UPDATE/ALTER sobre eles nao precisam de undo, o DROP ja cobre). }

interface

uses
  System.SysUtils, System.Classes, System.RegularExpressions, System.Math,
  Data.DB, Data.FmtBcd,
  FireDAC.Comp.Client, FireDAC.Comp.DataSet, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.DApt;

type
  TUndoComando = record
    Cmd: string;
    Undo: TArray<string>;
    Reversivel: Boolean;
    Aviso: string;
  end;

  TUndoBuilder = class
  private
    FConn: TFDConnection;
    FCriados: TStringList;
    function NovaQuery(const ASQL: string): TFDQuery;
    function Existe(const ASQL, ANome: string): Boolean;
    function ExisteObjeto(const ATipo, ANomeRDB: string): Boolean;
    function DefinicaoTipo(const AFieldSource: string): string;
    function ChavePrimaria(const ATabelaRDB: string): TArray<string>;
    function TamanhoTextoDominio(const ADominioRDB: string; out ATam: Integer): Boolean;
    function TamanhoTextoNovoTipo(const ATipoCmd: string; out ATam: Integer): Boolean;
    function ColunaTemDependencia(const ATabelaRDB, AColunaRDB: string): Boolean;
    procedure AddUndoEncolher(var R: TUndoComando; const ATabela, AColuna, ATipoAnterior: string;
      ATamAnterior, APosicao: Integer; ANotNull, ATemPadrao: Boolean; const APadrao: string);
    function Literal(AField: TField): string;
    function FonteProcedure(const ANome, ANomeRDB: string; out ASql: string): Boolean;
    function FonteTrigger(const ANome, ANomeRDB: string; out ASql: string): Boolean;
    function TentarCriacao(const ACmd: string; var R: TUndoComando): Boolean;
    function TentarObjetoPsql(const ACmd: string; var R: TUndoComando): Boolean;
    function TentarAlterTable(const ACmd: string; var R: TUndoComando): Boolean;
    function TentarGerador(const ACmd: string; var R: TUndoComando): Boolean;
    function TentarUpdate(const ACmd: string; var R: TUndoComando): Boolean;
    procedure Marcar(var R: TUndoComando; const AAviso: string);
    procedure AddUndo(var R: TUndoComando; const ASql: string);
  public
    constructor Create(AConn: TFDConnection);
    destructor Destroy; override;
    function Preparar(const ACmd: string): TUndoComando;
  end;

implementation

const
  RxNome = '("[^"]+"|[A-Za-z_][A-Za-z0-9_$]*)';

function NomeRDB(const AToken: string): string;
begin
  if (Length(AToken) >= 2) and (AToken[1] = '"') then
    Result := Copy(AToken, 2, Length(AToken) - 2)
  else
    Result := UpperCase(AToken);
end;

function NomeSql(const ANomeRDB: string): string;
begin
  if TRegEx.IsMatch(ANomeRDB, '^[A-Z_][A-Z0-9_$]*$') then
    Result := ANomeRDB
  else
    Result := '"' + ANomeRDB + '"';
end;

// Remove comentarios iniciais (/* */ e --) e espacos.
function NormalizarCmd(const ACmd: string): string;
var
  S: string;
  P: Integer;
begin
  S := Trim(ACmd);
  while True do
  begin
    if S.StartsWith('/*') then
    begin
      P := S.IndexOf('*/');
      if P < 0 then
        Break;
      S := Trim(S.Substring(P + 2));
    end
    else if S.StartsWith('--') then
    begin
      P := S.IndexOf(#10);
      if P < 0 then
        Exit('');
      S := Trim(S.Substring(P + 1));
    end
    else
      Break;
  end;
  Result := S;
end;

// Divide em AChar so no nivel 0 de parenteses e fora de strings.
function SplitTopLevel(const S: string; AChar: Char): TArray<string>;
var
  I, Nivel, Ini: Integer;
  Dentro: Boolean;
begin
  Result := [];
  Nivel := 0;
  Dentro := False;
  Ini := 1;
  for I := 1 to Length(S) do
  begin
    if S[I] = '''' then
      Dentro := not Dentro
    else if not Dentro then
    begin
      if S[I] = '(' then
        Inc(Nivel)
      else if S[I] = ')' then
        Dec(Nivel)
      else if (S[I] = AChar) and (Nivel = 0) then
      begin
        Result := Result + [Copy(S, Ini, I - Ini)];
        Ini := I + 1;
      end;
    end;
  end;
  Result := Result + [Copy(S, Ini, MaxInt)];
end;

// Posicao (1-based) de uma palavra-chave no nivel 0, fora de strings; 0 se nao achar.
function PosPalavraTopLevel(const S, APalavra: string): Integer;
var
  I, Nivel, Tam: Integer;
  Dentro: Boolean;
  Antes, Depois: Boolean;
begin
  Result := 0;
  Nivel := 0;
  Dentro := False;
  Tam := Length(APalavra);
  for I := 1 to Length(S) do
  begin
    if S[I] = '''' then
      Dentro := not Dentro
    else if not Dentro then
    begin
      if S[I] = '(' then
        Inc(Nivel)
      else if S[I] = ')' then
        Dec(Nivel)
      else if (Nivel = 0) and (I + Tam - 1 <= Length(S)) and
        SameText(Copy(S, I, Tam), APalavra) then
      begin
        Antes := (I = 1) or not CharInSet(S[I - 1], ['A'..'Z', 'a'..'z', '0'..'9', '_', '$']);
        Depois := (I + Tam > Length(S)) or
          not CharInSet(S[I + Tam], ['A'..'Z', 'a'..'z', '0'..'9', '_', '$']);
        if Antes and Depois then
          Exit(I);
      end;
    end;
  end;
end;

{ TUndoBuilder }

constructor TUndoBuilder.Create(AConn: TFDConnection);
begin
  inherited Create;
  FConn := AConn;
  FCriados := TStringList.Create;
  FCriados.CaseSensitive := False;
  FCriados.Sorted := True;
  FCriados.Duplicates := dupIgnore;
end;

destructor TUndoBuilder.Destroy;
begin
  FCriados.Free;
  inherited;
end;

function TUndoBuilder.NovaQuery(const ASQL: string): TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := FConn;
  Result.SQL.Text := ASQL;
end;

function TUndoBuilder.Existe(const ASQL, ANome: string): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := NovaQuery(ASQL);
  try
    Qry.ParamByName('n').AsString := ANome;
    Qry.Open;
    Result := not Qry.Eof;
  finally
    Qry.Free;
  end;
end;

function TUndoBuilder.ExisteObjeto(const ATipo, ANomeRDB: string): Boolean;
begin
  if ATipo = 'PROCEDURE' then
    Result := Existe('SELECT 1 FROM RDB$PROCEDURES WHERE RDB$PROCEDURE_NAME = :n ' +
      'AND RDB$PACKAGE_NAME IS NULL', ANomeRDB)
  else if ATipo = 'TRIGGER' then
    Result := Existe('SELECT 1 FROM RDB$TRIGGERS WHERE RDB$TRIGGER_NAME = :n', ANomeRDB)
  else if ATipo = 'FUNCTION' then
    Result := Existe('SELECT 1 FROM RDB$FUNCTIONS WHERE RDB$FUNCTION_NAME = :n ' +
      'AND RDB$PACKAGE_NAME IS NULL', ANomeRDB)
  else
    Result := Existe('SELECT 1 FROM RDB$RELATIONS WHERE RDB$RELATION_NAME = :n ' +
      'AND RDB$VIEW_BLR IS NOT NULL', ANomeRDB);
end;

procedure TUndoBuilder.Marcar(var R: TUndoComando; const AAviso: string);
begin
  R.Reversivel := False;
  R.Undo := [];
  R.Aviso := AAviso;
end;

procedure TUndoBuilder.AddUndo(var R: TUndoComando; const ASql: string);
begin
  R.Undo := R.Undo + [ASql];
end;

// Devolve a definicao de tipo: nome do dominio, ou o tipo expandido quando o
// campo usa um dominio interno (RDB$nnn).
function TUndoBuilder.DefinicaoTipo(const AFieldSource: string): string;
var
  Qry: TFDQuery;
  Tipo, Sub, Tam, Prec, Escala, TamChar: Integer;
  Nome: string;
begin
  Nome := Trim(AFieldSource);
  if not Nome.StartsWith('RDB$') then
    Exit(NomeSql(Nome));

  Qry := NovaQuery('SELECT RDB$FIELD_TYPE, RDB$FIELD_SUB_TYPE, RDB$FIELD_LENGTH, ' +
    'RDB$FIELD_PRECISION, RDB$FIELD_SCALE, RDB$CHARACTER_LENGTH FROM RDB$FIELDS ' +
    'WHERE RDB$FIELD_NAME = :n');
  try
    Qry.ParamByName('n').AsString := Nome;
    Qry.Open;
    if Qry.Eof then
      raise Exception.Create('Tipo ' + Nome + ' nao encontrado');
    Tipo := Qry.Fields[0].AsInteger;
    Sub := Qry.Fields[1].AsInteger;
    Tam := Qry.Fields[2].AsInteger;
    Prec := Qry.Fields[3].AsInteger;
    Escala := Qry.Fields[4].AsInteger;
    TamChar := Qry.Fields[5].AsInteger;
  finally
    Qry.Free;
  end;

  if (Tipo in [7, 8, 16]) and (Sub in [1, 2]) then
  begin
    if Sub = 1 then
      Result := 'NUMERIC'
    else
      Result := 'DECIMAL';
    Exit(Format('%s(%d,%d)', [Result, Prec, -Escala]));
  end;

  case Tipo of
    7: Result := 'SMALLINT';
    8: Result := 'INTEGER';
    16: Result := 'BIGINT';
    10: Result := 'FLOAT';
    27: Result := 'DOUBLE PRECISION';
    12: Result := 'DATE';
    13: Result := 'TIME';
    35: Result := 'TIMESTAMP';
    23: Result := 'BOOLEAN';
    14: Result := Format('CHAR(%d)', [IfThen(TamChar > 0, TamChar, Tam)]);
    37: Result := Format('VARCHAR(%d)', [IfThen(TamChar > 0, TamChar, Tam)]);
    261: Result := Format('BLOB SUB_TYPE %d', [Sub]);
  else
    raise Exception.CreateFmt('Tipo de campo %d nao suportado', [Tipo]);
  end;
end;

function TUndoBuilder.ChavePrimaria(const ATabelaRDB: string): TArray<string>;
var
  Qry: TFDQuery;
begin
  Result := [];
  Qry := NovaQuery('SELECT TRIM(s.RDB$FIELD_NAME) FROM RDB$RELATION_CONSTRAINTS rc ' +
    'JOIN RDB$INDEX_SEGMENTS s ON s.RDB$INDEX_NAME = rc.RDB$INDEX_NAME ' +
    'WHERE rc.RDB$RELATION_NAME = :r AND rc.RDB$CONSTRAINT_TYPE = ''PRIMARY KEY'' ' +
    'ORDER BY s.RDB$FIELD_POSITION');
  try
    Qry.ParamByName('r').AsString := ATabelaRDB;
    Qry.Open;
    while not Qry.Eof do
    begin
      Result := Result + [Qry.Fields[0].AsString];
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

// Tamanho em caracteres de um CHAR/VARCHAR (dominio ou tipo interno RDB$nnn).
function TUndoBuilder.TamanhoTextoDominio(const ADominioRDB: string; out ATam: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  ATam := 0;
  Qry := NovaQuery('SELECT RDB$FIELD_TYPE, RDB$FIELD_LENGTH, RDB$CHARACTER_LENGTH ' +
    'FROM RDB$FIELDS WHERE RDB$FIELD_NAME = :n');
  try
    Qry.ParamByName('n').AsString := Trim(ADominioRDB);
    Qry.Open;
    if Qry.Eof or not (Qry.Fields[0].AsInteger in [14, 37]) then
      Exit;
    if Qry.Fields[2].IsNull or (Qry.Fields[2].AsInteger = 0) then
      ATam := Qry.Fields[1].AsInteger
    else
      ATam := Qry.Fields[2].AsInteger;
    Result := True;
  finally
    Qry.Free;
  end;
end;

// Tamanho do tipo que o comando vai aplicar: "VARCHAR(50)" inline ou nome de dominio.
function TUndoBuilder.TamanhoTextoNovoTipo(const ATipoCmd: string; out ATam: Integer): Boolean;
var
  M: TMatch;
  T: string;
begin
  T := Trim(ATipoCmd);
  M := TRegEx.Match(T, '^(?:VARCHAR|CHAR|CHARACTER\s+VARYING|CHARACTER)\s*\(\s*(\d+)\s*\)',
    [roIgnoreCase]);
  if M.Success then
  begin
    ATam := StrToInt(M.Groups[1].Value);
    Exit(True);
  end;
  M := TRegEx.Match(T, '^' + RxNome + '\s*$', [roIgnoreCase]);
  if M.Success then
    Exit(TamanhoTextoDominio(NomeRDB(M.Groups[1].Value), ATam));
  M := TRegEx.Match(T, '^' + RxNome + '\b', [roIgnoreCase]);
  Result := M.Success and TamanhoTextoDominio(NomeRDB(M.Groups[1].Value), ATam);
end;

// Indice/constraint/view/procedure/trigger/check que usa a coluna: impede o DROP dela.
function TUndoBuilder.ColunaTemDependencia(const ATabelaRDB, AColunaRDB: string): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := NovaQuery('SELECT 1 FROM RDB$INDEX_SEGMENTS s JOIN RDB$INDICES i ' +
    'ON i.RDB$INDEX_NAME = s.RDB$INDEX_NAME WHERE i.RDB$RELATION_NAME = :r ' +
    'AND s.RDB$FIELD_NAME = :f ' +
    'UNION ALL SELECT 1 FROM RDB$DEPENDENCIES WHERE RDB$DEPENDED_ON_NAME = :r ' +
    'AND RDB$FIELD_NAME = :f');
  try
    Qry.ParamByName('r').AsString := ATabelaRDB;
    Qry.ParamByName('f').AsString := AColunaRDB;
    Qry.Open;
    Result := not Qry.Eof;
  finally
    Qry.Free;
  end;
end;

// O Firebird nao deixa diminuir CHAR/VARCHAR com ALTER ... TYPE. Alternativa:
// coluna temporaria no tipo antigo, copia truncada, DROP da coluna, renomear e
// devolver a posicao/NOT NULL/DEFAULT.
procedure TUndoBuilder.AddUndoEncolher(var R: TUndoComando; const ATabela, AColuna,
  ATipoAnterior: string; ATamAnterior, APosicao: Integer; ANotNull, ATemPadrao: Boolean;
  const APadrao: string);
const
  Tmp = 'ESTORNO_TMP';
var
  Prefixo, Padrao: string;
begin
  Prefixo := 'ALTER TABLE ' + ATabela + ' ';
  AddUndo(R, Prefixo + 'ADD ' + Tmp + ' ' + ATipoAnterior);
  AddUndo(R, Format('UPDATE %s SET %s = SUBSTRING(%s FROM 1 FOR %d)',
    [ATabela, Tmp, AColuna, ATamAnterior]));
  AddUndo(R, Prefixo + 'DROP ' + AColuna);
  AddUndo(R, Prefixo + 'ALTER ' + Tmp + ' TO ' + AColuna);
  AddUndo(R, Prefixo + 'ALTER ' + AColuna + ' POSITION ' + IntToStr(APosicao));
  if ANotNull then
    AddUndo(R, Prefixo + 'ALTER ' + AColuna + ' SET NOT NULL');
  if ATemPadrao then
  begin
    Padrao := Trim(APadrao);
    if Padrao.ToUpper.StartsWith('DEFAULT') then
      Padrao := Trim(Padrao.Substring(7));
    AddUndo(R, Prefixo + 'ALTER ' + AColuna + ' SET DEFAULT ' + Padrao);
  end;
end;

function TUndoBuilder.Literal(AField: TField): string;
var
  FS: TFormatSettings;
begin
  if AField.IsNull then
    Exit('NULL');
  FS := TFormatSettings.Invariant;
  case AField.DataType of
    ftString, ftWideString, ftFixedChar, ftFixedWideChar, ftMemo, ftWideMemo:
      Result := '''' + AField.AsString.Replace('''', '''''') + '''';
    ftSmallint, ftInteger, ftLargeint, ftWord, ftShortint, ftByte, ftLongWord:
      Result := AField.AsString;
    ftFloat, ftSingle, ftExtended, ftCurrency:
      Result := FloatToStr(AField.AsFloat, FS);
    ftBCD, ftFMTBcd:
      Result := BcdToStr(AField.AsBcd, FS);
    ftDate:
      Result := '''' + FormatDateTime('yyyy-mm-dd', AField.AsDateTime) + '''';
    ftTime:
      Result := '''' + FormatDateTime('hh:nn:ss.zzz', AField.AsDateTime) + '''';
    ftDateTime, ftTimeStamp:
      Result := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', AField.AsDateTime) + '''';
    ftBoolean:
      if AField.AsBoolean then
        Result := 'TRUE'
      else
        Result := 'FALSE';
  else
    raise Exception.Create('Tipo de coluna sem literal: ' + AField.FieldName);
  end;
end;

function TUndoBuilder.FonteProcedure(const ANome, ANomeRDB: string; out ASql: string): Boolean;
var
  Qry, QP: TFDQuery;
  Fonte, Entradas, Saidas, Def: string;
begin
  Result := False;
  Qry := NovaQuery('SELECT RDB$PROCEDURE_SOURCE FROM RDB$PROCEDURES ' +
    'WHERE RDB$PROCEDURE_NAME = :n AND RDB$PACKAGE_NAME IS NULL');
  try
    Qry.ParamByName('n').AsString := ANomeRDB;
    Qry.Open;
    if Qry.Eof or Qry.Fields[0].IsNull then
      Exit;
    Fonte := Qry.Fields[0].AsString;
  finally
    Qry.Free;
  end;

  Entradas := '';
  Saidas := '';
  QP := NovaQuery('SELECT TRIM(RDB$PARAMETER_NAME), RDB$FIELD_SOURCE, RDB$PARAMETER_TYPE, ' +
    'RDB$DEFAULT_SOURCE FROM RDB$PROCEDURE_PARAMETERS ' +
    'WHERE RDB$PROCEDURE_NAME = :n AND RDB$PACKAGE_NAME IS NULL ' +
    'ORDER BY RDB$PARAMETER_TYPE, RDB$PARAMETER_NUMBER');
  try
    QP.ParamByName('n').AsString := ANomeRDB;
    QP.Open;
    while not QP.Eof do
    begin
      Def := NomeSql(QP.Fields[0].AsString) + ' ' + DefinicaoTipo(QP.Fields[1].AsString);
      if not QP.Fields[3].IsNull then
        Def := Def + ' ' + Trim(QP.Fields[3].AsString);
      if QP.Fields[2].AsInteger = 0 then
      begin
        if Entradas <> '' then
          Entradas := Entradas + ', ';
        Entradas := Entradas + Def;
      end
      else
      begin
        if Saidas <> '' then
          Saidas := Saidas + ', ';
        Saidas := Saidas + Def;
      end;
      QP.Next;
    end;
  finally
    QP.Free;
  end;

  ASql := 'CREATE OR ALTER PROCEDURE ' + ANome;
  if Entradas <> '' then
    ASql := ASql + ' (' + Entradas + ')';
  if Saidas <> '' then
    ASql := ASql + ' RETURNS (' + Saidas + ')';
  ASql := ASql + ' AS ' + sLineBreak + Fonte;
  Result := True;
end;

function TUndoBuilder.FonteTrigger(const ANome, ANomeRDB: string; out ASql: string): Boolean;
var
  Qry: TFDQuery;
  Tipo, T1, I: Integer;
  Eventos, Quando, Estado, Fonte, Tabela: string;
  Ev: Integer;
const
  NomesEv: array[1..3] of string = ('INSERT', 'UPDATE', 'DELETE');
begin
  Result := False;
  Qry := NovaQuery('SELECT RDB$RELATION_NAME, RDB$TRIGGER_TYPE, RDB$TRIGGER_SEQUENCE, ' +
    'RDB$TRIGGER_INACTIVE, RDB$TRIGGER_SOURCE FROM RDB$TRIGGERS WHERE RDB$TRIGGER_NAME = :n');
  try
    Qry.ParamByName('n').AsString := ANomeRDB;
    Qry.Open;
    if Qry.Eof or Qry.Fields[0].IsNull or Qry.Fields[4].IsNull then
      Exit;
    Tipo := Qry.Fields[1].AsInteger;
    if (Tipo < 1) or (Tipo > 114) then
      Exit;
    Tabela := Trim(Qry.Fields[0].AsString);
    if Qry.Fields[3].AsInteger = 1 then
      Estado := 'INACTIVE'
    else
      Estado := 'ACTIVE';
    Fonte := Qry.Fields[4].AsString;
    T1 := Tipo + 1;
    if (T1 and 1) = 1 then
      Quando := 'AFTER'
    else
      Quando := 'BEFORE';
    Eventos := '';
    for I := 0 to 2 do
    begin
      Ev := (T1 shr (1 + 2 * I)) and 3;
      if Ev = 0 then
        Break;
      if Eventos <> '' then
        Eventos := Eventos + ' OR ';
      Eventos := Eventos + NomesEv[Ev];
    end;
    ASql := Format('CREATE OR ALTER TRIGGER %s FOR %s %s %s %s POSITION %d AS %s%s',
      [ANome, NomeSql(Tabela), Estado, Quando, Eventos, Qry.Fields[2].AsInteger,
       sLineBreak, Fonte]);
    Result := True;
  finally
    Qry.Free;
  end;
end;

function TUndoBuilder.TentarCriacao(const ACmd: string; var R: TUndoComando): Boolean;
var
  M: TMatch;
  Nome: string;
begin
  Result := True;

  M := TRegEx.Match(ACmd, '^CREATE\s+(?:GLOBAL\s+TEMPORARY\s+)?TABLE\s+' + RxNome, [roIgnoreCase]);
  if M.Success then
  begin
    Nome := M.Groups[1].Value;
    FCriados.Add(NomeRDB(Nome));
    AddUndo(R, 'DROP TABLE ' + Nome);
    Exit;
  end;

  M := TRegEx.Match(ACmd,
    '^CREATE\s+(?:UNIQUE\s+)?(?:ASC(?:ENDING)?\s+|DESC(?:ENDING)?\s+)*INDEX\s+' + RxNome,
    [roIgnoreCase]);
  if M.Success then
  begin
    AddUndo(R, 'DROP INDEX ' + M.Groups[1].Value);
    Exit;
  end;

  M := TRegEx.Match(ACmd, '^CREATE\s+(SEQUENCE|GENERATOR)\s+' + RxNome, [roIgnoreCase]);
  if M.Success then
  begin
    AddUndo(R, 'DROP SEQUENCE ' + M.Groups[2].Value);
    Exit;
  end;

  M := TRegEx.Match(ACmd, '^CREATE\s+(DOMAIN|EXCEPTION)\s+' + RxNome, [roIgnoreCase]);
  if M.Success then
  begin
    AddUndo(R, 'DROP ' + UpperCase(M.Groups[1].Value) + ' ' + M.Groups[2].Value);
    Exit;
  end;

  Result := False;
end;

function TUndoBuilder.TentarObjetoPsql(const ACmd: string; var R: TUndoComando): Boolean;
var
  M: TMatch;
  Verbo, Tipo, Nome, NomeR, Sql: string;
  Existia, Ok: Boolean;
begin
  M := TRegEx.Match(ACmd,
    '^(CREATE\s+OR\s+ALTER|RECREATE|CREATE|ALTER)\s+(PROCEDURE|TRIGGER|FUNCTION|VIEW)\s+' + RxNome,
    [roIgnoreCase]);
  Result := M.Success;
  if not Result then
    Exit;

  Verbo := UpperCase(TRegEx.Replace(M.Groups[1].Value, '\s+', ' '));
  Tipo := UpperCase(M.Groups[2].Value);
  Nome := M.Groups[3].Value;
  NomeR := NomeRDB(Nome);

  if Verbo = 'CREATE' then
    Existia := False
  else
    Existia := ExisteObjeto(Tipo, NomeR);

  if not Existia then
  begin
    AddUndo(R, 'DROP ' + Tipo + ' ' + Nome);
    Exit;
  end;

  Ok := False;
  if Tipo = 'PROCEDURE' then
    Ok := FonteProcedure(Nome, NomeR, Sql)
  else if Tipo = 'TRIGGER' then
    Ok := FonteTrigger(Nome, NomeR, Sql);

  if Ok then
    AddUndo(R, Sql)
  else
    Marcar(R, Format('%s %s ja existia e sua definicao anterior nao pode ser restaurada automaticamente.',
      [Tipo, Nome]));
end;

function TUndoBuilder.TentarAlterTable(const ACmd: string; var R: TUndoComando): Boolean;
var
  M, MA: TMatch;
  Tabela, TabelaR, Col, ColR, Resto, Prefixo, Padrao: string;
  Qry: TFDQuery;
  FieldSrc: string;
  NullFlag: Boolean;
  TemPadrao, Aumenta: Boolean;
  Posicao, TamAntigo, TamNovo: Integer;
begin
  M := TRegEx.Match(ACmd, '^ALTER\s+TABLE\s+' + RxNome + '\s+(.+)$', [roIgnoreCase, roSingleLine]);
  Result := M.Success;
  if not Result then
    Exit;

  Tabela := M.Groups[1].Value;
  TabelaR := NomeRDB(Tabela);
  Resto := Trim(M.Groups[2].Value);
  Prefixo := 'ALTER TABLE ' + Tabela + ' ';

  // ADD CONSTRAINT nome ...
  MA := TRegEx.Match(Resto, '^ADD\s+CONSTRAINT\s+' + RxNome, [roIgnoreCase]);
  if MA.Success then
  begin
    if TRegEx.Matches(Resto, '\bADD\b', [roIgnoreCase]).Count > 1 then
      Marcar(R, 'ALTER TABLE com varios ADD no mesmo comando: sem inverso automatico.')
    else
      AddUndo(R, Prefixo + 'DROP CONSTRAINT ' + MA.Groups[1].Value);
    Exit;
  end;

  // ADD PRIMARY/FOREIGN/UNIQUE/CHECK sem nome
  if TRegEx.IsMatch(Resto, '^ADD\s+(PRIMARY|FOREIGN|UNIQUE|CHECK)\b', [roIgnoreCase]) then
  begin
    Marcar(R, 'Constraint sem nome em ' + Tabela + ': sem inverso automatico.');
    Exit;
  end;

  // ADD [COLUMN] col ...
  MA := TRegEx.Match(Resto, '^ADD\s+(?:COLUMN\s+)?' + RxNome, [roIgnoreCase]);
  if MA.Success then
  begin
    if TRegEx.Matches(Resto, '\bADD\b', [roIgnoreCase]).Count > 1 then
      Marcar(R, 'ALTER TABLE com varios ADD no mesmo comando: sem inverso automatico.')
    else
    begin
      Col := MA.Groups[1].Value;
      FCriados.Add(TabelaR + '.' + NomeRDB(Col));
      AddUndo(R, Prefixo + 'DROP ' + Col);
    end;
    Exit;
  end;

  if TRegEx.IsMatch(Resto, '^DROP\b', [roIgnoreCase]) then
  begin
    Marcar(R, 'DROP em ' + Tabela + ': dados/definicao removidos nao sao restaurados automaticamente.');
    Exit;
  end;

  // ALTER [COLUMN] col ...
  MA := TRegEx.Match(Resto, '^ALTER\s+(?:COLUMN\s+)?' + RxNome + '\s+(.+)$',
    [roIgnoreCase, roSingleLine]);
  if not MA.Success then
  begin
    Marcar(R, 'ALTER TABLE sem inverso automatico.');
    Exit;
  end;

  Col := MA.Groups[1].Value;
  ColR := NomeRDB(Col);
  Resto := Trim(MA.Groups[2].Value);

  // Coluna criada neste mesmo script: o DROP da coluna ja desfaz tudo.
  if FCriados.IndexOf(TabelaR + '.' + ColR) >= 0 then
    Exit;

  // TO novo nome
  MA := TRegEx.Match(Resto, '^TO\s+' + RxNome, [roIgnoreCase]);
  if MA.Success then
  begin
    AddUndo(R, Prefixo + 'ALTER ' + MA.Groups[1].Value + ' TO ' + Col);
    Exit;
  end;

  Qry := NovaQuery('SELECT RDB$FIELD_SOURCE, RDB$NULL_FLAG, RDB$DEFAULT_SOURCE, ' +
    'RDB$FIELD_POSITION FROM RDB$RELATION_FIELDS WHERE RDB$RELATION_NAME = :r ' +
    'AND RDB$FIELD_NAME = :f');
  try
    Qry.ParamByName('r').AsString := TabelaR;
    Qry.ParamByName('f').AsString := ColR;
    Qry.Open;
    if Qry.Eof then
    begin
      Marcar(R, 'Coluna ' + Tabela + '.' + Col + ' nao encontrada para capturar o estado anterior.');
      Exit;
    end;
    FieldSrc := Qry.Fields[0].AsString;
    NullFlag := Qry.Fields[1].AsInteger = 1;
    TemPadrao := not Qry.Fields[2].IsNull;
    Padrao := Trim(Qry.Fields[2].AsString);
    Posicao := Qry.Fields[3].AsInteger + 1;
  finally
    Qry.Free;
  end;

  if TRegEx.IsMatch(Resto, '^TYPE\b', [roIgnoreCase]) then
  begin
    TamAntigo := 0;
    TamNovo := 0;
    Aumenta := TamanhoTextoDominio(FieldSrc, TamAntigo) and
      TamanhoTextoNovoTipo(Resto.Substring(4), TamNovo) and (TamNovo > TamAntigo);
    if not Aumenta then
      AddUndo(R, Prefixo + 'ALTER ' + Col + ' TYPE ' + DefinicaoTipo(FieldSrc))
    else if ColunaTemDependencia(TabelaR, ColR) then
      Marcar(R, Format('%s.%s aumentou de %d para %d e nao da para diminuir de volta: ' +
        'a coluna tem indice/constraint/view/trigger dependente.', [Tabela, Col, TamAntigo, TamNovo]))
    else
      AddUndoEncolher(R, Tabela, Col, DefinicaoTipo(FieldSrc), TamAntigo, Posicao,
        NullFlag, TemPadrao, Padrao);
  end
  else if TRegEx.IsMatch(Resto, '^SET\s+NOT\s+NULL', [roIgnoreCase]) then
  begin
    if not NullFlag then
      AddUndo(R, Prefixo + 'ALTER ' + Col + ' DROP NOT NULL');
  end
  else if TRegEx.IsMatch(Resto, '^DROP\s+NOT\s+NULL', [roIgnoreCase]) then
  begin
    if NullFlag then
      AddUndo(R, Prefixo + 'ALTER ' + Col + ' SET NOT NULL');
  end
  else if TRegEx.IsMatch(Resto, '^(SET|DROP)\s+DEFAULT', [roIgnoreCase]) then
  begin
    if TemPadrao then
    begin
      if Padrao.ToUpper.StartsWith('DEFAULT') then
        Padrao := Trim(Padrao.Substring(7));
      AddUndo(R, Prefixo + 'ALTER ' + Col + ' SET DEFAULT ' + Padrao);
    end
    else
      AddUndo(R, Prefixo + 'ALTER ' + Col + ' DROP DEFAULT');
  end
  else
    Marcar(R, 'ALTER ' + Col + ' em ' + Tabela + ': sem inverso automatico.');
end;

function TUndoBuilder.TentarGerador(const ACmd: string; var R: TUndoComando): Boolean;
var
  M: TMatch;
  Nome: string;
  Qry: TFDQuery;
begin
  M := TRegEx.Match(ACmd, '^(?:SET\s+GENERATOR\s+' + RxNome + '\s+TO\b|ALTER\s+SEQUENCE\s+' +
    RxNome + '\s+RESTART\b)', [roIgnoreCase]);
  Result := M.Success;
  if not Result then
    Exit;
  if M.Groups[1].Success and (M.Groups[1].Value <> '') then
    Nome := M.Groups[1].Value
  else
    Nome := M.Groups[2].Value;
  Qry := NovaQuery('SELECT GEN_ID(' + Nome + ', 0) FROM RDB$DATABASE');
  try
    Qry.Open;
    AddUndo(R, 'ALTER SEQUENCE ' + Nome + ' RESTART WITH ' + Qry.Fields[0].AsString);
  finally
    Qry.Free;
  end;
end;

function TUndoBuilder.TentarUpdate(const ACmd: string; var R: TUndoComando): Boolean;
const
  MaxLinhas = 5000;
var
  M: TMatch;
  Tabela, TabelaR, Resto, SetParte, WherePar, Sel, Sql, Atribs, Cond: string;
  PosWhere, I, N, QtdPk: Integer;
  Cols: TArray<string>;
  Pk: TArray<string>;
  Qry: TFDQuery;
  MC: TMatch;
begin
  M := TRegEx.Match(ACmd, '^UPDATE\s+' + RxNome + '\s+SET\s+(.+)$', [roIgnoreCase, roSingleLine]);
  Result := M.Success;
  if not Result then
    Exit;

  Tabela := M.Groups[1].Value;
  TabelaR := NomeRDB(Tabela);
  Resto := M.Groups[2].Value;

  if FCriados.IndexOf(TabelaR) >= 0 then
    Exit; // tabela criada neste script: o DROP TABLE cobre

  if (PosPalavraTopLevel(Resto, 'RETURNING') > 0) or (PosPalavraTopLevel(Resto, 'ROWS') > 0) or
     (PosPalavraTopLevel(Resto, 'ORDER') > 0) then
  begin
    Marcar(R, 'UPDATE em ' + Tabela + ' com RETURNING/ROWS/ORDER BY: sem inverso automatico.');
    Exit;
  end;

  PosWhere := PosPalavraTopLevel(Resto, 'WHERE');
  if PosWhere > 0 then
  begin
    SetParte := Copy(Resto, 1, PosWhere - 1);
    WherePar := Trim(Copy(Resto, PosWhere + 5, MaxInt));
  end
  else
  begin
    SetParte := Resto;
    WherePar := '';
  end;

  Cols := [];
  for Atribs in SplitTopLevel(SetParte, ',') do
  begin
    MC := TRegEx.Match(Trim(Atribs), '^(?:' + RxNome + '\.)?' + RxNome + '\s*=');
    if not MC.Success then
    begin
      Marcar(R, 'UPDATE em ' + Tabela + ': nao foi possivel identificar as colunas do SET.');
      Exit;
    end;
    if FCriados.IndexOf(TabelaR + '.' + NomeRDB(MC.Groups[2].Value)) < 0 then
      Cols := Cols + [MC.Groups[2].Value];
  end;
  if Length(Cols) = 0 then
    Exit; // so colunas criadas neste script

  Pk := ChavePrimaria(TabelaR);
  if Length(Pk) = 0 then
  begin
    Marcar(R, 'UPDATE em ' + Tabela + ' sem chave primaria: sem inverso automatico.');
    Exit;
  end;
  QtdPk := Length(Pk);

  Sel := '';
  for I := 0 to QtdPk - 1 do
    Sel := Sel + '"' + Pk[I] + '", ';
  for I := 0 to High(Cols) do
  begin
    Sel := Sel + Cols[I];
    if I < High(Cols) then
      Sel := Sel + ', ';
  end;
  Sql := 'SELECT FIRST ' + IntToStr(MaxLinhas + 1) + ' ' + Sel + ' FROM ' + Tabela;
  if WherePar <> '' then
    Sql := Sql + ' WHERE ' + WherePar;

  Qry := NovaQuery(Sql);
  try
    Qry.Open;
    N := 0;
    while not Qry.Eof do
    begin
      Inc(N);
      if N > MaxLinhas then
      begin
        Marcar(R, Format('UPDATE em %s afeta mais de %d linhas: valores anteriores nao guardados.',
          [Tabela, MaxLinhas]));
        Exit;
      end;
      Atribs := '';
      for I := 0 to High(Cols) do
      begin
        if I > 0 then
          Atribs := Atribs + ', ';
        Atribs := Atribs + Cols[I] + ' = ' + Literal(Qry.Fields[QtdPk + I]);
      end;
      Cond := '';
      for I := 0 to QtdPk - 1 do
      begin
        if I > 0 then
          Cond := Cond + ' AND ';
        Cond := Cond + '"' + Pk[I] + '" = ' + Literal(Qry.Fields[I]);
      end;
      AddUndo(R, 'UPDATE ' + Tabela + ' SET ' + Atribs + ' WHERE ' + Cond);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TUndoBuilder.Preparar(const ACmd: string): TUndoComando;
var
  Cmd: string;
begin
  Result.Cmd := ACmd;
  Result.Undo := [];
  Result.Reversivel := True;
  Result.Aviso := '';
  Cmd := NormalizarCmd(ACmd);

  try
    // O registro na tabela SCRIPT e tratado pelo estorno (DELETE FROM SCRIPT).
    if UpperCase(Cmd).StartsWith('INSERT INTO SCRIPT') then
      Exit;
    if TentarCriacao(Cmd, Result) then
      Exit;
    if TentarObjetoPsql(Cmd, Result) then
      Exit;
    if TentarAlterTable(Cmd, Result) then
      Exit;
    if TentarGerador(Cmd, Result) then
      Exit;
    if TentarUpdate(Cmd, Result) then
      Exit;
    Marcar(Result, 'Sem inverso automatico: ' + Copy(StringReplace(Cmd, sLineBreak, ' ',
      [rfReplaceAll]), 1, 80));
  except
    on E: Exception do
      Marcar(Result, 'Nao foi possivel calcular o inverso (' + E.Message + '): ' +
        Copy(StringReplace(Cmd, sLineBreak, ' ', [rfReplaceAll]), 1, 60));
  end;
end;

end.
