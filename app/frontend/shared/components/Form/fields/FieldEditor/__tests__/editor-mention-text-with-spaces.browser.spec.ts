// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { mockTextModuleSuggestionsQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/textModule/textModuleSuggestions.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { editorHtml, findEditor, mountEditor, waitForLastSearch } from './browser-utils.ts'

describe('Testing "text" popup: "::" command', () => {
  it('inserts a text > allows spaces in search', async () => {
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

    await userEvent.type(await findEditor(), '::weitere fragen') // supports space
    await waitForLastSearch(suggestions, { query: 'weitere fragen' })

    const popup = page.getByTestId('mention-text')

    await expect.element(popup).toMatchTextContent('Für weitere Fragen')
    await popup.getByText(/Für weitere Fragen/).click()

    await expect.poll(editorHtml).toContain('Für weitere Fragen stehe ich gerne zur Verfügung!')
    await userEvent.keyboard('{Backspace}{Backspace}123')
    await expect
      .poll(editorHtml)
      .toContain('<p dir="auto">Für weitere Fragen stehe ich gerne zur Verfügun123</p>')
  })
})
