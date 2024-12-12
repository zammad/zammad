// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'

let appInstance: App

export const setCurrentApp = (app: App) => {
  appInstance = app
}

export const getCurrentApp = () => {
  return appInstance
}
