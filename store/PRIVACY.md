# Privacy policy

Last updated: 2026-11-24

DSH Disk Cleanup ("the extension") has one purpose: to show the storage cleanup reports that the
DSH Disk Cleanup desktop tool already produces on your own computer, and to clear browsing data that
your browser already stores.

## What the extension reads

- Cleanup reports written by the DSH desktop tool under
  `%USERPROFILE%\.dsh\disk-cleanup\reports\` (`structure.json`, `latest.json`, `structure.md`).
  These files are read through a local native messaging host that you install and run yourself. They
  never leave your computer.
- The report data stays in the extension popup. It is not uploaded anywhere.

## What the extension changes

- Only browser data you explicitly select: cache, site data (cookies, localStorage, IndexedDB,
  file systems), history, and download history. The extension uses Chrome's `browsingData` API and
  asks for confirmation before each action.

## What the extension never does

- It does not read, delete, or upload files on disk. All disk cleanup is done by the separate
  desktop tool, which you run yourself.
- It has no analytics, no telemetry, no advertising, and no remote code.
- It does not access page content, tabs, or your browsing activity beyond the clearing actions above.

## Permissions

| Permission | Why |
| --- | --- |
| `nativeMessaging` | Read the local cleanup reports through the companion host installed on your computer. |
| `browsingData` | Clear the browser data you select. |
| `storage` | Remember nothing beyond the popup's own state; no personal data is stored. |

## Removing data

Uninstall the extension and delete `%USERPROFILE%\.dsh\disk-cleanup\` if you also want the reports
and quarantine removed. Browser data you cleared cannot be restored by the extension.

## Contact

Open an issue in the extension's repository for privacy questions.
