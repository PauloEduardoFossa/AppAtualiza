program AppAtualiza;

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  System.SysUtils,
  System.StrUtils,
  FireDAC.VCLUI.Wait,
  View.Main in 'View\View.Main.pas' {frmMain},
  View.GlyphIcons in 'View\View.GlyphIcons.pas',
  Controller.Main in 'Controller\Controller.Main.pas',
  Model.Config in 'Model\Model.Config.pas',
  Model.MigrationScript in 'Model\Model.MigrationScript.pas',
  Model.MigrationService in 'Model\Model.MigrationService.pas',
  Model.TopServersImport in 'Model\Model.TopServersImport.pas',
  Model.TopServersCrypto in 'Model\Model.TopServersCrypto.pas',
  Model.UndoBuilder in 'Model\Model.UndoBuilder.pas',
  Model.UndoStore in 'Model\Model.UndoStore.pas',
  Model.Version in 'Model\Model.Version.pas';

{$R Assets\AppAtualiza.res}
{$R Assets\Versao.res}

// Tema fixo (Amethyst Kamri), embutido no exe como recurso VCLSTYLE
// (Assets\AppAtualiza.rc). A VCL registra sozinha, na inicializacao, os estilos
// embutidos; o nome interno nao e o nome do arquivo, entao procura-se por "Amethyst".
procedure AplicarTemaEmbutido;
var
  Nome: string;
begin
  for Nome in TStyleManager.StyleNames do
    if ContainsText(Nome, 'Amethyst') then
    begin
      TStyleManager.TrySetStyle(Nome);
      Exit;
    end;
end;
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  AplicarTemaEmbutido;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
