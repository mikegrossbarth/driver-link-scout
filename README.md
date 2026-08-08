# Driver Link Scout

Driver Link Scout is a LUCAS-themed, Windows-only utility that scans the current PC and prints a list of official driver/support URLs.

It does not download drivers. It does not install drivers. It does not change the computer.

## How to Run

1. Open this folder on the Windows computer you want to scan.
2. Double-click `Driver Link Scout.vbs`.
3. Press `Run Inspection` for a read-only report.
4. Press `Prep Downloads` to create a folder in Downloads with official driver-source shortcuts and an HTML launch page.
5. Use `Copy Report` or `Save Report` if you want to share the list.

`Prep Downloads` does not install drivers. It prepares official download locations so the user can inspect and download from trusted sources.

## What It Checks

- PC manufacturer, model, and serial/service tag
- Windows version and architecture
- Motherboard/baseboard
- CPU
- Graphics adapters
- Physical network adapters
- Plug and Play hardware IDs for driver catalog searches

## Link Priority

Use the PC maker or motherboard maker first:
Dell, Lenovo, HP, ASUS, MSI, Gigabyte, Acer, Microsoft Surface, etc.

Then use Microsoft Update / Microsoft Update Catalog.

Then use component makers like Intel, AMD, NVIDIA, or Realtek.

## Safety Notes

- Avoid third-party driver updater sites.
- Create a restore point before installing drivers.
- BIOS and firmware updates should come only from the exact PC or motherboard maker.
- Laptops and prebuilt desktops often need OEM-customized drivers.

## Troubleshooting

If the app does not open, double-click `Driver Link Scout.cmd` to launch it with a visible troubleshooting terminal.

If Windows SmartScreen warns about the file, choose `More info` only if you trust the person who gave you this folder.
