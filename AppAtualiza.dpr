program AppAtualiza;

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  System.SysUtils,
  System.IOUtils,
  FireDAC.VCLUI.Wait,
  View.Main in 'View\View.Main.pas' {frmMain},
  Controller.Main in 'Controller\Controller.Main.pas',
  Model.Config in 'Model\Model.Config.pas',
  Model.MigrationScript in 'Model\Model.MigrationScript.pas',
  Model.MigrationService in 'Model\Model.MigrationService.pas',
  Model.TopServersImport in 'Model\Model.TopServersImport.pas';

{$R AppAtualiza.res}

function EstiloJaExistia(const ANome: string; const ANomes: TArray<string>): Boolean;
var
  N: string;
begin
  Result := False;
  for N in ANomes do
    if SameText(N, ANome) then
      Exit(True);
end;

var
  PastaEstilos: string;
  CaminhoEstiloPadrao: string;
  NomesAntes: TArray<string>;
  NomeEstiloPadrao: string;
  NomeEstilo: string;
  Arquivos: TArray<string>;
  Arquivo: string;

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  PastaEstilos := ExtractFilePath(ParamStr(0)) + 'Styles';

  // Carrega o estilo padrao primeiro, para descobrir seu nome interno
  // (o nome interno de um .vsf nao e o nome do arquivo) e deixa-lo ativo.
  CaminhoEstiloPadrao := TPath.Combine(PastaEstilos, 'Windows10Purple.vsf');
  NomeEstiloPadrao := '';
  if FileExists(CaminhoEstiloPadrao) then
  begin
    NomesAntes := TStyleManager.StyleNames;
    try
      TStyleManager.LoadFromFile(CaminhoEstiloPadrao);
      for NomeEstilo in TStyleManager.StyleNames do
        if not EstiloJaExistia(NomeEstilo, NomesAntes) then
        begin
          NomeEstiloPadrao := NomeEstilo;
          Break;
        end;
    except
      // segue sem estilo customizado se o .vsf nao puder ser carregado
    end;
  end;

  // Carrega os demais .vsf da pasta, para ficarem disponiveis no combobox
  // de temas (a troca em tempo real e feita em View.Main).
  if TDirectory.Exists(PastaEstilos) then
  begin
    Arquivos := TDirectory.GetFiles(PastaEstilos, '*.vsf');
    for Arquivo in Arquivos do
      if not SameText(Arquivo, CaminhoEstiloPadrao) then
        try
          TStyleManager.LoadFromFile(Arquivo);
        except
          // ignora arquivo de estilo invalido
        end;
  end;

  if NomeEstiloPadrao <> '' then
    TStyleManager.TrySetStyle(NomeEstiloPadrao);

  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
