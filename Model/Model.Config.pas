unit Model.Config;

interface

uses
  System.SysUtils, System.IOUtils, System.JSON, System.NetEncoding;

type
  TDBConfig = record
    Server: string;
    Port: Integer;
    DatabasePath: string;
    UserName: string;
    Password: string;
    CharacterSet: string;
    FbClientPath: string;
  end;

  TAppConfig = class
  private
    FDB: TDBConfig;
    FScriptsFolder: string;
    FStopOnError: Boolean;
    FThemeName: string;
    class function Ofuscar(const S: string): string; static;
    class function Desofuscar(const S: string): string; static;
  public
    constructor Create;
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string);
    property DB: TDBConfig read FDB write FDB;
    property ScriptsFolder: string read FScriptsFolder write FScriptsFolder;
    property StopOnError: Boolean read FStopOnError write FStopOnError;
    property ThemeName: string read FThemeName write FThemeName;
  end;

function DefaultConfigFileName: string;

implementation

const
  CHAVE_OFUSCACAO = $5A;

function DefaultConfigFileName: string;
begin
  Result := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'config.json');
end;

{ TAppConfig }

class function TAppConfig.Ofuscar(const S: string): string;
var
  Bytes: TBytes;
  I: Integer;
begin
  if S = '' then
    Exit('');
  Bytes := TEncoding.UTF8.GetBytes(S);
  for I := 0 to High(Bytes) do
    Bytes[I] := Bytes[I] xor CHAVE_OFUSCACAO;
  Result := TNetEncoding.Base64.EncodeBytesToString(Bytes);
end;

class function TAppConfig.Desofuscar(const S: string): string;
var
  Bytes: TBytes;
  I: Integer;
begin
  if S = '' then
    Exit('');
  Bytes := TNetEncoding.Base64.DecodeStringToBytes(S);
  for I := 0 to High(Bytes) do
    Bytes[I] := Bytes[I] xor CHAVE_OFUSCACAO;
  Result := TEncoding.UTF8.GetString(Bytes);
end;

constructor TAppConfig.Create;
begin
  inherited Create;
  FDB.Server := 'localhost';
  FDB.Port := 3050;
  FDB.CharacterSet := 'NONE';
  FDB.UserName := 'SYSDBA';
  FDB.Password := '';
  FDB.DatabasePath := '';
  FDB.FbClientPath := '';
  FScriptsFolder := '';
  FStopOnError := True;
  FThemeName := '';
end;

procedure TAppConfig.LoadFromFile(const AFileName: string);
var
  Raiz: TJSONObject;
  JDB: TJSONObject;
  Texto: string;
begin
  if not TFile.Exists(AFileName) then
    Exit;
  Texto := TFile.ReadAllText(AFileName, TEncoding.UTF8);
  Raiz := TJSONObject.ParseJSONValue(Texto) as TJSONObject;
  if Raiz = nil then
    Exit;
  try
    if Raiz.TryGetValue<TJSONObject>('database', JDB) then
    begin
      FDB.Server := JDB.GetValue<string>('server', FDB.Server);
      FDB.Port := JDB.GetValue<Integer>('port', FDB.Port);
      FDB.DatabasePath := JDB.GetValue<string>('path', FDB.DatabasePath);
      FDB.UserName := JDB.GetValue<string>('user', FDB.UserName);
      FDB.Password := Desofuscar(JDB.GetValue<string>('password', ''));
      FDB.CharacterSet := JDB.GetValue<string>('characterSet', FDB.CharacterSet);
      FDB.FbClientPath := JDB.GetValue<string>('fbClientPath', '');
    end;
    FScriptsFolder := Raiz.GetValue<string>('scriptsFolder', FScriptsFolder);
    FStopOnError := Raiz.GetValue<Boolean>('stopOnError', FStopOnError);
    FThemeName := Raiz.GetValue<string>('themeName', FThemeName);
  finally
    Raiz.Free;
  end;
end;

procedure TAppConfig.SaveToFile(const AFileName: string);
var
  Raiz, JDB: TJSONObject;
begin
  Raiz := TJSONObject.Create;
  try
    JDB := TJSONObject.Create;
    JDB.AddPair('server', FDB.Server);
    JDB.AddPair('port', TJSONNumber.Create(FDB.Port));
    JDB.AddPair('path', FDB.DatabasePath);
    JDB.AddPair('user', FDB.UserName);
    JDB.AddPair('password', Ofuscar(FDB.Password));
    JDB.AddPair('characterSet', FDB.CharacterSet);
    JDB.AddPair('fbClientPath', FDB.FbClientPath);
    Raiz.AddPair('database', JDB);
    Raiz.AddPair('scriptsFolder', FScriptsFolder);
    Raiz.AddPair('stopOnError', TJSONBool.Create(FStopOnError));
    Raiz.AddPair('themeName', FThemeName);
    TFile.WriteAllText(AFileName, Raiz.ToJSON, TEncoding.UTF8);
  finally
    Raiz.Free;
  end;
end;

end.
