// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { type App } from 'vue'

import tooltip, { setOptions } from '#shared/plugins/directives/tooltip/index.ts'

const initializeGlobalDirectives = (app: App) => {
  setOptions({ hideTooltip: true })
  app.directive(tooltip.name, tooltip.directive)
}

export default initializeGlobalDirectives
