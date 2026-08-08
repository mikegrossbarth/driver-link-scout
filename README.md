# Driver Link Scout

Driver Link Scout is a LUCAS-themed, Windows-only utility that scans the current PC and prints official driver URLs.

It identifies driver-needed/core components, searches official vendor/Microsoft pages for exact direct driver files, and remembers matches by hardware ID. It does not install drivers or change the computer.

## How to Run

1. Open this folder on the Windows computer you want to scan.
2. Double-click `Driver Link Scout.vbs`.
3. Press `Scan Links` to smart-search exact direct driver download files.
4. Press `Download` to save matched packages into a folder in Downloads.
5. Use `Copy` or `Save` if you want to share the list.

URLs in the report are clickable. `Download` saves matched official vendor/Microsoft files only; it does not install or run them.

## What It Checks

- PC manufacturer, model, and serial/service tag
- Windows version and architecture
- Motherboard/baseboard
- CPU
- Graphics adapters
- Physical network adapters
- Plug and Play hardware IDs for driver catalog searches

## Download Source

Driver Link Scout searches Google/DuckDuckGo results, crawls official vendor/Microsoft pages, extracts direct `.exe`, `.msi`, `.zip`, or `.cab` files, and caches matches in `%LOCALAPPDATA%\LUCAS Driver Link Scout\driver-url-cache.json`.

## Optional AI Resolver

If `OPENAI_API_KEY` is set on the Windows PC, Driver Link Scout asks OpenAI with web search to find exact official driver file URLs before falling back to the built-in crawler.

PowerShell:

```powershell
[Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "your_api_key_here", "User")
```

Restart the app after setting the key.

## Safety Notes

- Avoid third-party driver updater sites.
- Create a restore point before installing drivers.
- BIOS and firmware updates should come only from the exact PC or motherboard maker.
- Laptops and prebuilt desktops often need OEM-customized drivers.

## Troubleshooting

If the app does not open, double-click `Driver Link Scout.cmd` to launch it with a visible troubleshooting terminal.

If Windows SmartScreen warns about the file, choose `More info` only if you trust the person who gave you this folder.
