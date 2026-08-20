// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { i18n, type I18N } from '#shared/i18n/index.ts'

import type { FormKitNode } from '@formkit/core'

// Makes `$fns.t(…)` available in every node's schema, which is how both the form level and the
//   field level messages translate what they render — a message set from outside (a server side
//   user error) arrives as its source string.
const addTranslationFunction = (node: FormKitNode) => {
  const { context } = node

  if (!context) return

  context.fns.t = (source: Parameters<I18N['t']>[0], ...args: Array<Parameters<I18N['t']>[1]>) => {
    return i18n.t(source, ...args)
  }
}

export default addTranslationFunction
