
<#
.SYNOPSIS
    Download shows from ruv.is
    
.NOTES
    Requires ffmpeg and youtube-dl which can be defined with 'FfmpegPath' and 'YoutubeDlPath' parameter
    By default the script looks for these prereqs in ".\Binaries\"

.EXAMPLE
    Ruvloader.ps1 -DownloadDirectory "C:\RUV" -ShowName "hvolpasveitin"
    Ruvloader.ps1 -DownloadDirectory "C:\RUV" -ShowName "klingjur"
    Ruvloader.ps1 -DownloadDirectory "C:\RUV" -ShowName "froskur-og-vinir-hans"
#>

[CmdletBinding()]
param
(    
    #[Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ShowName,

    #[Parameter(Mandatory)]
    [ValidateScript({ Test-Path -Path $_ })]
    [string]$DownloadDirectory,

    [ValidateScript({ Test-Path -Path $_ })]
    [string]$FfmpegPath,

    [ValidateScript({ Test-Path -Path $_ })]
    [string]$YoutubeDlPath
)

# Set ffmpeg to default path if not defined
If ([string]::IsNullOrWhiteSpace($Global:FfmpegPath))
{
    $FfmpegPath = (Split-Path $MyInvocation.MyCommand.Path -Parent) + '\Binaries\ffmpeg-20180331-be502ec-win64-static\bin'
}
# Set ffmpeg to default path if not defined
If ([string]::IsNullOrWhiteSpace($Global:YoutubeDlPath))
{
    [string]$YoutubeDlPath = (Split-Path $MyInvocation.MyCommand.Path -Parent) + '\Binaries\youtube-dl.exe'
}

[string]$ruvAPIRoot = 'https://api.ruv.is/api/programs/'

function Main
{
    [RuvShow]$show = [RuvShow]::new($ShowName, $DownloadDirectory)
    $show.GetOnlineSeasons()
    $show.GetDownloadedSeasons() 
    $show.DownloadMissingEpisodes()
}

class RuvShow
{    
    [string]$showName
    [string]$downloadDirectory    
    [LocalSeason[]]$downloadedSeasons
    [OnlineSeason[]]$onlineSeasons
    
    RuvShow([string]$showName, [string]$downloadDirectory)
    {
        $this.showName = $showName
        $this.downloadDirectory = $downloadDirectory
    }

    GetDownloadedSeasons()
    {
        $seasons = Get-ChildItem -Path $this.downloadDirectory -Directory | Where-Object {$_.Name -like $ShowName}
        ForEach ($directory in $seasons)
        {            
            [LocalSeason]$season = [LocalSeason]::new($directory.name, $directory.fullName)
            $season.GetDownloadedEpisodes()
            $this.downloadedSeasons += $season
        }
    }

    GetOnlineSeasons()
    {
        $allShowsURI = $Global:ruvAPIRoot + "all"
        $allShowsHTML = Invoke-WebRequest -UseBasicParsing -Uri $allShowsURI
        $allShowsJSON = ConvertFrom-Json -InputObject $allShowsHTML.Content
        $targetShowJSON = $allShowsJSON | Where-Object {$_.slug -like "$ShowName"}
        
        ForEach ($season in $targetShowJSON)
        {            
            [OnlineSeason]$newSeason = [OnlineSeason]::new($season.slug, $season.id)
            $newSeason.GetOnlineEpisodes()
            $this.onlineSeasons += $newSeason  
        }
    }

    DownloadMissingEpisodes()
    {
        ForEach ($onlineSeason in $this.onlineSeasons)
        {
            # Create show directory if missing
            $showDirectory = Join-Path -Path $Global:DownloadDirectory -ChildPath $onlineSeason.title
            If ( (Test-Path -PathType Container -Path $showDirectory) -eq $false)
            {
                New-Item -ItemType Directory -Path $showDirectory
            }

            # Create season directory if missing
            $seasonDirectory = Join-Path -Path $showDirectory -ChildPath $onlineSeason.showID
            If ( (Test-Path -PathType Container -Path $seasonDirectory) -eq $false)
            {
                New-Item -ItemType Directory -Path $seasonDirectory    
            }
            
            # Download missing episodes
            ForEach ($onlineEpisode in $onlineSeason.onlineEpisodes)
            {
                # Get file type from m3u8 download path
                # http://sip-ruv-vod.dcp.adaptive.level3.net/lokad/2019/02/24/3600kbps/5018006T0.mp4.m3u8 => ".mp4"                

                $m3u8Path = $onlineEpisode.m3u8URL                
                $m3u8Path = $m3u8Path.Remove($m3u8Path.LastIndexOf('.'))
                $fileType = $m3u8Path.Substring($m3u8Path.LastIndexOf('.'))
                                
                $episodePath = Join-Path -Path $seasonDirectory -ChildPath ($onlineEpisode.title + $fileType)
                If ( (Test-Path -PathType Leaf -Path $episodePath) -eq $false)
                {
                    Start-Process -FilePath $Global:YoutubeDlPath -ArgumentList " --ffmpeg-location `"$Global:FfmpegPath`" `"$($onlineEpisode.m3u8URL)`" -o `"$episodePath`""
                }
            }
        }
    }
}


#region Season
class Season {    
    [string]$title
    Season([string]$title)
    {
        $this.title = $title
    }
}


class OnlineSeason : Season
{         
    [String]$showID
    [Episode[]]$onlineEpisodes
    
    OnlineSeason([String]$title, [String]$showID) : base($title)
    {         
        $this.showID = $showID
    }

    GetOnlineEpisodes()
    {        
        $id = $this.showID
        $seasonURI = $Global:ruvAPIRoot + "program/$id/all"        
        $seasonHTML = Invoke-WebRequest -UseBasicParsing -Uri $seasonURI
        $season = ConvertFrom-Json -InputObject $seasonHTML.Content

        ForEach ($episode in $season.episodes) 
        {
            [OnlineEpisode]$newEpisode = [OnlineEpisode]::new($episode.title, $episode.file)
            $this.onlineEpisodes += $newEpisode
        }
    }    
}

class LocalSeason : Season
{
    [LocalEpisode[]]$downloadedEpisodes
    [String]$filePath

    LocalSeason([String]$title, [String]$filePath) : base($title)
    {
        $this.filePath = $filePath
    }
    
    GetDownloadedEpisodes()
    {
        $episodes = Get-ChildItem -Path $this.filePath -File
        ForEach ($episode in $episodes)
        {
            [LocalEpisode]$episode = [LocalEpisode]::new($episode.name, $episode.fullName)
            $this.downloadedEpisodes += $episode
        }
    }
}
#endregion Season

#region Episode
class Episode {
    [string]$title
    Episode([string]$title)
    {
        $this.title = $title
    }
}


class OnlineEpisode : Episode
{
    [String]$m3u8URL
    
    OnlineEpisode([String]$title, [String]$m3u8URL) : base($title)
    {
        $this.m3u8URL = $m3u8URL
    }
}

class LocalEpisode : Episode
{
    [String]$filePath

    LocalEpisode([String]$title, [String]$filePath) : base($title)
    {
        $this.filePath = $filePath
    }
}
#endregion Episode


Main