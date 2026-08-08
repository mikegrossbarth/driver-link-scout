# Driver Link Scout

Driver Link Scout is a LUCAS-themed, Windows-only utility that scans the current PC and prints official driver URLs.

It can identify components that likely need driver attention, search official vendor/Microsoft sources for that specific part, and download Microsoft Update Catalog driver packages for detected hardware IDs. It does not install drivers or change the computer.

## How to Run

1. Open this folder on the Windows computer you want to scan.
2. Double-click `Driver Link Scout.vbs`.
3. Press `Inspect` for a read-only hardware and source report.
4. Press `Needed Links` to identify components that likely need driver attention and search official sources for that specific part.
5. Press `Catalog` to search Microsoft Update Catalog for direct driver package URLs matching detected hardware IDs.
6. Press `Download` to save matched Microsoft Update Catalog driver packages into a folder in Downloads.
7. Use `Copy Report` or `Save Report` if you want to share the list.

URLs in the report are clickable. `Needed Links` filters web results to known official Microsoft/OEM/vendor domains. `Catalog` uses Microsoft Update Catalog direct package URLs where available, usually `.cab` files. `Download` saves matched Microsoft Catalog packages only; it does not install or run them.

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
