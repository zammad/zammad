// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { type App, inject, ref } from 'vue'
import type { RouteLocationRaw, Router } from 'vue-router'

export class Walker {
  private previousRoute = ref<string | null>(null)

  static KEY_INJECT = Symbol('walker')

  constructor(private router: Router) {
    this.previousRoute.value = Walker.getHistoryBackRoute()

    router.afterEach(() => {
      this.previousRoute.value = Walker.getHistoryBackRoute()
    })
  }

  private static getHistoryBackRoute(): string | null {
    const { state } = window.history

    if (state && typeof state.back === 'string') {
      return state.back
    }

    return null
  }

  public getBackUrl(backupRoute: RouteLocationRaw) {
    return this.previousRoute.value || backupRoute
  }

  public get hasBackUrl() {
    return this.previousRoute.value !== null
  }

  public async back(path: RouteLocationRaw, ignore: string[] = []) {
    const previous = this.previousRoute.value
    if (previous && !ignore.find((entry) => previous.includes(entry))) {
      return this.router.back()
    }
    return this.router.push(path)
  }
}

declare module '@vue/runtime-core' {
  export interface ComponentCustomProperties {
    $walker: Walker
  }
}

export const useWalker = (): Walker => {
  return inject(Walker.KEY_INJECT) as Walker
}

export const initializeWalker = (app: App, router: Router) => {
  const walker = new Walker(router)
  app.provide(Walker.KEY_INJECT, walker)
  app.config.globalProperties.$walker = walker
}
