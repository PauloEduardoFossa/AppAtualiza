unit Model.MigrationScript;

interface

uses
  System.Generics.Collections;

type
  TMigrationStatus = (msPendente, msAplicado, msExecutando, msSucesso, msErro);

  TMigrationScript = class
  private
    FCodigo: string;
    FArquivo: string;
    FStatus: TMigrationStatus;
    FMensagemErro: string;
  public
    constructor Create(const ACodigo, AArquivo: string);
    property Codigo: string read FCodigo;
    property Arquivo: string read FArquivo;
    property Status: TMigrationStatus read FStatus write FStatus;
    property MensagemErro: string read FMensagemErro write FMensagemErro;
  end;

  TMigrationScriptList = class(TObjectList<TMigrationScript>)
  end;

function StatusDescricao(AStatus: TMigrationStatus): string;

implementation

function StatusDescricao(AStatus: TMigrationStatus): string;
begin
  case AStatus of
    msPendente:
      Result := 'Pendente';
    msAplicado:
      Result := 'Aplicado';
    msExecutando:
      Result := 'Executando...';
    msSucesso:
      Result := 'Sucesso';
    msErro:
      Result := 'Erro';
  else
    Result := '?';
  end;
end;

{ TMigrationScript }

constructor TMigrationScript.Create(const ACodigo, AArquivo: string);
begin
  inherited Create;
  FCodigo := ACodigo;
  FArquivo := AArquivo;
  FStatus := msPendente;
end;

end.
