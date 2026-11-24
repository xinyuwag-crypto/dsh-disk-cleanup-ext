// DSH Disk Cleanup - popup controller.

const BUILD = 'popup3'
const statusEl = document.getElementById('status')
const lastRunEl = document.getElementById('lastRun')
const totalSizeEl = document.getElementById('totalSize')
const barsEl = document.getElementById('bars')
const tipsEl = document.getElementById('tips')
const hintEl = document.getElementById('hint')
const clearResultEl = document.getElementById('clearResult')

function formatBytes(bytes) {
  const n = Number(bytes) || 0
  if (n >= 1024 ** 3) return `${(n / 1024 ** 3).toFixed(2)} GB`
  if (n >= 1024 ** 2) return `${(n / 1024 ** 2).toFixed(1)} MB`
  if (n >= 1024) return `${(n / 1024).toFixed(0)} KB`
  return `${n.toFixed(0)} B`
}

function setStatus(text, kind) {
  statusEl.textContent = text
  statusEl.className = `pill ${kind}`
}

function ask(message) {
  return new Promise((resolve) => {
    chrome.runtime.sendMessage(message, (response) => {
      if (chrome.runtime.lastError) {
        resolve({ ok: false, error: chrome.runtime.lastError.message })
        return
      }
      resolve(response || { ok: false, error: 'no response' })
    })
  })
}

const TIER_LABEL = { safe: '可清理', confirm: '需确认', avoid: '勿动' }
const TIER_CLASS = { safe: 'safe', confirm: 'confirm', avoid: 'avoid' }

document.getElementById('sub').textContent = `DSH 清理报告 + 浏览器数据 · ${BUILD}`

function renderStructure(structure) {
  totalSizeEl.textContent = structure ? formatBytes(structure.TotalBytes) : '—'

  barsEl.textContent = ''
  if (structure && Array.isArray(structure.TopDirs)) {
    for (const dir of structure.TopDirs.slice(0, 3)) {
      const row = document.createElement('div')
      row.className = 'bar'

      const name = document.createElement('span')
      name.className = 'name'
      name.textContent = dir.Name
      name.title = dir.Path

      const track = document.createElement('span')
      track.className = 'track'
      const fill = document.createElement('span')
      fill.className = 'fill'
      fill.style.width = `${Math.min(100, Math.max(2, dir.Share || 0))}%`
      track.appendChild(fill)

      const size = document.createElement('span')
      size.className = 'size'
      size.textContent = formatBytes(dir.Bytes)

      row.append(name, track, size)
      barsEl.appendChild(row)
    }
  }

  tipsEl.textContent = ''
  if (structure && Array.isArray(structure.Suggestions)) {
    for (const item of structure.Suggestions.slice(0, 3)) {
      const li = document.createElement('li')
      const tier = document.createElement('b')
      tier.textContent = `${TIER_LABEL[item.Tier] || item.Tier} · `
      tier.title = TIER_CLASS[item.Tier] || ''
      li.append(tier, document.createTextNode(`${item.Title} ${formatBytes(item.Bytes)}`))
      li.title = item.Path
      tipsEl.appendChild(li)
    }
  }
}

function renderStatus(status) {
  if (!status) {
    lastRunEl.textContent = '暂无记录'
    return
  }
  const when = status.Timestamp ? new Date(status.Timestamp) : null
  const mode = status.Mode === 'DryRun' ? '扫描' : '清理'
  const stamp = when ? when.toLocaleString() : '未知时间'
  lastRunEl.textContent = `${mode} · ${formatBytes(status.TotalBytes)} · ${stamp}`
}

async function refresh() {
  setStatus('连接中', 'pending')
  const [statusRes, structureRes] = await Promise.all([
    ask({ type: 'native', action: 'status' }),
    ask({ type: 'native', action: 'structure' }),
  ])

  if (!statusRes.ok) {
    setStatus('未连接', 'bad')
    hintEl.textContent = '未检测到本机清理服务：请先运行 native-host\\build-host.ps1 注册宿主程序。'
    hintEl.className = 'hint bad'
    return
  }

  setStatus('已连接', 'ok')
  hintEl.textContent = ''
  hintEl.className = 'hint'
  renderStatus(statusRes.data)
  renderStructure(structureRes.ok ? structureRes.data : null)
}

document.getElementById('refresh').addEventListener('click', refresh)

for (const button of document.querySelectorAll('button[data-preset]')) {
  button.addEventListener('click', async () => {
    const preset = button.dataset.preset
    const label = preset === 'cache' ? '缓存' : preset === 'cookies' ? '站点数据' : '浏览历史'
    if (!window.confirm(`确定清除${label}吗？此操作不影响磁盘文件，但退出登录状态可能恢复不了。`)) return

    const buttons = [...document.querySelectorAll('button[data-preset]')]
    buttons.forEach((b) => { b.disabled = true })
    clearResultEl.textContent = '正在清除…'
    clearResultEl.className = 'hint'

    const result = await ask({ type: 'clear', preset })
    buttons.forEach((b) => { b.disabled = false })

    if (result.ok) {
      clearResultEl.textContent = `已清除${label}。` + (result.build ? ` (${result.build})` : '')
      clearResultEl.className = 'hint ok'
    } else {
      clearResultEl.textContent = `清除失败：${result.error}`
      clearResultEl.className = 'hint bad'
    }
  })
}

refresh()
