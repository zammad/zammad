// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { type App } from 'vue'

import tooltip from '#shared/plugins/directives/tooltip/index.ts'

const initializeGlobalDirectives = (app: App) => {
  app.directive(tooltip.name, tooltip.directive)
}

export default initializeGlobalDirectives
