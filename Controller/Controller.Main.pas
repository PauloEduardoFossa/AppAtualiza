unit Controller.Main;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  Model.Config, Model.MigrationScript, Model.MigrationService;

type
  TLogProc = reference to procedure(const AMsg: string);
  TStatusProc = reference to procedure(AScript: TMigrationScript);
  TFimExecucaoProc = reference to procedure;

  TMainController = class
  private
    FConfig: TAppConfig;
    FService: TMigrationService;
    FScripts: TMigrationScriptList;
    FOnLog: TLogProc;
    FOnScriptStatus: TStatusProc;
    FOnFimExecucao: TFimExecucaoProc;
    FExecutando: Boolean;
    FArquivoLogErros: string;
    procedure HandleLog(Sender: TObject; const AMensagem: string);
    procedure HandleScriptStatus(Sender: TObject; AScript: TMigrationScript);
    procedure HandleErroComando(Sender: TObject; AScript: TMigrationScript;
      const AComando, AMensagem: string);
    procedure EnsureConectado;
  public
    constructor Create;
    destructor Destroy; override;
    procedure CarregarConfiguracao;
    procedure SalvarConfiguracao;
    procedure TestarConexao;
    procedure AtualizarListaScripts;
    procedure ExecutarPendentes(const AScripts: TArray<TMigrationScript> = nil);
    procedure PararExecucao;
    procedure RemoverScripts(const AScripts: TArray<TMigrationScript>);
    function UltimoCodigoAplicado: string;
    function EstaExecutando: Boolean;
    function TemLogErros: Boolean;
    property Config: TAppConfig read FConfig;
    property Scripts: TMigrationScriptList read FScripts;
    property ArquivoLogErros: string read FArquivoLogErros;
    property OnLog: TLogProc read FOnLog write FOnLog;
    property OnScriptStatus: TStatusProc read FOnScriptStatus write FOnScriptStatus;
    property OnFimExecucao: TFimExecucaoProc read FOnFimExecucao write FOnFimExecucao;
  end;

implementation

{ TMainController }

constructor TMainController.Create;
begin
  inherited Create;
  FConfig := TAppConfig.Create;
  FService := TMigrationService.Create;
  FService.OnLog := HandleLog;
  FService.OnScriptStatus := HandleScriptStatus;
  FService.OnErroComando := HandleErroComando;
  FScripts := nil;
  FExecutando := False;
end;

destructor TMainController.Destroy;
begin
  FScripts.Free;
  FService.Free;
  FConfig.Free;
  inherited;
end;

procedure TMainController.HandleLog(Sender: TObject; const AMensagem: string);
begin
  TThread.Queue(nil,
    procedure
    begin
      if Assigned(FOnLog) then
        FOnLog(AMensagem);
    end);
end;

procedure TMainController.HandleScriptStatus(Sender: TObject; AScript: TMigrationScript);
begin
  TThread.Queue(nil,
    procedure
    begin
      if Assigned(FOnScriptStatus) then
        FOnScriptStatus(AScript);
    end);
end;

procedure TMainController.HandleErroComando(Sender: TObject; AScript: TMigrationScript;
  const AComando, AMensagem: string);
var
  Bloco: TStringList;
begin
  Bloco := TStringList.Create;
  try
    Bloco.Add('[' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '] Script ' + AScript.Codigo);
    Bloco.Add('Comando:');
    Bloco.Add(AComando);
    Bloco.Add('Erro: ' + AMensagem);
    Bloco.Add(StringOfChar('-', 70));
    Bloco.Add('');
    TFile.AppendAllText(FArquivoLogErros, Bloco.Text, TEncoding.UTF8);
  finally
    Bloco.Free;
  end;
end;

procedure TMainController.CarregarConfiguracao;
begin
  FConfig.LoadFromFile(DefaultConfigFileName);
end;

procedure TMainController.SalvarConfiguracao;
begin
  FConfig.SaveToFile(DefaultConfigFileName);
end;

procedure TMainController.EnsureConectado;
begin
  FService.Conectar(FConfig.DB);
end;

procedure TMainController.TestarConexao;
begin
  FService.Conectar(FConfig.DB);
  HandleLog(Self, 'Conexao estabelecida com sucesso.');
end;

procedure TMainController.AtualizarListaScripts;
begin
  EnsureConectado;
  FreeAndNil(FScripts);
  FScripts := FService.ListarScripts(FConfig.ScriptsFolder);
end;

procedure TMainController.ExecutarPendentes(const AScripts: TArray<TMigrationScript>);
begin
  if FExecutando then
    Exit;
  if (FScripts = nil) or (FScripts.Count = 0) then
  begin
    HandleLog(Self, 'Nenhum script carregado. Atualize a lista primeiro.');
    Exit;
  end;

  FExecutando := True;
  FArquivoLogErros := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    'erros_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.log');
  TThread.CreateAnonymousThread(
    procedure
    var
      Lista: TMigrationScriptList;
      Item: TMigrationScript;
    begin
      try
        try
          EnsureConectado;
          if Length(AScripts) > 0 then
          begin
            Lista := TMigrationScriptList.Create(False);
            try
              for Item in AScripts do
                Lista.Add(Item);
              FService.ExecutarPendentes(Lista, FConfig.StopOnError, False);
            finally
              Lista.Free;
            end;
          end
          else
            FService.ExecutarPendentes(FScripts, FConfig.StopOnError, True);
        except
          on E: Exception do
            HandleLog(Self, 'ERRO: ' + E.Message);
        end;
      finally
        FExecutando := False;
        TThread.Queue(nil,
          procedure
          begin
            if Assigned(FOnFimExecucao) then
              FOnFimExecucao;
          end);
      end;
    end).Start;
end;

procedure TMainController.PararExecucao;
begin
  FService.Parar;
end;

procedure TMainController.RemoverScripts(const AScripts: TArray<TMigrationScript>);
var
  Script: TMigrationScript;
begin
  if FExecutando then
  begin
    HandleLog(Self, 'N'#227'o '#233' poss'#237'vel remover scripts durante a execu'#231#227'o.');
    Exit;
  end;
  if FScripts = nil then
    Exit;
  for Script in AScripts do
    FScripts.Remove(Script);
end;

function TMainController.UltimoCodigoAplicado: string;
begin
  Result := FService.UltimoCodigoAplicado;
end;

function TMainController.EstaExecutando: Boolean;
begin
  Result := FExecutando;
end;

function TMainController.TemLogErros: Boolean;
begin
  Result := (FArquivoLogErros <> '') and TFile.Exists(FArquivoLogErros);
end;

end.
