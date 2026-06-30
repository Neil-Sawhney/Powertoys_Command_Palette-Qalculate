# PowerQalc

A [PowerToys Command Palette](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/extensibility-overview) extension that evaluates expressions using the [Qalculate](https://qalculate.github.io/) engine (`qalc`).

Type math, combine **mixed units in one expression**, convert the result, solve equations, and copy answers — without leaving the launcher.

Unlike a simple unit converter, PowerQalc lets you **do real math with incompatible units** and convert only when you want. Add miles to kilometers, multiply speed by time, combine feet and inches — then convert to whatever you need.

It also ships with a **huge library of built-in physical, chemical, and mathematical constants** — far beyond what a typical calculator offers. Use them by name in any expression, with automatic unit handling.

## Features

- Live evaluation as you type (with debounce)
- Calculation history when you copy (Enter) or save (Ctrl+Enter) — not on every keystroke
- Copy results to the clipboard
- Bundled `qalc` runtime — works out of the box, no separate Qalculate install
- Configurable `qalc` path override in extension settings
- Extension settings page in Command Palette

## Example expressions

A few things to try — each shows a different capability:

| What it shows | Example | Result (approx.) |
|---------------|---------|------------------|
| **Mixed units** | `5 miles + 10 km` | `18 km` |
| **Solve for x, convert result** | `10 mph * x = 20 mi to min` | `x = 120 min` |
| **Percentages** | `240 * 15%` | `36` |
| **Algebra** | `x^2 + 2x = 0` | `x = 0 or x = -2` |
| **Constants & exotic units** | `planck to eV s` · `1 ly to km` | Planck constant · ~9.5 trillion km |

Qalculate knows hundreds of constants (`FineStructure`, `proton_mass`, `SpeedOfLight`, …) and units from everyday measures to light years and electron-volts — use them in any expression.

## Requirements

- Windows 10/11 with [PowerToys](https://github.com/microsoft/PowerToys) (Command Palette enabled)

The published MSIX bundles the Qalculate CLI (`qalc`) — no extra install step for end users.

## Local development

```powershell
# Bundle qalc, build, and install for local testing (admin)
.\test.ps1

# Production Store upload bundle (x64 + ARM64 .msixbundle)
.\build.ps1
```

Both scripts run `bundle-qalc.ps1` automatically. You need a local Qalculate install once (e.g. `winget install qalculate.qalculate`) so the bundle script can copy the runtime.

After installing, run **Reload** in Command Palette.

## Publishing

See Microsoft's guides for [WinGet](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/publish-extension-winget) and the [Extension Gallery](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/extension-gallery). Gallery metadata is in `gallery-submission/`; a WinGet manifest template is in `winget-template/`.

## License

MIT — see [LICENSE](LICENSE). Bundles the Qalculate CLI (`qalc`), licensed under GPL-2.0. License files ship in `qalc/licenses/` and `qalc/ThirdPartyNotices.txt` inside the MSIX.
