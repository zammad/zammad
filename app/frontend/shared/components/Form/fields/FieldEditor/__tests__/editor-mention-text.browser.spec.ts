// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { mockTextModuleSuggestionsQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/textModule/textModuleSuggestions.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  editorHtml,
  findEditor,
  mountEditor,
  pressCursorKey,
  waitForLastSearch,
} from './browser-utils.ts'

describe('Testing "text" popup: "::" command', () => {
  it('inserts a text', async () => {
    const suggestions = mockTextModuleSuggestionsQuery({
      textModuleSuggestions: [
        {
          id: convertToGraphQLId('TextModule', '1'),
          name: 'bur - Bitte um Rückruf',
          keywords: null,
          renderedContent:
            '<p dir="auto">ich konnte Sie telefonisch nicht erreichen.</p><p dir="auto">Können Sie mir bitte eine kurze E-Mail schicken wenn Sie wieder verfügbar sind?</p>',
        },
      ],
    })

    await mountEditor(
      {},
      {
        permissions: ['ticket.agent'],
        config: { fqdn: 'example.zammad.com', http_type: 'http' },
      },
    )

    await userEvent.type(await findEditor(), '::bur')
    await waitForLastSearch(suggestions, { query: 'bur' })

    const popup = page.getByTestId('mention-text')

    await expect.element(popup).toMatchTextContent('Bitte um Rückruf')
    await popup.getByText(/Bitte um Rückruf/).click()

    await expect.poll(editorHtml).toContain('telefonisch nicht erreichen')
    await userEvent.keyboard('{Backspace}{Backspace}123')
    await expect.poll(editorHtml).toContain('verfügbar sin123')
    await expect
      .poll(editorHtml)
      .toContain(
        '<p dir="auto">ich konnte Sie telefonisch nicht erreichen.</p><p dir="auto">Können Sie mir bitte eine kurze E-Mail schicken wenn Sie wieder verfügbar sin123</p>',
      )
  })
})

describe('Testing "text" popup: "::" command after a line break', () => {
  const firstLine = 'ich konnte Sie telefonisch nicht erreichen.'
  const secondLine = 'Können Sie mir bitte eine kurze E-Mail schicken?'

  const editorValue = () => String(getNode('editor')?.value ?? '').replaceAll(' dir="auto"', '')

  const insertTextModule = async (typed: string, renderedContent: string) => {
    const suggestions = mockTextModuleSuggestionsQuery({
      textModuleSuggestions: [
        {
          id: convertToGraphQLId('TextModule', '1'),
          name: 'bur - Bitte um Rückruf',
          keywords: null,
          renderedContent,
        },
      ],
    })

    await mountEditor({}, { permissions: ['ticket.agent'] })

    await userEvent.type(await findEditor(), `${typed}::bur`)
    await waitForLastSearch(suggestions, { query: 'bur' })

    await page
      .getByTestId('mention-text')
      .getByText(/Bitte um Rückruf/)
      .click()
  }

  it('keeps the line break before a text', async () => {
    await insertTextModule('Hello{Shift>}{Enter}{/Shift}', firstLine)

    await expect.poll(editorValue).toBe(`<p>Hello<br>${firstLine}</p>`)
  })

  it('starts paragraphs on the line of the search', async () => {
    await insertTextModule(
      'Hello{Shift>}{Enter}{/Shift}',
      `<p>${firstLine}</p><p>${secondLine}</p>`,
    )

    await expect.poll(editorValue).toBe(`<p>Hello</p><p>${firstLine}</p><p>${secondLine}</p>`)
  })

  it('keeps the empty line before paragraphs on the line of the search', async () => {
    await insertTextModule(
      'Hello{Shift>}{Enter}{/Shift}{Shift>}{Enter}{/Shift}',
      `<p>${firstLine}</p><p>${secondLine}</p>`,
    )

    await expect.poll(editorValue).toBe(`<p>Hello<br></p><p>${firstLine}</p><p>${secondLine}</p>`)
  })

  it('keeps the empty line of a paragraph a line break opens, before paragraphs', async () => {
    await insertTextModule(
      'Hello{Enter}{Shift>}{Enter}{/Shift}',
      `<p>${firstLine}</p><p>${secondLine}</p>`,
    )

    await expect
      .poll(editorValue)
      .toBe(`<p>Hello</p><p></p><p>${firstLine}</p><p>${secondLine}</p>`)
  })
})

describe('Testing "text" popup: "::" command between words', () => {
  const text = 'ich konnte Sie telefonisch nicht erreichen.'

  const editorValue = () => String(getNode('editor')?.value ?? '').replaceAll(' dir="auto"', '')

  const mountWithTextModule = async () => {
    const suggestions = mockTextModuleSuggestionsQuery({
      textModuleSuggestions: [
        {
          id: convertToGraphQLId('TextModule', '1'),
          name: 'bur - Bitte um Rückruf',
          keywords: null,
          renderedContent: text,
        },
      ],
    })

    await mountEditor({}, { permissions: ['ticket.agent'] })

    return { editor: await findEditor(), suggestions }
  }

  const pickTextModule = async (
    suggestions: Awaited<ReturnType<typeof mountWithTextModule>>['suggestions'],
  ) => {
    await waitForLastSearch(suggestions, { query: 'bur' })
    await page
      .getByTestId('mention-text')
      .getByText(/Bitte um Rückruf/)
      .click()
  }

  it('keeps the space before a text', async () => {
    const { editor, suggestions } = await mountWithTextModule()

    await userEvent.type(editor, 'Hello ::bur')
    await pickTextModule(suggestions)

    await expect.poll(editorValue).toBe(`<p>Hello ${text}</p>`)
  })

  it('keeps the space after a text', async () => {
    const { editor, suggestions } = await mountWithTextModule()

    await userEvent.type(editor, 'Hello ::bur world')
    await pressCursorKey('{ArrowLeft}'.repeat(6))
    await pickTextModule(suggestions)

    await expect.poll(editorValue).toBe(`<p>Hello ${text} world</p>`)
  })

  it.each([
    ['after a word', 'Hello', `<p>Hello ${text}</p>`],
    ['after a space', 'Hello ', `<p>Hello ${text}</p>`],
    ['at the start of a line', '', `<p>${text}</p>`],
  ])('opens from the toolbar %s, with one space before the text', async (_, typed, value) => {
    const { editor, suggestions } = await mountWithTextModule()

    await editor.click()
    if (typed) await userEvent.keyboard(typed)

    await page.getByTestId('action-bar').getByLabelText('Insert text from text module').click()
    await userEvent.keyboard('bur')
    await pickTextModule(suggestions)

    await expect.poll(editorValue).toBe(value)
  })
})
