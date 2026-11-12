// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { defineComponent, h, KeepAlive, ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import ChatComposer from '../ChatComposer.vue'

const renderComposer = (send = vi.fn(() => Promise.resolve())) => ({
  send,
  view: renderComponent(ChatComposer, { props: { send }, form: true }),
})

describe('ChatComposer', () => {
  it('sends the editor value on Enter', async () => {
    const { view, send } = renderComposer()

    await view.events.type(view.getByLabelText('Message'), 'Hello{Enter}')

    expect(send).toHaveBeenCalledExactlyOnceWith('Hello')
  })

  it('does not send on Shift+Enter', async () => {
    const { view, send } = renderComposer()

    await view.events.type(view.getByLabelText('Message'), 'Hello{Shift>}{Enter}{/Shift}there')

    expect(send).not.toHaveBeenCalled()
  })

  it('sends nothing while the field is empty or blank', async () => {
    const { view, send } = renderComposer()

    const field = view.getByLabelText('Message')

    await view.events.type(field, '{Enter}')
    await view.events.type(field, '   {Enter}')

    expect(send).not.toHaveBeenCalled()
    expect(view.getByRole('button', { name: 'Send' })).toBeDisabled()
  })

  it('tells that the agent is typing', async () => {
    const { view } = renderComposer()

    await view.events.type(view.getByLabelText('Message'), 'H')

    expect(view.emitted('typing')).toBeTruthy()
  })

  describe('while the message is on its way', () => {
    const renderPendingComposer = () => {
      const settle: { resolve: () => void; reject: () => void } = {
        resolve: () => undefined,
        reject: () => undefined,
      }

      const send = vi.fn(
        () =>
          new Promise<void>((resolve, reject) => {
            settle.resolve = resolve
            settle.reject = reject
          }),
      )

      return { settle, ...renderComposer(send) }
    }

    it('empties the field right away, like the old interface', async () => {
      const { view } = renderPendingComposer()

      const field = view.getByLabelText('Message')

      await view.events.type(field, 'first{Enter}')

      await waitFor(() => expect(field).toHaveValue(''))
    })

    it('keeps what the agent writes while the message is on its way', async () => {
      const { view, settle } = renderPendingComposer()

      const field = view.getByLabelText('Message')

      await view.events.type(field, 'first{Enter}')
      await view.events.type(field, 'second')

      settle.resolve()
      await waitForNextTick(true)

      expect(field).toHaveValue('second')
    })

    it('puts the message back for another try when it could not be stored', async () => {
      const { view, settle, send } = renderPendingComposer()

      const field = view.getByLabelText('Message')

      await view.events.type(field, 'first{Enter}')

      settle.reject()
      await waitFor(() => expect(field).toHaveValue('first'))

      await view.events.type(field, '{Enter}')

      expect(send).toHaveBeenCalledTimes(2)
    })

    it('puts it back before what the agent wrote since', async () => {
      const { view, settle } = renderPendingComposer()

      const field = view.getByLabelText('Message')

      await view.events.type(field, 'first{Enter}')
      await view.events.type(field, 'second')

      settle.reject()

      await waitFor(() => expect(field).toHaveValue('first<br>second'))
    })
  })

  it.each([
    ['composing', { isComposing: true }],
    ['committing a composition in Safari', { keyCode: 229 }],
  ])('does not send on the Enter that is pressed while %s', async (_, eventInit) => {
    const { view, send } = renderComposer()

    const field = view.getByLabelText('Message')

    await view.events.type(field, 'こんにちは')

    const keydown = new KeyboardEvent('keydown', {
      key: 'Enter',
      bubbles: true,
      cancelable: true,
      ...eventInit,
    })

    field.dispatchEvent(keydown)

    await waitForNextTick()

    // Not prevented either: the conversion has to be able to take the key.
    expect(keydown.defaultPrevented).toBe(false)
    expect(send).not.toHaveBeenCalled()
    expect(field).toHaveValue('こんにちは')
  })

  it('joins the Tab loop when it is added while the page is kept in the background', async () => {
    const count = ref(1)
    const isPageShown = ref(true)
    const pageElement = ref<HTMLElement>()

    // eslint-disable-next-line vue/one-component-per-file
    const Page = defineComponent({
      setup: () => () =>
        h(
          'div',
          { ref: pageElement },
          Array.from({ length: count.value }, (_, index) =>
            h(ChatComposer, { key: index, send: () => Promise.resolve() }),
          ),
        ),
    })

    // The layout keeps the chat page alive while the agent is on another one.
    // eslint-disable-next-line vue/one-component-per-file
    const KeptPage = defineComponent({
      setup: () => () =>
        h(KeepAlive, null, () => (isPageShown.value ? h(Page) : h('p', 'Elsewhere'))),
    })

    const view = renderComponent(KeptPage, { form: true })

    await view.findByLabelText('Message')

    isPageShown.value = false
    count.value = 2

    await waitFor(() => {
      expect(pageElement.value?.isConnected).toBe(false)
      expect(within(pageElement.value!).getAllByRole('textbox')).toHaveLength(2)
    })

    isPageShown.value = true

    const inputs = await view.findAllByLabelText('Message')

    // Backwards around the end, where the page order alone would not lead.
    await view.events.click(inputs[0])
    await view.events.tab({ shift: true })

    expect(inputs[1]).toHaveFocus()
  })
})
