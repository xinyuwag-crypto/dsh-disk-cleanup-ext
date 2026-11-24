# Chrome Web Store listing draft

## Name (45 chars max)
`DSH Disk Cleanup` (17)

## Short description (132 chars max)
`Reads your DSH cleanup reports and clears browser cache, cookies and history in one click.`

Character count: 94 — fits.

## Category
Productivity

## Language
Chinese (Simplified) + English

## Detailed description

```
DSH Disk Cleanup 把本机的磁盘清理结果放进浏览器，并用一键操作清掉浏览器侧的缓存。

【磁盘侧】
· 显示最近一次清理释放了多少空间、清理了哪些类别
· 显示存储结构：占用最大的目录、可清理/需确认/勿动 三档建议
· 数据来自本机 DSH 清理工具生成的报告，通过本地宿主程序读取，不上传、不联网

【浏览器侧】
· 清除缓存（cache / cacheStorage / service workers / code cache）
· 清除站点数据（cookies / localStorage / IndexedDB / file systems）
· 清除浏览历史与下载记录
· 每次清除前都会二次确认

【为什么需要配套程序】
Chrome 扩展本身无权访问磁盘。磁盘清理由独立的桌面端完成，扩展只负责读取它生成的 JSON 报告。
首次使用需运行 native-host\build-host.ps1 注册本地宿主程序。

【隐私】
无分析、无遥测、无广告、无远程代码；报告只在本机读取；清除范围完全由你选择。
```

## Permission justifications (reviewer notes)

| Permission | Justification |
| --- | --- |
| `nativeMessaging` | Reads JSON reports produced locally by the companion desktop tool; required for the dashboard feature. |
| `browsingData` | The extension's second feature is clearing cache, site data, and history at the user's explicit request. |
| `storage` | Reserved for popup state; no personal data is persisted. |

## Single purpose statement

`Show local disk-cleanup reports and clear user-selected browser data.` Both halves are cleanup of
storage the user owns; neither touches page content.

## Assets checklist

- [x] 128 px icon (`icons/icon128.png`)
- [ ] 1280×800 or 640×400 screenshots — must be captured from the running extension (`chrome://extensions` → Load unpacked → open popup). Not generated here because a fabricated screenshot would misrepresent the product.
- [ ] Small promo tile 440×280 (optional)
- [ ] Privacy policy URL — host `store/PRIVACY.md` and paste the URL in the developer dashboard
- [ ] Developer account (one-time USD 5) and a verified contact email

## Known review risk

Native messaging extensions are allowed, but reviewers will install the extension alone and see
"未连接". The listing must state the desktop companion requirement in the first paragraph, and the
popup must degrade gracefully (it does: shows a hint instead of an error).
