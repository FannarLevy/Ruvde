

[string]$ruvAPIRoot = 'https://api.ruv.is/api/programs/'
$allShowsURI = $Global:ruvAPIRoot + "all"
$allShowsHTML = Invoke-WebRequest -UseBasicParsing -Uri $allShowsURI
$allShowsJSON = ConvertFrom-Json -InputObject $allShowsHTML.Content
$targetShowJSON = $allShowsJSON | Where-Object -Property format -eq 'tv' | Group-Object -Property 'slug'
$targetShowJSON | Out-GridView -PassThru | Select-Object Values |  clip

