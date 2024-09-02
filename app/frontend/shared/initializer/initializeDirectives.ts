// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
import { type App } from 'vue'

import tooltip from '#shared/plugins/directives/tooltip/index.ts'

export const initializeTooltipDirective = (app: App) => {
  const { name, directive } = tooltip
  app.directive(name, directive)
}
