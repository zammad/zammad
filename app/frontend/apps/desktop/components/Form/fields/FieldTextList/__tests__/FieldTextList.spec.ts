// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { within } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

const renderTextList = async (value: string[] = []) => {
  const view = renderComponent(FormKit, {
    form: true,
    router: true,
    store: true,
    props: {
      id: 'textList',
      type: 'textList',
      name: 'textList',
      label: 'Messages',
      value,
      description: 'One of them is picked.',
      emptyLabel: 'No messages yet',
      itemLabel: 'Message text',
      itemPlaceholder: 'Say something',
      addLabel: 'Add message',
      editLabel: 'Edit message',
      removeLabel: 'Remove message',
    },
  })

  await waitForNextTick(true)

  return view
}

const value = () => getNode('textList')?.value

describe('Form - Field - TextList', () => {
  it('lists the texts under the label of the field', async () => {
    const view = await renderTextList(['First', 'Second'])

    const list = view.getByRole('list', { name: 'Messages' })

    expect(within(list).getAllByRole('listitem')).toHaveLength(2)
    expect(list).toHaveTextContent('First')
    expect(list).toHaveTextContent('Second')
    expect(list).toHaveAccessibleDescription('One of them is picked.')
  })

  it('says there is no text yet, and what the texts are for once there is one', async () => {
    const view = await renderTextList()

    expect(view.queryByRole('list')).not.toBeInTheDocument()
    expect(view.getByText('No messages yet')).toBeInTheDocument()
    expect(view.queryByText('One of them is picked.')).not.toBeInTheDocument()

    await view.events.click(view.getByRole('button', { name: 'Add message' }))
    await view.events.keyboard('First{Enter}')

    expect(view.queryByText('No messages yet')).not.toBeInTheDocument()
    expect(view.getByText('One of them is picked.')).toBeInTheDocument()
  })

  it('adds a line open for typing', async () => {
    const view = await renderTextList(['First'])

    await view.events.click(view.getByRole('button', { name: 'Add message' }))

    const input = await view.findByRole('textbox', { name: 'Message text' })

    expect(input).toHaveFocus()

    await view.events.type(input, 'Second{Enter}')

    expect(value()).toEqual(['First', 'Second'])
  })

  it('drops a new line given up before anything was typed', async () => {
    const view = await renderTextList(['First'])

    await view.events.click(view.getByRole('button', { name: 'Add message' }))
    await view.events.keyboard('{Escape}')

    expect(value()).toEqual(['First'])
    // Back where the agent started from, instead of nowhere.
    expect(view.getByRole('button', { name: 'Add message' })).toHaveFocus()
  })

  it('drops a new line left empty with Enter or a click elsewhere as well', async () => {
    const view = await renderTextList(['First'])

    const addButton = view.getByRole('button', { name: 'Add message' })

    await view.events.click(addButton)
    await view.events.keyboard('{Enter}')

    expect(value()).toEqual(['First'])
    expect(addButton).toHaveFocus()

    // A click elsewhere keeps the focus where it went.
    await view.events.click(addButton)
    await view.events.click(view.getByRole('button', { name: 'Action menu button' }))

    expect(value()).toEqual(['First'])
    expect(addButton).not.toHaveFocus()
  })

  it('edits and removes a text from its menu', async () => {
    const view = await renderTextList(['First', 'Second'])

    const [first, second] = view.getAllByRole('listitem')

    await view.events.click(within(first).getByRole('button', { name: 'Action menu button' }))
    await view.events.click(await view.findByRole('button', { name: 'Edit message' }))

    const input = await view.findByRole('textbox', { name: 'Message text' })

    expect(input).toHaveValue('First')

    await view.events.clear(input)
    await view.events.type(input, 'Changed{Enter}')

    expect(value()).toEqual(['Changed', 'Second'])

    const addButton = view.getByRole('button', { name: 'Add message' })

    await view.events.click(within(second).getByRole('button', { name: 'Action menu button' }))
    await view.events.click(await view.findByRole('button', { name: 'Remove message' }))

    expect(value()).toEqual(['Changed'])
    // The menu went with its row, so the focus does not.
    expect(addButton).toHaveFocus()

    await view.events.click(view.getByRole('button', { name: 'Action menu button' }))
    await view.events.click(await view.findByRole('button', { name: 'Remove message' }))

    expect(value()).toEqual([])
    expect(view.queryByRole('list')).not.toBeInTheDocument()
    expect(addButton).toHaveFocus()
  })
})
