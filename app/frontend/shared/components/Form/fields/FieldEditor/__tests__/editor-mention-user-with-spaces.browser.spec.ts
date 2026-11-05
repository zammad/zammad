// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { mockMentionSuggestionsQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/mention/mentionSuggestions.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { findEditor, mountEditor, pressCursorKey, waitForLastSearch } from './browser-utils.ts'

describe('Testing "user mention" popup: "@@" command', () => {
  it('inserts a user mention  > allows spaces in search', async () => {
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

    // But select Bob
    const popup = page.getByTestId('mention-user')

    await expect.element(popup).toMatchTextContent('John Doe')
    await expect.element(popup).toMatchTextContent('Bob Wance')
    await popup.getByText(/Bob Wance/).click()

    await expect.element(editor).toMatchTextContent('Bob Wance')
    // The insert focuses the editor again in the next animation frame, which also puts the cursor
    //   back to where the editor state has it.
    await new Promise(requestAnimationFrame)
    await userEvent.keyboard('{Backspace}{Backspace}')
    await pressCursorKey('{ArrowLeft}')
    await userEvent.keyboard('ndyke')
    await pressCursorKey('{ArrowRight}')
    await userEvent.keyboard('{Backspace}')
    await expect.element(editor).toMatchTextContent('Bob Wandyke') // can rename user

    const link = editor.getByRole('link')

    await expect.element(link).toMatchTextContent('Bob Wandyke')
    await expect.element(link).toHaveAttribute('data-mention-user-id', '3')
    await expect.element(link).toHaveAttribute('href', 'http://example.zammad.com/#user/profile/3')
  })
})
