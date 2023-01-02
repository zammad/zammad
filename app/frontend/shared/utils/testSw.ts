// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

export class ServiceWorkerHelper {
  private enabled = localStorage.getItem('_dev_sw') === 'true'

  public ontriggerupdate: (() => void) | null = null

  allow() {
    this.enabled = true
    localStorage.setItem('_dev_sw', 'true')
    window.location.reload()
  }

  unregister() {
    this.enabled = false
    localStorage.setItem('_dev_sw', 'false')
    navigator.serviceWorker.getRegistrations().then(async (registrations) => {
      await Promise.all(registrations.map((r) => r.unregister()))
      window.location.reload()
    })
  }

  triggerUpdate() {
    this.ontriggerupdate?.()
  }

  isEnabled() {
    return this.enabled
  }
}

window.sw = new ServiceWorkerHelper()

declare global {
  interface Window {
    sw?: ServiceWorkerHelper
  }
}
