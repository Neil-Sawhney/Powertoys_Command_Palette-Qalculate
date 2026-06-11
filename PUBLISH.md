# Publishing Qalculate to the Extension Gallery

This document lists everything already prepared in this repo and the steps **you** must complete manually. Command Palette discovers extensions through **installed MSIX packages** — not plain EXE installers. See [extensibility overview](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/extensibility-overview) and [extension gallery](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/extension-gallery).

---

## What is already done

| Item | Location |
|------|----------|
| Extension source code | `Qalculate/` |
| Version bumped to 1.0.0.0 | `Package.appxmanifest` |
| Auto `qalc` path resolution (bundled → PATH) | `QalcPathResolver.cs` |
| Optional `qalc` bundling script | `scripts/bundle-qalc.ps1` |
| Release MSIX build script | `scripts/build-msix.ps1` |
| Gallery metadata draft | `gallery-submission/neilsawhney/qalculate/extension.json` |
| WinGet manifest template | `winget-template/NeilSawhney.Qalculate.yaml` |
| WinGet dependency on `qalculate.qalculate` | In winget template (installs `qalc` for users) |
| README with feature overview | `README.md` |
| Local install script | `install.ps1` |

---

## What you must do

### 1. Create a GitHub repository

1. Create a public repo (e.g. `github.com/neilsawhney/Qalculate`).
2. Push this project.
3. Update placeholders if your GitHub username differs from `neilsawhney`:
   - `gallery-submission/neilsawhney/qalculate/extension.json`
   - `winget-template/NeilSawhney.Qalculate.yaml`
   - `README.md` links

### 2. Choose how users get `qalc`

**Recommended (smaller package):** Rely on the WinGet dependency `qalculate.qalculate`. When someone installs your extension via WinGet, Qalculate CLI is installed automatically.

**Optional (offline / no extra install):** Bundle `qalc` into the MSIX:

```powershell
winget install qalculate.qalculate
.\scripts\bundle-qalc.ps1
```

This adds ~160 MB. Qalculate is GPL — if you bundle it, ship license files (the full bundle script copies `licenses/` if you use the non-`-Minimal` path; consider adding a `ThirdPartyNotices.txt`).

### 3. Create a proper code-signing certificate

Your current dev cert (`CN=Qalculate Dev`) works for local sideloading only.

For public distribution you need either:

- **Partner Center / Store signing** — if publishing to Microsoft Store, or
- **A trusted code-signing certificate** — for WinGet MSIX distribution

Update `Package.appxmanifest` `Identity Publisher=` to match your certificate subject.

Files involved:

- `Qalculate/Qalculate_TemporaryKey.pfx` (replace for release)
- `Qalculate.csproj` — `PackageCertificateKeyFile`, `PackageCertificatePassword`

> Do not commit production certificate passwords to a public repo. Use GitHub Actions secrets.

### 4. Build Release MSIX packages

```powershell
.\scripts\build-msix.ps1
```

Produces x64 and ARM64 MSIX under `Qalculate/AppPackages/`.

Verify locally:

1. Install both MSIX (or at least x64).
2. Open Command Palette → **Reload**.
3. Search **Qalculate** and test `2+2`, `100 miles to km`.

### 5. Create a GitHub Release

```powershell
git tag v1.0.0
git push origin v1.0.0

gh release create v1.0.0 `
  "Qalculate/AppPackages/.../Qalculate_1.0.0.0_x64.msix" `
  "Qalculate/AppPackages/.../Qalculate_1.0.0.0_arm64.msix" `
  --title "v1.0.0" `
  --notes "Initial public release."
```

Rename/copy MSIX files to clear release asset names if needed.

### 6. Submit to WinGet

```powershell
winget install Microsoft.WingetCreate

# Interactive — use your GitHub release MSIX URLs
wingetcreate new "https://github.com/YOU/Qalculate/releases/download/v1.0.0/Qalculate_1.0.0.0_x64.msix"
```

After `wingetcreate` opens a PR to [microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs):

1. **Add the Command Palette tag** to every `*.locale.*.yaml` file:
   ```yaml
   Tags:
   - windows-commandpalette-extension
   ```
2. **Add dependencies** (see `winget-template/NeilSawhney.Qalculate.yaml`):
   - `qalculate.qalculate`
   - `Microsoft.WindowsAppRuntime.1.7`
3. Set `InstallerType: msix` and fill in `PackageFamilyName`, hashes from your signed MSIX.
4. Run `winget validate --manifest <folder>` before merging.

Full guide: [Publish to WinGet](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/publish-extension-winget).

**Suggested package ID:** `NeilSawhney.Qalculate` (change if you prefer a different publisher prefix).

### 7. Submit to the Extension Gallery

After WinGet accepts your package:

1. Copy `Assets/StoreLogo.png` to `gallery-submission/neilsawhney/qalculate/icon.png` (square PNG, ideally 256×256 or larger).
2. Fork [microsoft/CmdPal-Extensions](https://github.com/microsoft/CmdPal-Extensions).
3. Copy `gallery-submission/neilsawhney/` into `extensions/neilsawhney/qalculate/` in your fork.
4. Ensure `installSources[0].id` matches your WinGet package ID exactly.
5. Open a PR. CI validates JSON schema; maintainers review.

Gallery docs: [CmdPal-Extensions CONTRIBUTING](https://github.com/microsoft/CmdPal-Extensions/blob/main/docs/CONTRIBUTING.md).

### 8. Verify end-to-end

- [ ] `winget install NeilSawhney.Qalculate` installs extension + dependencies
- [ ] Command Palette → Settings → Extensions gallery shows **Qalculate**
- [ ] One-click install from gallery works
- [ ] `2+2` → `4`, `100 miles to km` works without manual `qalc` setup (if WinGet dep or bundle used)
- [ ] Uninstall removes extension from Command Palette

---

## Extension identity (do not change)

| Field | Value |
|-------|-------|
| CLSID | `4c78b6b9-26f9-493e-8fe9-27f6c08ddf65` |
| Gallery ID | `neilsawhney.qalculate` |
| WinGet ID | `NeilSawhney.Qalculate` |

Changing the CLSID after release would break upgrades and COM registration.

---

## Optional: GitHub Actions automation

A workflow template is in `.github/workflows/release-msix.yml`. To enable:

1. Add repository secrets for signing (if using automated signing).
2. Push a `v*` tag to trigger build + release upload.
3. Add `WINGET_PAT` secret for automated manifest updates (after first manual WinGet submission).

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Extension not in Command Palette after install | Must be MSIX; run **Reload**; check package installed in Settings → Apps |
| `qalc` not found | Install `qalculate.qalculate`, bundle via `bundle-qalc.ps1`, or set path in extension settings |
| WinGet install fails signature check | MSIX must be signed with a trusted certificate |
| Gallery PR rejected | Check `extension.json` schema, icon PNG, WinGet ID matches live package |
| Inno Setup / EXE installer not detected | Expected — CmdPal requires MSIX for discovery ([issue #47076](https://github.com/microsoft/PowerToys/issues/47076)) |

---

## Marketing copy (for Store / gallery / WinGet)

**Short:** Mixed-unit math + built-in physical constants — full Qalculate power in Command Palette.

**Long:** Bring Qalculate's full power to PowerToys Command Palette. Do real math with mixed units (`5 miles + 10 km`, `10 mph * 2 hours`), then convert when you want. Tap hundreds of built-in constants by name — fine-structure constant, Planck constant, proton mass in MeV/c², Boltzmann constant, Planck length, and more — with automatic unit handling. No typical calculator has these. Also: algebra, calculus, currency, and everyday conversions. Results update as you type; copy with one click. Requires PowerToys. Installs `qalc` automatically via WinGet.

**Example commands to highlight:** `5 miles + 10 km` · `FineStructure` · `planck to eV s` · `proton_mass to MeV/c^2` · `PlanckLength to nm` · `10 mph * 2 hours` · `molar_gas_constant * 298 K to J`
