// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { describe, expect, it, onTestFinished, vi } from 'vitest'
import { page, userEvent } from 'vitest/browser'
import { defineComponent, h, onMounted, useTemplateRef } from 'vue'

import { mountComponent } from '#tests/browser/utils.ts'

import { mockTextModuleSuggestionsQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/textModule/textModuleSuggestions.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import ChatComposer from '../ChatComposer.vue'

const PNG_DATA_URL =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='

// Pasted image files are only taken in when the system shows their type inline.
const config = { 'active_storage.content_types_allowed_inline': ['image/png', 'image/jpeg'] }

const mountComposer = async (permissions?: string[]) => {
  const send = vi.fn(() => Promise.resolve())

  await mountComponent(ChatComposer, { send }, { config, permissions })

  const field = page.getByRole('textbox', { name: 'Message' })

  await expect.element(field).toBeInTheDocument()

  return { send, field }
}

const pasteImage = async (field: Awaited<ReturnType<typeof mountComposer>>['field']) => {
  await userEvent.click(field)

  const blob = await (await fetch(PNG_DATA_URL)).blob()
  const clipboardData = new DataTransfer()

  clipboardData.items.add(new File([blob], 'pixel.png', { type: 'image/png' }))

  field
    .element()
    .dispatchEvent(new ClipboardEvent('paste', { clipboardData, bubbles: true, cancelable: true }))

  await expect.poll(() => page.getByRole('button', { name: 'Send' }).element()).toBeEnabled()
}

describe('ChatComposer in the browser', () => {
  it('sends the message as HTML on Enter and breaks the line on Shift+Enter', async () => {
    const { send, field } = await mountComposer()

    await userEvent.click(field)
    await userEvent.keyboard('Hello{Shift>}{Enter}{/Shift}there')

    expect(send).not.toHaveBeenCalled()

    await userEvent.keyboard('{Enter}')

    await expect.poll(() => send.mock.calls.length).toBe(1)
    // No block around it: the widget puts the message into a bubble of its own.
    expect(send).toHaveBeenCalledWith('Hello<br>there')
  })

  it('sends what was typed before the Enter, and nothing typed right after it', async () => {
    const { send, field } = await mountComposer()

    await userEvent.click(field)
    await userEvent.keyboard('Hi{Enter}Next')

    await expect.poll(() => send.mock.calls.length).toBe(1)
    expect(send).toHaveBeenCalledWith('Hi')
    await expect.element(field).toHaveTextContent('Next')
  })

  it('takes the focus asked for before its editor has loaded', async () => {
    const FocusedOnMount = defineComponent({
      setup() {
        const composer = useTemplateRef<{ focus: () => void }>('composer')

        onMounted(() => composer.value?.focus())

        return () => h(ChatComposer, { ref: 'composer', send: () => Promise.resolve() })
      },
    })

    await mountComponent(FocusedOnMount, {}, { config })

    await expect.element(page.getByRole('textbox', { name: 'Message' })).toHaveFocus()
  })

  it('offers no formatting toolbar', async () => {
    const { field } = await mountComposer()

    await userEvent.click(field)

    expect(page.getByRole('toolbar').query()).toBeNull()
  })

  it('sends a "<" as typed, not as markup', async () => {
    const { send, field } = await mountComposer()

    await userEvent.click(field)
    // In one go: the Enter right after the last key still sends it along.
    await userEvent.keyboard('a <b>{Enter}')

    await expect.poll(() => send.mock.calls.length).toBe(1)
    expect(send).toHaveBeenCalledWith('a &lt;b&gt;')
  })

  it('takes no key beyond 40,000 characters', async () => {
    const { send, field } = await mountComposer()

    // Filled from outside, as typing it key by key would take minutes.
    getNode(field.element().id)?.input('a'.repeat(40000))

    await expect.poll(() => field.element().textContent?.length).toBe(40000)

    await userEvent.click(field)
    await userEvent.keyboard('b{Enter}')

    await expect.poll(() => send.mock.calls.length).toBe(1)

    const [html] = send.mock.calls[0] as unknown as [string]

    expect(html).toHaveLength(40000)
  })

  it('sends a pasted image embedded as a data URL', async () => {
    const { send, field } = await mountComposer()

    await pasteImage(field)

    await userEvent.keyboard('{Enter}')

    await expect.poll(() => send.mock.calls.length).toBe(1)
    expect(send.mock.calls[0]).toEqual([
      expect.stringMatching(/<img [^>]*src="data:image\/[a-z]+;base64,/),
    ])
  })

  it('sends an image along that was pasted right before the Enter, and nothing written after it', async () => {
    const { readAsDataURL } = FileReader.prototype

    vi.spyOn(FileReader.prototype, 'readAsDataURL').mockImplementation(function read(
      this: FileReader,
      blob: Blob,
    ) {
      setTimeout(() => readAsDataURL.call(this, blob), 300)
    })
    onTestFinished(() => {
      vi.restoreAllMocks()
    })

    const { send, field } = await mountComposer()

    await userEvent.click(field)
    await userEvent.keyboard('Look:')
    await pasteImage(field)
    // In one go: the next message is begun while the image of this one is still being read.
    await userEvent.keyboard('{Enter}Next')

    await expect.poll(() => send.mock.calls.length).toBe(1)
    expect(send.mock.calls[0]).toEqual([
      expect.stringMatching(
        /^Look:<img [^>]*src="data:image\/[a-z]+;base64,[^"]+"[^>]*style="max-width: 100%; height: auto;"[^>]*>$/,
      ),
    ])
    await expect.element(field).toHaveTextContent('Next')
    expect(field.element().querySelector('img[src]')).toBeNull()
  })

  it('leaves the Enter on an image to the image, which opens its resize frame', async () => {
    const { send, field } = await mountComposer()

    await pasteImage(field)

    const imageButton = field.element().querySelector<HTMLButtonElement>('button:has(img)')!

    imageButton.focus()
    await userEvent.keyboard('{Enter}')

    await expect.element(page.getByAltText('Resize frame')).toBeInTheDocument()
    expect(send).not.toHaveBeenCalled()
  })

  it('moves with Tab between the message inputs of two composers, and leaves them with Escape', async () => {
    const onLeave = vi.fn()

    const TwoComposers = defineComponent({
      setup() {
        const send = () => Promise.resolve()

        return () => [h(ChatComposer, { send, onLeave }), h(ChatComposer, { send })]
      },
    })

    await mountComponent(TwoComposers, {}, { config })

    const first = page.getByRole('textbox', { name: 'Message' }).first()
    const second = page.getByRole('textbox', { name: 'Message' }).last()

    await expect.element(second).toBeInTheDocument()

    await userEvent.click(first)
    await userEvent.keyboard('{Tab}')

    await expect.element(second).toHaveFocus()

    await userEvent.keyboard('{Shift>}{Tab}{/Shift}')

    await expect.element(first).toHaveFocus()
    expect(onLeave).not.toHaveBeenCalled()

    await userEvent.keyboard('{Escape}')

    expect(onLeave).toHaveBeenCalledOnce()
  })

  it('puts a message that could not be sent back with its line breaks, also before an image', async () => {
    const send = vi
      .fn<(html: string) => Promise<unknown>>()
      .mockRejectedValueOnce(new Error('Network down'))
      .mockResolvedValue(undefined)

    await mountComponent(ChatComposer, { send }, { config })

    const field = page.getByRole('textbox', { name: 'Message' })

    await expect.element(field).toBeInTheDocument()

    await userEvent.click(field)
    await userEvent.keyboard('Look:{Shift>}{Enter}{/Shift}')
    await pasteImage(field)
    await userEvent.keyboard('{Enter}')

    await expect.poll(() => send.mock.calls.length).toBe(1)

    const [written] = send.mock.calls[0]

    expect(written).toMatch(/^Look:<br><img /)

    await expect.poll(() => field.element().querySelector('img[src]')).not.toBeNull()

    await userEvent.keyboard('{Enter}')

    await expect.poll(() => send.mock.calls.length).toBe(2)
    expect(send.mock.calls[1][0]).toBe(written)
  })

  describe('text modules', () => {
    const mockTextModules = () =>
      mockTextModuleSuggestionsQuery({
        textModuleSuggestions: [
          {
            id: convertToGraphQLId('TextModule', '1'),
            name: 'faq - Frequently asked questions',
            keywords: null,
            renderedContent:
              '<p>Hello, <strong>Chat Agent</strong> here.</p><p>See our <a href="https://example.com/faq">FAQ</a>.</p>',
          },
        ],
      })

    it('inserts the text module picked with Enter instead of sending, and sends it afterwards', async () => {
      mockTextModules()

      const { send, field } = await mountComposer(['ticket.agent'])

      await userEvent.click(field)
      await userEvent.keyboard('::')

      await expect
        .element(page.getByTestId('mention-text'))
        .toMatchTextContent('Frequently asked questions')
      await expect.element(field).toHaveAttribute('aria-activedescendant')

      await userEvent.keyboard('{Enter}')

      await expect.poll(() => field.element().textContent).toContain('FAQ')
      expect(send).not.toHaveBeenCalled()

      await userEvent.keyboard('{Enter}')

      await expect.poll(() => send.mock.calls.length).toBe(1)

      // The formatting is left out, the address of a link is not.
      const [html] = send.mock.calls[0] as unknown as [string]

      expect(html).toMatch(
        /^Hello, Chat Agent here\.<br>See our <a [^>]*href="https:\/\/example\.com\/faq"[^>]*>FAQ<\/a>\.$/,
      )
    })

    it('sends nothing on an Enter that comes before the text modules are there', async () => {
      mockTextModules()

      const { send, field } = await mountComposer(['ticket.agent'])

      await userEvent.click(field)
      // In one go: the list is still loading when the Enter arrives.
      await userEvent.keyboard('::faq{Enter}')

      await expect
        .element(page.getByTestId('mention-text'))
        .toMatchTextContent('Frequently asked questions')
      await expect.element(field).toHaveAttribute('aria-activedescendant')
      expect(send).not.toHaveBeenCalled()

      await userEvent.keyboard('{Enter}')

      await expect.poll(() => field.element().textContent).toContain('FAQ')
      expect(send).not.toHaveBeenCalled()
    })

    it('sends nothing while the list is open without a match, and sends once it is closed', async () => {
      mockTextModuleSuggestionsQuery({ textModuleSuggestions: [] })

      const { send, field } = await mountComposer(['ticket.agent'])

      await userEvent.click(field)
      await userEvent.keyboard('::nothing')

      await expect.element(page.getByTestId('mention-text')).toMatchTextContent('No results found')
      await expect.element(field).not.toHaveAttribute('data-suggestions-loading')

      await userEvent.keyboard('{Enter}')

      await expect.element(field).toHaveTextContent('::nothing')
      expect(send).not.toHaveBeenCalled()

      await userEvent.keyboard('{Escape}')
      await expect.element(field).not.toHaveAttribute('aria-expanded')
      await expect.element(field).toHaveFocus()

      await userEvent.keyboard('{Enter}')

      await expect.poll(() => send.mock.calls.length).toBe(1)
      expect(send).toHaveBeenCalledWith('::nothing')
    })

    it('offers none to an agent without access to tickets', async () => {
      mockTextModules()

      const { send, field } = await mountComposer(['chat.agent'])

      await userEvent.click(field)
      await userEvent.keyboard('::')

      // Set as soon as a list opens, also while it loads.
      await expect.element(field).not.toHaveAttribute('aria-haspopup')
      expect(page.getByTestId('mention-text').query()).toBeNull()

      await userEvent.keyboard('{Enter}')

      await expect.poll(() => send.mock.calls.length).toBe(1)
      expect(send).toHaveBeenCalledWith('::')
    })
  })
})
