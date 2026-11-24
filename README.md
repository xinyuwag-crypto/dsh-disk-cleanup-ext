# DSH Disk Cleanup — Chrome extension

Shows the storage reports that the DSH disk-cleanup plugin writes on this machine, and clears
browser data (cache, site data, history) on request.

Chrome extensions cannot touch the filesystem, so the disk half runs in the companion desktop tool
and is delivered here through **native messaging**.

```
apps/chrome-extension/
├─ manifest.json          MV3 manifest
├─ background.js          service worker: native relay + browsingData clearing
├─ popup.html/js/css      popup UI
├─ icons/                 16/32/48/128 PNG
├─ native-host/
│  ├─ host.cs             native messaging host (length-prefixed JSON over stdio)
│  ├─ build-host.ps1      compiles host.cs, writes the host manifest, registers Chrome + Edge
│  └─ test-host.ps1       protocol smoke test (ping / structure / status / unknown)
├─ tools/make-icons.ps1   redraws the PNG icons
├─ package.ps1            builds dist/dsh-disk-cleanup-v*.zip for the Web Store
└─ store/                 privacy policy + listing draft
```

## Run it locally

1. Build the native host (HKCU only, no administrator needed):
   ```powershell
   pwsh -File native-host\build-host.ps1 -NoRegister   # compile only
   ```
2. `chrome://extensions` → enable **Developer mode** → **Load unpacked** → pick this folder.
3. Copy the **ID** shown on the extension card, then register the host for that ID:
   ```powershell
   pwsh -File native-host\build-host.ps1 -ExtensionId <the-id>
   ```
4. Reload the extension and open the popup. It should show “已连接”, the last cleanup run, and the
   top directories.

The unpacked extension ID is derived from the folder path, so moving or renaming this directory
changes it — re-run step 3 whenever the ID changes. After publishing, use the ID the Web Store
assigns instead.

## Verify without Chrome

```powershell
pwsh -File native-host\test-host.ps1
```
Expected output: `ping/structure/status` return `ok`, an unknown action returns an error payload.

## Package for the Web Store

```powershell
pwsh -File package.ps1
```
Produces `dist/dsh-disk-cleanup-v1.0.1.zip` containing only runtime files.

Store assets and steps:

| Item | Where |
| --- | --- |
| Submission checklist (field by field) | [store/CHECKLIST.md](store/CHECKLIST.md) |
| Listing copy, permission justifications | [store/LISTING.md](store/LISTING.md) |
| Privacy policy page (GitHub Pages ready) | [docs/privacy/index.html](docs/privacy/index.html) → publish `/docs` |
| Promo tile 440×280 and feature card 1280×800 | `store/`, regenerate with `tools/make-store-assets.ps1` |
| Connection check after the store assigns a new id | `native-host/verify-connection.ps1` |

Publish the policy: Settings → Pages → Deploy from a branch → `main` + `/docs`, then use
`https://xinyuwag-crypto.github.io/dsh-disk-cleanup-ext/privacy/`.

After approval, the store id differs from the unpacked id — register it and verify:

```powershell
pwsh -File native-host\build-host.ps1 -ExtensionId <store-id>
pwsh -File native-host\verify-connection.ps1 -ExtensionId <store-id>
```

## Status

Verified on 2026-11-24 with Chrome 157, unpacked, extension id
`ejalgoimoedpiiclkimgcmjddainjhne`:

- extension loads and passes `--pack-extension` validation
- native host compiles, protocol answers `ping` / `structure` / `status`
- popup shows **已连接**, the last cleanup run, totals and suggestions
- all three clearing actions run against real browser data: cache, site data, history

Two defects were found and fixed during that verification, both only visible by actually
pressing the buttons:

1. `chrome.browsingData.remove` needs `(options, dataToRemove, callback)` — the first version passed
   a merged object as `options`, so every call failed with `No matching signature`.
2. `codeCache` is not a member of `browsingData.DataTypeSet`; including it failed validation for the
   cache button only. It is now removed — `cache` covers the HTTP cache, and the code cache is not
   exposed by this API.

Not yet verified: behavior from the published build (Web Store assigns a different id, so
`allowed_origins` must be re-registered), and the store screenshots.

## Limitations

- Requires the DSH cleanup reports to exist at `%USERPROFILE%\.dsh\disk-cleanup\reports\`. Without
  them the popup shows a connection hint instead of data.
- Clearing site data logs you out of sites; that is Chrome's behavior, not a bug.
- No store screenshots are generated here — they must come from the running extension.

