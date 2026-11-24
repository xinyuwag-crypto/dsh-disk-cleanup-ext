// DSH Disk Cleanup - service worker.
// Two jobs: relay report requests to the native host, and clear browser data on request.

const HOST_NAME = 'com.dsh.disk_cleanup'
const BUILD = 'bg3'

function sendNative(request) {
  return new Promise((resolve, reject) => {
    chrome.runtime.sendNativeMessage(HOST_NAME, request, (response) => {
      const error = chrome.runtime.lastError
      if (error) {
        reject(new Error(error.message || 'native host unavailable'))
        return
      }
      if (!response) {
        reject(new Error('empty response from native host'))
        return
      }
      if (response.data && response.data.error) {
        reject(new Error(response.data.error))
        return
      }
      resolve(response.data)
    })
  })
}

function clearBrowsingData(removalOptions, dataToRemove) {
  return new Promise((resolve, reject) => {
    chrome.browsingData.remove(removalOptions, dataToRemove, (removed) => {
      const error = chrome.runtime.lastError
      if (error) {
        reject(new Error(error.message))
        return
      }
      resolve(removed || {})
    })
  })
}

const CLEAR_PRESETS = {
  cache: {
    label: 'cache',
    options: { since: 0 },
    // DataTypeSet has no codeCache member; passing one makes the whole call fail validation.
    dataTypes: { cache: true, cacheStorage: true, serviceWorkers: true },
  },
  cookies: {
    label: 'cookies',
    options: { since: 0 },
    dataTypes: { cookies: true, localStorage: true, indexedDB: true, fileSystems: true },
  },
  history: {
    label: 'history',
    options: { since: 0 },
    dataTypes: { history: true, downloads: true },
  },
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (!message || typeof message.type !== 'string') return false

  if (message.type === 'native') {
    sendNative({ id: String(Date.now()), action: message.action || 'status' })
      .then((data) => sendResponse({ ok: true, data }))
      .catch((error) => sendResponse({ ok: false, error: error.message }))
    return true
  }

  if (message.type === 'clear') {
    const preset = CLEAR_PRESETS[message.preset]
    if (!preset) {
      sendResponse({ ok: false, error: `unknown preset: ${message.preset}` })
      return false
    }
    clearBrowsingData(preset.options, preset.dataTypes)
      .then((removed) => sendResponse({ ok: true, removed, build: BUILD }))
      .catch((error) => sendResponse({ ok: false, error: `${error.message} [${BUILD}]`, build: BUILD }))
    return true
  }

  return false
})
