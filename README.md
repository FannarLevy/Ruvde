#SYNOPSIS
    Download shows from ruv.is
    
#NOTES
    Requires ffmpeg and youtube-dl which can be defined with 'FfmpegPath' and 'YoutubeDlPath' parameter
    By default the script looks for these prereqs in ".\Binaries\"

#EXAMPLE
    Ruvloader.ps1 -DownloadDirectory "C:\RUV" -ShowName "hvolpasveitin"
    Ruvloader.ps1 -DownloadDirectory "C:\RUV" -ShowName "klingjur"
    Ruvloader.ps1 -DownloadDirectory "C:\RUV" -ShowName "froskur-og-vinir-hans"
