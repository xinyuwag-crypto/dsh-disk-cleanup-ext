# Chrome Web Store listing

Copy-and-paste values for the developer dashboard. Update this file whenever the store text changes
so the repository matches what is published.

## Name

`DSH Disk Cleanup`

## Short description (132 characters max)

Chinese (primary):

```
读取本机 DSH 清理报告，一键清除浏览器缓存、站点数据与历史。需配合桌面端使用。
```

English (secondary):

```
Reads your DSH cleanup reports and clears browser cache, cookies and history in one click.
```

## Detailed description

Chinese (primary):

```
DSH Disk Cleanup 把本机的磁盘清理结果放进浏览器，并让你一键清掉浏览器侧的缓存。

【磁盘侧 · 只读展示】
· 最近一次清理的时间、释放空间与分类
· 存储结构：占用最大的目录、最大文件、类型分布
· 三档清理建议：可清理 / 需确认 / 勿动
· 数据来自本机的 DSH 清理工具报告，只读，不修改任何文件

【浏览器侧 · 由你决定】
· 清除缓存（cache、cacheStorage、service worker）
· 清除站点数据（Cookie、localStorage、IndexedDB、文件系统）
· 清除浏览历史与下载记录
· 每次操作都会二次确认，结果即时反馈

【需要配套桌面程序】
Chrome 扩展无权访问磁盘，磁盘清理由独立的桌面端完成。扩展通过本地宿主程序（native messaging）
读取报告，因此需要先在本机安装并注册该宿主程序，否则弹窗会显示「未连接」。

【隐私】
· 报告只在本机读取，不上传、不联网
· 无分析、无遥测、无广告、无远程代码
· 不读取网页内容、不访问标签页

【系统要求】
· Windows 10 / 11，Chrome 116 及以上
· 配套的 DSH 清理桌面端与 native host
```

English (secondary):

```
DSH Disk Cleanup shows the disk-cleanup reports your local DSH tool already produces, and clears
browser data on request.

Disk side (read only)
· Last cleanup: time, freed space, categories
· Storage structure: largest directories, files, and file types
· Three-tier suggestions: safe / confirm / do not touch
· Reads local reports only; changes no files

Browser side (you decide)
· Clear cache (cache, cacheStorage, service workers)
· Clear site data (cookies, localStorage, IndexedDB, file systems)
· Clear browsing history and downloads
· Every action asks for confirmation and shows the result

Desktop companion required
Chrome extensions cannot access the filesystem. The disk half runs in a separate desktop tool; this
extension reads its reports through a local native messaging host that you install and register.
Without it the popup shows "not connected".

Privacy
· Reports are read locally; nothing is uploaded and no network calls are made
· No analytics, no telemetry, no ads, no remote code
· No access to page content or tabs

Requirements
· Windows 10/11, Chrome 116+
· The DSH cleanup desktop tool and its native host
```

## Category and language

- Category: **Productivity**
- Primary language: **Chinese (Simplified)**; add English as a secondary language

## Permission justifications

| Permission | Justification |
| --- | --- |
| `nativeMessaging` | Reads JSON reports produced locally by the companion desktop tool; required for the dashboard feature. |
| `browsingData` | The extension's second feature is clearing cache, site data, and history at the user's explicit request. |

Single purpose statement:

```
Show local disk-cleanup reports and clear user-selected browser data.
```

## Assets

| Slot | File | Size |
| --- | --- | --- |
| Store icon | `icons/icon128.png` | 128×128 |
| Screenshot 1 (connected + structure) | `store/screenshot-1.png` | 1280×800 |
| Screenshot 2 (clear result) | `store/screenshot-2.png` | 1280×800 |
| Small promo tile | `store/promo-440x280.png` | 440×280 |

Screenshots were composed from captures of the running extension; the UI itself is unmodified.

## Review risk and mitigation

The reviewer installs only the extension and will see "未连接". The first paragraph of the detailed
description states the desktop companion requirement, the popup degrades gracefully with an
explanatory hint, and the privacy policy repeats the requirement.
