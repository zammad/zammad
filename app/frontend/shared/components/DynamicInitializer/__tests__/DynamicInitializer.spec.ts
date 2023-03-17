// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { render } from '@testing-library/vue'
import { h, nextTick, ref } from 'vue'
import DynamicInitializer from '../DynamicInitializer.vue'
import { destroyComponent, pushComponent } from '../manage'

describe('dynamicaly add components to dom', () => {
  test('adds and destroys components', async () => {
    const view = render(DynamicInitializer, {
      props: {
        name: 'dialog',
      },
    })

    await pushComponent('dialog', '1', () => h('div', 'Hello, World!'))

    expect(view.container).toHaveTextContent('Hello, World!')

    await destroyComponent('dialog', '1')

    expect(view.container).not.toHaveTextContent('Hello, World!')
  })

  test("doesn't add other components", async () => {
    const view = render(DynamicInitializer, {
      props: {
        name: 'dialog',
      },
    })

    await pushComponent('not-dialog', '1', () => h('div', 'Hello, World!'))

    expect(view.container).not.toHaveTextContent('Hello, World!')
  })

  test('can pass down reactive variables', async () => {
    const view = render(DynamicInitializer, {
      props: {
        name: 'dialog',
      },
    })

    const name = ref('dialog')

    await pushComponent(
      'dialog',
      '1',
      (props) => h('div', `Hello, ${props.name}!`),
      { name },
    )

    expect(view.container).toHaveTextContent('Hello, dialog!')

    name.value = 'world'

    await nextTick()

    expect(view.container).toHaveTextContent('Hello, world!')
  })
})
