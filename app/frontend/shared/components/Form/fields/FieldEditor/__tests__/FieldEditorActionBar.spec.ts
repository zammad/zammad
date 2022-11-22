// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import FieldEditorActionBar from '../FieldEditorActionBar.vue'

describe('keyboard interactions', () => {
  it('can use arrows to traverse toolbar', async () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        visible: true,
        disabledPlugins: [],
      },
    })

    const actions = view.getAllByRole('button')

    await view.events.click(view.getByRole('toolbar'))

    await view.events.keyboard('{ArrowRight}')
    expect(actions[0]).toHaveFocus()

    await view.events.keyboard('{ArrowRight}')
    expect(actions[1]).toHaveFocus()

    await view.events.keyboard('{ArrowLeft}')
    expect(actions[0]).toHaveFocus()

    await view.events.keyboard('{ArrowLeft}')
    expect(actions.at(-1)).toHaveFocus()

    await view.events.keyboard('{ArrowRight}')
    expect(actions[0]).toHaveFocus()
  })
  it('can use home and end to traverse toolbar', async () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        visible: true,
        disabledPlugins: [],
      },
    })

    const actions = view.getAllByRole('button')

    await view.events.click(view.getByRole('toolbar'))

    await view.events.keyboard('{Home}')
    expect(actions[0]).toHaveFocus()

    await view.events.keyboard('{End}')
    expect(actions.at(-1)).toHaveFocus()
  })
  it('hides on blur', async () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        visible: true,
        disabledPlugins: [],
      },
    })

    await view.events.click(view.getByRole('toolbar'))
    await view.events.keyboard('{Tab}')

    expect(view.emitted().hide).toBeTruthy()
  })
  it('hides on escape', async () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        visible: true,
        disabledPlugins: [],
      },
    })

    await view.events.click(view.getByRole('toolbar'))
    await view.events.keyboard('{Escape}')

    // emits blur, because toolbar is not hidden, but focus is shifted to the editor instead
    expect(view.emitted().blur).toBeTruthy()
  })
  it('hides on click outside', async () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        visible: true,
        disabledPlugins: [],
      },
    })

    await view.events.click(document.body)

    expect(view.emitted().hide).toBeTruthy()
  })
})

describe('basic toolbar testing', () => {
  it("don't see disabled actions", async () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        visible: true,
        disabledPlugins: ['mentionUser'],
      },
    })

    expect(
      view.queryByRole('button', { name: 'Mention user' }),
    ).not.toBeInTheDocument()
    expect(view.queryByLabelText('Mention user')).not.toBeInTheDocument()
    expect(view.queryByText('Mention user')).not.toBeInTheDocument()
    expect(view.queryByIconName('mobile-at-sign')).not.toBeInTheDocument()
  })
})
