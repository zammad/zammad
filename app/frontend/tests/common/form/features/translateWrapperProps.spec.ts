// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@common/utils/i18n'
import translateWrapperProps from '@common/form/features/translateWrapperProps'
import { createNode } from '@formkit/core'
import { createLibraryPlugin } from '@formkit/inputs'

const map = new Map([
  ['example', 'Beispiel'],
  ['help me!', 'Hilf mir!'],
])

i18n.setTranslationMap(map)

describe('translateWrapperProps', () => {
  it('can translate the label, placeholder (as a prop) and help text', () => {
    const node = createNode({
      plugins: [
        createLibraryPlugin({
          text: {
            type: 'input',
            features: [translateWrapperProps],
            props: ['label', 'placeholder', 'help'],
          },
        }),
      ],
      props: {
        type: 'text',
        placeholder: 'example',
        label: 'example',
        help: 'help me!',
      },
    })

    expect(node.props.label.value).toEqual('Beispiel')
    expect(node.props.placeholder.value).toEqual('Beispiel')
    expect(node.props.help.value).toEqual('Hilf mir!')
  })
})
