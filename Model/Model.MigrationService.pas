unit Model.MigrationService;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.RegularExpressions,
  System.Generics.Collections, System.Generics.Defaults,
  FireDAC.Comp.Client, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet, FireDAC.DApt, FireDAC.Phys, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.Stan.Async, FireDAC.Stan.Param,
  FireDAC.Stan.Def, FireDAC.Stan.Pool,
  Model.Config, Model.MigrationScript;

type
  TLogEvent = procedure(Sender: TObject; const AMensagem: string) of object;
  TScriptStatusEvent = procedure(Sender: TObject; AScript: TMigrationScript) of object;
  TErroComandoEvent = procedure(Sender: TObject; AScript: TMigrationScript;
    const AComando, AMensagem: string) of object;

  TMigrationService = class
  private
    FConnection: TFDConnection;
    FOnLog: TLogEvent;
    FOnScriptStatus: TScriptStatusEvent;
    FOnErroComando: TErroComandoEvent;
    FParando: Boolean;
    procedure Log(const AMsg: string);
    procedure ErroComando(AScript: TMigrationScript; const ACmd, AMensagem: string);
    procedure AtualizarStatus(AScript: TMigrationScript);
    function CarregarCodigosAplicados: TArray<string>;
    function CodigoJaAplicado(const ACodigo: string; const ACodigos: TArray<string>): Boolean;
    function DividirEmComandos(const ATexto: string): TArray<string>;
    function PosicaoTerminadorFora(const ABuffer, ATerminador: string): Integer;
    function DeveIgnorarComando(const ACmd: string): Boolean;
    function EhInsertNaTabelaScript(const ACmd: string): Boolean;
    function ScriptJaAplicado(const ACodigo: string): Boolean;
    function LerArquivoTexto(const AArquivo: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Conectar(const ADB: TDBConfig);
    procedure Desconectar;
    function Conectado: Boolean;
    function ListarScripts(const APasta: string): TMigrationScriptList;
    procedure ExecutarPendentes(AScripts: TMigrationScriptList; AStopOnError: Boolean;
      AApenasPendentes: Boolean = True);
    procedure Parar;
    property OnLog: TLogEvent read FOnLog write FOnLog;
    property OnScriptStatus: TScriptStatusEvent read FOnScriptStatus write FOnScriptStatus;
    property OnErroComando: TErroComandoEvent read FOnErroComando write FOnErroComando;
  end;

implementation

{ TMigrationService }

constructor TMigrationService.Create;
begin
  inherited Create;
  FConnection := TFDConnection.Create(nil);
  FConnection.LoginPrompt := False;
end;

destructor TMigrationService.Destroy;
begin
  FConnection.Free;
  inherited;
end;

procedure TMigrationService.Log(const AMsg: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, AMsg);
end;

procedure TMigrationService.AtualizarStatus(AScript: TMigrationScript);
begin
  if Assigned(FOnScriptStatus) then
    FOnScriptStatus(Self, AScript);
end;

procedure TMigrationService.ErroComando(AScript: TMigrationScript; const ACmd, AMensagem: string);
begin
  if Assigned(FOnErroComando) then
    FOnErroComando(Self, AScript, ACmd, AMensagem);
end;

procedure TMigrationService.Conectar(const ADB: TDBConfig);
begin
  Desconectar;
  FConnection.Params.Clear;
  FConnection.Params.DriverID := 'FB';
  FConnection.Params.Database := ADB.DatabasePath;
  FConnection.Params.UserName := ADB.UserName;
  FConnection.Params.Password := ADB.Password;
  FConnection.Params.Values['Protocol'] := 'TCPIP';
  FConnection.Params.Values['Server'] := ADB.Server;
  FConnection.Params.Values['Port'] := IntToStr(ADB.Port);
  if ADB.CharacterSet <> '' then
    FConnection.Params.Values['CharacterSet'] := ADB.CharacterSet;
  if ADB.FbClientPath <> '' then
    FConnection.Params.Values['VendorLib'] := ADB.FbClientPath;
  FConnection.Connected := True;
end;

procedure TMigrationService.Desconectar;
begin
  if FConnection.Connected then
    FConnection.Connected := False;
end;

function TMigrationService.Conectado: Boolean;
begin
  Result := FConnection.Connected;
end;

function TMigrationService.CarregarCodigosAplicados: TArray<string>;
var
  Qry: TFDQuery;
  Lista: TList<string>;
begin
  Lista := TList<string>.Create;
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConnection;
    Qry.SQL.Text := 'SELECT CODIGO FROM SCRIPT';
    Qry.Open;
    while not Qry.Eof do
    begin
      Lista.Add(Trim(Qry.FieldByName('CODIGO').AsString));
      Qry.Next;
    end;
    Result := Lista.ToArray;
  finally
    Qry.Free;
    Lista.Free;
  end;
end;

function TMigrationService.CodigoJaAplicado(const ACodigo: string; const ACodigos: TArray<string>): Boolean;
var
  C: string;
begin
  Result := False;
  for C in ACodigos do
    if SameText(C, ACodigo) then
      Exit(True);
end;

function TMigrationService.ListarScripts(const APasta: string): TMigrationScriptList;
var
  Arquivos: TArray<string>;
  Codigos: TArray<string>;
  Arquivo, Codigo: string;
  Script: TMigrationScript;
begin
  Result := TMigrationScriptList.Create;
  if not TDirectory.Exists(APasta) then
  begin
    Log('Pasta de scripts nao encontrada: ' + APasta);
    Exit;
  end;

  Arquivos := TDirectory.GetFiles(APasta, '*.txt');
  TArray.Sort<string>(Arquivos, TComparer<string>.Construct(
    function(const L, R: string): Integer
    begin
      Result := CompareText(TPath.GetFileName(L), TPath.GetFileName(R));
    end));

  Codigos := [];
  if Conectado then
    Codigos := CarregarCodigosAplicados
  else
    Log('Sem conexao ativa: nao foi possivel verificar scripts ja aplicados.');

  for Arquivo in Arquivos do
  begin
    Codigo := TPath.GetFileNameWithoutExtension(Arquivo);
    Script := TMigrationScript.Create(Codigo, Arquivo);
    if CodigoJaAplicado(Codigo, Codigos) then
      Script.Status := msAplicado
    else
      Script.Status := msPendente;
    Result.Add(Script);
  end;
end;

function TMigrationService.DeveIgnorarComando(const ACmd: string): Boolean;
var
  Cmd: string;
begin
  Cmd := UpperCase(Trim(ACmd));
  Result := (Cmd = 'COMMIT') or (Cmd = 'COMMIT WORK') or (Cmd = '');
end;

function TMigrationService.EhInsertNaTabelaScript(const ACmd: string): Boolean;
begin
  Result := UpperCase(Trim(ACmd)).StartsWith('INSERT INTO SCRIPT');
end;

function TMigrationService.ScriptJaAplicado(const ACodigo: string): Boolean;
var
  Qry: TFDQuery;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConnection;
    Qry.SQL.Text := 'SELECT CODIGO FROM SCRIPT WHERE CODIGO = :codigo';
    Qry.ParamByName('codigo').AsString := ACodigo;
    Qry.Open;
    Result := not Qry.Eof;
  finally
    Qry.Free;
  end;
end;

function TMigrationService.LerArquivoTexto(const AArquivo: string): string;
var
  Bytes: TBytes;
begin
  Bytes := TFile.ReadAllBytes(AArquivo);
  if (Length(Bytes) >= 3) and (Bytes[0] = $EF) and (Bytes[1] = $BB) and (Bytes[2] = $BF) then
    Result := TEncoding.UTF8.GetString(Bytes, 3, Length(Bytes) - 3)
  else
    Result := TEncoding.GetEncoding(1252).GetString(Bytes);
end;

function TMigrationService.PosicaoTerminadorFora(const ABuffer, ATerminador: string): Integer;
var
  I, TamTerm: Integer;
  DentroString: Boolean;
begin
  Result := -1;
  DentroString := False;
  TamTerm := Length(ATerminador);
  I := 1;
  while I <= Length(ABuffer) do
  begin
    if ABuffer[I] = '''' then
    begin
      // Aspas simples duplicadas ('') dentro de uma string sao um escape
      // de aspas literal, nao o fechamento da string.
      if DentroString and (I < Length(ABuffer)) and (ABuffer[I + 1] = '''') then
      begin
        Inc(I, 2);
        Continue;
      end;
      DentroString := not DentroString;
      Inc(I);
      Continue;
    end;

    if (not DentroString) and (I + TamTerm - 1 <= Length(ABuffer)) and
       (Copy(ABuffer, I, TamTerm) = ATerminador) then
    begin
      Result := I - 1;
      Exit;
    end;
    Inc(I);
  end;
end;

function TMigrationService.DividirEmComandos(const ATexto: string): TArray<string>;
var
  Linhas: TArray<string>;
  Linha, LinhaTrim, Terminador, Buffer, Stmt: string;
  Lista: TList<string>;
  Match: TMatch;
  PosTerm: Integer;
begin
  Lista := TList<string>.Create;
  try
    Terminador := ';';
    Buffer := '';
    Linhas := ATexto.Replace(#13#10, #10).Replace(#13, #10).Split([#10]);

    for Linha in Linhas do
    begin
      LinhaTrim := Trim(Linha);

      if LinhaTrim <> '' then
      begin
        Match := TRegEx.Match(LinhaTrim, '^SET\s+TERM\s+(\S+?)\s*(\S+)\s*$', [roIgnoreCase]);
        if Match.Success then
        begin
          Terminador := Match.Groups[1].Value;
          Buffer := '';
          Continue;
        end;
      end;

      Buffer := Buffer + Linha + sLineBreak;

      // Uma mesma linha pode conter mais de um comando separado pelo
      // terminador (ex.: "UPDATE ...; COMMIT WORK;"), entao extrai todos os
      // comandos completos que ja estiverem no buffer, nao so o ultimo.
      // O terminador so conta fora de uma string literal (ex.: LIST(...,
      // ';') usa ';' como argumento, nao como fim de comando).
      PosTerm := PosicaoTerminadorFora(Buffer, Terminador);
      while PosTerm >= 0 do
      begin
        Stmt := Trim(Buffer.Substring(0, PosTerm));
        Buffer := Buffer.Substring(PosTerm + Length(Terminador));
        if Stmt <> '' then
          Lista.Add(Stmt);
        PosTerm := PosicaoTerminadorFora(Buffer, Terminador);
      end;
    end;

    if Trim(Buffer) <> '' then
      Lista.Add(Trim(Buffer));

    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

procedure TMigrationService.ExecutarPendentes(AScripts: TMigrationScriptList; AStopOnError: Boolean;
  AApenasPendentes: Boolean = True);
var
  Script: TMigrationScript;
  Texto: string;
  Comandos: TArray<string>;
  Cmd: string;
  Erro: Boolean;
  JaAplicadoAntes: Boolean;
begin
  FParando := False;
  for Script in AScripts do
  begin
    if FParando then
      Break;
    if AApenasPendentes and (Script.Status <> msPendente) then
      Continue;

    Script.Status := msExecutando;
    AtualizarStatus(Script);
    Log('Executando ' + Script.Codigo + '...');

    Texto := LerArquivoTexto(Script.Arquivo);
    Comandos := DividirEmComandos(Texto);
    Erro := False;
    Script.MensagemErro := '';
    JaAplicadoAntes := ScriptJaAplicado(Script.Codigo);

    for Cmd in Comandos do
    begin
      if DeveIgnorarComando(Cmd) then
        Continue;
      if JaAplicadoAntes and EhInsertNaTabelaScript(Cmd) then
      begin
        Log('  (ja registrado, ignorando INSERT) ' + Script.Codigo);
        Continue;
      end;
      try
        FConnection.ExecSQL(Cmd);
      except
        on E: Exception do
        begin
          Erro := True;
          if Script.MensagemErro <> '' then
            Script.MensagemErro := Script.MensagemErro + sLineBreak;
          Script.MensagemErro := Script.MensagemErro + E.Message;
          ErroComando(Script, Cmd, E.Message);
        end;
      end;
    end;

    if Erro then
    begin
      Script.Status := msErro;
      Log('Erro ao rodar script ' + Script.Codigo);
      if AStopOnError then
        FParando := True;
    end
    else
    begin
      Script.Status := msSucesso;
      Log(Script.Codigo + ' concluido com sucesso.');
    end;
    AtualizarStatus(Script);
  end;
end;

procedure TMigrationService.Parar;
begin
  FParando := True;
end;

end.
