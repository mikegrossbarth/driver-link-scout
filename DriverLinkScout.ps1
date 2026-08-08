Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "SilentlyContinue"

function Encode-Query {
    param([string]$Value)
    return [System.Uri]::EscapeDataString($Value)
}

function Add-Link {
    param(
        [System.Collections.Generic.List[object]]$Links,
        [string]$Title,
        [string]$Url,
        [string]$Reason,
        [string]$Priority = "Recommended"
    )

    if ([string]::IsNullOrWhiteSpace($Url)) { return }
    $existing = $Links | Where-Object { $_.Url -eq $Url } | Select-Object -First 1
    if ($null -ne $existing) { return }

    $Links.Add([pscustomobject]@{
        Priority = $Priority
        Title = $Title
        Url = $Url
        Reason = $Reason
    }) | Out-Null
}

function Get-OemLinks {
    param(
        [System.Collections.Generic.List[object]]$Links,
        [string]$Manufacturer,
        [string]$Model,
        [string]$Serial
    )

    $m = ($Manufacturer + " " + $Model).ToLowerInvariant()
    $encodedModel = Encode-Query $Model
    $encodedSerial = Encode-Query $Serial

    if ($m -match "dell") {
        Add-Link $Links "Dell Drivers & Downloads" "https://www.dell.com/support/home/en-us?app=drivers" "Best first stop for Dell systems. Enter the Service Tag if auto-detect is not available."
        if ($Serial) {
            Add-Link $Links "Dell Service Tag Search" "https://www.dell.com/support/home/en-us/product-support/servicetag/$encodedSerial/drivers" "Direct Dell support lookup using the detected Service Tag." "Exact model"
        }
    }
    elseif ($m -match "lenovo|thinkpad|ideapad|legion") {
        Add-Link $Links "Lenovo PC Support Drivers" "https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/downloads" "Best first stop for Lenovo systems. Use serial/model detection or search manually."
        Add-Link $Links "Lenovo Vantage" "https://www.lenovo.com/us/en/software/vantage/" "Lenovo's official app for driver and BIOS updates." "Install tool"
    }
    elseif ($m -match "hp|hewlett|compaq") {
        Add-Link $Links "HP Software and Drivers" "https://support.hp.com/us-en/drivers" "Best first stop for HP laptops, desktops, and printers."
        Add-Link $Links "HP Support Assistant" "https://support.hp.com/us-en/help/hp-support-assistant" "HP's official support app for finding recommended updates." "Install tool"
    }
    elseif ($m -match "asus|asustek|rog") {
        Add-Link $Links "ASUS Download Center" "https://www.asus.com/us/support/downloadcenter/" "Best first stop for ASUS systems and motherboards. Search for the exact model."
        Add-Link $Links "MyASUS" "https://www.asus.com/support/myasus-deeplink/" "ASUS' official support app for system-specific updates." "Install tool"
    }
    elseif ($m -match "micro-star|msi") {
        Add-Link $Links "MSI Downloads" "https://www.msi.com/support/download" "Best first stop for MSI laptops, desktops, graphics cards, and motherboards."
        Add-Link $Links "MSI Center" "https://www.msi.com/Landing/MSI-Center" "MSI's official utility for driver and device support." "Install tool"
    }
    elseif ($m -match "gigabyte|aorus") {
        Add-Link $Links "GIGABYTE Support" "https://www.gigabyte.com/Support" "Best first stop for GIGABYTE/AORUS systems, boards, and graphics cards."
        Add-Link $Links "GIGABYTE Control Center" "https://www.gigabyte.com/Consumer/Software/GIGABYTE-Control-Center/global/" "GIGABYTE's official update/support utility." "Install tool"
    }
    elseif ($m -match "acer") {
        Add-Link $Links "Acer Drivers and Manuals" "https://www.acer.com/us-en/support/drivers-and-manuals" "Best first stop for Acer systems. Search by serial number, SNID, or model."
    }
    elseif ($m -match "microsoft|surface") {
        Add-Link $Links "Surface Drivers and Firmware" "https://support.microsoft.com/surface" "Best first stop for Microsoft Surface drivers and firmware."
    }
    else {
        Add-Link $Links "PC Manufacturer Support Search" "https://www.google.com/search?q=$(Encode-Query ($Manufacturer + ' ' + $Model + ' drivers official support'))" "The manufacturer was not in the built-in list. Inspect results carefully and choose the official manufacturer site only." "Needs review"
    }

    if ($Model) {
        Add-Link $Links "Official Model Driver Search" "https://www.google.com/search?q=$(Encode-Query ($Manufacturer + ' ' + $Model + ' drivers official'))" "A convenience search for the exact detected model. Use only the official vendor result." "Needs review"
    }
}

function Get-ComponentLinks {
    param(
        [System.Collections.Generic.List[object]]$Links,
        [array]$Devices
    )

    $deviceText = (($Devices | ForEach-Object { "$($_.Name) $($_.Manufacturer) $($_.PNPDeviceID)" }) -join "`n").ToLowerInvariant()

    Add-Link $Links "Windows Update Optional Driver Updates" "ms-settings:windowsupdate-optionalupdates" "Open Settings > Windows Update > Advanced options > Optional updates > Driver updates." "Recommended"
    Add-Link $Links "Microsoft Update Catalog" "https://www.catalog.update.microsoft.com/" "Search Microsoft's catalog by hardware ID when the OEM page does not have what you need." "Recommended"

    if ($deviceText -match "ven_8086|intel\(r\)|\bintel\b") {
        Add-Link $Links "Intel Driver & Support Assistant" "https://www.intel.com/content/www/us/en/support/detect.html" "Official Intel tool for supported Intel chipset, graphics, Wi-Fi, Bluetooth, and storage drivers." "Install tool"
    }
    if ($deviceText -match "ven_1002|ven_1022|advanced micro devices|amd radeon|amd high definition|amd ryzen") {
        Add-Link $Links "AMD Drivers and Support" "https://www.amd.com/en/support/download/drivers.html" "Official AMD page for Radeon graphics, Ryzen chipset, and AMD auto-detect updates." "Install tool"
    }
    if ($deviceText -match "nvidia|geforce|quadro|rtx|ven_10de") {
        Add-Link $Links "NVIDIA Driver Downloads" "https://www.nvidia.com/Download/Find.aspx" "Official NVIDIA manual driver search."
        Add-Link $Links "NVIDIA App" "https://www.nvidia.com/en-us/software/nvidia-app/" "Official NVIDIA app for supported driver installation." "Install tool"
    }
    if ($deviceText -match "realtek|ven_10ec") {
        Add-Link $Links "Realtek Downloads" "https://www.realtek.com/Download/Overview" "Official Realtek download page. For audio, prefer your PC or motherboard maker first." "Secondary"
    }
    if ($deviceText -match "qualcomm|atheros|killer|ven_168c|ven_17cb") {
        Add-Link $Links "Qualcomm Driver Guidance" "https://www.qualcomm.com/drivers" "Qualcomm usually directs Windows users to OEM support pages or Windows Update." "Guidance"
    }
    if ($deviceText -match "broadcom|ven_14e4") {
        Add-Link $Links "Microsoft Update Catalog - Broadcom" "https://www.catalog.update.microsoft.com/Search.aspx?q=Broadcom%20driver" "Broadcom client drivers are usually supplied through the OEM or Microsoft Update Catalog." "Catalog search"
    }
    if ($deviceText -match "mediatek|ralink|ven_14c3|ven_1814") {
        Add-Link $Links "Microsoft Update Catalog - MediaTek" "https://www.catalog.update.microsoft.com/Search.aspx?q=MediaTek%20driver" "MediaTek/Ralink client drivers are usually supplied through the OEM or Microsoft Update Catalog." "Catalog search"
    }
}

function Get-HardwareIdLinks {
    param(
        [System.Collections.Generic.List[object]]$Links,
        [array]$Devices
    )

    $ids = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($device in $Devices) {
        $hardwareIds = $device.HardwareID
        if ($null -eq $hardwareIds) { continue }
        foreach ($id in $hardwareIds) {
            if ($id -match "^(PCI|USB|HDAUDIO|ACPI|BTHENUM)\\") {
                $shortId = $id
                if ($id -match "^(PCI\\VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4})") { $shortId = $Matches[1] }
                elseif ($id -match "^(USB\\VID_[0-9A-F]{4}&PID_[0-9A-F]{4})") { $shortId = $Matches[1] }
                elseif ($id -match "^(HDAUDIO\\FUNC_[0-9A-F]{2}&VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4})") { $shortId = $Matches[1] }
                $ids.Add($shortId) | Out-Null
            }
        }
    }

    foreach ($id in ($ids | Sort-Object | Select-Object -First 35)) {
        Add-Link $Links "Microsoft Update Catalog: $id" "https://www.catalog.update.microsoft.com/Search.aspx?q=$(Encode-Query $id)" "Exact hardware-ID search for this detected device." "Exact hardware ID"
    }
}

function Get-DetectedHardwareIds {
    param([array]$Devices)

    $ids = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($device in $Devices) {
        $hardwareIds = $device.HardwareID
        if ($null -eq $hardwareIds) { continue }
        foreach ($id in $hardwareIds) {
            if ($id -match "^(PCI|USB|HDAUDIO|ACPI|BTHENUM)\\") {
                $shortId = $id
                if ($id -match "^(PCI\\VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4})") { $shortId = $Matches[1] }
                elseif ($id -match "^(USB\\VID_[0-9A-F]{4}&PID_[0-9A-F]{4})") { $shortId = $Matches[1] }
                elseif ($id -match "^(HDAUDIO\\FUNC_[0-9A-F]{2}&VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4})") { $shortId = $Matches[1] }
                $ids.Add($shortId) | Out-Null
            }
        }
    }

    return @($ids | Sort-Object | Select-Object -First 35)
}

function Get-DriverScanData {
    $computer = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS
    $os = Get-CimInstance Win32_OperatingSystem
    $baseboard = Get-CimInstance Win32_BaseBoard
    $processor = Get-CimInstance Win32_Processor | Select-Object -First 1
    $video = Get-CimInstance Win32_VideoController
    $net = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true -and $_.Name -notmatch "Virtual|Bluetooth Device|WAN Miniport" }
    $pnp = Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPDeviceID -match "^(PCI|USB|HDAUDIO|ACPI|BTHENUM)\\" }

    return [pscustomobject]@{
        Computer = $computer
        Bios = $bios
        Os = $os
        Baseboard = $baseboard
        Processor = $processor
        Video = $video
        Network = $net
        HardwareIds = (Get-DetectedHardwareIds $pnp)
        Links = @()
    }
}

function Get-DriverReport {
    return Get-SmartDriverDownloadReport
}

function Get-OpenAiApiKey {
    $apiKey = [Environment]::GetEnvironmentVariable("OPENAI_API_KEY", "User")
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        $apiKey = [Environment]::GetEnvironmentVariable("OPENAI_API_KEY", "Machine")
    }
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        $apiKey = $env:OPENAI_API_KEY
    }
    return $apiKey
}

function Get-OpenAiModel {
    $model = $env:DRIVER_LINK_SCOUT_OPENAI_MODEL
    if ([string]::IsNullOrWhiteSpace($model)) { $model = "gpt-5" }
    return $model
}

function Get-OpenAiResponseText {
    param($Response)

    $text = $Response.output_text
    if (-not [string]::IsNullOrWhiteSpace($text)) { return $text }
    if ($null -eq $Response.output) { return "" }

    $parts = New-Object 'System.Collections.Generic.List[string]'
    foreach ($item in @($Response.output)) {
        foreach ($content in @($item.content)) {
            if ($content.text) { $parts.Add([string]$content.text) | Out-Null }
        }
    }
    return ($parts -join "`r`n")
}

function Get-CatalogDownloadUrls {
    param(
        [string]$HardwareId,
        [int]$MaxUpdates = 3
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $searchUrl = "https://www.catalog.update.microsoft.com/Search.aspx?q=$(Encode-Query $HardwareId)"
    $search = Invoke-WebRequest -Uri $searchUrl -UseBasicParsing -TimeoutSec 30
    $guids = @(
        [regex]::Matches($search.Content, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}') |
            ForEach-Object { $_.Value.ToLowerInvariant() } |
            Select-Object -Unique -First $MaxUpdates
    )

    $results = New-Object 'System.Collections.Generic.List[object]'
    foreach ($guid in $guids) {
        $payload = @(@{ size = 0; languages = ""; uidInfo = $guid; updateID = $guid }) | ConvertTo-Json -Compress
        $dialog = Invoke-WebRequest -Uri "https://www.catalog.update.microsoft.com/DownloadDialog.aspx" -Method Post -Body @{ updateIDs = $payload } -UseBasicParsing -TimeoutSec 30
        $urls = @(
            [regex]::Matches($dialog.Content, 'https?://download\.windowsupdate\.com/[^"''<>\s]+') |
                ForEach-Object { $_.Value -replace '\\u0026', '&' } |
                Select-Object -Unique
        )
        foreach ($url in $urls) {
            $results.Add([pscustomobject]@{
                HardwareId = $HardwareId
                UpdateId = $guid
                Url = $url
            }) | Out-Null
        }
    }

    return $results
}

function Get-CachePath {
    $folder = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "Driver Link Scout"
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    return (Join-Path $folder "driver-url-cache.json")
}

function Read-DriverUrlCache {
    $path = Get-CachePath
    if (-not (Test-Path $path)) { return @{} }
    try {
        $json = Get-Content -Path $path -Raw
        if ([string]::IsNullOrWhiteSpace($json)) { return @{} }
        $data = ConvertFrom-Json $json
        $cache = @{}
        foreach ($property in $data.PSObject.Properties) {
            $cache[$property.Name] = $property.Value
        }
        return $cache
    }
    catch {
        return @{}
    }
}

function Write-DriverUrlCache {
    param([hashtable]$Cache)

    $path = Get-CachePath
    ($Cache | ConvertTo-Json -Depth 8) | Set-Content -Path $path -Encoding UTF8
}

function Get-CacheKey {
    param($Device)

    if ($Device.HardwareId) { return $Device.HardwareId }
    return ($Device.Name -replace '[^A-Za-z0-9]+', '_')
}

function Get-VendorDomainsForDevice {
    param($Device)

    $text = ("{0} {1} {2}" -f $Device.Name, $Device.Manufacturer, $Device.HardwareId).ToLowerInvariant()
    $domains = New-Object 'System.Collections.Generic.List[string]'
    $domains.Add("catalog.update.microsoft.com") | Out-Null
    $domains.Add("download.windowsupdate.com") | Out-Null

    if ($text -match "ven_8086|intel") { $domains.Add("intel.com") | Out-Null }
    if ($text -match "ven_10de|nvidia|geforce|rtx|gtx") { $domains.Add("nvidia.com") | Out-Null }
    if ($text -match "ven_1002|ven_1022|amd radeon|advanced micro devices|amd ryzen") { $domains.Add("amd.com") | Out-Null }
    if ($text -match "ven_10ec|realtek") { $domains.Add("realtek.com") | Out-Null }
    if ($text -match "ven_14c3|mediatek|ralink") { $domains.Add("mediatek.com") | Out-Null }
    if ($text -match "ven_168c|ven_17cb|qualcomm|atheros|killer") { $domains.Add("qualcomm.com") | Out-Null }
    if ($text -match "ven_14e4|broadcom") { $domains.Add("broadcom.com") | Out-Null }

    return @($domains | Select-Object -Unique)
}

function Test-AllowedDomain {
    param(
        [string]$Url,
        [array]$Domains
    )

    try {
        $hostName = ([Uri]$Url).Host.ToLowerInvariant()
    }
    catch {
        return $false
    }

    foreach ($domain in $Domains) {
        if ($hostName -eq $domain -or $hostName.EndsWith("." + $domain)) { return $true }
    }
    return $false
}

function Test-DriverDownloadUrl {
    param([string]$Url)

    if ([string]::IsNullOrWhiteSpace($Url)) { return $false }
    if ($Url -notmatch "^https?://") { return $false }
    return ($Url -match "(?i)\.(exe|msi|zip|cab)(\?|$)")
}

function Resolve-Url {
    param(
        [string]$BaseUrl,
        [string]$Href
    )

    if ([string]::IsNullOrWhiteSpace($Href)) { return "" }
    $Href = $Href -replace "&amp;", "&"
    if ($Href -match "^https?://") { return $Href }
    try {
        return ([Uri]::new([Uri]$BaseUrl, $Href)).AbsoluteUri
    }
    catch {
        return ""
    }
}

function Get-SearchResultUrls {
    param(
        [string]$Query,
        [array]$AllowedDomains,
        [int]$MaxResults = 8
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $headers = @{ "User-Agent" = "Mozilla/5.0" }
    $urls = New-Object 'System.Collections.Generic.List[string]'
    $searchUrls = @(
        "https://www.google.com/search?q=$(Encode-Query $Query)",
        "https://duckduckgo.com/html/?q=$(Encode-Query $Query)"
    )

    foreach ($searchUrl in $searchUrls) {
        try {
            $response = Invoke-WebRequest -Uri $searchUrl -UseBasicParsing -TimeoutSec 25 -Headers $headers
            $hrefs = [regex]::Matches($response.Content, 'href="(?<url>[^"]+)"')
            foreach ($match in $hrefs) {
                $url = $match.Groups["url"].Value -replace "&amp;", "&"
                if ($url -match "/url\?q=([^&]+)") {
                    $url = [Uri]::UnescapeDataString($Matches[1])
                }
                elseif ($url -match "uddg=([^&]+)") {
                    $url = [Uri]::UnescapeDataString($Matches[1])
                }
                if ($url -notmatch "^https?://") { continue }
                if (-not (Test-AllowedDomain $url $AllowedDomains)) { continue }
                if ($urls -notcontains $url) { $urls.Add($url) | Out-Null }
                if ($urls.Count -ge $MaxResults) { return @($urls) }
            }
        }
        catch {
            continue
        }
    }

    return @($urls)
}

function Get-DirectDownloadsFromPage {
    param(
        [string]$PageUrl,
        [array]$AllowedDomains,
        [int]$MaxResults = 6
    )

    $downloads = New-Object 'System.Collections.Generic.List[string]'
    if (Test-DriverDownloadUrl $PageUrl) {
        if (Test-AllowedDomain $PageUrl $AllowedDomains) { $downloads.Add($PageUrl) | Out-Null }
        return @($downloads)
    }

    try {
        $response = Invoke-WebRequest -Uri $PageUrl -UseBasicParsing -TimeoutSec 30 -Headers @{ "User-Agent" = "Mozilla/5.0" }
    }
    catch {
        return @()
    }

    $hrefs = [regex]::Matches($response.Content, '(?i)(href|src)=["''](?<url>[^"'']+)["'']')
    foreach ($match in $hrefs) {
        $url = Resolve-Url $PageUrl $match.Groups["url"].Value
        if (-not (Test-DriverDownloadUrl $url)) { continue }
        if (-not (Test-AllowedDomain $url $AllowedDomains)) { continue }
        if ($downloads -notcontains $url) { $downloads.Add($url) | Out-Null }
        if ($downloads.Count -ge $MaxResults) { break }
    }

    return @($downloads)
}

function Get-AiDriverUrls {
    param(
        $Device,
        [array]$AllowedDomains
    )

    $apiKey = Get-OpenAiApiKey
    if ([string]::IsNullOrWhiteSpace($apiKey)) { return @() }

    $model = Get-OpenAiModel

    $prompt = @"
You are helping a custom PC builder find exact driver download files.

Device name: $($Device.Name)
Device manufacturer: $($Device.Manufacturer)
Device class: $($Device.PnpClass)
Hardware ID: $($Device.HardwareId)
Allowed domains: $($AllowedDomains -join ", ")

Search the web. Return ONLY JSON with this shape:
{"urls":["https://..."]}

Rules:
- Include only direct driver package file URLs ending in .exe, .msi, .zip, or .cab.
- Include only official vendor or Microsoft domains from the allowed domains list.
- Do not include support pages, search pages, homepages, manuals, BIOS files, ads, mirrors, forums, or third-party driver updater sites.
- If no exact direct driver file URL is findable, return {"urls":[]}.
"@

    $body = @{
        model = $model
        tools = @(@{ type = "web_search" })
        input = $prompt
    } | ConvertTo-Json -Depth 8

    try {
        $response = Invoke-RestMethod `
            -Uri "https://api.openai.com/v1/responses" `
            -Method Post `
            -Headers @{ "Authorization" = "Bearer $apiKey"; "Content-Type" = "application/json" } `
            -Body $body `
            -TimeoutSec 90
    }
    catch {
        return @()
    }

    $text = Get-OpenAiResponseText $response
    if ([string]::IsNullOrWhiteSpace($text)) { $text = ($response.output | ConvertTo-Json -Depth 12) }
    $jsonText = ([regex]::Match($text, '\{[\s\S]*\}')).Value
    if ([string]::IsNullOrWhiteSpace($jsonText)) { return @() }

    try {
        $parsed = ConvertFrom-Json $jsonText
    }
    catch {
        return @()
    }

    $urls = New-Object 'System.Collections.Generic.List[string]'
    foreach ($url in @($parsed.urls)) {
        if (-not (Test-DriverDownloadUrl $url)) { continue }
        if (-not (Test-AllowedDomain $url $AllowedDomains)) { continue }
        if ($urls -notcontains $url) { $urls.Add($url) | Out-Null }
    }

    return @($urls | Select-Object -First 4)
}

function Invoke-DriverAssistantChat {
    param(
        [string]$Message,
        [string]$ReportContext
    )

    $apiKey = Get-OpenAiApiKey
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        return @"
OpenAI is not connected yet.

Set OPENAI_API_KEY on this Windows PC, restart Driver Link Scout, then press ASK AI again.

PowerShell:
[Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "your_api_key_here", "User")
"@
    }

    $model = Get-OpenAiModel
    if ($ReportContext.Length -gt 9000) {
        $ReportContext = $ReportContext.Substring(0, 9000)
    }

    $prompt = @"
You are Driver Link Scout's AI assistant for a custom PC builder.

Goal:
- Help identify exact official driver download files for detected Windows hardware.
- Prefer official PC, motherboard, chipset, GPU, network, audio, Bluetooth, storage, and Microsoft sources.
- Never recommend third-party driver updater sites, mirrors, forums, ads, or random file hosts.
- If a direct official package URL is not verifiable, say that and give the safest official next step.
- If you list URLs, make each URL clickable and explain what hardware it appears to match.
- Do not tell the user to run downloaded installers automatically.

Current scan/report context:
$ReportContext

User question:
$Message
"@

    $body = @{
        model = $model
        tools = @(@{ type = "web_search" })
        input = $prompt
    } | ConvertTo-Json -Depth 8

    try {
        $response = Invoke-RestMethod `
            -Uri "https://api.openai.com/v1/responses" `
            -Method Post `
            -Headers @{ "Authorization" = "Bearer $apiKey"; "Content-Type" = "application/json" } `
            -Body $body `
            -TimeoutSec 120
        $text = Get-OpenAiResponseText $response
        if ([string]::IsNullOrWhiteSpace($text)) { return "AI returned an empty response." }
        return $text
    }
    catch {
        return "AI request failed:`r`n`r`n$($_.Exception.Message)"
    }
}

function Get-SmartDriverUrls {
    param(
        $Device,
        [hashtable]$Cache
    )

    $key = Get-CacheKey $Device
    if ($Cache.ContainsKey($key) -and $Cache[$key].Urls -and $Cache[$key].Urls.Count -gt 0) {
        return [pscustomobject]@{
            Source = "cache"
            Urls = @($Cache[$key].Urls)
            Query = $Cache[$key].Query
        }
    }

    $allowedDomains = Get-VendorDomainsForDevice $Device
    $queries = @(
        ("{0} {1} driver download" -f $Device.Name, $Device.HardwareId),
        ("{0} driver download official" -f $Device.Name),
        ("{0} Windows driver download" -f $Device.HardwareId)
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    $found = New-Object 'System.Collections.Generic.List[string]'
    $usedQuery = ""

    $aiUrls = @(Get-AiDriverUrls $Device $allowedDomains)
    foreach ($url in $aiUrls) {
        if ($found -notcontains $url) { $found.Add($url) | Out-Null }
    }
    if ($found.Count -gt 0) { $usedQuery = "OpenAI web search resolver" }

    foreach ($query in $queries) {
        if ($found.Count -gt 0) { break }
        $usedQuery = $query
        $resultPages = @(Get-SearchResultUrls $query $allowedDomains 8)
        foreach ($page in $resultPages) {
            $direct = @(Get-DirectDownloadsFromPage $page $allowedDomains 6)
            foreach ($url in $direct) {
                if ($found -notcontains $url) { $found.Add($url) | Out-Null }
            }
            if ($found.Count -ge 4) { break }
        }
        if ($found.Count -gt 0) { break }
    }

    if ($found.Count -eq 0 -and $Device.HardwareId) {
        try {
            $catalogUrls = @(Get-CatalogDownloadUrls $Device.HardwareId 2 | Select-Object -ExpandProperty Url -Unique | Select-Object -First 4)
            foreach ($url in $catalogUrls) {
                if ($found -notcontains $url) { $found.Add($url) | Out-Null }
            }
            if ($catalogUrls.Count -gt 0) { $usedQuery = "Microsoft Catalog: $($Device.HardwareId)" }
        }
        catch {}
    }

    if ($found.Count -gt 0) {
        $Cache[$key] = [pscustomobject]@{
            DeviceName = $Device.Name
            HardwareId = $Device.HardwareId
            Query = $usedQuery
            Urls = @($found | Select-Object -First 4)
            UpdatedAt = (Get-Date -Format "o")
        }
        Write-DriverUrlCache $Cache
    }

    return [pscustomobject]@{
        Source = "web"
        Urls = @($found | Select-Object -First 4)
        Query = $usedQuery
    }
}

function Get-SmartDriverDownloadReport {
    $candidates = @(Get-DriverNeedCandidates | Where-Object { $_.HardwareId } | Select-Object -First 25)
    $cache = Read-DriverUrlCache
    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add("Driver Link Scout Smart Driver Download Links") | Out-Null
    $lines.Add(("Generated: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))) | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("Only direct downloadable files from official vendor/Microsoft domains are shown.") | Out-Null
    $lines.Add("Cached matches are remembered by hardware ID.") | Out-Null
    $lines.Add("") | Out-Null

    if ($candidates.Count -eq 0) {
        $lines.Add("No driver-needed/core components with hardware IDs were found.") | Out-Null
        return ($lines -join [Environment]::NewLine)
    }

    foreach ($device in $candidates) {
        $lines.Add($device.Name) | Out-Null
        $lines.Add(("  Hardware ID: {0}" -f $device.HardwareId)) | Out-Null
        $lines.Add(("  Reason: {0}" -f $device.Reason)) | Out-Null
        $result = Get-SmartDriverUrls $device $cache
        $lines.Add(("  Search path: {0}" -f $result.Query)) | Out-Null
        $lines.Add(("  Source: {0}" -f $result.Source)) | Out-Null
        if ($result.Urls.Count -eq 0) {
            $lines.Add("  No exact direct download file found.") | Out-Null
        }
        else {
            $n = 1
            foreach ($url in $result.Urls) {
                $lines.Add(("  {0}. {1}" -f $n, $url)) | Out-Null
                $n++
            }
        }
        $lines.Add("") | Out-Null
    }

    return ($lines -join [Environment]::NewLine)
}

function Get-ExactCatalogDownloadReport {
    $candidates = @(Get-DriverNeedCandidates | Where-Object { $_.HardwareId } | Select-Object -First 25)
    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add("Driver Link Scout Exact Driver Download Links") | Out-Null
    $lines.Add(("Generated: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))) | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("Source: Microsoft Update Catalog direct package URLs for driver-needed/core components only.") | Out-Null
    $lines.Add("Click any URL in this report to open it.") | Out-Null
    $lines.Add("") | Out-Null

    if ($candidates.Count -eq 0) {
        $lines.Add("No driver-needed/core components with hardware IDs were found.") | Out-Null
        return ($lines -join [Environment]::NewLine)
    }

    $seenHardwareIds = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($device in $candidates) {
        $hardwareId = $device.HardwareId
        if (-not $seenHardwareIds.Add($hardwareId)) { continue }

        $lines.Add($device.Name) | Out-Null
        $lines.Add(("  Reason: {0}" -f $device.Reason)) | Out-Null
        $lines.Add(("  Hardware ID: {0}" -f $hardwareId)) | Out-Null
        try {
            $matches = @(Get-CatalogDownloadUrls $hardwareId 2)
            if ($matches.Count -eq 0) {
                $lines.Add("  No direct package URL found.") | Out-Null
            }
            else {
                $n = 1
                foreach ($match in $matches | Select-Object -First 4) {
                    $lines.Add(("  {0}. {1}" -f $n, $match.Url)) | Out-Null
                    $n++
                }
            }
        }
        catch {
            $lines.Add(("  Lookup failed: {0}" -f $_.Exception.Message)) | Out-Null
        }
        $lines.Add("") | Out-Null
    }

    $lines.Add("Important") | Out-Null
    $lines.Add("- These are direct Microsoft Catalog package links, usually .cab files.") | Out-Null
    $lines.Add("- Pick packages matching the Windows version and architecture shown in the normal inspection report.") | Out-Null
    $lines.Add("- OEM drivers can still be better for laptops and prebuilts when Microsoft does not expose the exact customized package.") | Out-Null

    return ($lines -join [Environment]::NewLine)
}

function Get-PrimaryHardwareId {
    param($Device)

    $hardwareIds = $Device.HardwareID
    if ($null -eq $hardwareIds) { return "" }
    foreach ($id in $hardwareIds) {
        if ($id -match "^(PCI\\VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4})") { return $Matches[1] }
        if ($id -match "^(USB\\VID_[0-9A-F]{4}&PID_[0-9A-F]{4})") { return $Matches[1] }
        if ($id -match "^(HDAUDIO\\FUNC_[0-9A-F]{2}&VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4})") { return $Matches[1] }
    }
    return [string]($hardwareIds | Select-Object -First 1)
}

function Test-CoreDriverClass {
    param([string]$PnpClass)

    return ($PnpClass -match "Display|Net|MEDIA|HDC|SCSIAdapter|System|Bluetooth|Biometric|Camera")
}

function Get-DriverNeedCandidates {
    $pnpDevices = Get-CimInstance Win32_PnPEntity | Where-Object {
        $_.PNPDeviceID -match "^(PCI|USB|HDAUDIO|ACPI|BTHENUM)\\" -and
        $_.Name -and
        $_.Name -notmatch "Generic volume|USB Composite Device|Root Hub|Microsoft|WAN Miniport|Volume Manager"
    }
    $signedDrivers = Get-CimInstance Win32_PnPSignedDriver
    $driverByDevice = @{}
    foreach ($driver in $signedDrivers) {
        if ($driver.DeviceID) { $driverByDevice[$driver.DeviceID] = $driver }
    }

    $candidates = New-Object 'System.Collections.Generic.List[object]'
    foreach ($device in $pnpDevices) {
        $driver = $driverByDevice[$device.PNPDeviceID]
        $problem = ($device.ConfigManagerErrorCode -and $device.ConfigManagerErrorCode -ne 0)
        $missingDriver = ($null -eq $driver -or [string]::IsNullOrWhiteSpace($driver.DriverVersion) -or [string]::IsNullOrWhiteSpace($driver.DriverProviderName))
        $coreClass = Test-CoreDriverClass $device.PNPClass
        if (-not ($problem -or $missingDriver -or $coreClass)) { continue }

        $reason = "Core driver candidate"
        if ($problem) { $reason = "Device Manager problem code $($device.ConfigManagerErrorCode)" }
        elseif ($missingDriver) { $reason = "Missing or incomplete driver metadata" }

        $candidates.Add([pscustomobject]@{
            Name = $device.Name
            Manufacturer = $device.Manufacturer
            PnpClass = $device.PNPClass
            HardwareId = (Get-PrimaryHardwareId $device)
            PnpDeviceId = $device.PNPDeviceID
            Reason = $reason
            DriverProvider = $driver.DriverProviderName
            DriverVersion = $driver.DriverVersion
            DriverDate = $driver.DriverDate
        }) | Out-Null
    }

    return @($candidates | Sort-Object Reason, PnpClass, Name)
}

function Get-OfficialSearchDomains {
    return @(
        "catalog.update.microsoft.com",
        "download.windowsupdate.com",
        "intel.com",
        "amd.com",
        "nvidia.com",
        "dell.com",
        "lenovo.com",
        "hp.com",
        "asus.com",
        "msi.com",
        "gigabyte.com",
        "realtek.com",
        "qualcomm.com",
        "acer.com",
        "microsoft.com"
    )
}

function Test-OfficialDriverUrl {
    param([string]$Url)

    if ([string]::IsNullOrWhiteSpace($Url)) { return $false }
    try {
        $hostName = ([Uri]$Url).Host.ToLowerInvariant()
    }
    catch {
        return $false
    }

    foreach ($domain in (Get-OfficialSearchDomains)) {
        if ($hostName -eq $domain -or $hostName.EndsWith("." + $domain)) { return $true }
    }
    return $false
}

function Get-OfficialWebSearchUrls {
    param(
        [string]$Query,
        [int]$MaxResults = 5
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $searchUrl = "https://duckduckgo.com/html/?q=$(Encode-Query $Query)"
    $response = Invoke-WebRequest -Uri $searchUrl -UseBasicParsing -TimeoutSec 25 -Headers @{ "User-Agent" = "Mozilla/5.0" }
    $urls = New-Object 'System.Collections.Generic.List[string]'
    $matches = [regex]::Matches($response.Content, 'href="(?<url>[^"]+)"')
    foreach ($match in $matches) {
        $url = $match.Groups["url"].Value -replace "&amp;", "&"
        if ($url -match "uddg=([^&]+)") {
            $url = [Uri]::UnescapeDataString($Matches[1])
        }
        if ($url -notmatch "^https?://") { continue }
        if (-not (Test-OfficialDriverUrl $url)) { continue }
        if ($url -notmatch "(driver|download|support|catalog|detect|update)") { continue }
        if ($urls -notcontains $url) { $urls.Add($url) | Out-Null }
        if ($urls.Count -ge $MaxResults) { break }
    }
    return @($urls)
}

function Get-NeededDriverDownloadReport {
    $scan = Get-DriverScanData
    $computer = $scan.Computer
    $candidates = @(Get-DriverNeedCandidates)
    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add("Driver Link Scout Needed Driver Download Links") | Out-Null
    $lines.Add(("Generated: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))) | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add(("Computer: {0} {1}" -f $computer.Manufacturer, $computer.Model)) | Out-Null
    $lines.Add("This report focuses on devices with driver problems, missing driver metadata, or core hardware classes that commonly need vendor drivers.") | Out-Null
    $lines.Add("Click any URL to open it.") | Out-Null
    $lines.Add("") | Out-Null

    if ($candidates.Count -eq 0) {
        $lines.Add("No obvious driver-needed devices were found.") | Out-Null
        return ($lines -join [Environment]::NewLine)
    }

    $index = 1
    foreach ($device in ($candidates | Select-Object -First 25)) {
        $lines.Add(("{0}. {1}" -f $index, $device.Name)) | Out-Null
        $lines.Add(("   Class: {0}" -f $device.PnpClass)) | Out-Null
        $lines.Add(("   Reason: {0}" -f $device.Reason)) | Out-Null
        $lines.Add(("   Current driver: {0} {1}" -f $device.DriverProvider, $device.DriverVersion)) | Out-Null
        if ($device.HardwareId) { $lines.Add(("   Hardware ID: {0}" -f $device.HardwareId)) | Out-Null }

        if ($device.HardwareId) {
            $lines.Add("   Microsoft Catalog direct package URLs:") | Out-Null
            try {
                $catalogMatches = @(Get-CatalogDownloadUrls $device.HardwareId 2)
                if ($catalogMatches.Count -eq 0) {
                    $lines.Add(("     https://www.catalog.update.microsoft.com/Search.aspx?q={0}" -f (Encode-Query $device.HardwareId))) | Out-Null
                }
                else {
                    foreach ($match in ($catalogMatches | Select-Object -First 4)) {
                        $lines.Add(("     {0}" -f $match.Url)) | Out-Null
                    }
                }
            }
            catch {
                $lines.Add(("     https://www.catalog.update.microsoft.com/Search.aspx?q={0}" -f (Encode-Query $device.HardwareId))) | Out-Null
            }
        }

        $queryParts = @($computer.Manufacturer, $computer.Model, $device.Name, $device.HardwareId, "driver download official")
        $query = (($queryParts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join " ")
        $lines.Add("   Official web candidates:") | Out-Null
        try {
            $webUrls = @(Get-OfficialWebSearchUrls $query 5)
            if ($webUrls.Count -eq 0) {
                $lines.Add(("     https://www.google.com/search?q={0}" -f (Encode-Query $query))) | Out-Null
            }
            else {
                foreach ($url in $webUrls) {
                    $lines.Add(("     {0}" -f $url)) | Out-Null
                }
            }
        }
        catch {
            $lines.Add(("     https://www.google.com/search?q={0}" -f (Encode-Query $query))) | Out-Null
        }

        $lines.Add("") | Out-Null
        $index++
    }

    $lines.Add("Safety filter") | Out-Null
    $lines.Add("- Web results are filtered to official vendor/Microsoft domains only.") | Out-Null
    $lines.Add("- Direct Microsoft package URLs are usually .cab files and may need manual installation through Device Manager or pnputil.") | Out-Null
    $lines.Add("- OEM laptop/prebuilt model pages can still be the best match when available.") | Out-Null

    return ($lines -join [Environment]::NewLine)
}

function ConvertTo-SafeFileName {
    param([string]$Value)
    $safe = $Value -replace '[\\/:*?"<>|]', '-'
    $safe = $safe -replace '\s+', ' '
    $safe = $safe.Trim()
    if ($safe.Length -gt 84) { $safe = $safe.Substring(0, 84).Trim() }
    if ([string]::IsNullOrWhiteSpace($safe)) { return "Driver Source" }
    return $safe
}

function New-InternetShortcut {
    param(
        [string]$Path,
        [string]$Url
    )

    $content = "[InternetShortcut]`r`nURL=$Url`r`n"
    [System.IO.File]::WriteAllText($Path, $content)
}

function New-DriverDownloadPack {
    $root = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads"
    $folderName = "Driver-Link-Scout-Downloaded-Drivers-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
    $folder = Join-Path $root $folderName
    New-Item -ItemType Directory -Path $folder -Force | Out-Null

    $candidates = @(Get-DriverNeedCandidates)
    $manifest = New-Object 'System.Collections.Generic.List[string]'
    $manifest.Add("Driver Link Scout Downloaded Driver Pack") | Out-Null
    $manifest.Add(("Generated: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))) | Out-Null
    $manifest.Add("") | Out-Null
    $manifest.Add("Source: Smart official-download resolver matched by hardware ID.") | Out-Null
    $manifest.Add("These packages are downloaded only. Nothing is installed.") | Out-Null
    $manifest.Add("") | Out-Null

    $downloaded = 0
    $skipped = 0
    $seenUrls = New-Object 'System.Collections.Generic.HashSet[string]'
    $cache = Read-DriverUrlCache

    foreach ($device in ($candidates | Where-Object { $_.HardwareId } | Select-Object -First 25)) {
        $manifest.Add($device.Name) | Out-Null
        $manifest.Add(("  Reason: {0}" -f $device.Reason)) | Out-Null
        $manifest.Add(("  Hardware ID: {0}" -f $device.HardwareId)) | Out-Null

        try {
            $smartResult = Get-SmartDriverUrls $device $cache
            $urls = @($smartResult.Urls | Select-Object -Unique | Select-Object -First 3)
            if ($urls.Count -eq 0) {
                $manifest.Add("  No exact direct download file found.") | Out-Null
                $skipped++
            }
            foreach ($url in $urls) {
                if (-not $seenUrls.Add($url)) { continue }
                $uri = [Uri]$url
                $sourceName = [IO.Path]::GetFileName($uri.AbsolutePath)
                if ([string]::IsNullOrWhiteSpace($sourceName)) { $sourceName = "driver-package.cab" }
                $safeDevice = ConvertTo-SafeFileName $device.Name
                $targetName = "{0:00} - {1} - {2}" -f ($downloaded + 1), $safeDevice, $sourceName
                if ($targetName.Length -gt 150) { $targetName = $targetName.Substring(0, 145) + [IO.Path]::GetExtension($sourceName) }
                $targetPath = Join-Path $folder $targetName
                Invoke-WebRequest -Uri $url -OutFile $targetPath -UseBasicParsing -TimeoutSec 300
                $manifest.Add(("  Downloaded: {0}" -f $targetName)) | Out-Null
                $manifest.Add(("  URL: {0}" -f $url)) | Out-Null
                $downloaded++
            }
        }
        catch {
            $manifest.Add(("  Download failed: {0}" -f $_.Exception.Message)) | Out-Null
            $skipped++
        }
        $manifest.Add("") | Out-Null
    }

    if ($downloaded -eq 0) {
        $manifest.Add("No driver packages were downloaded. Run SCAN LINKS to inspect direct package URL results for this PC.") | Out-Null
    }
    $manifest.Add("Install note") | Out-Null
    $manifest.Add("- Downloaded files are from cached or freshly discovered official vendor/Microsoft direct URLs.") | Out-Null
    $manifest.Add("- Packages may be .exe, .msi, .zip, or .cab. Confirm the correct device/OS before installing.") | Out-Null

    $manifestPath = Join-Path $folder "download-manifest.txt"
    [System.IO.File]::WriteAllText($manifestPath, ($manifest -join "`r`n"))
    Start-Process $folder | Out-Null

    return "Driver download complete.`r`n`r`nDownloaded packages: $downloaded`r`nSkipped/no direct file: $skipped`r`n`r`nFolder:`r`n$folder`r`n`r`nRead download-manifest.txt before installing. This downloaded direct files from official vendor/Microsoft URLs only; it did not install or run anything."
}

function New-AppButton {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [System.Drawing.Color]$BackColor,
        [System.Drawing.Color]$ForeColor
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.FlatStyle = "Flat"
    $button.FlatAppearance.BorderSize = 0
    $button.BackColor = $BackColor
    $button.ForeColor = $ForeColor
    $button.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $button.Size = New-Object System.Drawing.Size($Width, 40)
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $normal = $BackColor
    $hover = [System.Drawing.Color]::FromArgb(
        [Math]::Min(255, $BackColor.R + 16),
        [Math]::Min(255, $BackColor.G + 16),
        [Math]::Min(255, $BackColor.B + 16)
    )
    $button.Add_MouseEnter({ $this.BackColor = $hover })
    $button.Add_MouseLeave({ $this.BackColor = $normal })
    return $button
}

$appBg = [System.Drawing.Color]::FromArgb(7, 11, 18)
$appPanel = [System.Drawing.Color]::FromArgb(14, 20, 31)
$appPanel2 = [System.Drawing.Color]::FromArgb(18, 27, 42)
$appText = [System.Drawing.Color]::FromArgb(234, 242, 248)
$appMuted = [System.Drawing.Color]::FromArgb(151, 166, 184)
$appGreen = [System.Drawing.Color]::FromArgb(41, 222, 156)
$appBlue = [System.Drawing.Color]::FromArgb(64, 152, 255)
$appOrange = [System.Drawing.Color]::FromArgb(255, 177, 83)

function Show-AiAssistantWindow {
    param(
        [string]$InitialContext
    )

    $chatForm = New-Object System.Windows.Forms.Form
    $chatForm.Text = "Ask AI"
    $chatForm.Size = New-Object System.Drawing.Size(760, 620)
    $chatForm.StartPosition = "CenterParent"
    $chatForm.MinimumSize = New-Object System.Drawing.Size(620, 500)
    $chatForm.BackColor = $appBg
    $chatForm.ForeColor = $appText

    $chatHeader = New-Object System.Windows.Forms.Label
    $chatHeader.Text = "Ask AI"
    $chatHeader.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 20)
    $chatHeader.ForeColor = $appGreen
    $chatHeader.AutoSize = $true
    $chatHeader.Location = New-Object System.Drawing.Point(22, 18)
    $chatForm.Controls.Add($chatHeader)

    $chatStatus = New-Object System.Windows.Forms.Label
    $chatStatus.Text = "Uses the current scan/report as context."
    $chatStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $chatStatus.ForeColor = $appMuted
    $chatStatus.AutoSize = $true
    $chatStatus.Location = New-Object System.Drawing.Point(25, 56)
    $chatForm.Controls.Add($chatStatus)

    $chatLog = New-Object System.Windows.Forms.RichTextBox
    $chatLog.ReadOnly = $true
    $chatLog.DetectUrls = $true
    $chatLog.BorderStyle = "None"
    $chatLog.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $chatLog.BackColor = [System.Drawing.Color]::FromArgb(8, 13, 21)
    $chatLog.ForeColor = [System.Drawing.Color]::FromArgb(215, 228, 236)
    $chatLog.Location = New-Object System.Drawing.Point(24, 88)
    $chatLog.Size = New-Object System.Drawing.Size(($chatForm.ClientSize.Width - 48), ($chatForm.ClientSize.Height - 226))
    $chatLog.Anchor = "Top,Bottom,Left,Right"
    $chatLog.Text = "Ask about missing drivers, suspicious results, or a specific device from the scan.`r`n"
    $chatLog.Add_LinkClicked({ Start-Process $_.LinkText | Out-Null })
    $chatForm.Controls.Add($chatLog)

    $questionBox = New-Object System.Windows.Forms.TextBox
    $questionBox.Multiline = $true
    $questionBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $questionBox.BackColor = [System.Drawing.Color]::FromArgb(14, 20, 31)
    $questionBox.ForeColor = $appText
    $questionBox.BorderStyle = "FixedSingle"
    $questionBox.Location = New-Object System.Drawing.Point(24, ($chatForm.ClientSize.Height - 122))
    $questionBox.Size = New-Object System.Drawing.Size(($chatForm.ClientSize.Width - 182), 72)
    $questionBox.Anchor = "Bottom,Left,Right"
    $questionBox.Text = "Find exact official driver download links for the devices in this scan."
    $chatForm.Controls.Add($questionBox)

    $askButton = New-AppButton "ASK" ($chatForm.ClientSize.Width - 142) ($chatForm.ClientSize.Height - 122) 118 $appGreen $appBg
    $askButton.Anchor = "Bottom,Right"
    $chatForm.Controls.Add($askButton)

    $closeButton = New-AppButton "CLOSE" ($chatForm.ClientSize.Width - 142) ($chatForm.ClientSize.Height - 70) 118 $appPanel2 $appText
    $closeButton.Anchor = "Bottom,Right"
    $chatForm.Controls.Add($closeButton)

    $sendQuestion = {
        $message = $questionBox.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($message)) { return }

        $askButton.Enabled = $false
        $questionBox.Enabled = $false
        $chatStatus.Text = "Thinking..."
        $chatLog.AppendText("`r`nYou:`r`n$message`r`n")
        [System.Windows.Forms.Application]::DoEvents()

        $answer = Invoke-DriverAssistantChat $message $InitialContext
        $chatLog.AppendText("`r`nAI:`r`n$answer`r`n")
        $chatLog.SelectionStart = $chatLog.TextLength
        $chatLog.ScrollToCaret()
        $chatStatus.Text = "Ready"
        $questionBox.Enabled = $true
        $askButton.Enabled = $true
        $questionBox.Focus()
    }

    $askButton.Add_Click($sendQuestion)
    $closeButton.Add_Click({ $chatForm.Close() })
    [void]$chatForm.ShowDialog($form)
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Driver Link Scout"
$form.Size = New-Object System.Drawing.Size(1080, 760)
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object System.Drawing.Size(860, 620)
$form.BackColor = $appBg
$form.ForeColor = $appText

$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.Size = New-Object System.Drawing.Size($form.ClientSize.Width, 172)
$header.Anchor = "Top,Left,Right"
$header.BackColor = $appPanel
$header.Add_Paint({
    param($sender, $event)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $sender.Width, $sender.Height)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(8, 14, 24),
        [System.Drawing.Color]::FromArgb(19, 43, 55),
        0
    )
    $event.Graphics.FillRectangle($brush, $rect)
    $brush.Dispose()
    $pen = New-Object System.Drawing.Pen($appGreen, 3)
    $event.Graphics.DrawLine($pen, 0, $sender.Height - 2, $sender.Width, $sender.Height - 2)
    $pen.Dispose()
})
$form.Controls.Add($header)

$brand = New-Object System.Windows.Forms.Label
$brand.Text = "DLS"
$brand.Font = New-Object System.Drawing.Font("Segoe UI Black", 28, [System.Drawing.FontStyle]::Bold)
$brand.ForeColor = $appGreen
$brand.BackColor = [System.Drawing.Color]::Transparent
$brand.AutoSize = $true
$brand.Location = New-Object System.Drawing.Point(28, 22)
$header.Controls.Add($brand)

$title = New-Object System.Windows.Forms.Label
$title.Text = "Driver Link Scout"
$title.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 24)
$title.ForeColor = $appText
$title.BackColor = [System.Drawing.Color]::Transparent
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(28, 68)
$header.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "Smart-search exact official driver downloads and remember matches by hardware ID."
$subtitle.Font = New-Object System.Drawing.Font("Segoe UI", 10.5)
$subtitle.ForeColor = $appMuted
$subtitle.BackColor = [System.Drawing.Color]::Transparent
$subtitle.AutoSize = $true
$subtitle.Location = New-Object System.Drawing.Point(31, 112)
$header.Controls.Add($subtitle)

$signal = New-Object System.Windows.Forms.Label
$signal.Text = "INSPECTION MODE"
$signal.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
$signal.ForeColor = $appBg
$signal.BackColor = $appOrange
$signal.TextAlign = "MiddleCenter"
$signal.Size = New-Object System.Drawing.Size(142, 28)
$signal.Anchor = "Top,Right"
$signal.Location = New-Object System.Drawing.Point(900, 30)
$header.Controls.Add($signal)

$statusShell = New-Object System.Windows.Forms.Panel
$statusShell.BackColor = [System.Drawing.Color]::FromArgb(10, 17, 27)
$statusShell.Size = New-Object System.Drawing.Size(180, 34)
$statusShell.Anchor = "Top,Right"
$statusShell.Location = New-Object System.Drawing.Point(862, 76)
$header.Controls.Add($statusShell)

$statusTag = New-Object System.Windows.Forms.Label
$statusTag.Text = "LIVE"
$statusTag.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8)
$statusTag.ForeColor = $appGreen
$statusTag.AutoSize = $true
$statusTag.Location = New-Object System.Drawing.Point(12, 9)
$statusShell.Controls.Add($statusTag)

$status = New-Object System.Windows.Forms.Label
$status.Text = "Ready"
$status.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
$status.ForeColor = $appText
$status.AutoSize = $true
$status.Location = New-Object System.Drawing.Point(36, 8)
$statusShell.Controls.Add($status)

$main = New-Object System.Windows.Forms.Panel
$main.Location = New-Object System.Drawing.Point(24, 194)
$main.Size = New-Object System.Drawing.Size(($form.ClientSize.Width - 48), ($form.ClientSize.Height - 216))
$main.Anchor = "Top,Bottom,Left,Right"
$main.BackColor = $appBg
$form.Controls.Add($main)

$reportShell = New-Object System.Windows.Forms.Panel
$reportShell.Location = New-Object System.Drawing.Point(0, 92)
$reportShell.Size = New-Object System.Drawing.Size($main.ClientSize.Width, ($main.ClientSize.Height - 92))
$reportShell.Anchor = "Top,Bottom,Left,Right"
$reportShell.Padding = New-Object System.Windows.Forms.Padding(1)
$reportShell.BackColor = [System.Drawing.Color]::FromArgb(39, 62, 82)
$main.Controls.Add($reportShell)

$commandBar = New-Object System.Windows.Forms.Panel
$commandBar.Location = New-Object System.Drawing.Point(0, 0)
$commandBar.Size = New-Object System.Drawing.Size($main.ClientSize.Width, 76)
$commandBar.Anchor = "Top,Left,Right"
$commandBar.BackColor = $appPanel
$main.Controls.Add($commandBar)

$scanButton = New-AppButton "SCAN LINKS" 18 18 132 $appGreen $appBg
$commandBar.Controls.Add($scanButton)

$downloadButton = New-AppButton "DOWNLOAD" 164 18 132 $appOrange $appBg
$commandBar.Controls.Add($downloadButton)

$aiButton = New-AppButton "ASK AI" 310 18 104 $appBlue $appText
$commandBar.Controls.Add($aiButton)

$copyButton = New-AppButton "COPY" 428 18 94 $appPanel2 $appText
$copyButton.Enabled = $false
$commandBar.Controls.Add($copyButton)

$saveButton = New-AppButton "SAVE" 536 18 94 $appPanel2 $appText
$saveButton.Enabled = $false
$commandBar.Controls.Add($saveButton)

$hint = New-Object System.Windows.Forms.Label
$hint.Text = "Official sources only"
$hint.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$hint.ForeColor = $appMuted
$hint.AutoSize = $false
$hint.Size = New-Object System.Drawing.Size(180, 24)
$hint.Location = New-Object System.Drawing.Point(652, 28)
$hint.Anchor = "Top,Left"
$commandBar.Controls.Add($hint)

$output = New-Object System.Windows.Forms.RichTextBox
$output.BorderStyle = "None"
$output.Dock = "Fill"
$output.ReadOnly = $true
$output.DetectUrls = $true
$output.Multiline = $true
$output.ScrollBars = "Both"
$output.WordWrap = $false
$output.Font = New-Object System.Drawing.Font("Cascadia Mono", 10)
$output.BackColor = [System.Drawing.Color]::FromArgb(8, 13, 21)
$output.ForeColor = [System.Drawing.Color]::FromArgb(215, 228, 236)
$output.SelectionBackColor = [System.Drawing.Color]::FromArgb(37, 84, 108)
$output.Text = "Ready.`r`n`r`nChoose SCAN LINKS to smart-search exact official driver downloads, or DOWNLOAD to save matched packages."
$reportShell.Controls.Add($output)
$output.Add_LinkClicked({ Start-Process $_.LinkText | Out-Null })
$commandBar.BringToFront()
$header.BringToFront()

function Update-AppLayout {
    $header.Width = $form.ClientSize.Width
    $signal.Left = [Math]::Max(700, $header.ClientSize.Width - 180)
    $statusShell.Left = [Math]::Max(662, $header.ClientSize.Width - 218)

    $mainWidth = [Math]::Max(600, $form.ClientSize.Width - 48)
    $mainHeight = [Math]::Max(320, $form.ClientSize.Height - 216)
    $main.SetBounds(24, 194, $mainWidth, $mainHeight)

    $commandBar.SetBounds(0, 0, $main.ClientSize.Width, 76)
    $reportShell.SetBounds(0, 92, $main.ClientSize.Width, [Math]::Max(160, $main.ClientSize.Height - 92))
    $commandBar.BringToFront()
}

$form.Add_Resize({ Update-AppLayout })
Update-AppLayout

$scanButton.Add_Click({
    $scanButton.Enabled = $false
    $downloadButton.Enabled = $false
    $aiButton.Enabled = $false
    $copyButton.Enabled = $false
    $saveButton.Enabled = $false
    $status.Text = "Resolving..."
    $output.Text = "Searching official sources for exact direct driver downloads. This can take a few minutes..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $report = Get-DriverReport
        $output.Text = $report
        $status.Text = "Links ready."
        $copyButton.Enabled = $true
        $saveButton.Enabled = $true
    }
    catch {
        $output.Text = "Scan failed:`r`n`r`n$($_.Exception.Message)"
        $status.Text = "Scan failed."
    }
    finally {
        $scanButton.Enabled = $true
        $downloadButton.Enabled = $true
        $aiButton.Enabled = $true
    }
})

$downloadButton.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "This will download exact driver files found from official vendor/Microsoft URLs for detected driver-needed/core components into a folder in Downloads. It will not install or run anything.",
        "Download driver packages?",
        [System.Windows.Forms.MessageBoxButtons]::OKCancel,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    if ($answer -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $scanButton.Enabled = $false
    $downloadButton.Enabled = $false
    $aiButton.Enabled = $false
    $copyButton.Enabled = $false
    $saveButton.Enabled = $false
    $status.Text = "Downloading..."
    $output.Text = "Downloading matched official driver files. This can take several minutes..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $result = New-DriverDownloadPack
        $output.Text = $result
        $status.Text = "Download complete"
        $copyButton.Enabled = $true
        $saveButton.Enabled = $true
    }
    catch {
        $output.Text = "Driver download failed:`r`n`r`n$($_.Exception.Message)"
        $status.Text = "Download failed"
    }
    finally {
        $scanButton.Enabled = $true
        $downloadButton.Enabled = $true
        $aiButton.Enabled = $true
    }
})

$aiButton.Add_Click({
    $context = $output.Text
    if ([string]::IsNullOrWhiteSpace($context)) {
        $context = "No scan report has been generated yet."
    }
    Show-AiAssistantWindow $context
})

$copyButton.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText($output.Text)
    $status.Text = "Report copied."
})

$saveButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = "Text report (*.txt)|*.txt|All files (*.*)|*.*"
    $dialog.FileName = "Driver-Link-Scout-Report.txt"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        [System.IO.File]::WriteAllText($dialog.FileName, $output.Text)
        $status.Text = "Report saved."
    }
})

[void]$form.ShowDialog()
