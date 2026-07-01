# PowerQalc Privacy Policy

Last updated: June 30, 2026

PowerQalc ("the app") is a PowerToys Command Palette extension published by Neil Sawhney.

## Summary

PowerQalc does not collect, transmit, or sell personal data. Calculations run locally on your device.

## Data stored on your device

- **Calculation history (optional):** Recent expressions and results may be saved locally when you copy a result (Enter) or press Ctrl+Enter. Live previews while typing are not saved. You can disable this in Command Palette → PowerQalc → Settings → **Save calculation history**, or clear history from the extension menu.
- **Settings:** Preferences such as history limit and the optional `qalc` executable path are stored locally by PowerToys.
- **Qalculate session (optional):** While PowerQalc is running, `qalc` may store session state (for example `ans()` and user-defined variables) under the extension settings folder.

This data stays on your PC. The developer does not receive it.

## Network use

The app bundles the Qalculate engine (`qalc`). If you enter expressions that require live data (for example, currency conversion), `qalc` may connect to the internet to fetch rates or related information. That traffic goes to third-party services used by Qalculate, not to the developer.

The app manifest declares general network client access (`internetClient`) for this purpose. PowerQalc itself does not send your expressions or results to the developer.

## What we do not do

- No accounts or sign-in
- No analytics or telemetry to the developer
- No advertising
- No sale or sharing of personal data

## Third parties

- **Microsoft** — Microsoft Store distribution, updates, and signing
- **PowerToys / Command Palette** — hosts and loads the extension
- **Qalculate** — bundled calculation engine ([GPL-2.0](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)); see `qalc/licenses/` in the app package for bundled license files

## Children

PowerQalc is a general-purpose calculator extension and is not directed at children under 13.

## Changes

This policy may be updated from time to time. The "Last updated" date at the top will change when it does.

## Contact

Questions or concerns: [GitHub Issues](https://github.com/Neil-Sawhney/PowerQalc/issues)
