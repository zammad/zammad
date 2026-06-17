// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import TooltipDirective from '#shared/plugins/directives/tooltip/index.ts'

declare module 'vue' {
  export interface GlobalDirectives {
    vTooltip: typeof TooltipDirective.directive
  }
}
