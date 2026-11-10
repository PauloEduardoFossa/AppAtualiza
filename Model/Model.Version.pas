unit Model.Version;

{ Versao do aplicativo: SUBSTITUICAO.DISPONIBILIZACAO.RELEASE

  - SUBSTITUICAO: sobe quando a mudanca exige apagar todos os arquivos e copiar
    de novo (formato do config.json/historico de estorno, pastas, Styles...).
  - DISPONIBILIZACAO: sobe a cada versao entregue para uso.
  - RELEASE: contador de builds, incrementado sozinho pelo build.bat
    (Assets\gerar_versao.ps1 grava Assets\build.number e Model.Version.Build.inc).

  Alterar so os dois primeiros numeros, a mao, aqui. }

interface

const
  VERSAO_SUBSTITUICAO = 1;
  VERSAO_DISPONIBILIZACAO = 0;
  {$I Model.Version.Build.inc}

function VersaoTexto: string;

implementation

uses
  System.SysUtils;

function VersaoTexto: string;
begin
  Result := Format('%d.%d.%d', [VERSAO_SUBSTITUICAO, VERSAO_DISPONIBILIZACAO, VERSAO_RELEASE]);
end;

end.
