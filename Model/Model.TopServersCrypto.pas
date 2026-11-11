unit Model.TopServersCrypto;

// Decifra o campo "senha" dos topservers*.config. Mesmo esquema do TopSystem
// (ClassesProjetosDelphi\TopSystemClasses\UTopSystem.Criptografia.Senha.CompativelCSharp.pas):
// AES-128 CBC pela CryptoAPI do Windows, chave = CryptDeriveKey(SHA-256(UTF-16 do segredo)),
// texto em UTF-16LE, resultado em Base64.

interface

// AChave e o segredo do TopSystem (nao fica no codigo: vem do config.json, campo
// topServersKey). Retorna '' se AValue for vazio. Levanta excecao se a chave estiver
// vazia ou se nao for uma senha valida.
function DescriptografarSenhaTopServer(const AValue, AChave: string): string;

implementation

uses
  Winapi.Windows, System.SysUtils, System.NetEncoding;

const
  ADVAPI32 = 'ADVAPI32.dll';
  CALG_SHA_256 = 32780;
  CALG_AES_128 = 26126;
  CRYPT_NEWKEYSET = $00000008;
  PROV_RSA_AES = 24;
  KP_MODE = 4;
  CRYPT_MODE_CBC = 1;

type
  HCRYPTPROV = NativeUInt;
  HCRYPTKEY = NativeUInt;
  HCRYPTHASH = NativeUInt;

function CryptAcquireContextW(var Prov: HCRYPTPROV; Container, Provider: PWideChar;
  ProvType, Flags: DWORD): BOOL; stdcall; external ADVAPI32;
function CryptCreateHash(Prov: HCRYPTPROV; Algid: DWORD; Key: HCRYPTKEY; Flags: DWORD;
  var Hash: HCRYPTHASH): BOOL; stdcall; external ADVAPI32;
function CryptHashData(Hash: HCRYPTHASH; Data: PByte; DataLen, Flags: DWORD): BOOL;
  stdcall; external ADVAPI32;
function CryptDeriveKey(Prov: HCRYPTPROV; Algid: DWORD; BaseData: HCRYPTHASH; Flags: DWORD;
  var Key: HCRYPTKEY): BOOL; stdcall; external ADVAPI32;
function CryptSetKeyParam(Key: HCRYPTKEY; Param: DWORD; Data: PByte; Flags: DWORD): BOOL;
  stdcall; external ADVAPI32;
function CryptDecrypt(Key: HCRYPTKEY; Hash: HCRYPTHASH; Final: BOOL; Flags: DWORD;
  Data: PByte; var Len: DWORD): BOOL; stdcall; external ADVAPI32;
function CryptDestroyHash(Hash: HCRYPTHASH): BOOL; stdcall; external ADVAPI32;
function CryptDestroyKey(Key: HCRYPTKEY): BOOL; stdcall; external ADVAPI32;
function CryptReleaseContext(Prov: HCRYPTPROV; Flags: DWORD): BOOL; stdcall; external ADVAPI32;

function DescriptografarSenhaTopServer(const AValue, AChave: string): string;
var
  Prov: HCRYPTPROV;
  Hash: HCRYPTHASH;
  Key: HCRYPTKEY;
  Mode, Len: DWORD;
  Buffer: TBytes;
begin
  if AValue = '' then
    Exit('');
  if AChave = '' then
    raise Exception.Create('Chave dos topservers nao configurada (topServersKey no config.json)');

  if not CryptAcquireContextW(Prov, nil, nil, PROV_RSA_AES, 0) then
    if GetLastError = DWORD(NTE_BAD_KEYSET) then
      Win32Check(CryptAcquireContextW(Prov, nil, nil, PROV_RSA_AES, CRYPT_NEWKEYSET))
    else
      RaiseLastOSError;
  try
    Win32Check(CryptCreateHash(Prov, CALG_SHA_256, 0, 0, Hash));
    try
      Win32Check(CryptHashData(Hash, PByte(PWideChar(AChave)), Length(AChave) * SizeOf(WideChar), 0));
      Win32Check(CryptDeriveKey(Prov, CALG_AES_128, Hash, 0, Key));
    finally
      CryptDestroyHash(Hash);
    end;
    try
      Mode := CRYPT_MODE_CBC;
      Win32Check(CryptSetKeyParam(Key, KP_MODE, PByte(@Mode), 0));
      Buffer := TNetEncoding.Base64.DecodeStringToBytes(AValue);
      if Length(Buffer) = 0 then
        raise Exception.Create('Senha vazia ou Base64 invalido');
      Len := Length(Buffer);
      Win32Check(CryptDecrypt(Key, 0, True, 0, @Buffer[0], Len));
      Result := TEncoding.Unicode.GetString(Buffer, 0, Len);
    finally
      CryptDestroyKey(Key);
    end;
  finally
    CryptReleaseContext(Prov, 0);
  end;
end;

end.
