// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { type App } from 'vue'

import { initializeTooltipDirective } from '#shared/initializer/initializeDirectives.ts'

const initializeGlobalDirectives = (app: App) => {
  initializeTooltipDirective(app)
}

export default initializeGlobalDirectives
