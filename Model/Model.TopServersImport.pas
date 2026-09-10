unit Model.TopServersImport;

interface

uses
  System.SysUtils, System.IOUtils, System.JSON, System.Generics.Collections,
  System.Generics.Defaults;

type
  TTopServerEntry = record
    NomeExibicao: string;
    Host: string;
    Porta: Integer;
    Caminho: string;
    Usuario: string;
  end;

function ListarTopServers(const APasta: string = 'C:\TopSystem\Server'): TArray<TTopServerEntry>;

implementation

const
  ARQUIVO_ATUAL = 'topservers.config';
  PREFIXO_NOMEADO = 'topservers - ';
  SUFIXO_CONFIG = '.config';

function TentaCarregarEntry(const AArquivo: string; out AEntry: TTopServerEntry): Boolean;
var
  Texto: string;
  Raiz, JBanco: TJSONObject;
begin
  Result := False;
  try
    Texto := TFile.ReadAllText(AArquivo, TEncoding.UTF8);
    Raiz := TJSONObject.ParseJSONValue(Texto) as TJSONObject;
    if Raiz = nil then
      Exit;
    try
      if not Raiz.TryGetValue<TJSONObject>('bancoDados', JBanco) then
        Exit;
      AEntry.Host := JBanco.GetValue<string>('host', '');
      AEntry.Porta := JBanco.GetValue<Integer>('porta', 0);
      AEntry.Caminho := JBanco.GetValue<string>('path', '');
      AEntry.Usuario := JBanco.GetValue<string>('usuario', '');
      Result := (AEntry.Host <> '') and (AEntry.Caminho <> '');
    finally
      Raiz.Free;
    end;
  except
    Result := False;
  end;
end;

function ChaveDedup(const AEntry: TTopServerEntry): string;
begin
  Result := LowerCase(AEntry.Host) + ':' + IntToStr(AEntry.Porta) + '|' + LowerCase(AEntry.Caminho);
end;

function ListarTopServers(const APasta: string): TArray<TTopServerEntry>;
var
  Arquivos: TArray<string>;
  Arquivo, Nome: string;
  Entry, Atual: TTopServerEntry;
  TemAtual: Boolean;
  Nomeados: TList<TTopServerEntry>;
  Chaves: TList<string>;
  Chave: string;
  I: Integer;
begin
  Result := [];
  if not TDirectory.Exists(APasta) then
    Exit;

  Arquivos := TDirectory.GetFiles(APasta, 'topservers*.config');
  TemAtual := False;

  Nomeados := TList<TTopServerEntry>.Create;
  Chaves := TList<string>.Create;
  try
    for Arquivo in Arquivos do
    begin
      Nome := TPath.GetFileName(Arquivo);

      if SameText(Nome, ARQUIVO_ATUAL) then
      begin
        if TentaCarregarEntry(Arquivo, Atual) then
        begin
          Atual.NomeExibicao := 'Atual (ativo)';
          TemAtual := True;
        end;
        Continue;
      end;

      if not (SameText(Copy(Nome, 1, Length(PREFIXO_NOMEADO)), PREFIXO_NOMEADO) and
              Nome.EndsWith(SUFIXO_CONFIG, True)) then
        Continue;

      if not TentaCarregarEntry(Arquivo, Entry) then
        Continue;

      Entry.NomeExibicao := Copy(Nome, Length(PREFIXO_NOMEADO) + 1,
        Length(Nome) - Length(PREFIXO_NOMEADO) - Length(SUFIXO_CONFIG));
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
    Nomeados.Free;
    Chaves.Free;
  end;
end;

end.
