# Driver Link Scout

Driver Link Scout is a LUCAS-themed, Windows-only utility that scans the current PC and prints official driver URLs.

It identifies driver-needed/core components and resolves Microsoft Update Catalog driver package URLs for detected hardware IDs. It can also download the matched packages. It does not install drivers or change the computer.

## How to Run

1. Open this folder on the Windows computer you want to scan.
2. Double-click `Driver Link Scout.vbs`.
3. Press `Scan Links` to show direct driver package URLs only.
4. Press `Download` to save matched Microsoft Update Catalog driver packages into a folder in Downloads.
5. Use `Copy` or `Save` if you want to share the list.

URLs in the report are clickable. `Download` saves matched Microsoft Catalog packages only; it does not install or run them.

## What It Checks

- PC manufacturer, model, and serial/service tag
- Windows version and architecture
- Motherboard/baseboard
- CPU
- Graphics adapters
- Physical network adapters
- Plug and Play hardware IDs for driver catalog searches

## Download Source

Driver Link Scout downloads only matched Microsoft Update Catalog packages by detected hardware ID.

## Safety Notes

- Avoid third-party driver updater sites.
- Create a restore point before installing drivers.
- BIOS and firmware updates should come only from the exact PC or motherboard maker.
- Laptops and prebuilt desktops often need OEM-customized drivers.

## Troubleshooting

If the app does not open, double-click `Driver Link Scout.cmd` to launch it with a visible troubleshooting terminal.

If Windows SmartScreen warns about the file, choose `More info` only if you trust the person who gave you this folder.
