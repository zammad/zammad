// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { createNode } from '@formkit/core'
import { createLibraryPlugin } from '@formkit/inputs'
import formUpdaterTrigger from '../formUpdaterTrigger'

describe('formUpdaterTrigger', () => {
  it('triggers form updater directly', () => {
    const node = createNode({
      plugins: [
        createLibraryPlugin({
          text: {
            type: 'input',
            features: [formUpdaterTrigger()],
          },
        }),
      ],
      props: {
        type: 'text',
        triggerFormUpdater: true,
      },
    })

    expect(node.props.delay).toEqual(20)
  })

  it('triggers form updater delayed', () => {
    const node = createNode({
      plugins: [
        createLibraryPlugin({
          text: {
            type: 'input',
            features: [formUpdaterTrigger('delayed')],
          },
        }),
      ],
      props: {
        type: 'text',
        triggerFormUpdater: true,
      },
    })

    expect(node.props.delay).toEqual(300)
  })
})
