@echo off
rem Compila para bin\AppAtualiza.exe, com os .dcu em dcu\
call "C:\Program Files (x86)\Embarcadero\Studio\20.0\bin\rsvars.bat"
if not exist dcu mkdir dcu
if not exist bin mkdir bin
dcc32 AppAtualiza.dpr -B -NUdcu -E"bin"
