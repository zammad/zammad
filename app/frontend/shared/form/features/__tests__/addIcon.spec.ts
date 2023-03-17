// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { createNode } from '@formkit/core'
import { createLibraryPlugin } from '@formkit/inputs'
import addIcon from '../addIcon'

describe('hideIcon', () => {
  it('can show icon inside of a text field', () => {
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
        icon: 'mobile-show',
        onIconClick: vi.fn(),
      },
    })

    expect(node.props).toHaveProperty('icon')
    expect(node.props).toHaveProperty('onIconClick')
  })
})
