// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { mockTextModuleSuggestionsQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/textModule/textModuleSuggestions.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { editorHtml, findEditor, mountEditor, waitForLastSearch } from './browser-utils.ts'

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
