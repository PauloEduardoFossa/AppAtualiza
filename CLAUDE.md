# CLAUDE.md

Guidance for Claude Code when working in this repository.

## O que e

**AppAtualiza** — app Delphi VCL (MVC) para executar os scripts SQL de
atualizacao de banco do TopSystem (os `.txt` em
`C:\TopSystem\Delphi\TopDados\Scripts\<versao>\...`) contra um Firebird,
sem depender de rodar `isql` na mao. Criado em 2026-08-28. Nao e uma
working copy SVN; nao faz parte do monorepo TopSystem em `C:\TopSystem\Delphi`
(projeto novo e independente).

## Build

```
cmd /c "call ""C:\Program Files (x86)\Embarcadero\Studio\20.0\bin\rsvars.bat"" && dcc32 AppAtualiza.dpr -B"
```

Sem `.dproj` — compila direto com `dcc32` porque o `dcc32.cfg` da instalacao ja
inclui `C:\...\Studio\20.0\lib\win32\release` no `-u`, onde estao os `.dcu` de
RTL/VCL/FireDAC. Nao precisa de `-U` extra.

O `.res` com o icone (`AppAtualiza.RES`) precisa existir **antes** de compilar
(veja "Icone do executavel" abaixo) — o `.dpr` tem `{$R AppAtualiza.res}`.

## Arquitetura (MVC)

- `Model\Model.Config.pas` — `TDBConfig` (server/porta/caminho do `.fdb`/usuario/
  senha/charset/`fbclient.dll`) + `TAppConfig` (load/save em `config.json` ao
  lado do exe). Senha e ofuscada com XOR($5A)+Base64, **nao e criptografia
  real** — suficiente para nao aparecer em texto puro num arquivo local.
- `Model\Model.MigrationScript.pas` — `TMigrationScript` (codigo extraido do
  nome do arquivo, status: Pendente/Aplicado/Executando/Sucesso/Erro).
- `Model\Model.MigrationService.pas` — o nucleo: conecta via FireDAC (driver
  `FB`), lista `*.txt` de uma pasta, consulta `SELECT CODIGO FROM SCRIPT` para
  marcar o que ja foi aplicado, faz parsing dos scripts respeitando
  `SET TERM <novo> ;` (blocos PSQL/triggers), e executa **cada comando em sua
  propria transacao implicita** (sem `StartTransaction` explicito) — ver
  gotcha abaixo sobre por que isso e proposital.
- `Controller\Controller.Main.pas` — media View/Model; roda a execucao dos
  scripts numa thread de fundo (`TThread.CreateAnonymousThread`) e repassa
  log/status pra UI via `TThread.Queue`.
- `View\View.Main.pas/.dfm` — dashboard: sidebar com config de conexao +
  pasta de scripts, cards de contagem (Total/Pendentes/Aplicados/Erros), grid
  de scripts, console de log. `BorderStyle = bsNone` (sem barra de titulo do
  Windows) com botao "X" custom (`btnFechar`) e arraste pela `pnlHeader` via
  `WM_SYSCOMMAND`/`HTCAPTION`.

## config.json

Fica ao lado do exe (`Model.Config.DefaultConfigFileName`). Formato:
```json
{
  "database": { "server": "...", "port": 3050, "path": "...", "user": "...",
                "password": "<ofuscada>", "characterSet": "NONE", "fbClientPath": "" },
  "scriptsFolder": "...",
  "stopOnError": true
}
```

## Gotchas ja resolvidos (nao redescobrir)

- **`Statement failed ... object TABLE X is in use` ao rodar scripts que
  misturam UPDATE + `ALTER TABLE ... ALTER COLUMN`**: aconteceu rodando via
  `isql` manualmente (script `3.1.1.4.39.txt` do TopDados) porque o DDL do
  Firebird sempre pede lock NOWAIT, e a UPDATE anterior ainda nao tinha
  commitado. Por isso o `TMigrationService.ExecutarPendentes` **nao** agrupa
  comandos numa transacao so — cada `FConnection.ExecSQL(Cmd)` roda com
  autocommit implicito do FireDAC (nunca chamar `StartTransaction` aqui).
  Comandos `COMMIT;`/`COMMIT WORK;` do proprio script sao ignorados
  (`DeveIgnorarComando`) porque nao sao SQL valido pra mandar ao servidor.
- **`Style 'X' not found`**: o nome interno de um `.vsf` nao e o nome do
  arquivo. `AppAtualiza.dpr` carrega `Styles\Windows10Blue.vsf` e descobre o
  nome comparando `TStyleManager.StyleNames` antes/depois do `LoadFromFile`
  (nao tem `.TrySetStyle` com string fixa).
- **`Object factory for class {...} is missing ... TFDGUIxWaitCursor`**: app
  FireDAC sem nenhuma unit visual do FireDAC no `uses` nao registra o
  wait-cursor factory usado internamente em operacoes longas. Fix: `uses
  FireDAC.VCLUI.Wait` no `.dpr` (so precisa estar linkado, nao precisa
  instanciar nada).

## Icone do executavel

`Assets\AppAtualiza.ico` (multi-resolucao 16..256, frames PNG) foi gerado por
script PowerShell ad-hoc (nao versionado no projeto) usando GDI+
(`System.Drawing`). Pra regenerar algo parecido, ou mudar o desenho:

- **PowerShell `New-Object Tipo(a, b - c*d, ...)` com aritmetica inline
  dentro dos parenteses quebra** (`op_Multiply` em `System.Object[]`) — o
  parser de "argument mode" do PowerShell confunde `-`/`*` inline com
  parametros. Sempre pre-calcular cada valor numa variavel antes e so passar
  variaveis pros construtores (`New-Object System.Drawing.RectangleF $x, $y,
  $w, $h`).
- Embutir o `.ico` no exe: `AppAtualiza.rc` com
  `MAINICON ICON "Assets/AppAtualiza.ico"` — **usar barra normal, nao
  invertida** (o preprocessor do `rc` engole `\A` como escape invalido e
  corrompe o caminho).
- `brcc32.exe` (o compilador de resource classico do Delphi) **falha**
  (`Allocate failed`) em `.ico` moderno com frame 256x256 comprimido em PNG.
  Usar `cgrc.exe` (mesma pasta `bin` do RAD Studio) — ele empacota o `rc.exe`
  da Microsoft por baixo:
  ```
  cgrc AppAtualiza.rc
  ```
  (gera `AppAtualiza.RES` automaticamente; sem `/fo`/`/r` — esses switches
  nessa versao dao "Invalid number of arguments").
