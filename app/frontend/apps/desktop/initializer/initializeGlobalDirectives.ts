// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { type App, type Directive } from 'vue'

import type { ImportGlobEagerDefault } from '#shared/types/utils.ts'

import vTooltip from '#desktop/plugins/directives/tooltip.ts'

interface DirectiveModule {
  name: string
  directive: Record<string, unknown> | ((...args: unknown[]) => unknown)
}

const directiveModules: ImportGlobEagerDefault<DirectiveModule>[] =
  Object.values(
    import.meta.glob('../plugins/directives/*', {
      eager: true,
    }),
  )

export const directives: Record<string, Directive> = directiveModules.reduce(
  (directiveRecord: Record<string, Directive>, module) => {
    const { name, directive } = module.default
    directiveRecord[name] = directive
    return directiveRecord
  },
  {},
)

const initializeGlobalDirectives = (app: App) => {
  directiveModules.forEach(
    (module: ImportGlobEagerDefault<DirectiveModule>) => {
      const { name, directive } = module.default
      app.directive(name, directive)
    },
  )
}

export default initializeGlobalDirectives

// :TODO improve DX by adding type definitions for global directives
declare module '@vue/runtime-core' {
  export interface GlobalDirectives {
    vTooltip: typeof vTooltip
  }
  // export interface ComponentCustomProperties {
  //   vTooltip: typeof vTooltip.directive
  // }
}
