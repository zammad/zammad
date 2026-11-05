// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it, onTestFinished } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { useNotifications } from '#shared/components/CommonNotifications/index.ts'
import { mockMentionSuggestionsQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/mention/mentionSuggestions.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { findEditor, mountEditor, pressCursorKey, waitForLastSearch } from './browser-utils.ts'

describe('Testing "user mention" popup: "@@" command', () => {
  it('shows notification when no group is provided', async () => {
    const { notifications, clearAllNotifications } = useNotifications()

    onTestFinished(clearAllNotifications)

    await mountEditor({}, { permissions: ['ticket.agent'] })

    await userEvent.type(await findEditor(), '@@t')

    // The group is only looked up once the debounced search runs.
    await expect.poll(() => notifications.value).toHaveLength(1)
    expect(notifications.value[0].message).toBe('Before you mention a user, please select a group.')
  })

  it('inserts a user mention', async () => {
    const suggestions = mockMentionSuggestionsQuery({
      mentionSuggestions: [
        {
          id: convertToGraphQLId('User', '3'),
          internalId: 3,
          fullname: 'Bob Wance',
          email: 'bob@mail.com',
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
    await userEvent.type(editor, '@@Jo')
    await waitForLastSearch(suggestions, { query: 'Jo', groupId: convertToGraphQLId('Group', '1') })

    const popup = page.getByTestId('mention-user')

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
