// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'

const bindEmit = (node: FormKitNode) => {
  const { props, context } = node

  if (!props.definition || !context || node.type !== 'input') return

  context.handlers.bindEmit = (name: string) => (e: Event) => node.emit(name, e)
}

export default bindEmit
