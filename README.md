# Qalculate for Command Palette

A [PowerToys Command Palette](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/extensibility-overview) extension that evaluates expressions using the [Qalculate](https://qalculate.github.io/) CLI (`qalc`).

Type math, combine **mixed units in one expression**, convert the result, solve equations, and copy answers — without leaving the launcher.

Unlike a simple unit converter, Qalculate lets you **do real math with incompatible units** and convert only when you want. Add miles to kilometers, multiply speed by time, combine feet and inches — then convert to whatever you need.

It also ships with a **huge library of built-in physical, chemical, and mathematical constants** — far beyond what a typical calculator offers. Use them by name in any expression, with automatic unit handling.

## Features

- Live evaluation as you type (with debounce)
- Copy results to the clipboard
- Configurable `qalc` path (or automatic detection)
- Optional bundled `qalc` runtime
- Extension settings page in Command Palette

## Example expressions

| Type | Example | Result (approx.) |
|------|---------|------------------|
| **Mixed-unit math** | `5 miles + 10 km` | `18.04672 km` |
| **Math, then convert** | `(5 ft + 8 in) to cm` | `172.72 cm` |
| **Rate × time** | `10 mph * 2 hours` | `20 mi` |
| **Duration math** | `3 h + 45 min to seconds` | `13500 s` |
| **Fine-structure constant** | `FineStructure` | `0.0072973526` (α ≈ 1/137) |
| **Planck constant** | `planck to eV s` | `4.136×10⁻¹⁵ eV·s` |
| **Reduced Planck (ħ)** | `dirac to eV s` | `6.582×10⁻¹⁶ eV·s` |
| **Particle mass** | `proton_mass to MeV/c^2` | `938.27 MeV/c²` |
| **Quantum scale** | `PlanckLength to nm` | `1.616×10⁻²⁶ nm` |
| **Stat mech** | `k_B to J/K` | `1.381×10⁻²³ J/K` |
| **Speed of light** | `SpeedOfLight to mph` | `670,616,629 mph` |
| **Ideal gas** | `molar_gas_constant * 298 K to J` | `2477 J` |
| Arithmetic | `2+2` | `4` |
| Percentages | `15% of 240` | `36` |
| Simple conversion | `100 miles to km` | `160.9344 km` |
| Temperature | `72 fahrenheit to celsius` | `22.22 °C` |
| Trigonometry | `sin(45 deg)` | `0.7071` |
| Algebra | `x^2+2x=0` | `x = -2 or x = 0` |
| Integration | `integrate(x^2, x, 0, 5)` | `41.666667` |
| Currency | `100 USD to EUR` | (live rate) |
| Date math | `today + 90 days` | (date) |

## Requirements

- Windows 10/11 with [PowerToys](https://github.com/microsoft/PowerToys) (Command Palette enabled)
- `qalc` — installed automatically when using the WinGet package, or via `winget install qalculate.qalculate`

## Local development

```powershell
# Build and install (admin once)
.\install.ps1

# Or build only
.\scripts\build-msix.ps1
```

After installing, run **Reload** in Command Palette.

## Optional: bundle qalc

To ship `qalc` inside the extension package (~160 MB):

```powershell
winget install qalculate.qalculate   # if not already installed
.\scripts\bundle-qalc.ps1
.\scripts\build-msix.ps1
```

## Publishing

See [PUBLISH.md](PUBLISH.md) for WinGet and Extension Gallery submission steps.

## License

MIT — see [LICENSE](LICENSE). Uses the Qalculate CLI, which is licensed under the GPL. If you bundle `qalc`, include Qalculate license files (see `scripts/bundle-qalc.ps1`).
