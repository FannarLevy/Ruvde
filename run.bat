@echo off

REM shows to download
Powershell -file .\Ruvloader.ps1 -DownloadDirectory "C:\RUV" -ShowName "hvolpasveitin"
Powershell -file .\Ruvloader.ps1 -DownloadDirectory "C:\RUV" -ShowName "klingjur"
Powershell -file .\Ruvloader.ps1 -DownloadDirectory "C:\RUV" -ShowName "froskur-og-vinir-hans"
Powershell -file .\Ruvloader.ps1 -DownloadDirectory "C:\RUV" -ShowName "nord-i-reykjavik"




REM update plex library
C:\Program Files (x86)\Plex\Plex Media Server> & '.\Plex Media Scanner.exe' --scan
