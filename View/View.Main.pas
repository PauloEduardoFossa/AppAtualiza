unit View.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, Winapi.MultiMon, System.SysUtils, System.Variants,
  System.Classes, System.IOUtils, System.Generics.Collections, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.FileCtrl, Vcl.Menus,
  Vcl.Themes, System.UITypes, Controller.Main, Model.MigrationScript, Model.Config,
  Model.TopServersImport;

type
  TfrmMain = class(TForm)
    pnlHeader: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    lblTema: TLabel;
    cbxTema: TComboBox;
    btnMaximizar: TButton;
    btnFechar: TButton;
    pnlSidebar: TPanel;
    lblSecaoBanco: TLabel;
    lblClienteBase: TLabel;
    cbxClienteBase: TComboBox;
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
    procedure miLimparLogClick(Sender: TObject);
    procedure cbxClienteBaseChange(Sender: TObject);
    procedure cbxVersaoScriptsChange(Sender: TObject);
    procedure cbxVersaoScriptsDropDown(Sender: TObject);
    procedure cbxTemaChange(Sender: TObject);
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
    procedure CarregarTemas;
    function ItemDoScript(AScript: TMigrationScript): TListItem;
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
  FController.OnLog := AppendLog;
  FController.OnScriptStatus :=
    procedure(AScript: TMigrationScript)
    var
      Item: TListItem;
    begin
      Item := ItemDoScript(AScript);
      if Item <> nil then
        Item.SubItems[1] := StatusDescricao(AScript.Status);
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
  CarregarTemas;
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
  FController.Config.StopOnError := chkPararErro.Checked;
  if cbxTema.ItemIndex >= 0 then
    FController.Config.ThemeName := cbxTema.Items[cbxTema.ItemIndex];
end;

procedure TfrmMain.CarregarClientesBase;
var
  Entry: TTopServerEntry;
begin
  FTopServers := ListarTopServers;
  cbxClienteBase.Items.Clear;
  for Entry in FTopServers do
    cbxClienteBase.Items.Add(Entry.NomeExibicao);
  cbxClienteBase.Enabled := cbxClienteBase.Items.Count > 0;
  cbxClienteBase.ItemIndex := -1;
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
end;

procedure TfrmMain.CarregarVersoesScripts;
var
  Pastas: TArray<string>;
  Pasta, Atual, Selecionada: string;
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
    FRaizVersoes := ExcludeTrailingPathDelimiter(Pasta);

  cbxVersaoScripts.Items.Clear;
  if (FRaizVersoes <> '') and TDirectory.Exists(FRaizVersoes) then
  begin
    Pastas := TDirectory.GetDirectories(FRaizVersoes);
    TArray.Sort<string>(Pastas);
    for Atual in Pastas do
      cbxVersaoScripts.Items.Add(ExtractFileName(Atual));
  end;
  cbxVersaoScripts.ItemIndex := cbxVersaoScripts.Items.IndexOf(Selecionada);
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

procedure TfrmMain.CarregarTemas;
var
  Nome: string;
  Idx: Integer;
begin
  cbxTema.Items.Clear;
  for Nome in TStyleManager.StyleNames do
    cbxTema.Items.Add(Nome);

  if (FController.Config.ThemeName <> '') and
     (cbxTema.Items.IndexOf(FController.Config.ThemeName) >= 0) then
    TStyleManager.TrySetStyle(FController.Config.ThemeName);

  Idx := cbxTema.Items.IndexOf(TStyleManager.ActiveStyle.Name);
  cbxTema.ItemIndex := Idx;
end;

procedure TfrmMain.cbxTemaChange(Sender: TObject);
begin
  if cbxTema.ItemIndex < 0 then
    Exit;
  TStyleManager.TrySetStyle(cbxTema.Items[cbxTema.ItemIndex]);
  FController.Config.ThemeName := cbxTema.Items[cbxTema.ItemIndex];
  FController.SalvarConfiguracao;
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

procedure TfrmMain.pmScriptsPopup(Sender: TObject);
begin
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
