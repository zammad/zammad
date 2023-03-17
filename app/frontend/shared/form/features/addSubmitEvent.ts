// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'

const addSubmitEvent = (node: FormKitNode) => {
  // TODO: think about adding a `submit` boolean prop as well, and submitting the whole form implicitly if set to true.
  node.addProps(['onSubmit'])

  node.on('created', () => {
    if (!node.context || typeof node.props.onSubmit !== 'function') return

    node.context.attrs.onKeypress = (event: KeyboardEvent) => {
      if (event.key !== 'Enter') return

      // Prevent the form from being submitted, this should now be the responsibility of the custom handler.
      event.preventDefault()

      node.props.onSubmit.call(
        null,
        new SubmitEvent('submit', {
          submitter: event.target as HTMLElement,
        }),
      )
    }
  })
}

export default addSubmitEvent
