// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { AppName } from '#shared/types/app.ts'
import type { CacheInitializerModules } from '#shared/types/server/apollo/client.ts'

import type { Plugin } from 'vue'

// What the components of an app are mounted with; `apps/` holds one per app, and the setup
//   registers the one a spec belongs to before its tests run.
export interface BrowserApp {
  name: AppName
  plugins: Plugin[]
  cacheInitializerModules: CacheInitializerModules
}

let browserApp: BrowserApp | undefined

export const registerBrowserApp = (app: BrowserApp) => {
  browserApp = app
}

export const getBrowserApp = () => {
  if (!browserApp)
    throw new Error('The setup registers the app before the tests run: mount inside a test.')

  return browserApp
}
