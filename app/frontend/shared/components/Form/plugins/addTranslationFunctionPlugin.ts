// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { i18n, type I18N } from '#shared/i18n/index.ts'

import type { FormKitNode } from '@formkit/core'

const addTranslationFunctionPlugin = (node: FormKitNode) => {
  const { context } = node

  if (!context) return

  context.fns.t = (source: Parameters<I18N['t']>[0], ...args: Array<Parameters<I18N['t']>[1]>) => {
    return i18n.t(source, ...args)
  }
}

export default addTranslationFunctionPlugin
