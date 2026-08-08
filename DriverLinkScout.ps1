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
$header.Dock = "Top"
$header.Height = 172
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
$subtitle.Text = "Scan this Windows PC and generate official driver/support URLs. No downloads. No installs. Just the map."
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
$main.Dock = "Fill"
$main.Padding = New-Object System.Windows.Forms.Padding(24, 22, 24, 22)
$main.BackColor = $lucasBg
$form.Controls.Add($main)

$commandBar = New-Object System.Windows.Forms.Panel
$commandBar.Dock = "Top"
$commandBar.Height = 76
$commandBar.BackColor = $lucasPanel
$main.Controls.Add($commandBar)

$scanButton = New-LucasButton "SCAN THIS PC" 18 18 154 $lucasGreen $lucasBg
$commandBar.Controls.Add($scanButton)

$copyButton = New-LucasButton "COPY REPORT" 186 18 140 $lucasPanel2 $lucasText
$copyButton.Enabled = $false
$commandBar.Controls.Add($copyButton)

$saveButton = New-LucasButton "SAVE REPORT" 340 18 140 $lucasPanel2 $lucasText
$saveButton.Enabled = $false
$commandBar.Controls.Add($saveButton)

$hint = New-Object System.Windows.Forms.Label
$hint.Text = "Official sources only. OEM first, Microsoft catalog second, component vendors third."
$hint.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$hint.ForeColor = $lucasMuted
$hint.AutoSize = $true
$hint.Location = New-Object System.Drawing.Point(504, 28)
$hint.Anchor = "Top,Left"
$commandBar.Controls.Add($hint)

$reportShell = New-Object System.Windows.Forms.Panel
$reportShell.Dock = "Fill"
$reportShell.Padding = New-Object System.Windows.Forms.Padding(1)
$reportShell.BackColor = [System.Drawing.Color]::FromArgb(39, 62, 82)
$main.Controls.Add($reportShell)

$output = New-Object System.Windows.Forms.RichTextBox
$output.BorderStyle = "None"
$output.Dock = "Fill"
$output.ReadOnly = $true
$output.Multiline = $true
$output.ScrollBars = "Both"
$output.WordWrap = $false
$output.Font = New-Object System.Drawing.Font("Cascadia Mono", 10)
$output.BackColor = [System.Drawing.Color]::FromArgb(8, 13, 21)
$output.ForeColor = [System.Drawing.Color]::FromArgb(215, 228, 236)
$output.SelectionBackColor = [System.Drawing.Color]::FromArgb(37, 84, 108)
$output.Text = "Ready for scan.`r`n`r`nPress SCAN THIS PC to identify this machine and build a trusted driver-link report."
$reportShell.Controls.Add($output)
$commandBar.BringToFront()

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
