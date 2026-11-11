unit View.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, Winapi.MultiMon, System.SysUtils, System.Variants,
  System.Classes, System.IOUtils, System.Generics.Collections, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.FileCtrl, Vcl.Menus,
  Vcl.Themes, System.UITypes, Controller.Main, Model.MigrationScript, Model.Config,
  Model.TopServersImport, Model.TopServersCrypto, View.GlyphIcons, Model.MigrationService, Model.Version;

type
  TfrmMain = class(TForm)
    pnlHeader: TPanel;
    lblTitulo: TLabel;
    lblVersao: TLabel;
    lblSubtitulo: TLabel;
    btnMaximizar: TButton;
    btnFechar: TButton;
    pnlSidebar: TPanel;
    lblSecaoBanco: TLabel;
    lblClienteBase: TLabel;
    cbxClienteBase: TComboBox;
    btnRecarregarBases: TButton;
    btnAtivarBase: TButton;
    lblMigrarBases: TLabel;
    lblServidor: TLabel;
    edtServidor: TEdit;
    lblPorta: TLabel;
    edtPorta: TEdit;
    lblCaminhoBanco: TLabel;
    edtCaminhoBanco: TEdit;
    btnBrowseBanco: TButton;
    lblUsuario: TLabel;
    edtUsuario: TEdit;
    lblSenha: TLabel;
    edtSenha: TEdit;
    lblCharset: TLabel;
    cbxCharset: TComboBox;
    lblFbClient: TLabel;
    edtFbClient: TEdit;
    btnBrowseFbClient: TButton;
    lblSecaoScripts: TLabel;
    lblVersaoScripts: TLabel;
    cbxVersaoScripts: TComboBox;
    lblPastaScripts: TLabel;
    edtPastaScripts: TEdit;
    btnBrowsePastaScripts: TButton;
    chkPararErro: TCheckBox;
    btnTestarConexao: TButton;
    btnSalvarConfig: TButton;
    lblStatusConexao: TLabel;
    pnlConteudo: TPanel;
    pnlToolbar: TPanel;
    btnAtualizarLista: TButton;
    btnExecutar: TButton;
    btnParar: TButton;
    btnProximaVersao: TButton;
    btnVersaoAnterior: TButton;
    pnlCards: TPanel;
    pnlCardTotal: TPanel;
    lblCardTotalValor: TLabel;
    lblCardTotalTitulo: TLabel;
    pnlCardPendentes: TPanel;
    lblCardPendentesValor: TLabel;
    lblCardPendentesTitulo: TLabel;
    pnlCardAplicados: TPanel;
    lblCardAplicadosValor: TLabel;
    lblCardAplicadosTitulo: TLabel;
    pnlCardErros: TPanel;
    lblCardErrosValor: TLabel;
    lblCardErrosTitulo: TLabel;
    pnlCardUltimo: TPanel;
    lblCardUltimoValor: TLabel;
    lblCardUltimoTitulo: TLabel;
    lvScripts: TListView;
    pmScripts: TPopupMenu;
    miExcluirScript: TMenuItem;
    miAbrirDiretorio: TMenuItem;
    miDesmarcarTodos: TMenuItem;
    miEstornarScript: TMenuItem;
    miExecutarScript: TMenuItem;
    pmLog: TPopupMenu;
    miLimparLog: TMenuItem;
    pnlLog: TPanel;
    lblLogTitulo: TLabel;
    memoLog: TMemo;
    btnAbrirLogErros: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnAbrirLogErrosClick(Sender: TObject);
    procedure btnBrowseBancoClick(Sender: TObject);
    procedure btnBrowseFbClientClick(Sender: TObject);
    procedure btnBrowsePastaScriptsClick(Sender: TObject);
    procedure btnTestarConexaoClick(Sender: TObject);
    procedure btnSalvarConfigClick(Sender: TObject);
    procedure btnAtualizarListaClick(Sender: TObject);
    procedure btnExecutarClick(Sender: TObject);
    procedure btnPararClick(Sender: TObject);
    procedure btnProximaVersaoClick(Sender: TObject);
    procedure btnVersaoAnteriorClick(Sender: TObject);
    procedure SelecionarVersao(ADelta: Integer);
    procedure btnFecharClick(Sender: TObject);
    procedure btnMaximizarClick(Sender: TObject);
    procedure pnlHeaderMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure lvScriptsMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure lvScriptsDblClick(Sender: TObject);
    procedure miAbrirDiretorioClick(Sender: TObject);
    procedure pmScriptsPopup(Sender: TObject);
    procedure miExcluirScriptClick(Sender: TObject);
    procedure miDesmarcarTodosClick(Sender: TObject);
    procedure miEstornarScriptClick(Sender: TObject);
    procedure miExecutarScriptClick(Sender: TObject);
    procedure miLimparLogClick(Sender: TObject);
    procedure cbxClienteBaseChange(Sender: TObject);
    procedure btnRecarregarBasesClick(Sender: TObject);
    procedure btnAtivarBaseClick(Sender: TObject);
    procedure btnMigrarBasesClick(Sender: TObject);
    procedure PreencherVersoes(const ASelecionada: string);
    procedure cbxVersaoScriptsChange(Sender: TObject);
    procedure cbxVersaoScriptsDropDown(Sender: TObject);
  private
    FController: TMainController;
    FTopServers: TArray<TTopServerEntry>;
    FRaizVersoes: string;
    procedure ConfigParaTela;
    procedure TelaParaConfig;
    procedure AtualizarCards;
    procedure RecarregarGrid;
    procedure CarregarClientesBase;
    procedure CarregarVersoesScripts;
    procedure ConfigurarIcones;
    function ItemDoScript(AScript: TMigrationScript): TListItem;
    function ScriptsAlvo: TArray<TMigrationScript>;
    procedure AppendLog(const AMsg: string);
    procedure HabilitarControles(AHabilitado: Boolean);
    procedure WMGetMinMaxInfo(var Msg: TWMGetMinMaxInfo); message WM_GETMINMAXINFO;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.WMGetMinMaxInfo(var Msg: TWMGetMinMaxInfo);
var
  hMon: HMONITOR;
  Info: TMonitorInfo;
begin
  inherited;
  // Sem borda, o Windows maximiza sobre o monitor inteiro; limita a area de trabalho
  // (respeita a barra de tarefas) do monitor onde a janela esta. Consulta a API a cada
  // chamada (nao o Screen.Monitors do VCL, que pode ficar defasado ao trocar de monitor).
  if not HandleAllocated then
    Exit;
  hMon := MonitorFromWindow(Handle, MONITOR_DEFAULTTONEAREST);
  Info.cbSize := SizeOf(Info);
  if not GetMonitorInfo(hMon, @Info) then
    Exit;
  Msg.MinMaxInfo^.ptMaxPosition.X := Info.rcWork.Left - Info.rcMonitor.Left;
  Msg.MinMaxInfo^.ptMaxPosition.Y := Info.rcWork.Top - Info.rcMonitor.Top;
  Msg.MinMaxInfo^.ptMaxSize.X := Info.rcWork.Right - Info.rcWork.Left;
  Msg.MinMaxInfo^.ptMaxSize.Y := Info.rcWork.Bottom - Info.rcWork.Top;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FController := TMainController.Create;
  lblVersao.Caption := 'v' + VersaoTexto;
  lvScripts.HideSelection := False;
  FController.OnLog := AppendLog;
  FController.OnScriptStatus :=
    procedure(AScript: TMigrationScript)
    var
      Item: TListItem;
    begin
      Item := ItemDoScript(AScript);
      if Item <> nil then
      begin
        Item.SubItems[1] := StatusDescricao(AScript.Status);
        if AScript.Status = msExecutando then
        begin
          lvScripts.Selected := Item;
          Item.MakeVisible(False);
        end;
      end;
      AtualizarCards;
    end;
  FController.OnFimExecucao :=
    procedure
    begin
      HabilitarControles(True);
      AppendLog('Execu'#231#227'o finalizada.');
    end;

  FController.CarregarConfiguracao;
  ConfigParaTela;
  CarregarClientesBase;
  CarregarVersoesScripts;
  ConfigurarIcones;
end;

// Icones dos botoes (glifos da Segoe MDL2 Assets, gerados em tempo de execucao).
// Sem a fonte (Windows antigo) os botoes ficam so com texto.
procedure TfrmMain.ConfigurarIcones;
type
  TIcone = record
    Botao: TButton;
    Glifo: Word;
    Cor: TColor;
    SoIcone: Boolean;
    Dica: string;
  end;
var
  Neutra, Desab: TColor;

  function Ic(ABotao: TButton; AGlifo: Word; ACor: TColor; ASoIcone: Boolean = False;
    const ADica: string = ''): TIcone;
  begin
    Result.Botao := ABotao;
    Result.Glifo := AGlifo;
    Result.Cor := ACor;
    Result.SoIcone := ASoIcone;
    Result.Dica := ADica;
  end;

  // Cria uma lista de imagens para o grupo e a aplica nos botoes do grupo.
  procedure Aplicar(const AItens: array of TIcone; ATamanho, AMargemEsq: Integer);
  var
    Lista: TImageList;
    Glifos: array of Word;
    Cores: array of TColor;
    I, N: Integer;
  begin
    N := Length(AItens);
    SetLength(Glifos, N);
    SetLength(Cores, N);
    for I := 0 to N - 1 do
    begin
      Glifos[I] := AItens[I].Glifo;
      Cores[I] := AItens[I].Cor;
    end;
    Lista := CriarImageListGlifos(Self, Glifos, Cores, ATamanho, Desab);
    for I := 0 to N - 1 do
      with AItens[I].Botao do
      begin
        Images := Lista;
        ImageIndex := I;
        DisabledImageIndex := N + I;
        if AItens[I].SoIcone then
        begin
          Caption := '';
          ImageAlignment := TImageAlignment.iaCenter;
          if AItens[I].Dica <> '' then
          begin
            Hint := AItens[I].Dica;
            ShowHint := True;
          end;
        end
        else
        begin
          ImageAlignment := TImageAlignment.iaLeft;
          ImageMargins.Left := AMargemEsq;
          ImageMargins.Right := 4;
        end;
      end;
  end;

begin
  if not FonteDeIconesDisponivel then
    Exit;
  Neutra := TStyleManager.ActiveStyle.GetStyleFontColor(sfButtonTextNormal);
  Desab := TStyleManager.ActiveStyle.GetStyleFontColor(sfButtonTextDisabled);

  // Botoes grandes (32 px de altura), com texto
  Aplicar([
    Ic(btnAtualizarLista, $E72C, RGB(100, 181, 246)),            // Sync
    Ic(btnVersaoAnterior, $E76B, Neutra, True),                  // ChevronLeft
    Ic(btnProximaVersao, $E76C, Neutra, True),                   // ChevronRight
    Ic(btnExecutar, $E102, RGB(76, 175, 80)),                    // Play
    Ic(btnParar, $E71A, RGB(239, 83, 80)),                       // Stop
    Ic(btnAtivarBase, $E73E, RGB(76, 175, 80)),                  // CheckMark
    Ic(btnTestarConexao, $E839, RGB(100, 181, 246)),             // Rede
    Ic(btnSalvarConfig, $E74E, Neutra),                          // Save
    Ic(btnAbrirLogErros, $E7BA, RGB(255, 183, 77))               // Warning
  ], 20, 12);

  // Botoes pequenos (so icone)
  Aplicar([
    Ic(btnRecarregarBases, $E72C, RGB(100, 181, 246), True, 'Recarregar lista de bases'),
    Ic(btnBrowseBanco, $E8A5, Neutra, True, 'Selecionar o arquivo do banco'),
    Ic(btnBrowseFbClient, $E8A5, Neutra, True, 'Selecionar o fbclient.dll'),
    Ic(btnBrowsePastaScripts, $E838, Neutra, True, 'Selecionar a pasta dos scripts'),
    Ic(btnMaximizar, $E922, Neutra, True, 'Maximizar / restaurar'),
    Ic(btnFechar, $E8BB, Neutra, True, 'Fechar')
  ], 16, 0);
end;
procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FController.Free;
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = Ord('A')) and (ActiveControl is TCustomEdit) then
  begin
    TCustomEdit(ActiveControl).SelectAll;
    Key := 0;
  end;
end;

procedure TfrmMain.btnAbrirLogErrosClick(Sender: TObject);
begin
  if not FController.TemLogErros then
  begin
    MessageDlg('Nenhum erro registrado nesta execu'#231#227'o.', mtInformation, [mbOK], 0);
    Exit;
  end;
  ShellExecute(0, 'open', PChar(FController.ArquivoLogErros), nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmMain.ConfigParaTela;
begin
  edtServidor.Text := FController.Config.DB.Server;
  edtPorta.Text := IntToStr(FController.Config.DB.Port);
  edtCaminhoBanco.Text := FController.Config.DB.DatabasePath;
  edtUsuario.Text := FController.Config.DB.UserName;
  edtSenha.Text := FController.Config.DB.Password;
  if cbxCharset.Items.IndexOf(FController.Config.DB.CharacterSet) >= 0 then
    cbxCharset.ItemIndex := cbxCharset.Items.IndexOf(FController.Config.DB.CharacterSet)
  else
    cbxCharset.ItemIndex := 0;
  edtFbClient.Text := FController.Config.DB.FbClientPath;
  edtPastaScripts.Text := FController.Config.ScriptsFolder;
  FRaizVersoes := ExcludeTrailingPathDelimiter(FController.Config.ScriptsRoot);
  PreencherVersoes(FController.Config.ScriptsVersion);
  chkPararErro.Checked := FController.Config.StopOnError;
end;

procedure TfrmMain.TelaParaConfig;
var
  DB: TDBConfig;
begin
  DB := FController.Config.DB;
  DB.Server := Trim(edtServidor.Text);
  DB.Port := StrToIntDef(Trim(edtPorta.Text), 3050);
  DB.DatabasePath := Trim(edtCaminhoBanco.Text);
  DB.UserName := Trim(edtUsuario.Text);
  DB.Password := edtSenha.Text;
  if cbxCharset.ItemIndex >= 0 then
    DB.CharacterSet := cbxCharset.Items[cbxCharset.ItemIndex]
  else
    DB.CharacterSet := 'NONE';
  DB.FbClientPath := Trim(edtFbClient.Text);
  FController.Config.DB := DB;
  FController.Config.ScriptsFolder := Trim(edtPastaScripts.Text);
  if (FRaizVersoes <> '') and (cbxVersaoScripts.ItemIndex >= 0) and
     SameText(ExcludeTrailingPathDelimiter(Trim(edtPastaScripts.Text)),
              TPath.Combine(FRaizVersoes, cbxVersaoScripts.Items[cbxVersaoScripts.ItemIndex])) then
  begin
    FController.Config.ScriptsRoot := FRaizVersoes;
    FController.Config.ScriptsVersion := cbxVersaoScripts.Items[cbxVersaoScripts.ItemIndex];
  end
  else
  begin
    FController.Config.ScriptsRoot := Trim(edtPastaScripts.Text);
    FController.Config.ScriptsVersion := '';
  end;
  FController.Config.StopOnError := chkPararErro.Checked;
  if cbxClienteBase.ItemIndex >= 0 then
    FController.Config.ClientName := cbxClienteBase.Items[cbxClienteBase.ItemIndex]
  else
    FController.Config.ClientName := '';
end;

procedure TfrmMain.CarregarClientesBase;
var
  Entry: TTopServerEntry;
  Avisos: TStringList;
  Aviso, Ativa, Selecionado: string;
  Soltos: Integer;
begin
  Selecionado := cbxClienteBase.Text;
  if Selecionado = '' then
    Selecionado := FController.Config.ClientName;

  Avisos := TStringList.Create;
  try
    FTopServers := ListarTopServers(PASTA_SERVER_PADRAO, Avisos);
    for Aviso in Avisos do
      AppendLog('Bases: ' + Aviso);
  finally
    Avisos.Free;
  end;

  cbxClienteBase.Items.Clear;
  for Entry in FTopServers do
    cbxClienteBase.Items.Add(Entry.NomeExibicao);
  cbxClienteBase.Enabled := cbxClienteBase.Items.Count > 0;
  cbxClienteBase.ItemIndex := cbxClienteBase.Items.IndexOf(Selecionado);

  Ativa := NomeBaseAtiva(FTopServers);
  if Ativa <> '' then
    lblClienteBase.Caption := 'Cliente/Base (ativa: ' + Ativa + ')'
  else
    lblClienteBase.Caption := 'Cliente/Base';

  Soltos := 0;
  if TDirectory.Exists(PASTA_SERVER_PADRAO) then
    Soltos := Length(TDirectory.GetFiles(PASTA_SERVER_PADRAO, 'topservers - *.config'));
  lblMigrarBases.Visible := Soltos > 0;
  lblMigrarBases.Caption := Format('Migrar %d soltos', [Soltos]);
  btnAtivarBase.Enabled := cbxClienteBase.Items.Count > 0;
end;

procedure TfrmMain.btnRecarregarBasesClick(Sender: TObject);
begin
  CarregarClientesBase;
  AppendLog(Format('Bases recarregadas (%d).', [Length(FTopServers)]));
end;

procedure TfrmMain.btnMigrarBasesClick(Sender: TObject);
var
  Qtde: Integer;
begin
  if MessageDlg('Mover os arquivos "topservers - *.config" soltos em ' + PASTA_SERVER_PADRAO +
    ' para ' + PastaBases + '?'#13#10'O topservers.config n'#227'o '#233' alterado.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  try
    Qtde := MigrarArquivosSoltos;
    AppendLog(Format('%d arquivo(s) movido(s) para %s.', [Qtde, PastaBases]));
  except
    on E: Exception do
      MessageDlg('Falha ao migrar: ' + E.Message, mtError, [mbOK], 0);
  end;
  CarregarClientesBase;
end;

procedure TfrmMain.btnAtivarBaseClick(Sender: TObject);
var
  Entry: TTopServerEntry;
  Backup: string;
begin
  if (cbxClienteBase.ItemIndex < 0) or (cbxClienteBase.ItemIndex >= Length(FTopServers)) then
  begin
    MessageDlg('Selecione uma base na lista.', mtInformation, [mbOK], 0);
    Exit;
  end;
  Entry := FTopServers[cbxClienteBase.ItemIndex];
  if Entry.EhAtual then
  begin
    MessageDlg('Esta '#233' a base que j'#225' est'#225' ativa (topservers.config).', mtInformation, [mbOK], 0);
    Exit;
  end;
  try
    Backup := AtivarTopServer(Entry);
    AppendLog(Format('topservers.config agora aponta para "%s". Backup: %s',
      [Entry.NomeExibicao, Backup]));
  except
    on E: Exception do
    begin
      MessageDlg('Falha ao ativar a base: ' + E.Message, mtError, [mbOK], 0);
      Exit;
    end;
  end;
  CarregarClientesBase;
end;

procedure TfrmMain.cbxClienteBaseChange(Sender: TObject);
var
  Entry: TTopServerEntry;
begin
  if (cbxClienteBase.ItemIndex < 0) or (cbxClienteBase.ItemIndex >= Length(FTopServers)) then
    Exit;
  Entry := FTopServers[cbxClienteBase.ItemIndex];
  edtServidor.Text := Entry.Host;
  edtPorta.Text := IntToStr(Entry.Porta);
  edtCaminhoBanco.Text := Entry.Caminho;
  edtUsuario.Text := Entry.Usuario;
  try
    edtSenha.Text := DescriptografarSenhaTopServer(Entry.SenhaCifrada,
      FController.Config.TopServersKey);
  except
    on E: Exception do
    begin
      edtSenha.Text := '';
      AppendLog('N'#227'o foi poss'#237'vel ler a senha de "' + Entry.NomeExibicao + '": ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.CarregarVersoesScripts;
var
  Pasta, Selecionada: string;
begin
  Pasta := Trim(edtPastaScripts.Text);
  Selecionada := '';
  if cbxVersaoScripts.ItemIndex >= 0 then
    Selecionada := cbxVersaoScripts.Items[cbxVersaoScripts.ItemIndex];

  // Se o campo so aponta para a versao escolhida no combo, a raiz continua
  // a mesma (senao listaria as subpastas da propria versao).
  if not ((FRaizVersoes <> '') and (Selecionada <> '') and
          SameText(ExcludeTrailingPathDelimiter(Pasta),
                   TPath.Combine(FRaizVersoes, Selecionada))) then
  begin
    FRaizVersoes := ExcludeTrailingPathDelimiter(Pasta);
    // Pasta ja e uma versao especifica (nao tem subpastas): lista as versoes
    // da pasta anterior e deixa esta selecionada.
    if (FRaizVersoes <> '') and TDirectory.Exists(FRaizVersoes) and
       (Length(TDirectory.GetDirectories(FRaizVersoes)) = 0) then
    begin
      Selecionada := ExtractFileName(FRaizVersoes);
      FRaizVersoes := ExcludeTrailingPathDelimiter(ExtractFilePath(FRaizVersoes));
    end;
  end;
  PreencherVersoes(Selecionada);
end;

procedure TfrmMain.PreencherVersoes(const ASelecionada: string);
var
  Pastas: TArray<string>;
  Atual: string;
begin
  cbxVersaoScripts.Items.Clear;
  if (FRaizVersoes <> '') and TDirectory.Exists(FRaizVersoes) then
  begin
    Pastas := TDirectory.GetDirectories(FRaizVersoes);
    TArray.Sort<string>(Pastas);
    for Atual in Pastas do
      cbxVersaoScripts.Items.Add(ExtractFileName(Atual));
  end;
  cbxVersaoScripts.ItemIndex := cbxVersaoScripts.Items.IndexOf(ASelecionada);
end;

procedure TfrmMain.cbxVersaoScriptsDropDown(Sender: TObject);
begin
  CarregarVersoesScripts;
end;

procedure TfrmMain.cbxVersaoScriptsChange(Sender: TObject);
begin
  if cbxVersaoScripts.ItemIndex < 0 then
    Exit;
  edtPastaScripts.Text := TPath.Combine(FRaizVersoes,
    cbxVersaoScripts.Items[cbxVersaoScripts.ItemIndex]);
end;

procedure TfrmMain.btnBrowseBancoClick(Sender: TObject);
var
  Dlg: TOpenDialog;
begin
  Dlg := TOpenDialog.Create(nil);
  try
    Dlg.Filter := 'Banco Firebird (*.fdb)|*.fdb|Todos os arquivos (*.*)|*.*';
    if Dlg.Execute then
      edtCaminhoBanco.Text := Dlg.FileName;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmMain.btnBrowseFbClientClick(Sender: TObject);
var
  Dlg: TOpenDialog;
begin
  Dlg := TOpenDialog.Create(nil);
  try
    Dlg.Filter := 'fbclient.dll|fbclient.dll|Todos os arquivos (*.*)|*.*';
    if Dlg.Execute then
      edtFbClient.Text := Dlg.FileName;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmMain.btnBrowsePastaScriptsClick(Sender: TObject);
var
  Pasta: string;
begin
  Pasta := edtPastaScripts.Text;
  if SelectDirectory('Selecione a pasta dos scripts', '', Pasta) then
    edtPastaScripts.Text := Pasta;
end;

procedure TfrmMain.btnTestarConexaoClick(Sender: TObject);
begin
  TelaParaConfig;
  try
    FController.TestarConexao;
    lblStatusConexao.Caption := 'Conectado';
    lblStatusConexao.Font.Color := clGreen;
  except
    on E: Exception do
    begin
      lblStatusConexao.Caption := 'Falha na conex'#227'o';
      lblStatusConexao.Font.Color := clRed;
      AppendLog('ERRO ao conectar: ' + E.Message);
      MessageDlg('N'#227'o foi poss'#237'vel conectar ao banco:'#13#10 + E.Message,
        mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmMain.btnSalvarConfigClick(Sender: TObject);
begin
  TelaParaConfig;
  FController.SalvarConfiguracao;
  AppendLog('Configura'#231#227'o salva.');
end;

function TfrmMain.ItemDoScript(AScript: TMigrationScript): TListItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to lvScripts.Items.Count - 1 do
    if lvScripts.Items[I].Data = Pointer(AScript) then
      Exit(lvScripts.Items[I]);
end;

procedure TfrmMain.RecarregarGrid;
var
  Script: TMigrationScript;
  Item: TListItem;
begin
  lvScripts.Items.BeginUpdate;
  try
    lvScripts.Items.Clear;
    if FController.Scripts = nil then
      Exit;
    for Script in FController.Scripts do
    begin
      Item := lvScripts.Items.Add;
      Item.Caption := Script.Codigo;
      Item.SubItems.Add(ExtractFileName(Script.Arquivo));
      Item.SubItems.Add(StatusDescricao(Script.Status));
      Item.Data := Pointer(Script);
    end;
  finally
    lvScripts.Items.EndUpdate;
  end;
  AtualizarCards;
end;

procedure TfrmMain.AtualizarCards;
var
  Script: TMigrationScript;
  Total, Pendentes, Aplicados, Erros: Integer;
begin
  Total := 0;
  Pendentes := 0;
  Aplicados := 0;
  Erros := 0;
  if FController.Scripts <> nil then
    for Script in FController.Scripts do
    begin
      Inc(Total);
      case Script.Status of
        msPendente, msExecutando:
          Inc(Pendentes);
        msAplicado, msSucesso:
          Inc(Aplicados);
        msErro:
          Inc(Erros);
      end;
    end;
  lblCardTotalValor.Caption := IntToStr(Total);
  lblCardPendentesValor.Caption := IntToStr(Pendentes);
  lblCardAplicadosValor.Caption := IntToStr(Aplicados);
  lblCardErrosValor.Caption := IntToStr(Erros);
end;

procedure TfrmMain.AppendLog(const AMsg: string);
begin
  memoLog.Lines.Add('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
  SendMessage(memoLog.Handle, EM_LINESCROLL, 0, memoLog.Lines.Count);
end;

procedure TfrmMain.HabilitarControles(AHabilitado: Boolean);
begin
  btnAtualizarLista.Enabled := AHabilitado;
  btnExecutar.Enabled := AHabilitado;
  btnProximaVersao.Enabled := AHabilitado;
  btnVersaoAnterior.Enabled := AHabilitado;
  btnTestarConexao.Enabled := AHabilitado;
  btnSalvarConfig.Enabled := AHabilitado;
  btnParar.Enabled := not AHabilitado;
end;

procedure TfrmMain.btnAtualizarListaClick(Sender: TObject);
begin
  TelaParaConfig;
  try
    FController.AtualizarListaScripts;
    RecarregarGrid;
    if FController.UltimoCodigoAplicado <> '' then
      lblCardUltimoValor.Caption := FController.UltimoCodigoAplicado
    else
      lblCardUltimoValor.Caption := '-';
    AppendLog('Lista de scripts atualizada: ' + IntToStr(FController.Scripts.Count) +
      ' arquivo(s) encontrado(s).');
  except
    on E: Exception do
    begin
      AppendLog('ERRO ao listar scripts: ' + E.Message);
      MessageDlg('Erro ao carregar scripts:'#13#10 + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmMain.btnExecutarClick(Sender: TObject);
var
  I: Integer;
  Selecionados: TArray<TMigrationScript>;
  Mensagem: string;
begin
  if (FController.Scripts = nil) or (FController.Scripts.Count = 0) then
  begin
    MessageDlg('Atualize a lista de scripts antes de executar.', mtWarning, [mbOK], 0);
    Exit;
  end;

  Selecionados := [];
  for I := 0 to lvScripts.Items.Count - 1 do
    if lvScripts.Items[I].Checked then
      Selecionados := Selecionados + [TMigrationScript(lvScripts.Items[I].Data)];

  if Length(Selecionados) > 0 then
    Mensagem := Format('Executar os %d script(s) selecionado(s)?', [Length(Selecionados)])
  else
    Mensagem := 'Executar os scripts pendentes agora?';

  if MessageDlg(Mensagem, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  TelaParaConfig;
  HabilitarControles(False);
  FController.ExecutarPendentes(Selecionados);
end;

procedure TfrmMain.btnPararClick(Sender: TObject);
begin
  FController.PararExecucao;
  AppendLog('Solicitada parada ap'#243's o script atual...');
end;

procedure TfrmMain.btnProximaVersaoClick(Sender: TObject);
begin
  SelecionarVersao(1);
end;

procedure TfrmMain.btnVersaoAnteriorClick(Sender: TObject);
begin
  SelecionarVersao(-1);
end;

procedure TfrmMain.SelecionarVersao(ADelta: Integer);
var
  Idx: Integer;
begin
  if cbxVersaoScripts.ItemIndex < 0 then
  begin
    MessageDlg('Informe uma Vers'#227'o dos Scripts', mtInformation, [mbOK], 0);
    cbxVersaoScripts.SetFocus;
    Exit;
  end;

  CarregarVersoesScripts;
  Idx := cbxVersaoScripts.ItemIndex;
  if (Idx < 0) or (Idx + ADelta < 0) or
     (Idx + ADelta > cbxVersaoScripts.Items.Count - 1) then
  begin
    if ADelta > 0 then
      MessageDlg('N'#227'o existe pr'#243'xima vers'#227'o de scripts', mtInformation, [mbOK], 0)
    else
      MessageDlg('N'#227'o existe vers'#227'o anterior de scripts', mtInformation, [mbOK], 0);
    Exit;
  end;

  cbxVersaoScripts.ItemIndex := Idx + ADelta;
  cbxVersaoScriptsChange(cbxVersaoScripts);
end;

procedure TfrmMain.btnFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.btnMaximizarClick(Sender: TObject);
begin
  if WindowState = wsMaximized then
    WindowState := wsNormal
  else
    WindowState := wsMaximized;
end;

procedure TfrmMain.pnlHeaderMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    ReleaseCapture;
    Perform(WM_SYSCOMMAND, SC_MOVE + HTCAPTION, 0);
  end;
end;

procedure TfrmMain.lvScriptsMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Item: TListItem;
begin
  if Button = mbRight then
  begin
    Item := lvScripts.GetItemAt(X, Y);
    if Item <> nil then
    begin
      Item.Selected := True;
      Item.Focused := True;
    end;
  end;
end;

procedure TfrmMain.lvScriptsDblClick(Sender: TObject);
var
  Pt: TPoint;
  Item: TListItem;
begin
  Pt := lvScripts.ScreenToClient(Mouse.CursorPos);
  Item := lvScripts.GetItemAt(Pt.X, Pt.Y);
  if Item = nil then
    Exit;
  ShellExecute(0, 'open', PChar(TMigrationScript(Item.Data).Arquivo), nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmMain.miAbrirDiretorioClick(Sender: TObject);
var
  Arquivo: string;
begin
  if lvScripts.Selected = nil then
    Exit;
  Arquivo := TMigrationScript(lvScripts.Selected.Data).Arquivo;
  ShellExecute(0, 'open', 'explorer.exe', PChar('/select,"' + Arquivo + '"'), nil, SW_SHOWNORMAL);
end;

// Scripts marcados na grade; se nao houver, o selecionado.
function TfrmMain.ScriptsAlvo: TArray<TMigrationScript>;
var
  I: Integer;
begin
  Result := [];
  for I := 0 to lvScripts.Items.Count - 1 do
    if lvScripts.Items[I].Checked then
      Result := Result + [TMigrationScript(lvScripts.Items[I].Data)];
  if (Length(Result) = 0) and (lvScripts.Selected <> nil) then
    Result := [TMigrationScript(lvScripts.Selected.Data)];
end;

procedure TfrmMain.miEstornarScriptClick(Sender: TObject);
var
  Alvo, Validos: TArray<TMigrationScript>;
  Script: TMigrationScript;
  Resumo: TResumoEstorno;
  Mensagem, Aviso: string;
begin
  if FController.EstaExecutando then
    Exit;
  Alvo := ScriptsAlvo;
  Validos := [];
  for Script in Alvo do
    if FController.PodeEstornar(Script) then
      Validos := Validos + [Script];
  if Length(Validos) = 0 then
  begin
    MessageDlg('Nenhum dos scripts tem hist'#243'rico de estorno nesta base.'#13#10 +
      'S'#243' d'#225' para estornar scripts aplicados por este aplicativo.', mtInformation, [mbOK], 0);
    Exit;
  end;

  Resumo := FController.ResumoEstorno(Validos);
  Mensagem := Format('Estornar %d script(s) (do mais novo para o mais antigo)?'#13#10 +
    '%d comando(s) de desfazer ser'#227'o executados e o registro na tabela SCRIPT ser'#225' removido.',
    [Length(Validos), Resumo.Reversiveis]);
  if Length(Resumo.Avisos) > 0 then
  begin
    Mensagem := Mensagem + #13#10#13#10 + 'N'#195'O ser'#227'o revertidos:';
    for Aviso in Resumo.Avisos do
      Mensagem := Mensagem + #13#10'- ' + Aviso;
  end;
  if MessageDlg(Mensagem, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  TelaParaConfig;
  HabilitarControles(False);
  FController.EstornarScripts(Validos);
end;

// Executa so o script selecionado (ignora os marcados), qualquer que seja o status.
procedure TfrmMain.miExecutarScriptClick(Sender: TObject);
var
  Script: TMigrationScript;
  Mensagem: string;
begin
  if (lvScripts.Selected = nil) or FController.EstaExecutando then
    Exit;
  Script := TMigrationScript(lvScripts.Selected.Data);

  Mensagem := Format('Executar somente o script %s?', [Script.Codigo]);
  if Script.Status in [msAplicado, msSucesso] then
    Mensagem := Mensagem + #13#10#13#10'Ele j'#225' consta como aplicado: os comandos ser'#227'o ' +
      'executados novamente (o registro na tabela SCRIPT n'#227'o ser'#225' duplicado).';
  if MessageDlg(Mensagem, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  TelaParaConfig;
  HabilitarControles(False);
  FController.ExecutarPendentes([Script]);
end;

procedure TfrmMain.pmScriptsPopup(Sender: TObject);
var
  Script: TMigrationScript;
  Pode: Boolean;
begin
  Pode := False;
  if not FController.EstaExecutando then
    for Script in ScriptsAlvo do
      if FController.PodeEstornar(Script) then
        Pode := True;
  miEstornarScript.Enabled := Pode;
  miExecutarScript.Enabled := (lvScripts.Selected <> nil) and not FController.EstaExecutando;
  miAbrirDiretorio.Enabled := lvScripts.Selected <> nil;
  miDesmarcarTodos.Enabled := lvScripts.Items.Count > 0;
  miExcluirScript.Enabled := (lvScripts.Items.Count > 0) and not FController.EstaExecutando;
end;

procedure TfrmMain.miExcluirScriptClick(Sender: TObject);
var
  I, Qtde: Integer;
  Selecionados: TArray<TMigrationScript>;
begin
  if FController.EstaExecutando then
  begin
    MessageDlg('N'#227'o '#233' poss'#237'vel remover scripts durante a execu'#231#227'o.',
      mtWarning, [mbOK], 0);
    Exit;
  end;

  Selecionados := [];
  for I := 0 to lvScripts.Items.Count - 1 do
    if lvScripts.Items[I].Checked then
      Selecionados := Selecionados + [TMigrationScript(lvScripts.Items[I].Data)];

  if Length(Selecionados) = 0 then
  begin
    if lvScripts.Selected = nil then
      Exit;
    Selecionados := [TMigrationScript(lvScripts.Selected.Data)];
  end;

  Qtde := Length(Selecionados);
  if MessageDlg(Format('Remover %d script(s) da lista?', [Qtde]), mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then
    Exit;

  FController.RemoverScripts(Selecionados);
  RecarregarGrid;
  AppendLog(Format('%d script(s) removido(s) da lista.', [Qtde]));
end;

procedure TfrmMain.miDesmarcarTodosClick(Sender: TObject);
var
  I: Integer;
begin
  lvScripts.Items.BeginUpdate;
  try
    for I := 0 to lvScripts.Items.Count - 1 do
      lvScripts.Items[I].Checked := False;
  finally
    lvScripts.Items.EndUpdate;
  end;
end;

procedure TfrmMain.miLimparLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

end.
