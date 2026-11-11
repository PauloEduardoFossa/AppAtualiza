@echo off
rem Compila para bin\AppAtualiza.exe, com os .dcu em dcu\
call "C:\Program Files (x86)\Embarcadero\Studio\20.0\bin\rsvars.bat"
if not exist dcu mkdir dcu
if not exist bin mkdir bin

rem Incrementa o release e gera o recurso de versao do .exe (Assets\Versao.RES)
powershell -NoProfile -ExecutionPolicy Bypass -File Assets\gerar_versao.ps1
if errorlevel 1 exit /b 1
pushd Assets
cgrc Versao.rc
cgrc AppAtualiza.rc
popd

dcc32 AppAtualiza.dpr -B -NUdcu -E"bin"
