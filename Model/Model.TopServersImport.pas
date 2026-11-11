unit Model.TopServersImport;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.JSON,
  System.Generics.Collections, System.Generics.Defaults;

type
  TTopServerEntry = record
    NomeExibicao: string;
    Host: string;
    Porta: Integer;
    Caminho: string;
    Usuario: string;
    Arquivo: string; // arquivo de origem
    EhAtual: Boolean; // True = topservers.config (o que o sistema le)
  end;

const
  PASTA_SERVER_PADRAO = 'C:\TopSystem\Server';

// Le o topservers.config (Atual) + os arquivos nomeados em
// <pasta>\bases\*.config e, por compatibilidade, os
// "topservers - NOME.config" soltos na raiz. Arquivos invalidos sao
// descritos em AAvisos (opcional).
function ListarTopServers(const APasta: string = PASTA_SERVER_PADRAO;
  AAvisos: TStrings = nil): TArray<TTopServerEntry>;

// Nome da base nomeada que coincide com o topservers.config atual ('' se nenhuma).
function NomeBaseAtiva(const ALista: TArray<TTopServerEntry>): string;

// Move os "topservers - *.config" soltos da raiz para a subpasta bases.
// Nunca mexe no topservers.config. Retorna quantos foram movidos.
function MigrarArquivosSoltos(const APasta: string = PASTA_SERVER_PADRAO): Integer;

// Grava no topservers.config os dados de banco da entrada escolhida,
// preservando o restante do JSON. Faz backup antes e grava de forma atomica.
// Retorna o caminho do backup.
function AtivarTopServer(const AEntry: TTopServerEntry;
  const APasta: string = PASTA_SERVER_PADRAO): string;

function PastaBases(const APasta: string = PASTA_SERVER_PADRAO): string;

implementation

uses
  Winapi.Windows;

const
  ARQUIVO_ATUAL = 'topservers.config';
  PREFIXO_NOMEADO = 'topservers - ';
  SUFIXO_CONFIG = '.config';
  MAX_BACKUPS = 10;

function PastaBases(const APasta: string): string;
begin
  Result := TPath.Combine(APasta, 'bases');
end;

function PastaBackup(const APasta: string): string;
begin
  Result := TPath.Combine(PastaBases(APasta), '_backup');
end;

function TentaCarregarEntry(const AArquivo: string; out AEntry: TTopServerEntry;
  out AMotivo: string): Boolean;
var
  Texto: string;
  Raiz, JBanco: TJSONObject;
begin
  Result := False;
  AMotivo := '';
  AEntry := Default(TTopServerEntry);
  try
    Texto := TFile.ReadAllText(AArquivo, TEncoding.UTF8);
    Raiz := TJSONObject.ParseJSONValue(Texto) as TJSONObject;
    if Raiz = nil then
    begin
      AMotivo := 'JSON invalido';
      Exit;
    end;
    try
      if not Raiz.TryGetValue<TJSONObject>('bancoDados', JBanco) then
      begin
        AMotivo := 'sem o bloco "bancoDados"';
        Exit;
      end;
      AEntry.Host := JBanco.GetValue<string>('host', '');
      AEntry.Porta := JBanco.GetValue<Integer>('porta', 0);
      AEntry.Caminho := JBanco.GetValue<string>('path', '');
      AEntry.Usuario := JBanco.GetValue<string>('usuario', '');
      AEntry.Arquivo := AArquivo;
      Result := (AEntry.Host <> '') and (AEntry.Caminho <> '');
      if not Result then
        AMotivo := 'host ou path vazio';
    finally
      Raiz.Free;
    end;
  except
    on E: Exception do
    begin
      Result := False;
      AMotivo := E.Message;
    end;
  end;
end;

function ChaveDedup(const AEntry: TTopServerEntry): string;
begin
  Result := LowerCase(AEntry.Host) + ':' + IntToStr(AEntry.Porta) + '|' + LowerCase(AEntry.Caminho);
end;

function NomeDeExibicao(const AArquivo: string): string;
begin
  Result := TPath.GetFileNameWithoutExtension(AArquivo);
  if SameText(Copy(Result, 1, Length(PREFIXO_NOMEADO)), PREFIXO_NOMEADO) then
    Result := Copy(Result, Length(PREFIXO_NOMEADO) + 1, MaxInt);
end;

function ListarTopServers(const APasta: string; AAvisos: TStrings): TArray<TTopServerEntry>;
var
  Arquivos: TList<string>;
  Arquivo, Motivo, Pasta: string;
  Entry, Atual: TTopServerEntry;
  TemAtual: Boolean;
  Nomeados: TList<TTopServerEntry>;
  Chaves: TList<string>;
  Chave: string;
  I: Integer;

  procedure Aviso(const AArq, AMotivo: string);
  begin
    if AAvisos <> nil then
      AAvisos.Add(Format('%s ignorado: %s', [AArq, AMotivo]));
  end;

begin
  Result := [];
  if not TDirectory.Exists(APasta) then
    Exit;

  TemAtual := False;
  Arquivos := TList<string>.Create;
  Nomeados := TList<TTopServerEntry>.Create;
  Chaves := TList<string>.Create;
  try
    // atual
    Arquivo := TPath.Combine(APasta, ARQUIVO_ATUAL);
    if TFile.Exists(Arquivo) then
    begin
      if TentaCarregarEntry(Arquivo, Atual, Motivo) then
      begin
        Atual.NomeExibicao := 'Atual (ativo)';
        Atual.EhAtual := True;
        TemAtual := True;
      end
      else
        Aviso(ARQUIVO_ATUAL, Motivo);
    end;

    // nomeados: subpasta bases + soltos na raiz (compatibilidade)
    Pasta := PastaBases(APasta);
    if TDirectory.Exists(Pasta) then
      Arquivos.AddRange(TDirectory.GetFiles(Pasta, '*' + SUFIXO_CONFIG));
    Arquivos.AddRange(TDirectory.GetFiles(APasta, PREFIXO_NOMEADO + '*' + SUFIXO_CONFIG));

    for Arquivo in Arquivos do
    begin
      if not TentaCarregarEntry(Arquivo, Entry, Motivo) then
      begin
        Aviso(TPath.GetFileName(Arquivo), Motivo);
        Continue;
      end;
      Entry.NomeExibicao := NomeDeExibicao(Arquivo);
      Nomeados.Add(Entry);
    end;

    Nomeados.Sort(TComparer<TTopServerEntry>.Construct(
      function(const L, R: TTopServerEntry): Integer
      begin
        Result := CompareText(L.NomeExibicao, R.NomeExibicao);
      end));

    if TemAtual then
      Result := Result + [Atual];

    for I := 0 to Nomeados.Count - 1 do
    begin
      Chave := ChaveDedup(Nomeados[I]);
      if Chaves.Contains(Chave) then
        Continue;
      Chaves.Add(Chave);
      Result := Result + [Nomeados[I]];
    end;
  finally
    Arquivos.Free;
    Nomeados.Free;
    Chaves.Free;
  end;
end;

function NomeBaseAtiva(const ALista: TArray<TTopServerEntry>): string;
var
  Atual, E: TTopServerEntry;
  TemAtual: Boolean;
begin
  Result := '';
  TemAtual := False;
  for E in ALista do
    if E.EhAtual then
    begin
      Atual := E;
      TemAtual := True;
      Break;
    end;
  if not TemAtual then
    Exit;
  for E in ALista do
    if (not E.EhAtual) and (ChaveDedup(E) = ChaveDedup(Atual)) then
      Exit(E.NomeExibicao);
end;

function MigrarArquivosSoltos(const APasta: string): Integer;
var
  Pasta, Arquivo, Destino: string;
begin
  Result := 0;
  if not TDirectory.Exists(APasta) then
    Exit;
  Pasta := PastaBases(APasta);
  for Arquivo in TDirectory.GetFiles(APasta, PREFIXO_NOMEADO + '*' + SUFIXO_CONFIG) do
  begin
    if SameText(TPath.GetFileName(Arquivo), ARQUIVO_ATUAL) then
      Continue;
    TDirectory.CreateDirectory(Pasta);
    Destino := TPath.Combine(Pasta, TPath.GetFileName(Arquivo));
    if TFile.Exists(Destino) then
      Continue; // nao sobrescreve
    TFile.Move(Arquivo, Destino);
    Inc(Result);
  end;
end;

procedure PodarBackups(const APasta: string);
var
  Arqs: TArray<string>;
  I: Integer;
begin
  Arqs := TDirectory.GetFiles(PastaBackup(APasta), ARQUIVO_ATUAL + '.bak-*');
  TArray.Sort<string>(Arqs); // carimbo yyyymmdd-hhnnss ordena cronologicamente
  for I := 0 to Length(Arqs) - MAX_BACKUPS - 1 do
    TFile.Delete(Arqs[I]);
end;

function AtivarTopServer(const AEntry: TTopServerEntry; const APasta: string): string;
const
  CAMPOS: array[0..4] of string = ('host', 'porta', 'path', 'usuario', 'senha');
var
  Atual, Temp: string;
  JOrigem, JAtual, BancoOrigem, BancoAtual: TJSONObject;
  Campo: string;
  Valor: TJSONValue;
  Texto: string;
begin
  if AEntry.EhAtual then
    raise Exception.Create('Esta entrada ja e o topservers.config atual.');
  if not TFile.Exists(AEntry.Arquivo) then
    raise Exception.CreateFmt('Arquivo de origem nao encontrado: %s', [AEntry.Arquivo]);

  Atual := TPath.Combine(APasta, ARQUIVO_ATUAL);
  if not TFile.Exists(Atual) then
    raise Exception.CreateFmt('%s nao encontrado em %s', [ARQUIVO_ATUAL, APasta]);

  JOrigem := TJSONObject.ParseJSONValue(TFile.ReadAllText(AEntry.Arquivo, TEncoding.UTF8)) as TJSONObject;
  if JOrigem = nil then
    raise Exception.Create('Arquivo de origem nao e um JSON valido.');
  try
    JAtual := TJSONObject.ParseJSONValue(TFile.ReadAllText(Atual, TEncoding.UTF8)) as TJSONObject;
    if JAtual = nil then
      raise Exception.Create('topservers.config atual nao e um JSON valido.');
    try
      if not JOrigem.TryGetValue<TJSONObject>('bancoDados', BancoOrigem) then
        raise Exception.Create('Arquivo de origem sem o bloco "bancoDados".');
      if not JAtual.TryGetValue<TJSONObject>('bancoDados', BancoAtual) then
        raise Exception.Create('topservers.config atual sem o bloco "bancoDados".');

      // backup antes de qualquer escrita
      TDirectory.CreateDirectory(PastaBackup(APasta));
      Result := TPath.Combine(PastaBackup(APasta),
        ARQUIVO_ATUAL + '.bak-' + FormatDateTime('yyyymmdd-hhnnss', Now));
      TFile.Copy(Atual, Result, True);

      // copia so os campos de conexao; o resto do JSON fica intacto
      for Campo in CAMPOS do
      begin
        Valor := BancoOrigem.GetValue(Campo);
        if Valor = nil then
          Continue;
        BancoAtual.RemovePair(Campo).Free;
        BancoAtual.AddPair(Campo, Valor.Clone as TJSONValue);
      end;

      Texto := JAtual.Format(2);
    finally
      JAtual.Free;
    end;
  finally
    JOrigem.Free;
  end;

  // gravacao atomica: temp na mesma pasta + substituicao
  Temp := Atual + '.tmp';
  TFile.WriteAllBytes(Temp, TEncoding.UTF8.GetBytes(Texto)); // UTF-8 sem BOM
  if not MoveFileEx(PChar(Temp), PChar(Atual), MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then
  begin
    TFile.Delete(Temp);
    RaiseLastOSError;
  end;

  PodarBackups(APasta);
end;

end.
