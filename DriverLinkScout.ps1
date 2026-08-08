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

function Get-DriverReport {
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

$form = New-Object System.Windows.Forms.Form
$form.Text = "Driver Link Scout"
$form.Size = New-Object System.Drawing.Size(980, 720)
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object System.Drawing.Size(760, 520)

$title = New-Object System.Windows.Forms.Label
$title.Text = "Driver Link Scout"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(18, 16)
$form.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "Scan this Windows PC and generate official driver/support URLs. This app does not download or install drivers."
$subtitle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$subtitle.AutoSize = $true
$subtitle.Location = New-Object System.Drawing.Point(22, 55)
$form.Controls.Add($subtitle)

$scanButton = New-Object System.Windows.Forms.Button
$scanButton.Text = "Scan This PC"
$scanButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$scanButton.Size = New-Object System.Drawing.Size(140, 36)
$scanButton.Location = New-Object System.Drawing.Point(22, 86)
$form.Controls.Add($scanButton)

$copyButton = New-Object System.Windows.Forms.Button
$copyButton.Text = "Copy Report"
$copyButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$copyButton.Size = New-Object System.Drawing.Size(120, 36)
$copyButton.Location = New-Object System.Drawing.Point(174, 86)
$copyButton.Enabled = $false
$form.Controls.Add($copyButton)

$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = "Save Report"
$saveButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$saveButton.Size = New-Object System.Drawing.Size(120, 36)
$saveButton.Location = New-Object System.Drawing.Point(306, 86)
$saveButton.Enabled = $false
$form.Controls.Add($saveButton)

$status = New-Object System.Windows.Forms.Label
$status.Text = "Ready."
$status.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$status.AutoSize = $true
$status.Location = New-Object System.Drawing.Point(440, 95)
$form.Controls.Add($status)

$output = New-Object System.Windows.Forms.TextBox
$output.Multiline = $true
$output.ScrollBars = "Both"
$output.WordWrap = $false
$output.Font = New-Object System.Drawing.Font("Consolas", 10)
$output.Location = New-Object System.Drawing.Point(22, 138)
$output.Size = New-Object System.Drawing.Size(920, 510)
$output.Anchor = "Top,Bottom,Left,Right"
$form.Controls.Add($output)

$scanButton.Add_Click({
    $scanButton.Enabled = $false
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
