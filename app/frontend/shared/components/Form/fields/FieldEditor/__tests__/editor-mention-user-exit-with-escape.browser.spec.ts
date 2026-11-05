// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { mockMentionSuggestionsQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/mention/mentionSuggestions.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { editorHtml, findEditor, mountEditor, waitForLastSearch } from './browser-utils.ts'

describe('Testing "user mention" popup: "@@" command', () => {
  it('inserts a user mention > allows spaces in search but exit on Esc', async () => {
    const suggestions = mockMentionSuggestionsQuery({
      mentionSuggestions: [
        {
          id: convertToGraphQLId('User', '3'),
          internalId: 3,
          fullname: 'Bob Wance',
          email: 'bob@example.com',
        },
        {
          id: convertToGraphQLId('User', '4'),
          internalId: 4,
          fullname: 'John Doe',
          email: 'john@mail.com',
        },
      ],
    })

    await mountEditor(
      { groupId: '1' },
      {
        permissions: ['ticket.agent'],
        config: { fqdn: 'example.zammad.com', http_type: 'http' },
      },
    )

    const editor = await findEditor()

    // Search for John
    await userEvent.type(editor, '@@Jo mail.com') // supports space
    await waitForLastSearch(suggestions, {
      query: 'Jo mail.com',
      groupId: convertToGraphQLId('Group', '1'),
    })

    const popup = page.getByTestId('mention-user')

    await expect.element(popup).toBeInTheDocument()
    await userEvent.keyboard('{Escape}')
    await expect.element(popup).not.toBeInTheDocument()

    await expect.poll(editorHtml).toContain('<p dir="auto">@@Jo mail.com</p>')
    // Escape in any editor currently blurs it (see zammad/zammad#6525); `type` refocuses it.
    await userEvent.type(editor, '{Backspace}{Backspace}123')
    await expect.poll(editorHtml).toContain('<p dir="auto">@@Jo mail.c123</p>')
    await userEvent.type(editor, '{ArrowLeft}{ArrowLeft}654')
    await expect.poll(editorHtml).toContain('<p dir="auto">@@Jo mail.c165423</p>')
  })
})
