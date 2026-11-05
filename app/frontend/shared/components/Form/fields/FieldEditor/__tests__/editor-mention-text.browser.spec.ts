// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { mockTextModuleSuggestionsQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/textModule/textModuleSuggestions.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { editorHtml, findEditor, mountEditor } from './browser-utils.ts'

describe('Testing "text" popup: "::" command', () => {
  it('inserts a text', async () => {
    const suggestions = mockTextModuleSuggestionsQuery({
      textModuleSuggestions: [
        {
          id: convertToGraphQLId('TextModule', '1'),
          name: 'ass - Anliegen sichten',
          keywords: null,
          renderedContent:
            '<p dir="auto">Vielen Dank für Ihre Anfrage.</p><p dir="auto">Wir werden Ihr Anliegen sichten und uns schnellstmöglich mit Ihnen in Verbindung setzen.</p>',
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

    await userEvent.type(await findEditor(), '::ass')

    const popup = page.getByTestId('mention-text')

    await expect.element(popup).toMatchTextContent('Anliegen sichten')
    await popup.getByText(/Anliegen sichten/).click()

    await expect.poll(editorHtml).toContain('Vielen Dank für Ihre Anfrage')
    await userEvent.keyboard('{Backspace}{Backspace}123')
    await expect.poll(editorHtml).toContain('Verbindung setze123')
    await expect
      .poll(editorHtml)
      .toContain(
        '<p dir="auto">Vielen Dank für Ihre Anfrage.</p><p dir="auto">Wir werden Ihr Anliegen sichten und uns schnellstmöglich mit Ihnen in Verbindung setze123</p>',
      )

    const [call] = await suggestions.waitForCalls()
    expect(call.variables).toMatchObject({ query: 'ass' })
  })
})
