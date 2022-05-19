// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { createNode } from '@formkit/core'
import { createLibraryPlugin } from '@formkit/inputs'
import addIcon from '../addIcon'

describe('translateWrapperProps', () => {
  it('can translate the label, placeholder (as a prop) and help text', () => {
    const node = createNode({
      plugins: [
        createLibraryPlugin({
          text: {
            type: 'input',
            features: [addIcon],
            props: ['label'],
          },
        }),
      ],
      props: {
        type: 'text',
        label: 'example',
        icon: 'eye',
        onIconClick: vi.fn(),
      },
    })

    expect(node.props).toHaveProperty('icon')
    expect(node.props).toHaveProperty('onIconClick')
  })
})
