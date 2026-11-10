# Chamado pelo build.bat antes de compilar:
#  - incrementa o contador de release (Assets\build.number)
#  - grava Model\Model.Version.Build.inc (VERSAO_RELEASE)
#  - gera Assets\Versao.rc (VERSIONINFO do .exe) a partir dos 3 numeros
$ErrorActionPreference = 'Stop'
$raiz = Split-Path $PSScriptRoot -Parent

$pas = Get-Content (Join-Path $raiz 'Model\Model.Version.pas') -Raw
$maior = [int][regex]::Match($pas, 'VERSAO_SUBSTITUICAO\s*=\s*(\d+)').Groups[1].Value
$medio = [int][regex]::Match($pas, 'VERSAO_DISPONIBILIZACAO\s*=\s*(\d+)').Groups[1].Value

$arqBuild = Join-Path $PSScriptRoot 'build.number'
$build = 0
if (Test-Path $arqBuild) { $build = [int](Get-Content $arqBuild -Raw).Trim() }
$build++
Set-Content -Path $arqBuild -Value $build -Encoding ascii
Set-Content -Path (Join-Path $raiz 'Model\Model.Version.Build.inc') -Value "VERSAO_RELEASE = $build;" -Encoding ascii

$v = "$maior.$medio.$build"
$rc = @"
1 VERSIONINFO
FILEVERSION $maior,$medio,$build,0
PRODUCTVERSION $maior,$medio,$build,0
FILEOS 0x4
FILETYPE 0x1
BEGIN
  BLOCK "StringFileInfo"
  BEGIN
    BLOCK "041604B0"
    BEGIN
      VALUE "FileDescription", "AppAtualiza"
      VALUE "FileVersion", "$v"
      VALUE "ProductName", "AppAtualiza"
      VALUE "ProductVersion", "$v"
      VALUE "OriginalFilename", "AppAtualiza.exe"
    END
  END
  BLOCK "VarFileInfo"
  BEGIN
    VALUE "Translation", 0x0416, 1200
  END
END
"@
Set-Content -Path (Join-Path $PSScriptRoot 'Versao.rc') -Value $rc -Encoding ascii
Write-Host "Versao $v"
