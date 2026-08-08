# Driver Link Scout

Driver Link Scout is a Windows-only utility that scans the current PC and prints a list of official driver/support URLs.

It does not download drivers. It does not install drivers. It does not change the computer.

## How to Run

1. Open this folder on the Windows computer you want to scan.
2. Double-click `Driver Link Scout.cmd`.
3. Press `Scan This PC`.
4. Inspect the report.
5. Use `Copy Report` or `Save Report` if you want to share the list.

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

If the app does not open, right-click `Driver Link Scout.cmd` and choose `Run as administrator`.

If Windows SmartScreen warns about the file, choose `More info` only if you trust the person who gave you this folder.
