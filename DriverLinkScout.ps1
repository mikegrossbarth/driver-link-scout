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

    if ($deviceText -match "intel|ven_8086") {
        Add-Link $Links "Intel Driver & Support Assistant" "https://www.intel.com/content/www/us/en/support/detect.html" "Official Intel tool for supported Intel chipset, graphics, Wi-Fi, Bluetooth, and storage drivers." "Install tool"
    }
    if ($deviceText -match "amd|advanced micro devices|radeon|ven_1002|ven_1022") {
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

    $links = New-Object 'System.Collections.Generic.List[object]'
    Get-OemLinks $links $computer.Manufacturer $computer.Model $bios.SerialNumber
    Get-ComponentLinks $links $pnp
    Get-HardwareIdLinks $links $pnp

    return [pscustomobject]@{
        Computer = $computer
        Bios = $bios
        Os = $os
        Baseboard = $baseboard
        Processor = $processor
        Video = $video
        Network = $net
        HardwareIds = (Get-DetectedHardwareIds $pnp)
        Links = $links
    }
}

function Get-DriverReport {
    $scan = Get-DriverScanData
    $computer = $scan.Computer
    $bios = $scan.Bios
    $os = $scan.Os
    $baseboard = $scan.Baseboard
    $processor = $scan.Processor
    $video = $scan.Video
    $net = $scan.Network
    $links = $scan.Links

    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add("Driver Link Scout Report") | Out-Null
    $lines.Add(("Generated: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))) | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("Detected computer") | Out-Null
    $lines.Add(("Manufacturer: {0}" -f $computer.Manufacturer)) | Out-Null
    $lines.Add(("Model: {0}" -f $computer.Model)) | Out-Null
    $lines.Add(("Serial/Service Tag: {0}" -f $bios.SerialNumber)) | Out-Null
    $lines.Add(("Baseboard: {0} {1}" -f $baseboard.Manufacturer, $baseboard.Product)) | Out-Null
    $lines.Add(("OS: {0} {1} build {2}" -f $os.Caption, $os.OSArchitecture, $os.BuildNumber)) | Out-Null
    $lines.Add(("CPU: {0}" -f $processor.Name)) | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("Graphics") | Out-Null
    foreach ($item in $video) { $lines.Add(("- {0} | Driver {1}" -f $item.Name, $item.DriverVersion)) | Out-Null }
    $lines.Add("") | Out-Null
    $lines.Add("Network adapters") | Out-Null
    foreach ($item in $net) { $lines.Add(("- {0} | Driver {1}" -f $item.Name, $item.DriverVersion)) | Out-Null }
    $lines.Add("") | Out-Null
    $lines.Add("Official driver/support URLs") | Out-Null
    $lines.Add("Inspect these pages before installing anything. Prefer the exact PC/motherboard manufacturer page first.") | Out-Null
    $lines.Add("") | Out-Null

    $i = 1
    foreach ($link in $links) {
        $lines.Add(("{0}. [{1}] {2}" -f $i, $link.Priority, $link.Title)) | Out-Null
        $lines.Add(("   {0}" -f $link.Url)) | Out-Null
        $lines.Add(("   Why: {0}" -f $link.Reason)) | Out-Null
        $lines.Add("") | Out-Null
        $i++
    }

    $lines.Add("Safety notes") | Out-Null
    $lines.Add("- Do not use third-party driver updater sites.") | Out-Null
    $lines.Add("- Install OEM laptop/prebuilt drivers before generic component drivers.") | Out-Null
    $lines.Add("- Create a restore point before driver or BIOS/firmware updates.") | Out-Null
    $lines.Add("- BIOS/firmware updates should come only from the exact PC or motherboard maker.") | Out-Null

    return ($lines -join [Environment]::NewLine)
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

function Get-ExactCatalogDownloadReport {
    $scan = Get-DriverScanData
    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add("LUCAS Exact Driver Download Links") | Out-Null
    $lines.Add(("Generated: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))) | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("Source: Microsoft Update Catalog direct package URLs for detected hardware IDs.") | Out-Null
    $lines.Add("Click any URL in this report to open it.") | Out-Null
    $lines.Add("") | Out-Null

    foreach ($hardwareId in $scan.HardwareIds) {
        $lines.Add($hardwareId) | Out-Null
        try {
            $matches = @(Get-CatalogDownloadUrls $hardwareId 3)
            if ($matches.Count -eq 0) {
                $lines.Add("  No direct Catalog package URL found.") | Out-Null
                $lines.Add(("  Search manually: https://www.catalog.update.microsoft.com/Search.aspx?q={0}" -f (Encode-Query $hardwareId))) | Out-Null
            }
            else {
                $n = 1
                foreach ($match in $matches | Select-Object -First 6) {
                    $lines.Add(("  {0}. {1}" -f $n, $match.Url)) | Out-Null
                    $n++
                }
            }
        }
        catch {
            $lines.Add(("  Lookup failed: {0}" -f $_.Exception.Message)) | Out-Null
            $lines.Add(("  Search manually: https://www.catalog.update.microsoft.com/Search.aspx?q={0}" -f (Encode-Query $hardwareId))) | Out-Null
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

    return ($PnpClass -match "Display|Net|MEDIA|HDC|SCSIAdapter|System|Bluetooth|USB|Biometric|Camera|SoftwareComponent")
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
    $lines.Add("LUCAS Needed Driver Download Links") | Out-Null
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
    $scan = Get-DriverScanData
    $computer = $scan.Computer
    $links = $scan.Links

    $root = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads"
    $folderName = "LUCAS-Driver-Downloads-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
    $folder = Join-Path $root $folderName
    New-Item -ItemType Directory -Path $folder -Force | Out-Null

    $reportPath = Join-Path $folder "driver-link-report.txt"
    [System.IO.File]::WriteAllText($reportPath, (Get-DriverReport))

    $htmlPath = Join-Path $folder "open-driver-sources.html"
    $html = New-Object 'System.Collections.Generic.List[string]'
    $html.Add("<!doctype html><html><head><meta charset='utf-8'><title>LUCAS Driver Sources</title>") | Out-Null
    $html.Add("<style>body{background:#070b12;color:#eaf2f8;font-family:Segoe UI,Arial,sans-serif;margin:32px}a{color:#29de9c}section{border-top:1px solid #273e52;padding-top:16px;margin-top:22px}.tag{color:#071218;background:#ffb153;padding:3px 7px;font-size:12px;font-weight:700}.reason{color:#97a6b8}</style></head><body>") | Out-Null
    $html.Add("<h1>LUCAS Driver Sources</h1>") | Out-Null
    $html.Add(("<p>{0} {1}</p>" -f $computer.Manufacturer, $computer.Model)) | Out-Null
    $html.Add("<p>This pack prepares official places to download drivers. It does not install anything, and it does not use third-party driver updater sites.</p>") | Out-Null

    $i = 1
    foreach ($link in $links) {
        $fileName = "{0:00} - {1}.url" -f $i, (ConvertTo-SafeFileName $link.Title)
        New-InternetShortcut (Join-Path $folder $fileName) $link.Url
        $html.Add("<section>") | Out-Null
        $html.Add(("<div><span class='tag'>{0}</span></div>" -f [System.Security.SecurityElement]::Escape($link.Priority))) | Out-Null
        $html.Add(("<h2><a href='{0}'>{1}</a></h2>" -f [System.Security.SecurityElement]::Escape($link.Url), [System.Security.SecurityElement]::Escape($link.Title))) | Out-Null
        $html.Add(("<p class='reason'>{0}</p>" -f [System.Security.SecurityElement]::Escape($link.Reason))) | Out-Null
        $html.Add("</section>") | Out-Null
        $i++
    }
    $html.Add("</body></html>") | Out-Null
    [System.IO.File]::WriteAllText($htmlPath, ($html -join "`r`n"))

    Start-Process $folder | Out-Null
    Start-Process $htmlPath | Out-Null

    return "Download prep complete.`r`n`r`nCreated folder:`r`n$folder`r`n`r`nInside it you will find:`r`n- driver-link-report.txt`r`n- open-driver-sources.html`r`n- .url shortcuts for every official source`r`n`r`nThis mode prepares official download locations. It does not install drivers or scrape unsigned packages."
}

function New-LucasButton {
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

$lucasBg = [System.Drawing.Color]::FromArgb(7, 11, 18)
$lucasPanel = [System.Drawing.Color]::FromArgb(14, 20, 31)
$lucasPanel2 = [System.Drawing.Color]::FromArgb(18, 27, 42)
$lucasText = [System.Drawing.Color]::FromArgb(234, 242, 248)
$lucasMuted = [System.Drawing.Color]::FromArgb(151, 166, 184)
$lucasGreen = [System.Drawing.Color]::FromArgb(41, 222, 156)
$lucasBlue = [System.Drawing.Color]::FromArgb(64, 152, 255)
$lucasOrange = [System.Drawing.Color]::FromArgb(255, 177, 83)

$form = New-Object System.Windows.Forms.Form
$form.Text = "LUCAS Driver Link Scout"
$form.Size = New-Object System.Drawing.Size(1080, 760)
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object System.Drawing.Size(860, 620)
$form.BackColor = $lucasBg
$form.ForeColor = $lucasText

$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.Size = New-Object System.Drawing.Size($form.ClientSize.Width, 172)
$header.Anchor = "Top,Left,Right"
$header.BackColor = $lucasPanel
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
    $pen = New-Object System.Drawing.Pen($lucasGreen, 3)
    $event.Graphics.DrawLine($pen, 0, $sender.Height - 2, $sender.Width, $sender.Height - 2)
    $pen.Dispose()
})
$form.Controls.Add($header)

$brand = New-Object System.Windows.Forms.Label
$brand.Text = "LUCAS"
$brand.Font = New-Object System.Drawing.Font("Segoe UI Black", 28, [System.Drawing.FontStyle]::Bold)
$brand.ForeColor = $lucasGreen
$brand.BackColor = [System.Drawing.Color]::Transparent
$brand.AutoSize = $true
$brand.Location = New-Object System.Drawing.Point(28, 22)
$header.Controls.Add($brand)

$title = New-Object System.Windows.Forms.Label
$title.Text = "Driver Link Scout"
$title.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 24)
$title.ForeColor = $lucasText
$title.BackColor = [System.Drawing.Color]::Transparent
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(28, 68)
$header.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "Inspect hardware, resolve direct Microsoft Catalog package links, or prep official driver download sources."
$subtitle.Font = New-Object System.Drawing.Font("Segoe UI", 10.5)
$subtitle.ForeColor = $lucasMuted
$subtitle.BackColor = [System.Drawing.Color]::Transparent
$subtitle.AutoSize = $true
$subtitle.Location = New-Object System.Drawing.Point(31, 112)
$header.Controls.Add($subtitle)

$signal = New-Object System.Windows.Forms.Label
$signal.Text = "INSPECTION MODE"
$signal.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
$signal.ForeColor = $lucasBg
$signal.BackColor = $lucasOrange
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
$statusTag.ForeColor = $lucasGreen
$statusTag.AutoSize = $true
$statusTag.Location = New-Object System.Drawing.Point(12, 9)
$statusShell.Controls.Add($statusTag)

$status = New-Object System.Windows.Forms.Label
$status.Text = "Ready"
$status.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
$status.ForeColor = $lucasText
$status.AutoSize = $true
$status.Location = New-Object System.Drawing.Point(36, 8)
$statusShell.Controls.Add($status)

$main = New-Object System.Windows.Forms.Panel
$main.Location = New-Object System.Drawing.Point(24, 194)
$main.Size = New-Object System.Drawing.Size(($form.ClientSize.Width - 48), ($form.ClientSize.Height - 216))
$main.Anchor = "Top,Bottom,Left,Right"
$main.BackColor = $lucasBg
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
$commandBar.BackColor = $lucasPanel
$main.Controls.Add($commandBar)

$scanButton = New-LucasButton "INSPECT" 18 18 92 $lucasGreen $lucasBg
$commandBar.Controls.Add($scanButton)

$neededButton = New-LucasButton "NEEDED LINKS" 122 18 142 $lucasBlue $lucasBg
$commandBar.Controls.Add($neededButton)

$exactButton = New-LucasButton "CATALOG" 276 18 104 $lucasPanel2 $lucasText
$commandBar.Controls.Add($exactButton)

$downloadButton = New-LucasButton "PREP PACK" 392 18 112 $lucasOrange $lucasBg
$commandBar.Controls.Add($downloadButton)

$copyButton = New-LucasButton "COPY" 516 18 78 $lucasPanel2 $lucasText
$copyButton.Enabled = $false
$commandBar.Controls.Add($copyButton)

$saveButton = New-LucasButton "SAVE" 606 18 78 $lucasPanel2 $lucasText
$saveButton.Enabled = $false
$commandBar.Controls.Add($saveButton)

$hint = New-Object System.Windows.Forms.Label
$hint.Text = "Official sources only"
$hint.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$hint.ForeColor = $lucasMuted
$hint.AutoSize = $false
$hint.Size = New-Object System.Drawing.Size(180, 24)
$hint.Location = New-Object System.Drawing.Point(704, 28)
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
$output.Text = "Ready for scan.`r`n`r`nChoose INSPECT for hardware, NEEDED LINKS for official per-component download candidates, CATALOG for direct Microsoft package URLs, or PREP PACK for source shortcuts."
$reportShell.Controls.Add($output)
$output.Add_LinkClicked({ Start-Process $_.LinkText | Out-Null })
$commandBar.BringToFront()
$header.BringToFront()

function Update-LucasLayout {
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

$form.Add_Resize({ Update-LucasLayout })
Update-LucasLayout

$scanButton.Add_Click({
    $scanButton.Enabled = $false
    $neededButton.Enabled = $false
    $exactButton.Enabled = $false
    $downloadButton.Enabled = $false
    $copyButton.Enabled = $false
    $saveButton.Enabled = $false
    $status.Text = "Scanning..."
    $output.Text = "Scanning this PC. This may take a few seconds..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $report = Get-DriverReport
        $output.Text = $report
        $status.Text = "Scan complete."
        $copyButton.Enabled = $true
        $saveButton.Enabled = $true
    }
    catch {
        $output.Text = "Scan failed:`r`n`r`n$($_.Exception.Message)"
        $status.Text = "Scan failed."
    }
    finally {
        $scanButton.Enabled = $true
        $neededButton.Enabled = $true
        $exactButton.Enabled = $true
        $downloadButton.Enabled = $true
    }
})

$neededButton.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "This will identify components that likely need driver attention and search the web for official per-component download candidates. It filters to known Microsoft/OEM/vendor domains and will not download or install anything.",
        "Search needed driver links?",
        [System.Windows.Forms.MessageBoxButtons]::OKCancel,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    if ($answer -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $scanButton.Enabled = $false
    $neededButton.Enabled = $false
    $exactButton.Enabled = $false
    $downloadButton.Enabled = $false
    $copyButton.Enabled = $false
    $saveButton.Enabled = $false
    $status.Text = "Searching..."
    $output.Text = "Identifying driver-needed components and searching official sources. This can take a few minutes..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $report = Get-NeededDriverDownloadReport
        $output.Text = $report
        $status.Text = "Needed links ready"
        $copyButton.Enabled = $true
        $saveButton.Enabled = $true
    }
    catch {
        $output.Text = "Needed-link search failed:`r`n`r`n$($_.Exception.Message)"
        $status.Text = "Search failed"
    }
    finally {
        $scanButton.Enabled = $true
        $neededButton.Enabled = $true
        $exactButton.Enabled = $true
        $downloadButton.Enabled = $true
    }
})

$exactButton.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "This will use the internet to search Microsoft Update Catalog for direct package URLs matching detected hardware IDs. It will not download or install anything.",
        "Find exact download links?",
        [System.Windows.Forms.MessageBoxButtons]::OKCancel,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    if ($answer -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $scanButton.Enabled = $false
    $neededButton.Enabled = $false
    $exactButton.Enabled = $false
    $downloadButton.Enabled = $false
    $copyButton.Enabled = $false
    $saveButton.Enabled = $false
    $status.Text = "Resolving..."
    $output.Text = "Finding direct Microsoft Catalog package URLs. This can take a minute..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $report = Get-ExactCatalogDownloadReport
        $output.Text = $report
        $status.Text = "Links ready"
        $copyButton.Enabled = $true
        $saveButton.Enabled = $true
    }
    catch {
        $output.Text = "Exact-link lookup failed:`r`n`r`n$($_.Exception.Message)"
        $status.Text = "Lookup failed"
    }
    finally {
        $scanButton.Enabled = $true
        $neededButton.Enabled = $true
        $exactButton.Enabled = $true
        $downloadButton.Enabled = $true
    }
})

$downloadButton.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "This will scan the PC, create a folder in Downloads, and open an HTML page with official driver download sources. It will not install drivers or use third-party updater sites.",
        "Prep driver downloads?",
        [System.Windows.Forms.MessageBoxButtons]::OKCancel,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    if ($answer -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $scanButton.Enabled = $false
    $neededButton.Enabled = $false
    $exactButton.Enabled = $false
    $downloadButton.Enabled = $false
    $copyButton.Enabled = $false
    $saveButton.Enabled = $false
    $status.Text = "Preparing..."
    $output.Text = "Preparing official driver download sources..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $result = New-DriverDownloadPack
        $output.Text = $result
        $status.Text = "Prep complete"
        $copyButton.Enabled = $true
        $saveButton.Enabled = $true
    }
    catch {
        $output.Text = "Download prep failed:`r`n`r`n$($_.Exception.Message)"
        $status.Text = "Prep failed"
    }
    finally {
        $scanButton.Enabled = $true
        $neededButton.Enabled = $true
        $exactButton.Enabled = $true
        $downloadButton.Enabled = $true
    }
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
