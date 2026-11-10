unit Model.UndoStore;

{ Guarda em disco (bin\estornos\<hash da base>\<codigo>.json) os comandos de
  desfazer de cada script aplicado pelo AppAtualiza. }

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.JSON, System.Hash,
  Model.UndoBuilder;

type
  TUndoRegistro = record
    Codigo: string;
    AplicadoEm: string;
    Comandos: TArray<TUndoComando>;
  end;

  TUndoStore = class
  private
    FPasta: string;
    function Arquivo(const ACodigo: string): string;
  public
    constructor Create;
    procedure DefinirBase(const AChaveBase: string);
    function Existe(const ACodigo: string): Boolean;
    function Carregar(const ACodigo: string; out ARegistro: TUndoRegistro): Boolean;
    procedure Salvar(const ARegistro: TUndoRegistro);
    procedure Apagar(const ACodigo: string);
  end;

implementation

constructor TUndoStore.Create;
begin
  inherited Create;
end;

procedure TUndoStore.DefinirBase(const AChaveBase: string);
begin
  FPasta := TPath.Combine(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'estornos'),
    THashMD5.GetHashString(LowerCase(AChaveBase)));
end;

function TUndoStore.Arquivo(const ACodigo: string): string;
begin
  Result := TPath.Combine(FPasta, TPath.GetFileName(ACodigo) + '.json');
end;

function TUndoStore.Existe(const ACodigo: string): Boolean;
begin
  Result := (FPasta <> '') and TFile.Exists(Arquivo(ACodigo));
end;

function TUndoStore.Carregar(const ACodigo: string; out ARegistro: TUndoRegistro): Boolean;
var
  Json, Item: TJSONObject;
  Cmds, Undos: TJSONArray;
  I, J: Integer;
  C: TUndoComando;
begin
  Result := False;
  ARegistro.Codigo := ACodigo;
  ARegistro.AplicadoEm := '';
  ARegistro.Comandos := [];
  if not Existe(ACodigo) then
    Exit;
  Json := TJSONObject.ParseJSONValue(TFile.ReadAllText(Arquivo(ACodigo), TEncoding.UTF8))
    as TJSONObject;
  if Json = nil then
    Exit;
  try
    ARegistro.AplicadoEm := Json.GetValue<string>('aplicadoEm', '');
    Cmds := Json.GetValue('comandos') as TJSONArray;
    if Cmds <> nil then
      for I := 0 to Cmds.Count - 1 do
      begin
        Item := Cmds.Items[I] as TJSONObject;
        C.Cmd := Item.GetValue<string>('cmd', '');
        C.Reversivel := Item.GetValue<Boolean>('reversivel', True);
        C.Aviso := Item.GetValue<string>('aviso', '');
        C.Undo := [];
        Undos := Item.GetValue('undo') as TJSONArray;
        if Undos <> nil then
          for J := 0 to Undos.Count - 1 do
            C.Undo := C.Undo + [Undos.Items[J].Value];
        ARegistro.Comandos := ARegistro.Comandos + [C];
      end;
    Result := True;
  finally
    Json.Free;
  end;
end;

procedure TUndoStore.Salvar(const ARegistro: TUndoRegistro);
var
  Json, Item: TJSONObject;
  Cmds, Undos: TJSONArray;
  C: TUndoComando;
  S: string;
begin
  Json := TJSONObject.Create;
  try
    Json.AddPair('codigo', ARegistro.Codigo);
    Json.AddPair('aplicadoEm', ARegistro.AplicadoEm);
    Cmds := TJSONArray.Create;
    Json.AddPair('comandos', Cmds);
    for C in ARegistro.Comandos do
    begin
      Item := TJSONObject.Create;
      Item.AddPair('cmd', C.Cmd);
      Item.AddPair('reversivel', TJSONBool.Create(C.Reversivel));
      Item.AddPair('aviso', C.Aviso);
      Undos := TJSONArray.Create;
      for S in C.Undo do
        Undos.Add(S);
      Item.AddPair('undo', Undos);
      Cmds.AddElement(Item);
    end;
    ForceDirectories(FPasta);
    TFile.WriteAllText(Arquivo(ARegistro.Codigo), Json.ToJSON, TEncoding.UTF8);
  finally
    Json.Free;
  end;
end;

procedure TUndoStore.Apagar(const ACodigo: string);
begin
  if Existe(ACodigo) then
    TFile.Delete(Arquivo(ACodigo));
end;

end.
