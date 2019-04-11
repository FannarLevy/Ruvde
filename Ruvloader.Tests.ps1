$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "RuvShow" {
    Mock Get-ChildItem { 
        @{Name = "Hvolpasveitin — Þáttur 6 af 26.mp4"},
        @{Name = "Hvolpasveitin — Þáttur 7 af 26.mp4"}
    }
        
    It "Should return correct number of shows" {
        [RuvShow]$show = [RuvShow]::new("", "")
        $show.GetDownloadedEpisodes()
        $show.downloadedEpisodes.Count | Should Be 2
    }
}
