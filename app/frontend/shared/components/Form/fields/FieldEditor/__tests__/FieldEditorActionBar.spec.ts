// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import FieldEditorActionBar from '../FieldEditorActionBar.vue'

// not actually executed in a unit test, should speed up tests
vi.mock('@tiptap/vue-3', () => {
  return {
    VueRenderer: () => true,
  }
})

vi.mock('@tiptap/pm/state', () => {
  return {
    PluginKey: vi.fn((name: string) => name),
  }
})

describe('keyboard interactions', () => {
  it('can use arrows to traverse toolbar', async () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        visible: true,
        contentType: 'text/html',
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
        contentType: 'text/html',
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
        contentType: 'text/html',
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
        contentType: 'text/html',
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
        contentType: 'text/html',
        visible: true,
        disabledPlugins: [],
      },
    })

    await view.events.click(document.body)

    expect(view.emitted().hide).toBeTruthy()
  })
})

describe('basic toolbar testing', () => {
  it("don't see disabled actions", () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/html',
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

  it("don't see plain text actions", () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/plain',
        visible: true,
        disabledPlugins: [],
      },
    })

    expect(
      view.getByLabelText('Insert text from text module'),
    ).toBeInTheDocument()
    expect(view.getByIconName('mobile-snippet')).toBeInTheDocument()

    expect(
      view.getByLabelText('Insert text from Knowledge Base article'),
    ).toBeInTheDocument()
    expect(view.getByIconName('mobile-mention-kb')).toBeInTheDocument()

    expect(
      view.queryByRole('button', { name: 'Mention user' }),
    ).not.toBeInTheDocument()
    expect(view.queryByLabelText('Mention user')).not.toBeInTheDocument()

    expect(view.queryByLabelText('Add link')).not.toBeInTheDocument()
    expect(view.queryByLabelText('Add image')).not.toBeInTheDocument()
    expect(
      view.queryByLabelText('Format as underlined'),
    ).not.toBeInTheDocument()
  })
})
