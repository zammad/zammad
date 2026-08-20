// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import extendSchemaDefinition from '#shared/form/utils/extendSchemaDefinition.ts'

import type { FormKitNode } from '@formkit/core'

// Renders field messages through the translation function, like Form.vue does for the form level
//   ones. Without it a message that is set from outside — a server side user error, which arrives
//   as its source string because the backend only marks it for extraction — stays in English.
//
// FormKit's own validation messages are already translated when they are built (see
//   shared/form/i18n/locales.ts); translating them again is a no-op.
const translateMessages = (node: FormKitNode) => {
  // Fields only: the messages of the form itself are rendered by FormKitMessages in Form.vue, which
  //   translates them there already.
  if (node.type !== 'input') return

  extendSchemaDefinition(node, 'message', {
    children: '$fns.t($message.value)',
  })
}

export default translateMessages
