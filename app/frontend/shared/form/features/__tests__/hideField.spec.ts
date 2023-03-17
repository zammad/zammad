// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { createNode } from '@formkit/core'
import { createLibraryPlugin } from '@formkit/inputs'
import hideField from '../hideField'

describe('hideField', () => {
  it('can hide a field', () => {
    const node = createNode({
      plugins: [
        createLibraryPlugin({
          text: {
            type: 'input',
            features: [hideField],
            props: ['label'],
          },
        }),
      ],
      props: {
        type: 'text',
        label: 'example',
        hidden: true,
      },
    })

    expect(node.props.outerClass).toContain('hidden')

    node.props.hidden = false

    expect(node.props.outerClass).eq('')
  })
})
