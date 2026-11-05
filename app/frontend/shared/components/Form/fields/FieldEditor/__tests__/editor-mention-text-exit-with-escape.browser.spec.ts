// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { mockTextModuleSuggestionsQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/textModule/textModuleSuggestions.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { editorHtml, findEditor, mountEditor, waitForLastSearch } from './browser-utils.ts'

describe('Testing "text" popup: "::" command', () => {
  it('inserts a text > allows spaces in search but exit on Esc', async () => {
    const suggestions = mockTextModuleSuggestionsQuery({
      textModuleSuggestions: [
        {
          id: convertToGraphQLId('TextModule', '2'),
          name: 'fwf - Für weitere Fragen stehe ich...',
          keywords: null,
          renderedContent: 'Für weitere Fragen stehe ich gerne zur Verfügung!',
        },
      ],
    })

    await mountEditor({}, { permissions: ['ticket.agent'] })

    const editor = await findEditor()
    await userEvent.type(editor, '::weitere fragen') // supports space
    await waitForLastSearch(suggestions, { query: 'weitere fragen' })

    const popup = page.getByTestId('mention-text')

    await expect.element(popup).toBeInTheDocument()
    await userEvent.keyboard('{Escape}')
    await expect.element(popup).not.toBeInTheDocument()

    await expect.poll(editorHtml).toContain('<p dir="auto">::weitere fragen</p>')
    // Escape in any editor currently blurs it (see zammad/zammad#6525); `type` refocuses it.
    await userEvent.type(editor, '{Backspace}{Backspace}123')
    await expect.poll(editorHtml).toContain('<p dir="auto">::weitere frag123</p>')
    await userEvent.type(editor, '{ArrowLeft}{ArrowLeft}654')
    await expect.poll(editorHtml).toContain('<p dir="auto">::weitere frag165423</p>')
  })
})
