// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { App } from 'vue'

export type InitializerModule = (app: App) => void

export interface Initializer {
  app: App
  modules: Array<InitializerModule>
  initialize(): void
}
